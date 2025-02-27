part of 'download_bloc.dart';

abstract class DownloadEvent extends Equatable {
  const DownloadEvent();

  @override
  List<Object?> get props => [];
}

class DownloadTracks extends DownloadEvent {
  final List<Track> tracksToDownload;
  final String userId;
  final String playlistId;

  const DownloadTracks(
      {required this.tracksToDownload,
      required this.userId,
      required this.playlistId});

  @override
  List<Object> get props => [tracksToDownload, userId, playlistId];
}

class SyncDownloadsWithAllTracks extends DownloadEvent {
  final List<Track> tracksToDownload;
  final String userId;

  const SyncDownloadsWithAllTracks({
    required this.tracksToDownload,
    required this.userId,
  });

  @override
  List<Object> get props => [tracksToDownload, userId];
}

class RemoveDownloadedTracks extends DownloadEvent {
  final List<Track> tracksToUnDownload;
  final String userId;
  final String playlistId;

  const RemoveDownloadedTracks(
      {required this.tracksToUnDownload,
      required this.userId,
      required this.playlistId});

  @override
  List<Object> get props => [tracksToUnDownload, userId, playlistId];
}

class RemoveDownloadsNotInAllTracks extends DownloadEvent {
  final List<Track> allTracks;
  final String userId;

  const RemoveDownloadsNotInAllTracks({
    required this.allTracks,
    required this.userId,
  });

  @override
  List<Object> get props => [allTracks, userId];
}

class UpdateDownloadProgress extends DownloadEvent {
  final Track track;
  final double progress;
  final String? playlistId; // Now optional

  UpdateDownloadProgress(this.track, this.progress, this.playlistId);

  @override
  List<Object?> get props => [track, progress, playlistId];
}

class StopDownload extends DownloadEvent {
  final String playlistId;
  final List<Track> playlistTracks;
  final String userId;

  StopDownload({
    required this.playlistId,
    required this.playlistTracks,
    required this.userId,
  });

  @override
  List<Object> get props => [
        playlistId,
        playlistTracks,
        // trackId,
        // taskId
      ];
}

class DownloadError extends DownloadEvent {
  final String errorMessage;
  final String playlistId;

  const DownloadError(this.errorMessage, this.playlistId);

  @override
  List<Object> get props => [errorMessage, playlistId];
}

class InitialDownloadState extends DownloadEvent {
  final String playlistId;

  const InitialDownloadState(this.playlistId);
  @override
  List<Object?> get props => [playlistId];
}

class RemoveAllDownloads extends DownloadEvent {
  final String userId;

  const RemoveAllDownloads({
    required this.userId,
  });

  @override
  List<Object> get props => [userId];
}
