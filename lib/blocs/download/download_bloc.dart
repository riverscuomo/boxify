import 'dart:async';
import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:boxify/app_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'download_event.dart';
part 'download_state.dart';

class DownloadBloc extends Bloc<DownloadEvent, DownloadState> {
  List<CancelToken> downloadTokens = [];

  DownloadBloc() : super(DownloadState.initial()) {
    on<InitialDownloadState>(_onInitialDownloadState);
    on<DownloadTracks>(_onDownloadTracks);
    on<SyncDownloadsWithAllTracks>(_onSyncDownloadsWithAllTracks);
    on<RemoveDownloadedTracks>(_onRemoveDownloadedTracks);
    on<RemoveDownloadsNotInAllTracks>(_onRemoveDownloadsNotInAllTracks);
    on<RemoveAllDownloads>(_onRemoveAllDownloads);
    on<UpdateDownloadProgress>(_onUpdateDownloadProgress);
    on<StopDownload>(_onStopAllDownloadsForPlaylist);
    on<DownloadError>(_onDownloadError);
  }

  @override
  Future<void> close() {
    for (var token in downloadTokens) {
      token.cancel("user canceled");
    }
    return super.close();
  }

  Future<void> _onInitialDownloadState(
    InitialDownloadState event,
    Emitter<DownloadState> emit,
  ) async {
    emit(state.copyWithPlaylistStatus(
        playlistId: event.playlistId, status: DownloadStatus.initial));
  }

  Future<void> _onDownloadTracks(
    DownloadTracks event,
    Emitter<DownloadState> emit,
  ) async {
    await _handleDownload(
        event.playlistId, event.tracksToDownload, event.userId, emit);
  }

  Future<void> _onSyncDownloadsWithAllTracks(
    SyncDownloadsWithAllTracks event,
    Emitter<DownloadState> emit,
  ) async {
    emit(state.copyWith(status: DownloadStatus.syncingDownloads));

    if (Core.app.type == AppType.basic) {
      await _handleDownload(null, event.tracksToDownload, event.userId, emit);
    }

    add(RemoveDownloadsNotInAllTracks(
        allTracks: event.tracksToDownload, userId: event.userId));

    emit(state.copyWith(status: DownloadStatus.syncingDownloadsCompleted));
  }

  Future<void> _handleDownload(
    String? playlistId, // Now optional
    List<Track> tracksToDownload,
    String userId,
    Emitter<DownloadState> emit,
  ) async {
    logger.i('_handleDownload: Attempting to start download.');

    if (kIsWeb) {
      logger.i('Download Bloc: Cannot start downloads on web platform.');
      emit(
        playlistId != null
            ? state
                .copyWithPlaylistStatus(
                  playlistId: playlistId,
                  status: DownloadStatus.error,
                )
                .copyWith(
                    errorMessage:
                        'Downloading is not supported on the web platform.')
            : state.copyWith(
                errorMessage:
                    'Downloading is not supported on the web platform.',
              ),
      );
      return;
    }

    emit(
      playlistId != null
          ? state
              .copyWithPlaylistStatus(
              playlistId: playlistId,
              status: DownloadStatus.preparing,
            )
              .copyWith(
                  tracksToUnDownload: [], tracksToDownload: tracksToDownload)
          : state.copyWith(
              tracksToUnDownload: [],
              tracksToDownload: tracksToDownload,
            ),
    );

    final localPath = await findLocalPath(userId);
    await prepareSaveDir(localPath);

    if (playlistId != null) {
      emit(
        state.copyWithPlaylistStatus(
          playlistId: playlistId,
          status: DownloadStatus.downloading,
        ),
      );
    }

    try {
      await _downloadTracks(tracksToDownload, playlistId, localPath, emit);
      if (!state.isDownloadCancelled) {
        emit(
          playlistId != null
              ? state.copyWithPlaylistStatus(
                  status: DownloadStatus.completed,
                  playlistId: playlistId,
                )
              : state,
        );
      }
    } catch (e) {
      emit(
        playlistId != null
            ? state
                .copyWithPlaylistStatus(
                  playlistId: playlistId,
                  status: DownloadStatus.error,
                )
                .copyWith(errorMessage: e.toString())
            : state.copyWith(errorMessage: e.toString()),
      );
      logger.e('Error during download: $e');
    }
  }

