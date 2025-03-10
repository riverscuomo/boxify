import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:boxify/app_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:equatable/equatable.dart';

part 'player_event.dart';
part 'my_player_state.dart';

/// `PlayerBloc` is a Business Logic Component (BLOC) responsible for managing
/// the audio playback state of the application. It receives `PlayerEvent`s,
/// which it translates into changes in the `MyPlayerState`. This bloc is an
/// essential part of the application's state management architecture and is
/// designed to be the single source of truth for all audio playback operations.
///
/// The `PlayerBloc` reacts to a variety of events such as play, pause, stop,
/// seek, and load new tracks. It manages the `AudioPlayer` instance and
/// a `ConcatenatingAudioSource` that holds the playlist's audio sources.
///
/// The bloc ensures a decoupled and testable approach to handling playback
/// logic, keeping playback concerns separate from UI and data layers.
///
/// Usage Example:
/// ```dart
/// final playerBloc = PlayerBloc(audioPlayer: myAudioPlayer, audioSource: myAudioSource);
/// playerBloc.add(PlayEvent(track: myTrack));
/// ```
///
/// Handling transitions between player states (e.g., loading, playing, paused) should reflect
/// changes in the UI accordingly, providing a reactive and smooth user experience.
class PlayerBloc extends Bloc<PlayerEvent, MyPlayerState> {
  final AudioPlayer _audioPlayer;
  StreamSubscription<PositionDiscontinuity>? _discontinuitySubscription;

  PlayerBloc({
    required AudioPlayer audioPlayer,
  })  : _audioPlayer = audioPlayer,
        super(MyPlayerState.initial(
          player: audioPlayer,
        )) {
    // logger.f('playerBloc: Player hashcode = ${audioPlayer.hashCode}');

    on<PlayerReset>(_onPlayerReset);
    on<StartPlayback>(_onStartPlayback);
    on<LoadPlayer>(_onLoadPlayer);
    on<Play>(_onPlay);
    on<SeekToNext>(_onSeekToNext);
    on<SeekToPrevious>(_onSeekToPrevious);
    on<SeekToIndex>(_onSeekToIndex);
    on<NotifyAutoAdvance>(_onNotifyAutoAdvance);
    on<UpdateTrackBackgroundColor>(_onUpdateTrackBackgroundColor);

    _discontinuitySubscription =
        _audioPlayer.positionDiscontinuityStream.listen((discontinuity) {
      if (discontinuity.reason == PositionDiscontinuityReason.autoAdvance) {
        add(NotifyAutoAdvance());
      }
    });
  }

  @override
  Future<void> close() {
    _discontinuitySubscription?.cancel();
    // Check if a track is already playing
    if (state.player.playing) {
      state.player.stop(); // Stop the current track
    }
    _audioPlayer.dispose();

    return super.close();
  }

  /// was causing a memory leak https://github.com/riverscuomo/flutter-apps/issues/104
  Future<void> _onPlayerReset(
    PlayerReset event,
    Emitter<MyPlayerState> emit,
  ) async {
    // Assuming you want to completely reset the player
    await _audioPlayer.stop(); // Stop any current playback
    await _audioPlayer.seek(Duration
        .zero); // Seek to the beginning of the audio source if necessary
    await _audioPlayer
        .dispose(); // If you need to dispose of the current instance

    emit(MyPlayerState.initial(player: _audioPlayer));
  }

  Future<void> _onPlay(Play event, Emitter<MyPlayerState> emit) async {
    logger.i('bloc _play at index ${state.player.currentIndex}');
    emit(state.copyWith(status: PlayerStatus.loading));
    // Check if a track is already playing
    if (state.player.playing) {
      await state.player.stop(); // Stop the current track
    }
    state.player.play();
    emit(state.copyWith(player: state.player, status: PlayerStatus.loaded));

    // logger.i('done play ${state.player.currentIndex}');
  }

  Future<void> _onNotifyAutoAdvance(
    NotifyAutoAdvance event,
    Emitter<MyPlayerState> emit,
  ) async {
    if (state.status != PlayerStatus.playPressed) {
      logger.i('bloc _onNotifyAutoAdvance');
      emit(state.copyWith(
        status: PlayerStatus.loading,
      ));
      emit(state.copyWith(
        status: PlayerStatus.loaded,
        player: state.player,
      ));
    }
  }

