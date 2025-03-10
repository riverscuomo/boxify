import 'package:boxify/app_core.dart';

import 'package:flutter/material.dart';

enum PlayType {
  play,
  updateQueueFromIndexAndPlay,
}

/// A service that handles actions related to player in an application
///
/// This class defines the services associated with the media player
/// across the application. Currently, it has one method -- [handlePlay] for playing the selected track
class PlayerService {
  /// This function handles the action of playing a track or a playlist
  ///
  /// If the track is available, it dispatches the `Play` event to the [UserBloc] which
  /// results in the track starting to play.
  /// If the track is not available, it presents a [SnackBar] to the user
  /// stating that they can purchase the corresponding bundle in the Market.
  ///
  /// Parameters:
  /// - `context` ([BuildContext]): the context in which the function is executed
  /// - `track` ([Track]): the track that should be played
  /// - `userBloc` ([UserBloc]): the player bloc to handle play related actions
  ///
  final PlayerBloc _playerBloc;
  final TrackBloc _trackBloc;
  final PlaylistBloc _playlistBloc;

  PlayerService(this._playerBloc, this._trackBloc, this._playlistBloc);

  /// This function handles the action of playing a track or a playlist.
  ///
  /// Use cases:
  /// - Playing the [queue] from the [PlayerScreen].
  /// - Playing a [Playlist] from the home screen: should select the playlist, select the first track, and play the track.
  /// - Playing a [Playlist] from the playlist screen: should select the playlist, select the first track, and play the track.
  /// - Playing a [Track] from the [TrackScreen]: should select the track and play the track.
  /// - Play a [Track] from the [BasePlaylistScreen]: should select the track and play the track.
  /// - Toggling the play button between play and pause from either screen listen above.
  ///
  /// You can pass updateQueue as true to always reninit the player,
  /// such as double tapping a Track Row, or double tapping a playlist widget in the
  /// library sidebar.
  /// Otherwise this function will check to see if the track is already playing.

  ///
  /// Furthermore, in the case of Weezify, this function should check if the track is available before playing.
  /// In either case, this function returns a boolean value indicating whether the track was played.
  ///
  /// Parameters:
  /// - `track` ([Track]): the track that should be played
  /// - `selectPlaylist` ([bool]): whether the playlist should be selected
  /// - `selectTrack` ([bool]): whether the track should be selected
  /// - `updateQueue` ([bool]): whether the player should be reinitialized
  /// - `index` ([int]): the index of the track to be played
  /// - `source` ([String]): the source of the track (where it's being played from - e.g. 'PLAYLIST', 'SEARCH', etc.)
  bool handlePlay({
    List<Track>? tracks,
    Playlist? playlist,
    int? index,
    required String source,
  }) {
    /// If you're simply toggling the play button for the current track
    if (tracks == null) {
      _playerBloc.add(Play());
      return true;
    } else {
      /// Two quick checks:
      /// 1. If the track is not available, show a snack
      /// 2. If there are no available tracks, show a snack
      if (index != null) {
        if (tracks[index].available != true) {
          return false;
        }
      } else {
        // iterate through _trackBloc.state.displayedTracks and check if any tracks are available
        // if none are available, return false
        // if any are available, set updateQueue to true
        // if any are available, set track to the first available track
        var containsAvailable = false;
        for (Track track in tracks) {
          if (track.available == true) {
            // updateQueue = true;
            // index = 0; // because now updateQueue only loads the tracks.available
            containsAvailable = true;
            break;
          }
        }
        if (!containsAvailable) {
          return false;
        }
      }

      // Enqueue playlist if it's not already enqueued
      // Note: playlist can be null (e.g. when playing from search results), will reset the queue
      if (_playlistBloc.state.enquedPlaylist != playlist) {
        if (playlist == null) {
          _playlistBloc.add(ResetEnqueuedPlaylist());
        } else {
          _playlistBloc.add(SetEnqueuedPlaylist(playlist: playlist));
        }
      }

      _playerBloc.add(StartPlayback(
        tracks: tracks,
        index: index,
        source: source,
      ));

      return true;
    }
  }

  bool isPlaying(Track track) {
    // wait but what about indexWithinPlayableTracks
    if (_playlistBloc.state.enquedPlaylist !=
        _playlistBloc.state.viewedPlaylist) {
      return false;
    }
    final isPlaying = _playerBloc.state.player.currentIndex ==
        _trackBloc.state.displayedTracksPlayable.indexOf(track);
    return isPlaying;
  }

  TrackPlayingState getPlayingState(Track track) {
    // wait but what about indexWithinPlayableTracks
    if (isPlaying(track)) {
      return _playerBloc.state.player.playing
          ? TrackPlayingState.playing
          : TrackPlayingState.paused;
    } else {
      return TrackPlayingState.unselected;
    }
  }
}

enum TrackPlayingState {
  playing,
  paused,
  unselected,
}

/// This function creates a mapping between the displayed track indices and the audio source indices.
Map<int, int> createTrackIndexMapping(List<Track> tracks) {
  Map<int, int> trackIndexMapping = {};
  int audioSourceIndex = 0;

  for (int displayIndex = 0; displayIndex < tracks.length; displayIndex++) {
    final track = tracks[displayIndex];

    // If the track has a local file, then use that
    if (track.downloadedUrl?.isNotEmpty == true) {
      trackIndexMapping[displayIndex] = audioSourceIndex++;
    }
    // If the track has a link, then use that
    else if (track.link?.isNotEmpty == true) {
      trackIndexMapping[displayIndex] = audioSourceIndex++;
    }

    // Otherwise, the track is not available, so don't add it to the mapping
  }

  return trackIndexMapping;
}

bool areTrackListsEqual(List<Track> list1, List<Track> list2) {
  if (list1.length != list2.length) {
    return false;
  }

  for (int i = 0; i < list1.length; i++) {
    if (list1[i].uuid != list2[i].uuid) {
      return false;
    }
  }
  return true;
}