  Future<void> _downloadTracks(
    List<Track> tracksToDownload,
    String? playlistId, // Now optional
    String localPath,
    Emitter<DownloadState> emit,
  ) async {
    for (final track in tracksToDownload) {
      if (state.isDownloadCancelled) {
        logger.e('_downloadTracks: Download cancelled.');
        break;
      }

      final filePath = '$localPath/${track.uuid}.mp3';
      final file = File(filePath);

      // Check if the file already exists
      if (file.existsSync()) {
        // logger.i(
        //     '_downloadTracks: File for track ${track.uuid} already exists, skipping download.');

        // Add the existing track to the downloaded state
        final updatedTrack = track.copyWith(
            downloadedUrl: 'file:///$filePath',
            displayTitle: track.displayTitle);
        final updatedDownloadedTracks =
            Map<String, Track>.from(state.downloadedTracks)
              ..[track.uuid!] = updatedTrack;
        final updatedDownloadProgress =
            Map<String, double>.from(state.downloadProgress)
              ..[track.uuid!] = 1.0; // Mark as fully downloaded

        emit(
          playlistId != null
              ? state
                  .copyWithPlaylistStatus(
                    playlistId: playlistId,
                    status: DownloadStatus.downloading,
                  )
                  .copyWith(
                    downloadProgress: updatedDownloadProgress,
                    downloadedTracks: updatedDownloadedTracks,
                    downloadedCount: state.downloadedCount + 1,
                  )
              : state.copyWith(
                  downloadProgress: updatedDownloadProgress,
                  downloadedTracks: updatedDownloadedTracks,
                  downloadedCount: state.downloadedCount + 1,
                ),
        );

        continue; // Skip to the next track
      }

      // If file does not exist, proceed with downloading
      final trackDownloadTask = DownloadTask(
        url: track.link!,
        filename: '${track.uuid}.mp3',
        baseDirectory: BaseDirectory.root,
        directory: localPath,
        updates: Updates.statusAndProgress,
        requiresWiFi: true,
        retries: 3,
      );

      await FileDownloader().download(trackDownloadTask,
          onProgress: (progress) {
        // Pass null for playlistId if it's not available
        add(UpdateDownloadProgress(track, progress, playlistId));
      }, onStatus: (status) {
        _handleDownloadStatus(status, track, trackDownloadTask.taskId,
            localPath, playlistId, emit);
      });
    }
  }

  void _handleDownloadStatus(
    TaskStatus status,
    Track track,
    String taskId,
    String localPath,
    String? playlistId, // Now optional
    Emitter<DownloadState> emit,
  ) {
    if (status == TaskStatus.running) {
      final newDownloadTaskIds = Map<String, String>.from(state.downloadTaskIds)
        ..[track.uuid!] = taskId;
      emit(state.copyWith(downloadTaskIds: newDownloadTaskIds));
    }

    if (status == TaskStatus.complete) {
      final localFilePath = 'file:///$localPath/${track.uuid}.mp3';
      final updatedTrack = track.copyWith(
          downloadedUrl: localFilePath, displayTitle: track.displayTitle);

      final updatedDownloadedTracks =
          Map<String, Track>.from(state.downloadedTracks)
            ..[track.uuid!] = updatedTrack;
      final updatedDownloadProgress =
          Map<String, double>.from(state.downloadProgress)..[track.uuid!] = 1.0;

      emit(
        playlistId != null
            ? state
                .copyWithPlaylistStatus(
                  playlistId: playlistId,
                  status: DownloadStatus.downloading,
                )
                .copyWith(
                  downloadProgress: updatedDownloadProgress,
                  downloadedTracks: updatedDownloadedTracks,
                  downloadedCount: state.downloadedCount + 1,
                )
            : state.copyWith(
                downloadProgress: updatedDownloadProgress,
                downloadedTracks: updatedDownloadedTracks,
                downloadedCount: state.downloadedCount + 1,
              ),
      );
    }
  }