  Future<void> _onStartPlayback(
    StartPlayback event,
    Emitter<MyPlayerState> emit,
  ) async {
    logger.i('_onStartPlayback PlayerStatus.playPressed');
    emit(
        state.copyWith(status: PlayerStatus.playPressed, source: event.source));

    final trackIndexMapping = createTrackIndexMapping(event.tracks);
    final audioSourceIndex = trackIndexMapping[event.index];

    final availableTracksInEvent =
        event.tracks.where((track) => track.available == true).toList();

    final queue =
        state.queue.where((track) => track.available == true).toList();

    if (!areTrackListsEqual(availableTracksInEvent, queue)) {
      emit(state.copyWith(queue: availableTracksInEvent));
      logger.i(
          'User has requested a new queue (tracks != state.queue) so setting audio source');
      await _setAudioSource(availableTracksInEvent);
    }

    if (audioSourceIndex != null &&
        audioSourceIndex != state.player.currentIndex) {
      logger.i(
          'audioSourceIndex $audioSourceIndex != state.player.currentIndex ${state.player.currentIndex} so seeking to $audioSourceIndex');

      // // Update currentIndex in PlayerState
      // emit(
      //   state.copyWith(
      //     status: PlayerStatus.playing,
      //     queue: availableTracksInEvent,
      //   ),
      // );

      // Seek to the desired index in AudioPlayer
      await state.player.seek(Duration.zero, index: audioSourceIndex);
    }
    // Emit the updated state with status playing
    emit(
      state.copyWith(
        status: PlayerStatus.playing,
        // queue: availableTracksInEvent,
      ),
    );

    await state.player.play(); // Start playback
  }

  // Future<void> _onStartPlayback(
  //   StartPlayback event,
  //   Emitter<MyPlayerState> emit,
  // ) async {
  //   logger.i('_onStartPlayback PlayerStatus.playPressed');
  //   // logger.i(state.player.currentIndex);
  //   emit(state.copyWith(status: PlayerStatus.playPressed));
  //   // logger.i(state.player.currentIndex);

  //   final trackIndexMapping = createTrackIndexMapping(event.tracks);
  //   final audioSourceIndex = trackIndexMapping[event.index];

  //   final availableTracksInEvent = event.tracks
  //       .where((track) => track.available == true)
  //       .toList(); // filtering out unavailable tracks

  //   final queue = state.queue
  //       .where((track) => track.available == true)
  //       .toList(); // filtering out unavailable tracks

  //   /// If the user has requested a new queue by either:
  //   /// - clicking the [PlayButtonInCircle] for the first time to play a unqueued playlist
  //   /// - tapping on an unqueued playlist track
  //   if (!areTrackListsEqual(availableTracksInEvent, queue)) {
  //     logger.i(
  //         'user has requested a new queue (tracks != state.queue) so setting audiosource');

  //     await _setAudioSource(availableTracksInEvent);
  //   }

  //   /// If you've clicked in a list at an index that is not the current index
  //   if (audioSourceIndex != null &&
  //       audioSourceIndex != state.player.currentIndex) {
  //     logger.d(
  //         'audioSourceIndex $audioSourceIndex != state.player.currentIndex ${state.player.currentIndex} so seeking to $audioSourceIndex');
  //     add(SeekToIndex(index: audioSourceIndex));

  //     emit(
  //       state.copyWith(
  //         status: PlayerStatus.playing,
  //         player: state.player,
  //         queue: availableTracksInEvent,
  //       ),
  //     );
  //   }

  //   state.player
  //       .play(); // don't add the event Play() because that fire before Seek is done
  //   logger.i('emitting PlayerStatus.playing');
  //   emit(
  //     state.copyWith(
  //       status: PlayerStatus.playing,
  //       queue: availableTracksInEvent,
  //     ),
  //   );
  // }

  Future<void> _onLoadPlayer(
    LoadPlayer event,
    Emitter<MyPlayerState> emit,
  ) async {
    logger.i('_onLoadPlayer Player with new tracks.');

    emit(state.copyWith(status: PlayerStatus.loading));

    try {
      final r = await _setAudioSource(event.tracks);

      logger.i('done setting audio source so emitting PlayerStatus.loaded');

      emit(
        state.copyWith(
          status: PlayerStatus.loaded,
          player: state.player,
          queue: event.tracks,
        ),
      );
    } catch (err) {
      logger.e('Error setting audio source: $err');
      emit(
        state.copyWith(
          status: PlayerStatus.error,
          // Consider defining an appropriate error message and passing it in the Failure
          failure:
              Failure(code: err.hashCode.toString(), message: err.toString()),
        ),
      );
    }
  }

