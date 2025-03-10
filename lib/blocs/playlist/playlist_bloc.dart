import 'dart:async';

import 'package:boxify/app_core.dart';
import 'package:boxify/enums/load_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
// ignore: depend_on_referenced_packages
// needed in playlist_event

part 'playlist_event.dart';
part 'playlist_state.dart';

class PlaylistBloc extends Bloc<PlaylistEvent, PlaylistState> {
  final AuthBloc _authBloc;
  final TrackBloc _trackBloc;

  final PlaylistRepository _playlistRepository;
  final UserRepository _userRepository;
  final PlaylistHelper _playlistHelper;
  final CacheHelper _cacheHelper;

  PlaylistBloc({
    required AuthBloc authBloc,
    required TrackBloc trackBloc,
    required UserRepository userRepository,
    required TrackRepository trackRepository,
    required PlaylistRepository playlistRepository,
    required MetaDataRepository metaDataRepository,
    required StorageRepository storageRepository,
    required BundleRepository bundleRepository,
  })  : _authBloc = authBloc,
        _trackBloc = trackBloc,
        _playlistRepository = playlistRepository,
        _userRepository = userRepository,
        _playlistHelper = PlaylistHelper(),
        _cacheHelper = CacheHelper(),
        super(PlaylistState.initial()) {
    on<LoadAllPlaylists>(_onLoadAllPlaylists);
    on<InitialPlaylistState>(_onInitialState);
    on<SetEditingPlaylist>(_onSetEditingPlaylist);
    on<SetEnqueuedPlaylist>(_onSetEnqueuedPlaylist);
    on<ResetEnqueuedPlaylist>(_onResetEnqueuedPlaylist);
    on<LoadFollowedPlaylists>(_onLoadFollowedPlaylists);
    on<Load4And5StarPlaylists>(_onLoad4And5StarPlaylists);
    on<LoadAllSongsPlaylist>(_onLoadAllSongsPlaylist);

    on<LoadLikedSongsPlaylist>(_onLoadLikedSongs);
    on<LoadNewReleasesPlaylist>(_onLoadNewReleases);
    on<PlaylistCreated>(_onPlaylistCreated);
    on<PlaylistFollowed>(_onPlaylistFollowed);
    on<PlaylistUpdated>(_onPlaylistUpdated);
    on<PlaylistDeleted>(_onPlaylistDeleted);
    on<PlaylistUnfollowed>(_onPlaylistUnfollowed);
    on<LoadUnratedPlaylist>(_onLoadUnratedPlaylist);

    /// JUST LOAD ALL THE PLAYLISTS AGAIN
    on<SetViewedPlaylist>(_onSetViewedPlaylist);
    on<SetPlaylistIdPassedToUrl>(_onSetPlaylistIdPassedToUrl);
  }

  Future<void> _onInitialState(
    InitialPlaylistState event,
    Emitter<PlaylistState> emit,
  ) async {
    emit(state.copyWith(status: PlaylistStatus.initial));
  }

  /// Loads the likedSongsPlaylist asynchronously.
  /// This method is responsible for loading the likedSongsPlaylist from state.allPlaylists
  /// It is an asynchronous operation and returns a [Future] that completes when the loading is finished.
  Future<void> _onLoadLikedSongs(
    LoadLikedSongsPlaylist event,
    Emitter<PlaylistState> emit,
  ) async {
    final likedSongsPlaylist =
        _playlistHelper.createLikedSongsPlaylist(event.user, event.ratings);

    final updatedViewedPlaylist = event.user.id == state.viewedPlaylist?.id
        ? likedSongsPlaylist
        : state.viewedPlaylist;

    emit(state.copyWith(
      likedSongsPlaylist: likedSongsPlaylist,
      viewedPlaylist: updatedViewedPlaylist,
      status: PlaylistStatus.likedSongsPlaylistLoaded,
    ));
  }

  Future<void> _onSetEditingPlaylist(
    SetEditingPlaylist event,
    Emitter<PlaylistState> emit,
  ) async {
    emit(state.copyWith(editingPlaylist: event.playlist));
  }