  void _onUpdateDownloadProgress(
    UpdateDownloadProgress event,
    Emitter<DownloadState> emit,
  ) {
    // Assume that trackDownloadProgress is a Map<String, double> with track UUID as key and progress as value
    final newDownloadProgress =
        Map<String, double>.from(state.downloadProgress);
    newDownloadProgress[event.track.uuid!] = event.progress;
    // logger.f(newDownloadProgress.toString());
    emit(state.copyWith(downloadProgress: newDownloadProgress));
  }

  Future<void> _onRemoveDownloadedTracks(
    RemoveDownloadedTracks event,
    Emitter<DownloadState> emit,
  ) async {
    logger.i('DownloadBloc: Removing downloaded playlist.');
    if (kIsWeb) {
      // Deletion of downloaded files is not applicable in a web environment.
      logger.i('DownloadBloc: Cannot remove downloads in a web environment.');
      return;
    }

    // Emit the `removing` status to indicate the start of the removal process
    emit(
      state.copyWithPlaylistStatus(
        playlistId: event.playlistId,
        status: DownloadStatus.removing,
      ),
    );

    emit(
      state
          .copyWithPlaylistStatus(
        playlistId: event.playlistId,
        status: DownloadStatus.preparing,
      )
          .copyWith(
        isDownloadCancelled: true,
        tracksToDownload: [],
      ),
    );

    // Find the path to local storage where the downloads are stored.
    final localPath = await findLocalPath(event.userId);

    // Cancel any on-going download tokens if they exist.
    for (var token in downloadTokens) {
      token.cancel("Cancellation requested by user.");
    }
    downloadTokens.clear();

    bool allDeleted = true;

    // Iterate through each track, attempt to delete and update its link.
    final updated = event.tracksToUnDownload.map((track) {
      final path = '$localPath/${track.uuid}.mp3';
      try {
        final file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
          logger.i('DownloadBloc: Deleted file at path: $path');
          return track.copyWith(
            downloadedUrl: '',
            displayTitle: track.displayTitle,
          );
        }
      } catch (e) {
        logger.e('DownloadBloc: Failed to delete file at path: $path. $e');
        allDeleted = false;
      }

      // If the file didn't exist but had a value for `downloadedUrl`, clear it
      return track.copyWith(
        downloadedUrl: '',
        displayTitle: track.displayTitle,
      );
    }).toList();

