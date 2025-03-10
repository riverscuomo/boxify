import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:boxify/app_core.dart';

/// Used in [ScaffoldWithPlayer] userLibraryWidget (left side) as [DraggablePlaylistTile] and ...
///
/// why called 'large'?
///
/// A widget representing a large Library panel tile.
/// A [GestureDetector] provides the ability to detect taps and double taps.
/// Taps are used to navigate to the playlist route, while double taps are
/// used to play the first track in the playlist.
/// Secondary taps are used to show the context menu for the playlist, which
/// contains options to delete or add the playlist to the library.
///
/// The widget accepts the following required parameters:
/// - [isDragTarget]: A  bools representing if the current item is a drag target.
/// - [playlist]: The playlist object associated with this widget.
/// - [index]: The index of the item in the list.
/// - [itemName]: The name of the item.
/// - [userId]: The user ID of the logged-in user.
///
/// Note: can be wrapped in a [DraggablePlaylistTile] to make it draggable.
/// This is used to rearrange the order of playlists and to add playlists to [Library].
/// That functionality is only available for playlists owned by the logged-in user.
/// In other words, only available in the Weezify version of the app, not the Rivify version.
///
class LargePlaylistTile extends StatelessWidget {
  const LargePlaylistTile({
    super.key,
    required this.isSelected,
    required this.playlist,
    required this.index,
    required this.itemName,
    required this.canAddRemovePlaylist,

    /// For dragging and dropping in Weezify
    this.userId,
    this.isDragTarget = false,
    this.isInsertAboveTarget = false,
    this.isInsertBelowTarget = false,
  });

  final bool isDragTarget;
  final bool isInsertAboveTarget;
  final bool isInsertBelowTarget;

  final bool isSelected;
  final Playlist playlist;
  final int index;
  final String itemName;
  final String? userId;
  final bool canAddRemovePlaylist;

  @override
  Widget build(BuildContext context) {
    final userBloc = context.read<UserBloc>();
    final playlistBloc = context.read<PlaylistBloc>();
    final trackBloc = context.read<TrackBloc>();

    final playlistService = context.read<PlaylistService>();
    final playlistTracks = playlistService.getPlaylistTracks(playlist);
    final playlistHelper = PlaylistHelper();
    final bool isFullyDownloaded =
        playlistHelper.isFullyDownloaded(playlistTracks);

    return GestureDetector(
      onSecondaryTapDown: (details) =>
          PopupMenuActions.showContextMenuForPlaylist(
        context,
        details.globalPosition,
        playlist.id!,
        playlist: playlist,
        addPlaylistToLibrary: playlist.isFollowable,
        createPlaylist: Core.app.type == AppType.advanced,
        editDetails: playlist.isEditable,
        removePlaylistFromLibrary: playlist.isRemoveable,
        deletePlaylist: playlist.isDeleteable,
      ),
      onLongPressStart: (details) =>
          PopupMenuActions.showContextMenuForPlaylist(
        context,
        details.globalPosition,
        playlist.id!,
        playlist: playlist,
        addPlaylistToLibrary: playlist.isFollowable,
        createPlaylist: Core.app.type == AppType.advanced,
        editDetails: playlist.isEditable,
        removePlaylistFromLibrary: playlist.isRemoveable,
        deletePlaylist: playlist.isDeleteable,
      ),
      // onTap: () {
      //   // logger.i('should select the item but do nothing else');
      //   // handled in the listtile below
      // },
      onDoubleTap: () {
        logger.i('doubleTapped so view and play the playlist');
        // If the playlist is not the one being viewed, then view it along with its tracks
        playlistBloc.add(
          SetViewedPlaylist(
            playlist: playlist,
          ),
        );
        // Navigate to the playlist route
        GoRouter.of(context).push('/playlist/${playlist.id}');
        final PlaylistService playlistService = context.read<PlaylistService>();
        final tracks = playlistService.getPlaylistTracks(playlist);
        context.read<PlayerService>().handlePlay(
              tracks: tracks,
              playlist: playlist,
              source: 'PLAYLIST',
            );
      },
      child: Container(
        decoration: BoxDecoration(
          border:

              /// For inserting a Playlist above this playlist
              isInsertAboveTarget
                  ? Border(
                      top: BorderSide(width: 4, color: Core.appColor.primary),
                    )
                  :

                  /// For inserting a Playlist below this playlist
                  isInsertBelowTarget
                      ? Border(
                          bottom: BorderSide(
                              width: 4, color: Core.appColor.primary),
                        )
                      :

                      /// For dropping a Track onto this playlist
                      isDragTarget
                          ? Border.all(color: Core.appColor.primary)
                          : null,
        ),
        child: ListTile(
          leading: imageOrIcon(
            imageUrl: playlist.imageUrl,
            filename: playlist.imageFilename,
            height: 40,
            width: 40,
          ),
          title: Text(
            playlist.displayTitle ?? playlist.name ?? 'Untitled',
            style: TextStyle(
              color:
                  (isSelected & context.read<PlayerBloc>().state.player.playing)
                      ? Core.appColor.primary
                      : Core.appColor.titleColor,
              fontSize: Core.app.titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Row(
            children: [
              DownloadedIcon(isFullyDownloaded: isFullyDownloaded),
              (playlist.owner != null)
                  ? Text(
                      playlist.owner!['username'].toString(),
                      style: TextStyle(
                        color: Core.appColor.subtitleColor,
                        fontSize: Core.app.subtitleFontSize,
                      ),
                    )
                  : Container(),
            ],
          ),
          hoverColor: isSelected
              ? Core.appColor.hoverSelectedColor
              : Core.appColor.hoverColor,
          tileColor: isSelected
              ? Core.appColor.selectedColor
              : Core.appColor.panelColor,
          onTap: () {
            logger.i(
                'selected playlist but do not play: ${playlist.displayTitle}');
            playlistBloc.add(
              SetViewedPlaylist(
                playlist: playlist,
              ),
            );
            GoRouter.of(context).push('/playlist/${playlist.id}');
          },
        ),
      ),
    );
  }
}