  Future<void> _onSetEnqueuedPlaylist(
    SetEnqueuedPlaylist event,
    Emitter<PlaylistState> emit,
  ) async {
    logger.f('_onSetEnqueuedPlaylist');
    emit(state.copyWith(status: PlaylistStatus.enqueuedPlaylistLoading));

    try {
      emit(state.copyWith(
        enquedPlaylist: event.playlist,
        status: PlaylistStatus.enqueuedPlaylistLoaded,
      ));
    } catch (err, s) {
      logger.e('error in _onSetEnqueuedPlaylist: $err\n$s');
      emit(
        state.copyWith(
          status: PlaylistStatus.error,
          failure: Failure(
            message: 'PlayerBloc._onSetEnqueuedPlaylist: ${err.toString()}.',
          ),
        ),
      );
    }
  }

  /// Reset the enqueued playlist to null
  Future<void> _onResetEnqueuedPlaylist(
    ResetEnqueuedPlaylist event,
    Emitter<PlaylistState> emit,
  ) async {
    // enqueued playlist value can't be reset with copyWith, since
    // providing a null value will not change the value of the state
    final newState = state.copyWith(); // so we create a new state..
    newState.enquedPlaylist = null; // ..and set the value to null manually
    emit(newState);
  }

  /// Loads all the playlists asynchronously.
  ///
  /// This method is responsible for loading the playlists from a data source or cache.
  /// Requires a string userId to get the playlists created by the user, regardless of score.
  /// It is an asynchronous operation and returns a [Future] that completes when the playlists are loaded.
  Future<void> _onLoadAllPlaylists(
    LoadAllPlaylists event,
    Emitter<PlaylistState> emit,
  ) async {
    logger.i('_onLoadAllPlaylists');
    emit(state.copyWith(status: PlaylistStatus.playlistsLoading));

    if (event.clearCache) {
      logger.i('clearing playlists cache');
      await _cacheHelper.clearSpecific(
          CacheHelper.keyForPlaylists(_authBloc.state.user!.uid));
    }

    List<String>? roles;

    if (Core.app.type == AppType.basic) {
      final user = await _userRepository.getUserWithId(
          userId: _authBloc.state.user!.uid);
      roles = user.roles;
    }

    // Get the cached playlists if they exist
    var cachedPlaylists = await _cacheHelper.getPlaylists(
      event.serverPlaylistsUpdated!,
      event.userId,
    );

    // If the cached playlists are not null, use them
    if (cachedPlaylists != null && cachedPlaylists.isNotEmpty) {
      logger.i('_onLoadAllPlaylists: got cache');

      // If the app is RiverTunes, sort the playlists by display name, descending
      if (Core.app.type == AppType.basic) {
        cachedPlaylists = sortBasicPlaylists(cachedPlaylists);
      }

      // If the app is RiverTunes, remove playlists that are not associated with the user's roles
      if (Core.app.type == AppType.basic) {
        // If the user is not a collaborator, exclude the 'collaborator' playlists
        cachedPlaylists = filterPlaylistsByRole(roles, cachedPlaylists);

        emit(state.copyWith(
          allPlaylists: cachedPlaylists,
          status: PlaylistStatus.playlistsLoaded,
        ));
        return;
      }

      // Otherwise, return all the cached playlists
      emit(state.copyWith(
        allPlaylists: cachedPlaylists,
        status: PlaylistStatus.playlistsLoaded,
      ));
      return;
    }
    logger.i(' no cache so fetching from _playlistRepository');

    List<Playlist> allPlaylists;

    if (Core.app.type == AppType.advanced) {
      allPlaylists =
          await _playlistRepository.fetchPlaylistsAdvanced(event.userId);
    } else {
      allPlaylists =
          await _playlistRepository.fetchPlaylistsBasic(event.userId);

      allPlaylists = filterPlaylistsByRole(roles, allPlaylists);
    }

    // If the app is RiverTunes, sort the playlists by display name, descending
    if (Core.app.type == AppType.basic) {
      allPlaylists = sortBasicPlaylists(allPlaylists);
    }

    // Save the playlists to cache
    await _cacheHelper.savePlaylists(allPlaylists, event.userId);
    logger.i('_onLoadAllPlaylists: Emitting state with PlaylistStatus.loaded');
    emit(
      state.copyWith(
        allPlaylists: allPlaylists,
        status: PlaylistStatus.playlistsLoaded,
      ),
    );
  }

  List<Playlist> filterPlaylistsByRole(
      List<String>? roles, List<Playlist> playlists) {
    if (!roles!.contains('collaborator')) {
      playlists = playlists
          .where((playlist) => !playlist.roles.contains('collaborator'))
          .toList();
    }

    // If the user is not a weezer, exclude the 'weezer' playlists
    if (!roles.contains('weezer')) {
      playlists = playlists
          .where((playlist) => !playlist.roles.contains('weezer'))
          .toList();
    }

    // If the user is not an admin, exclude the 'admin' playlists
    if (!roles.contains('admin')) {
      playlists = playlists
          .where((playlist) => !playlist.roles.contains('admin'))
          .toList();
    }
    return playlists;
  }