    if (allDeleted) {
      // Emit success state if all deletions were successful.
      final newDownloadedTracks =
          Map<String, Track>.from(state.downloadedTracks);

      // Remove the undownloaded tracks from the state:
      for (var track in event.tracksToUnDownload) {
        newDownloadedTracks.remove(track.uuid);
      }
      emit(
        state
            .copyWithPlaylistStatus(
              playlistId: event.playlistId,
              status: DownloadStatus.undownloaded,
            )
            .copyWith(
              tracksToUnDownload: updated,
              downloadedTracks: newDownloadedTracks,
              isDownloadCancelled: false,
            ),
      );
    } else {
      emit(
        state
            .copyWithPlaylistStatus(
              playlistId: event.playlistId,
              status: DownloadStatus.error,
            )
            .copyWith(
              errorMessage: 'Failed to delete one or more downloaded tracks.',
            ),
      );
    }
  }

  Future<void> _onRemoveDownloadsNotInAllTracks(
    RemoveDownloadsNotInAllTracks event,
    Emitter<DownloadState> emit,
  ) async {
    logger.i('DownloadBloc: Removing downloads not in all tracks.');
    if (kIsWeb) {
      // Deletion of downloaded files is not applicable in a web environment.
      logger.i('DownloadBloc: Cannot remove downloads in a web environment.');
      return;
    }

    // Find the path to local storage where the downloads are stored.
    final localPath = await findLocalPath(event.userId);

    // get a list of all the track ids from the files in the directory
    final allTrackIdsInPath = Directory(localPath)
        .listSync()
        .where((file) => file.path.endsWith('.mp3'))
        .map((file) => file.path.split('/').last.split('.').first)
        .toList();

    final uuidsToDelete = allTrackIdsInPath
        .where((uuid) => !event.allTracks.any((track) => track.uuid == uuid))
        .toList();

    // // Cancel any on-going download tokens if they exist.
    // for (var token in downloadTokens) {
    //   token.cancel("Cancellation requested by user.");
    // }
    // downloadTokens.clear();

    bool allDeleted = true;

    // Iterate through each uuid, attempt to delete and update its link.
    for (var uuid in uuidsToDelete) {
      final path = '$localPath/$uuid.mp3';
      try {
        final file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
          logger.i('DownloadBloc: Deleted file at path: $path');
        }
      } catch (e) {
        logger.e('DownloadBloc: Failed to delete file at path: $path. $e');
        allDeleted = false;
      }
    }

    //   /// in the case that the file didn't exist but had a value for downloadedUrl, let's wipe it out
    //   return track.copyWith(
    //       downloadedUrl: '', displayTitle: track.displayTitle);
    // }).toList();

    if (allDeleted) {
      // // Emit success state if all deletions were successful.
      // final newDownloadedTracks =
      //     Map<String, Track>.from(state.downloadedTracks);

      // // Remove the undownloaded tracks from the state:
      // for (var track in event.allTracks) {
      //   newDownloadedTracks.remove(track.uuid);
      // }
      // emit(state.copyWith(
      //   // tracksToDownload: [],
      //   // downloadedTracks: newDownloadedTracks,
      //   // isDownloadCancelled: false,
      //   status: DownloadStatus.completed,
      // ));
    } else {
      emit(
        state.copyWith(
          errorMessage: 'Failed to delete one or more downloaded tracks.',
        ),
      );
    }
  }

  void _onStopAllDownloadsForPlaylist(
    StopDownload event,
    Emitter<DownloadState> emit,
  ) async {
    // Emit a state indicating that the download has been cancelled
    emit(state.copyWith(isDownloadCancelled: true));
    final trackIds = event.playlistTracks.map((track) => track.uuid).toList();

    // Create a list to keep track of which track IDs were actually cancelled
    List<String> cancelledTrackIds = [];

    for (var trackId in trackIds) {
      final taskId = state.downloadTaskIds[trackId];
      if (taskId != null) {
        await FileDownloader().cancelTaskWithId(taskId);
        cancelledTrackIds.add(trackId!);
      }
    }

    // After canceling, clear the task IDs and progress for tracks that were cancelled
    final newDownloadTaskIds = Map<String, String>.from(state.downloadTaskIds)
      ..removeWhere((trackId, _) => cancelledTrackIds.contains(trackId));
    final newDownloadProgress = Map<String, double>.from(state.downloadProgress)
      ..removeWhere((trackId, _) => cancelledTrackIds.contains(trackId));

    // Emit new state with updated maps
    emit(state.copyWith(
      downloadTaskIds: newDownloadTaskIds,
      downloadProgress: newDownloadProgress,
      // Remove the tracks' statuses from playlistDownloadStatus if necessary
      playlistDownloadStatus:
          Map<String, DownloadStatus>.from(state.playlistDownloadStatus)
            ..remove(event.playlistId),
      // Reset other necessary parts of the state
    ));
    add(RemoveDownloadedTracks(
        tracksToUnDownload: event.playlistTracks,
        userId: event.userId,
        playlistId: event.playlistId));

    // Log completion and any updates for UI if necessary
    logger.i(
        'All downloads for playlist ${event.playlistId} have been cancelled.');

    // // Get track IDs from the provided playlist tracks
    // final trackIds = event.playlistTracks.map((track) => track.uuid);

    // // This will store the cancelled tasks' UUIDs
    // List<String> cancelledTaskUuids = [];

    // for (final trackId in trackIds) {
    //   // Retrieve the corresponding download task ID using track UUID
    //   final taskId = state.downloadTaskIds[trackId];
    //   if (taskId != null) {
    //     await FileDownloader().cancelTaskWithId(taskId);
    //     cancelledTaskUuids.add(trackId!);
    //   }
    // }

    // // Update state to remove the cancelled task IDs, and reset progress
    // final updatedTaskIds = Map<String, String>.from(state.downloadTaskIds)
    //   ..removeWhere((key, _) => cancelledTaskUuids.contains(key));
    // final updatedDownloadProgress =
    //     Map<String, double>.from(state.downloadProgress)
    //       ..removeWhere((key, _) => cancelledTaskUuids.contains(key));

    // emit(state.copyWith(
    //   downloadTaskIds: updatedTaskIds,
    //   downloadProgress: updatedDownloadProgress,
    //   // If desired, you can also update other parts of the state such as resetting the download status for the playlist
    //   playlistDownloadStatus: Map.from(state.playlistDownloadStatus)
    //     ..[event.playlistId] = DownloadStatus.initial,
    // ));
  }

  void _onDownloadError(
    DownloadError event,
    Emitter<DownloadState> emit,
  ) {
    emit(
      state
          .copyWithPlaylistStatus(
              playlistId: event.playlistId, status: DownloadStatus.error)
          .copyWith(
            errorMessage: event.errorMessage,
          ),
    );
  }

  Future<void> _onRemoveAllDownloads(
    RemoveAllDownloads event,
    Emitter<DownloadState> emit,
  ) async {
    logger.i('DownloadBloc: Removing all downloads');
    
    if (kIsWeb) {
      // Deletion of downloaded files is not applicable in a web environment.
      logger.i('DownloadBloc: Cannot remove downloads in a web environment.');
      return;
    }

    emit(state.copyWith(status: DownloadStatus.removing));

    // Find the path to local storage where the downloads are stored.
    final localPath = await findLocalPath(event.userId);
    
    // Cancel any on-going download tokens if they exist.
    for (var token in downloadTokens) {
      token.cancel("Cancellation requested by user.");
    }
    downloadTokens.clear();
    
    bool allDeleted = true;
    
    try {
      final directory = Directory(localPath);
      if (await directory.exists()) {
        // Get all mp3 files in the directory
        final files = directory.listSync()
            .where((file) => file.path.endsWith('.mp3'))
            .toList();
        
        logger.i('Found ${files.length} downloaded files to delete');
        
        // Delete each file
        for (var file in files) {
          try {
            if (file is File && await file.exists()) {
              await file.delete();
              logger.i('Deleted file: ${file.path}');
            }
          } catch (e) {
            logger.e('Error deleting file ${file.path}: $e');
            allDeleted = false;
          }
        }
      } else {
        logger.i('Download directory does not exist: $localPath');
      }
      
      // Get the filenames as UUIDs
      final downloadedTracks = Map<String, Track>.from(state.downloadedTracks);
      // Create an empty map for download progress
      final downloadProgress = Map<String, double>.from({});
      
      if (allDeleted) {
        emit(state.copyWith(
          status: DownloadStatus.completed,
          downloadedTracks: {}, // Clear the downloaded tracks
          downloadProgress: downloadProgress,
          downloadedCount: 0,
        ));
      } else {
        emit(state.copyWith(
          status: DownloadStatus.error,
          errorMessage: 'Failed to delete one or more downloaded tracks',
        ));
      }
    } catch (e) {
      logger.e('Error removing all downloads: $e');
      emit(state.copyWith(
        status: DownloadStatus.error,
        errorMessage: 'Error removing all downloads: $e',
      ));
    }
  }
}
