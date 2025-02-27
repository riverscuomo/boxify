import 'dart:async';
import 'dart:io';

import 'package:boxify/app_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: depend_on_referenced_packages
// needed in playlist_event

part 'playlist_tracks_event.dart';
part 'playlist_tracks_state.dart';

class PlaylistTracksBloc
    extends Bloc<PlaylistTracksEvent, PlaylistTracksState> {
  final PlaylistRepository _playlistRepository;

  PlaylistTracksBloc({
    required PlaylistRepository playlistRepository,
  })  : _playlistRepository = playlistRepository,
        super(PlaylistTracksState.initial()) {
    /// PlaylistTracks Bloc
    on<SelectTrackForAddingToPlaylist>(_onSelectTrackForAddingToPlaylist);
    on<AddTrackToPlaylist>(_onAddTrackToPlaylist);
    on<RemoveTrackFromPlaylist>(_onRemoveTrackFromPlaylist);
    on<MoveTrack>(_onMoveTrack);
    on<PlaylistTracksReset>(_onPlaylistTracksReset);
  }

  Future<void> _onPlaylistTracksReset(
    PlaylistTracksReset event,
    Emitter<PlaylistTracksState> emit,
  ) async {
    emit(state.copyWith(status: PlaylistTracksStatus.initial));
  }

  Future<void> _onAddTrackToPlaylist(
    AddTrackToPlaylist event,
    Emitter<PlaylistTracksState> emit,
  ) async {
    logger.i('addTrackToPlaylist: ');

    // Indicate that an update operation is in progress
    emit(state.copyWith(status: PlaylistTracksStatus.updating));

    final playlist = event.playlist;

    try {
      // Perform the operation to add the track to the playlist
      await _playlistRepository.addTrackToPlaylist(
        playlistId: playlist.id!,
        track: event.track,
      );

      // Create an updated playlist with the new track added
      Playlist updatedPlaylist = playlist.copyWith(
        trackIds: List.from(playlist.trackIds)..add(event.track.uuid!),
        total: playlist.total + 1,
        updated:
            Timestamp.fromDate(DateTime.now()), // Convert DateTime to Timestamp
      );

      // Emit the new state with the updated playlist
      emit(
        state.copyWith(
          updatedPlaylist: updatedPlaylist,
          status: PlaylistTracksStatus.updated,
        ),
      );
    } catch (e) {
      // Log the error
      logger.e('Failed to add track to playlist: $e');

      // Emit the error state or failure state, based on your state management
      emit(
        state.copyWith(
          status: PlaylistTracksStatus.error,
        ),
      );
    }
  }

  Future<void> _onMoveTrack(
      MoveTrack event, Emitter<PlaylistTracksState> emit) async {
    // Indicate that an update operation is in progress
    emit(state.copyWith(status: PlaylistTracksStatus.updating));

    final playlist = event.playlist;

    try {
      final List<String> trackIds = playlist.trackIds;
      final String trackId = trackIds.removeAt(event.oldIndex);
      trackIds.insert(event.newIndex, trackId);

      await _playlistRepository.setPlaylistSequence(
        playlistId: playlist.id!,
        trackIds: trackIds,
      );

      final updatedPlaylist = playlist.copyWith(
        trackIds: trackIds,
        updated:
            Timestamp.fromDate(DateTime.now()), // Convert DateTime to Timestamp
      );

      // Emit a new state with the updated playlist if the operation succeeded
      emit(state.copyWith(
        updatedPlaylist: updatedPlaylist,
        status: PlaylistTracksStatus.updated,
      ));
    } catch (error) {
      // Handle the error state by emitting an error state or logging the error
      logger.e('Failed to move track: $error');
      emit(state.copyWith(status: PlaylistTracksStatus.error));
    }
  }

  Future<void> _onRemoveTrackFromPlaylist(
    RemoveTrackFromPlaylist event,
    Emitter<PlaylistTracksState> emit,
  ) async {
    logger.i('removeTrackFromPlaylist bloc ');
    emit(state.copyWith(status: PlaylistTracksStatus.updating));

    final playlist = event.playlist;

    try {
      await _playlistRepository.removeTrackFromPlaylist(
        playlistId: playlist.id!,
        index: event.index,
      );

      // Create an updated playlist with the track removed
      Playlist updatedPlaylist = playlist.copyWith(
        trackIds: List.from(playlist.trackIds)
          ..remove(playlist.trackIds[event.index]),
        total: playlist.total - 1,

        updated:
            Timestamp.fromDate(DateTime.now()), // Convert DateTime to Timestamp
      );

      emit(
        state.copyWith(
          updatedPlaylist: updatedPlaylist,
          status: PlaylistTracksStatus.updated,
        ),
      );
    } catch (e) {
      // Log the error
      logger.e('Failed to remove track from playlist: $e');

      // Emit the error state or failure state, based on your state management
      emit(
        state.copyWith(
          status: PlaylistTracksStatus.error,
        ),
      );
    }
  }

  Future<void> _onSelectTrackForAddingToPlaylist(
    SelectTrackForAddingToPlaylist event,
    Emitter<PlaylistTracksState> emit,
  ) async {
    logger.i('selectTrackForAddingToPlaylist bloc ${event.track.title} ');

    emit(
      state.copyWith(
        trackToAdd: event.track,
      ),
    );
  }
}