  List<Playlist> sortBasicPlaylists(List<Playlist> playlists) {
    // Function to check if a string starts with a number
    bool startsWithNumber(String? s) => RegExp(r'^\d').hasMatch(s ?? "");

    playlists.sort((a, b) {
      bool aStartsWithNumber = startsWithNumber(a.displayTitle);
      bool bStartsWithNumber = startsWithNumber(b.displayTitle);

      if (aStartsWithNumber && bStartsWithNumber) {
        // Both start with numbers, sort descending
        return b.displayTitle!.compareTo(a.displayTitle!);
      } else if (!aStartsWithNumber && !bStartsWithNumber) {
        // Neither starts with a number, sort ascending
        return a.displayTitle!.compareTo(b.displayTitle!);
      } else {
        // If one starts with a number and the other doesn't, the one that does comes first
        return aStartsWithNumber ? -1 : 1;
      }
    });

    return playlists;
  }

  /// Loads the followedPlaylists asynchronously.
  ///
  /// This method is responsible for loading the followedPlaylists from state.allPlaylists
  /// It is an asynchronous operation and returns a [Future] that completes when the loading is finished.
  Future<void> _onLoadFollowedPlaylists(
    LoadFollowedPlaylists event,
    Emitter<PlaylistState> emit,
  ) async {
    logger.i('_onLoadFollowedPlaylists');
    emit(state.copyWith(status: PlaylistStatus.followedPlaylistsLoading));

    List<Playlist> followedPlaylists;
    List<Playlist> recommendedPlaylists;

    final result =
        _playlistHelper.getFollowedPlaylists(event.user, state.allPlaylists);

    // Check for bad playlist IDs and handle them
    if (result.badPlaylistIds.isNotEmpty) {
      emit(state.copyWith(
        status: PlaylistStatus.foundBadPlaylistIds,
        badPlaylistIds: result.badPlaylistIds,
      ));
    }

    followedPlaylists = result.validPlaylists;

    recommendedPlaylists =
        _playlistHelper.getRecommendedPlaylists(event.user, state.allPlaylists);

    if (Core.app.type == AppType.basic) {
      final user = await _userRepository.getUserWithId(
          userId: _authBloc.state.user!.uid);
      final roles = user.roles;
      followedPlaylists = filterPlaylistsByRole(roles, followedPlaylists);
      recommendedPlaylists = filterPlaylistsByRole(roles, recommendedPlaylists);
    }

    logger.i(
        '_onLoadFollowedPlaylists: Emitting state with PlaylistStatus.loaded');
    emit(
      state.copyWith(
        followedPlaylists: followedPlaylists,
        recommendedPlaylists: recommendedPlaylists,
        status: PlaylistStatus.followedPlaylistsLoaded,
      ),
    );
  }

  /// Loads the fiveStarPlaylist asynchronously.
  /// This method is responsible for loading the fiveStarPlaylist from state.allPlaylists
  /// It is an asynchronous operation and returns a [Future] that completes when the loading is finished.
  Future<void> _onLoad4And5StarPlaylists(
    Load4And5StarPlaylists event,
    Emitter<PlaylistState> emit,
  ) async {
    final fiveStarPlaylist = _playlistHelper.create5StarPlaylist(
        event.user, event.ratings, event.tracks);
    final fourStarPlaylist = _playlistHelper.create4StarPlaylist(
        event.user, event.ratings, event.tracks);

    emit(state.copyWith(
      fiveStarPlaylist: fiveStarPlaylist,
      fourStarPlaylist: fourStarPlaylist,
      status: PlaylistStatus.fourAndFiveStarPlaylistsLoaded,
    ));
  }

  /// Loads the fiveStarPlaylist asynchronously.
  /// This method is responsible for loading the fiveStarPlaylist from state.allPlaylists
  /// It is an asynchronous operation and returns a [Future] that completes when the loading is finished.
  Future<void> _onLoadAllSongsPlaylist(
    LoadAllSongsPlaylist event,
    Emitter<PlaylistState> emit,
  ) async {
    final allsongsPlaylist = _playlistHelper.createAllSongsPlaylist(
        event.user, event.ratings, event.tracks);

    emit(state.copyWith(
      allSongsPlaylist: allsongsPlaylist,
      status: PlaylistStatus.allSongsPlaylistLoaded,
    ));
  }