  Future<void> _onSeekToIndex(
    SeekToIndex event,
    Emitter<MyPlayerState> emit,
  ) async {
    logger.i('_onSeekToIndex #${event.index}');
    emit(state.copyWith(status: PlayerStatus.loading));
    // Check if a track is already playing
    // if (state.player.playing) {
    //   await state.player.stop(); // Stop the current track
    // }
    await state.player.seek(Duration.zero, index: event.index);

    // logger.i('done emmitting _onSeekToIndex #${event.index}');
    emit(state.copyWith(player: state.player, status: PlayerStatus.loaded));
  }

  Future<void> _onSeekToNext(
    SeekToNext event,
    Emitter<MyPlayerState> emit,
  ) async {
    emit(state.copyWith(status: PlayerStatus.loading));
    // logger.i('bloc seekToNext');
    await state.player.seekToNext();
    emit(state.copyWith(status: PlayerStatus.loaded));
    // emit(
    //   state.copyWith(
    //     selectedIndex: state.player.currentIndex!,
    //   ),
    // );
  }

  Future<void> _onSeekToPrevious(
    SeekToPrevious event,
    Emitter<MyPlayerState> emit,
  ) async {
    logger.i('bloc seek to previous');
    emit(state.copyWith(status: PlayerStatus.loading));
    await state.player.seekToPrevious();
    // while (state.queue[state.player.currentIndex!].available == false) {
    //   logger.i('skipping ${state.queue[state.player.currentIndex!].title}');
    //   await state.player.seekToPrevious();
    // }
    // emit(
    //   state.copyWith(
    //     selectedIndex: state.player.currentIndex,
    //   ),
    // );
    emit(state.copyWith(status: PlayerStatus.loaded));
  }

  String cleanUrlKeepRaw(String url) {
    // url = url.split('?')[0]; // remove query params from url
    // url += '?raw=1'; // add raw=1 to url
    // url = url.replaceAll('scl/fi', 's'); // replace spaces with %20
    url = url.replaceAll('www.dropbox.com',
        'dl.dropboxusercontent.com'); // replace spaces with %20
    return url;
  }

  /// Returns a [Future] that completes after adding state.displayedTracks to [audioSource].
  ///
  /// This asynchronous function converts each selected track to an [AudioSource]
  /// with a URI and [MediaItem] (containing track metadata) as parameters and then adds them to
  /// the [ConcatenatingAudioSource] instance referred to by [audioSource].
  ///
  /// The [MediaItem] is used to display metadata in the notification. Unique ID is given
  /// for each track and Dropbox file links are parsed to fetch raw artwork file and track file.
  Future<void> _setAudioSource(List<Track> tracks) async {
    logger.i('_setAudioSource');
    final audioSource = ConcatenatingAudioSource(children: []);

    try {
      await audioSource.addAll(
        tracks
            .where(
                (track) => track.available!) // filtering out unavailable tracks
            .map(
          (track) {
            var url =
                (track.downloadedUrl == null || track.downloadedUrl!.isEmpty)
                    ? track.link!
                    : track.downloadedUrl;

            // url = url!.split('?')[0]; // remove query params from url
            logger.i(url);
            // String cleanedUrl = cleanUrlKeepRaw();
            // logger.d(cleanedUrl);

            if (kIsWeb) {
              // If problems on web, maybe it has something to do with renaming the files with
              // and index number? Consider handling?
            }
            // print(url);
            url = Utils.sanitizeUrl(url!);

            return AudioSource.uri(
              Uri.parse(
                url,
              ),
              tag: MediaItem(
                // Specify a unique ID for each media item:
                id: track.uuid!,
                // Metadata to display in the notification:
                album: track.album,
                title: track.displayTitle,
                artUri: Uri.parse(track.imageUrl!),
              ),
            );
          },
        ).toList(),
      );
      logger.i('done adding tracks to audio source');
      await state.player.setAudioSource(audioSource);
      logger.f('done setting audio source');
    } catch (e) {
      logger.e('Error setting audio source: $e');
    }
  }

  /// Updates the background color of the player based on the track's cover image.
  Future<void> _onUpdateTrackBackgroundColor(
    UpdateTrackBackgroundColor event,
    Emitter<MyPlayerState> emit,
  ) async {
    logger.i('_onUpdateTrackBackgroundColor');
    emit(state.copyWith(backgroundColor: event.backgroundColor));
  }
}
