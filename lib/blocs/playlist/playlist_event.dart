part of 'playlist_bloc.dart';

abstract class PlaylistEvent extends Equatable {
  const PlaylistEvent();

  @override
  List<Object?> get props => [];
}

class SetEditingPlaylist extends PlaylistEvent {
  final Playlist playlist;

  const SetEditingPlaylist({required this.playlist});
  @override
  List<Object?> get props => [playlist];
}

class LoadLikedSongsPlaylist extends PlaylistEvent {
  final bool clearPlaylistsCache;
  final User user;

  final List<Rating> ratings;

  /// emits [PlaylistStatus.likedSongsPlaylistLoaded]
  const LoadLikedSongsPlaylist(
      {this.clearPlaylistsCache = false,
      required this.user,
      required this.ratings});
}

class SetEnqueuedPlaylist extends PlaylistEvent {
  final Playlist playlist;
  const SetEnqueuedPlaylist({required this.playlist});
  @override
  List<Object?> get props => [playlist];
}

class ResetEnqueuedPlaylist extends PlaylistEvent {
  const ResetEnqueuedPlaylist();
}

class LoadNewReleasesPlaylist extends PlaylistEvent {
  final bool clearPlaylistsCache;

  const LoadNewReleasesPlaylist({this.clearPlaylistsCache = false});

  @override
  List<Object?> get props => [clearPlaylistsCache];
}

class Load4And5StarPlaylists extends PlaylistEvent {
  final bool clearPlaylistsCache;
  final User user;
  final List<Track>? tracks;

  final List<Rating> ratings;

  /// emits [PlaylistStatus.fourAndFiveStarPlaylistsLoaded]
  const Load4And5StarPlaylists(
      {this.clearPlaylistsCache = false,
      required this.user,
      required this.ratings,
      this.tracks});

  @override
  List<Object?> get props => [clearPlaylistsCache, user];
}

class LoadAllSongsPlaylist extends PlaylistEvent {
  final bool clearPlaylistsCache;
  final User user;
  final List<Track>? tracks;
  final List<Rating> ratings;

  const LoadAllSongsPlaylist(
      {this.clearPlaylistsCache = false,
      required this.user,
      required this.ratings,
      this.tracks});

  @override
  List<Object?> get props => [clearPlaylistsCache];
}

class LoadUnratedPlaylist extends PlaylistEvent {
  final bool clearPlaylistsCache;
  final User user;
  final List<Track> tracks;
  final List<Rating> ratings;

  const LoadUnratedPlaylist(
      {this.clearPlaylistsCache = false,
      required this.user,
      required this.ratings,
      required this.tracks});

  @override
  List<Object?> get props => [clearPlaylistsCache, user, ratings, tracks];
}

class SetViewedPlaylist extends PlaylistEvent {
  final Playlist playlist;

  /// This event is used to set state.viewedPlaylist.
  /// It does not update the state.queue, which is handled by [InitPlayerWithoutReloading]?
  const SetViewedPlaylist({required this.playlist});
  @override
  List<Object?> get props => [playlist];
}

class SetPlaylistIdPassedToUrl extends PlaylistEvent {
  final String? playlistId;

  const SetPlaylistIdPassedToUrl({required this.playlistId});
  @override
  List<Object?> get props => [playlistId];
}

class LoadAllPlaylists extends PlaylistEvent {
  final bool clearCache;
  final String userId;
  final DateTime? serverPlaylistsUpdated;

  /// Returns all the playlists from the database or cache.
  /// [User].id is required.
  /// In the case of advanced app type, it only fetches the playlists
  /// that meet the minimum score are are followed by the user.
  /// Furthermore, in the case of kDebugMode, it only fetches playlists with a
  /// max return of 10.
  const LoadAllPlaylists(
      {this.clearCache = false,
      required this.userId,
      this.serverPlaylistsUpdated});

  @override
  List<Object?> get props => [clearCache, userId, serverPlaylistsUpdated];
}

class LoadFollowedPlaylists extends PlaylistEvent {
  final bool clearPlaylistsCache;
  final User user;

  const LoadFollowedPlaylists(
      {this.clearPlaylistsCache = false, required this.user});

  @override
  List<Object?> get props => [clearPlaylistsCache, user];
}

class PlaylistCreated extends PlaylistEvent {
  final Playlist playlist;

  PlaylistCreated({required this.playlist});
}

class PlaylistFollowed extends PlaylistEvent {
  final Playlist playlist;

  PlaylistFollowed({required this.playlist});
}

class PlaylistUpdated extends PlaylistEvent {
  final Playlist playlist;

  PlaylistUpdated({required this.playlist});
}

class PlaylistDeleted extends PlaylistEvent {
  final String playlistId;

  PlaylistDeleted({required this.playlistId});
}

/// JUST LOAD ALL THE PLAYLISTS AGAIN
class PlaylistUnfollowed extends PlaylistEvent {
  final Playlist playlist;

  PlaylistUnfollowed({required this.playlist});
}

class InitialPlaylistState extends PlaylistEvent {
  @override
  List<Object?> get props => [];
}