  /// Loads the unratedPlaylist asynchronously.
  Future<void> _onLoadUnratedPlaylist(
    LoadUnratedPlaylist event,
    Emitter<PlaylistState> emit,
  ) async {
    emit(state.copyWith(status: PlaylistStatus.unratedPlaylistLoading));
    final unratedPlaylist = _playlistHelper.createUnratedPlaylist(
        event.user, event.ratings, event.tracks);

    emit(state.copyWith(
      unratedPlaylist: unratedPlaylist,
      status: PlaylistStatus.unratedPlaylistLoaded,
    ));
  }

  /// Loads the newReleasesPlaylist asynchronously.
  /// This method is responsible for loading the newReleasesPlaylist from state.allPlaylists
  /// It is an asynchronous operation and returns a [Future] that completes when the loading is finished.
  Future<void> _onLoadNewReleases(
    LoadNewReleasesPlaylist event,
    Emitter<PlaylistState> emit,
  ) async {
    logger.i('_onLoadNewReleases');
    emit(state.copyWith(status: PlaylistStatus.newReleasesPlaylistLoading));
    // Note, this playlist is added as an individual property to the state, not to the user's playlists.
    final newReleasesPlaylist = _playlistHelper.createNewReleasesPlaylist(
      state.allPlaylists,
    );

    emit(state.copyWith(
      newReleasesPlaylist: newReleasesPlaylist,
      status: PlaylistStatus.newReleasesPlaylistLoaded,
    ));
  }

  Future<void> _onSetViewedPlaylist(
    SetViewedPlaylist event,
    Emitter<PlaylistState> emit,
  ) async {
    logger.f('playlistBloc._onSetViewedPlaylist: ${event.playlist.name}');
    if (event.playlist == state.viewedPlaylist) {
      return;
    }
    emit(
      state.copyWith(
        // Set viewed playlist before it has loaded so that the UI can show playlist info while it loads
        viewedPlaylist: event.playlist,
        status: PlaylistStatus.viewedPlaylistLoading,
      ),
    );
    try {
      // If tracks have not been loaded, wait for them to be loaded and ready
      if (_trackBloc.state.tracksLoadStatus != LoadStatus.loaded) {
        await _trackBloc.stream.firstWhere(
            (trackState) => trackState.tracksLoadStatus == LoadStatus.loaded);
      }

      // Signal that the playlist has been loaded
      emit(state.copyWith(status: PlaylistStatus.viewedPlaylistLoaded));
    } catch (err, s) {
      logger.e('error in _selectPlaylist: $err\n$s');
      emit(
        state.copyWith(
          status: PlaylistStatus.error,
          failure: Failure(
            message: 'PlayerBloc._selectPlaylist: ${err.toString()}.',
          ),
        ),
      );
    }
  }

  Future<void> _onSetPlaylistIdPassedToUrl(
    SetPlaylistIdPassedToUrl event,
    Emitter<PlaylistState> emit,
  ) async {
    try {
      emit(
        state.copyWith(
          playlistIdPassedToUrl: event.playlistId,

          // status: PlaylistStatus.viewedPlaylistLoaded,
        ),
      );
    } catch (err, s) {
      logger.e('error in _selectPlaylist: $err\n$s');
      emit(
        state.copyWith(
          status: PlaylistStatus.error,
          failure: Failure(
            message: 'PlayerBloc._selectPlaylist: ${err.toString()}.',
          ),
        ),
      );
    }
  }

  Future<void> _onPlaylistUpdated(
      PlaylistUpdated event, Emitter<PlaylistState> emit) async {
    // Create an updated list of all playlists by iterating over the current list of all playlists.
    final updatedAllPlaylists = state.allPlaylists.map((p) {
      // If the playlist being iterated over matches the `id` of the playlist in the event,
      // then replace it with the updated playlist from the event.
      // Otherwise, keep the original playlist.
      return p.id == event.playlist.id ? event.playlist : p;
    }).toList(); // Convert the result back to a list.

// Create an updated list of followed playlists by iterating over the current list of followed playlists.
    final updatedFollowedPlaylists = state.followedPlaylists.map((p) {
      // Similarly, if the playlist being iterated matches the `id` of the updated playlist in the event,
      // replace it with the updated playlist. If not, keep the original playlist.
      return p.id == event.playlist.id ? event.playlist : p;
    }).toList(); // Again, convert the result back to a list.

    // update the cache
    await _cacheHelper.savePlaylists(
        updatedAllPlaylists, _authBloc.state.user!.uid);

    final updatedViewedPlaylist = event.playlist.id == state.viewedPlaylist?.id
        ? event.playlist
        : state.viewedPlaylist;

    emit(state.copyWith(
      viewedPlaylist: updatedViewedPlaylist,
      allPlaylists: updatedAllPlaylists,
      followedPlaylists: updatedFollowedPlaylists,
      status: PlaylistStatus.playlistsUpdated,
    ));
  }

  // Event handler for when a new playlist is added.
  Future<void> _onPlaylistCreated(
      PlaylistCreated event, Emitter<PlaylistState> emit) async {
    // Add the new playlist to the list of all playlists.
    final updatedAllPlaylists = List<Playlist>.from(state.allPlaylists)
      ..add(event.playlist);

    //also add the new playlist to the list of followed playlists if needed
    final updatedFollowedPlaylists =
        List<Playlist>.from(state.followedPlaylists)..add(event.playlist);

    // Update the cache with the new all playlists list.
    await _cacheHelper.savePlaylists(
        updatedAllPlaylists, _authBloc.state.user!.uid);

    // There is no need to update the viewedPlaylist as this is adding a new playlist,
    // not updating or viewing an existing one.

    // Emit a new state with the updated playlists lists.
    emit(state.copyWith(
      allPlaylists: updatedAllPlaylists,
      followedPlaylists: updatedFollowedPlaylists,
      status: PlaylistStatus
          .playlistsUpdated, // Assuming you have a status for this action
    ));
  }

  Future<void> _onPlaylistFollowed(
      PlaylistFollowed event, Emitter<PlaylistState> emit) async {
    // Create an updated list of all playlists by iterating over the current list of all playlists.
    final updatedAllPlaylists = state.allPlaylists.map<Playlist>((p) {
      // If the playlist being iterated over matches the `id` of the playlist in the event,
      // then replace it with the updated playlist from the event.
      // Otherwise, keep the original playlist.
      return p.id == event.playlist.id
          ? event.playlist.copyWith(isFollowable: false)
          : p;
    }).toList(); // Convert the result back to a list.

    // update the cache
    await _cacheHelper.savePlaylists(
        updatedAllPlaylists, _authBloc.state.user!.uid);
    emit(state.copyWith(
      // followedPlaylists: updatedFollowedPlaylists,
      viewedPlaylist: event.playlist.copyWith(
        isFollowable: false,
        followerCount: event.playlist.followerCount,
      ),
      allPlaylists: updatedAllPlaylists,
      status: PlaylistStatus.playlistsUpdated,
    ));
  }

  Future<void> _onPlaylistDeleted(
      PlaylistDeleted event, Emitter<PlaylistState> emit) async {
    emit(state.copyWith(
      status: PlaylistStatus.playlistsLoading,
    ));
    final updatedAllPlaylists = state.allPlaylists
        .where((p) => p.id != event.playlistId)
        .toList(growable: false);

    // update the cache
    await _cacheHelper.savePlaylists(
        updatedAllPlaylists, _authBloc.state.user!.uid);

    final updatedFollowedPlaylists = state.followedPlaylists
        .where((p) => p.id != event.playlistId)
        .toList(growable: false);

    emit(state.copyWith(
      allPlaylists: updatedAllPlaylists,
      followedPlaylists: updatedFollowedPlaylists,
      status: PlaylistStatus.playlistsLoaded,
    ));
  }

  Future<void> _onPlaylistUnfollowed(
      PlaylistUnfollowed event, Emitter<PlaylistState> emit) async {
    emit(state.copyWith(
      status: PlaylistStatus.playlistsLoading,
    ));

    /// Switch the playlist.isFollowable flag to true
    /// so that it can be followed again
    final updatedAllPlaylists = state.allPlaylists
        .map<Playlist>((p) => p.id == event.playlist.id
            ? p.copyWith(isFollowable: true, followerCount: p.followerCount - 1)
            : p)
        .toList(growable: false);

    // update the cache
    await _cacheHelper.savePlaylists(
        updatedAllPlaylists, _authBloc.state.user!.uid);

    emit(state.copyWith(
      viewedPlaylist: event.playlist.copyWith(
          isFollowable: true, followerCount: event.playlist.followerCount - 1),
      allPlaylists: updatedAllPlaylists,
      status: PlaylistStatus.playlistsUpdated,
    ));
  }
}
