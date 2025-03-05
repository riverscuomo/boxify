import 'package:boxify/app_core.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'popup_menu_builder.dart';

/// This must be for the web app and Large Mobile. For small mobile, you must be using
/// show modal bottom sheet in [OverflowIconForPlaylist]
class PopupMenuActions {
  /// Optional parameters:
  /// [addToPlaylist] shows the 'Add to your library' option.
  /// [deletePlaylist] shows the 'Delete' option.
  /// [removePlaylistFromLibrary] shows the 'Remove from your library' option.
  /// [removeTrackFromPlaylist] shows the 'Remove from this playlist' option.
  /// [stopFollowing] shows the 'Stop following' option.
  /// [share] shows the 'Copy link to playlist' option.
  ///
  /// Used in [HorizontalListItem] and [LargePlaylistTile] in both apps.
  static showContextMenuForPlaylist(
    BuildContext context,
    Offset offset,
    String playlistId, {
    required Playlist playlist,
    bool? addPlaylistToLibrary = false,
    bool? createPlaylist = true,
    bool? deletePlaylist = false,
    bool? editDetails = false,
    bool? removePlaylistFromLibrary = false,
    bool? removeTrackFromPlaylist = false,
    bool? stopFollowing = false,
    bool? share = true,
  }) async {
    final left = offset.dx - 500;
    final top = offset.dy;
    final trackBloc = context.read<TrackBloc>();

    final playlistHelper = PlaylistHelper();
    final isFullyDownloaded =
        playlistHelper.isFullyDownloaded(trackBloc.state.displayedTracks);

    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(left, top, left, top),
      items: [
        // currently ordered for left side library panel
        if (editDetails == true)
          PopupMenuBuilder.buildEditPlaylistPopupMenuItem(context, playlist),
        if (deletePlaylist == true)
          PopupMenuBuilder.buildDeletePlaylistPopupMenuItem(context, playlist),
        if (removePlaylistFromLibrary == true)
          PopupMenuBuilder.buildRemovePlaylistPopupMenuItem(context, playlist),
        if (createPlaylist == true)
          PopupMenuBuilder.buildCreatePlaylistPopupMenuItem(context),
        if (addPlaylistToLibrary == true)
          PopupMenuBuilder.buildAddPlaylistToLibraryPopupMenuItem(
              context, playlistId),

        // NO DOWNLOAD ON WEB
        if (!kIsWeb)
          PopupMenuBuilder.buildDownloadPlaylistPopupMenuItem(
              context, playlist, isFullyDownloaded),
        if (share == true)
          PopupMenuBuilder.buildSharePopupMenuItem(playlistId, context),

        // if (deletePlaylist == true)
        if (removeTrackFromPlaylist == true)
          PopupMenuBuilder.buildRemoveTrackFromPlaylistPopupMenuItem(
              context, playlist!, 0),
        // if (stopFollowing == true)
      ],
      elevation: 8,
    );
  }

  static showContextMenuOnSearchScreenIfOwnPlaylist(
    BuildContext context,
    Offset offset,
    String playlistId,
  ) async {
    final left = offset.dx - 500;
    final top = offset.dy;
    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(left, top, left, top),
      items: [
        PopupMenuItem<String>(
          onTap: () {
            FlutterClipboard.copy(
              '${Core.app.playlistUrl}$playlistId',
            );
            showMySnack(
              context,
              message: 'linkCopiedToClipboard'.translate(),
            );
          },
          child: Text('copyLinkToPlaylist'.translate()),
        ),
        PopupMenuItem<String>(child: Text('rename'.translate())),
      ],
      elevation: 8,
    );
  }

  /// [SearchUserScreen]
  static showContextMenuOnSearchScreenIfOthersPlaylist(
    BuildContext context,
    Offset offset,
    Playlist playlist,
  ) async {
    logger.i('showContextMenuOnSearchScreenIfOthersPlaylist');
    final left = offset.dx - 500;
    final top = offset.dy;
    final playlists = context.read<PlaylistBloc>().state.followedPlaylists;
    final playlistIds = playlists.map((playlist) => playlist.id).toList();

    playlistIds.contains(playlist.id)
        ? await showMenu(
            context: context,
            position: RelativeRect.fromLTRB(left, top, left, top),
            items: [
              PopupMenuBuilder.buildSharePopupMenuItem(playlist.id!, context),
              PopupMenuBuilder.buildRemovePlaylistPopupMenuItem(
                  context, playlist)
            ],
            elevation: 8,
          )
        : await showMenu(
            context: context,
            position: RelativeRect.fromLTRB(left, top, left, top),
            items: [
              PopupMenuBuilder.buildSharePopupMenuItem(playlist.id!, context),
              PopupMenuBuilder.buildAddPlaylistToLibraryPopupMenuItem(
                  context, playlist.id!)
            ],
            elevation: 8,
          );
  }

  /// In the left side large Nav panel.
  /// This deletes a playlist from library.
  static showContextMenuForOwnPlaylist(
    BuildContext context,
    Offset offset,
    Playlist playlist,
  ) async {
    final left = offset.dx - 500;
    final top = offset.dy;
    logger.i('showContextMenuForOwnPlaylist');
    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(left, top, left, top),
      items: [
        PopupMenuBuilder.buildSharePopupMenuItem(playlist.id!, context),
        PopupMenuBuilder.buildRemovePlaylistPopupMenuItem(context, playlist),
        PopupMenuBuilder.buildEditPlaylistPopupMenuItem(context, playlist),
      ],
      elevation: 8,
    );
  }

  /// In the large Nav panel.
  /// Add or Remove a playlist to or from library..
  static showContextMenuForOthersPlaylist(
    BuildContext context,
    Offset offset,
    Playlist playlist,
  ) async {
    logger.i('showContextMenuForOthersPlaylist');
    final left = offset.dx - 500;
    final top = offset.dy;
    final playlists = context.read<PlaylistBloc>().state.followedPlaylists;
    final playlistIds = playlists.map((playlist) => playlist.id).toList();

    final isAnonymous = context.read<UserBloc>().state.user.id == '';

    playlistIds.contains(playlist.id)
        ? await showMenu(
            context: context,
            position: RelativeRect.fromLTRB(left, top, left, top),
            items: [
              PopupMenuBuilder.buildSharePopupMenuItem(playlist.id!, context),
              PopupMenuItem<String>(
                onTap: () {
                  // Ensure that the user is logged in.
                  if (UserHelper.isLoggedInOrReroute(userState, context,
                      'actionEditLibrary'.translate(), Icons.playlist_remove)) {
                    // The user is logged in. Remove the playlist from the library.
                    context.read<LibraryBloc>().add(RemovePlaylist(
                        playlist: playlist,
                        user: context.read<UserBloc>().state.user));
                    ScaffoldMessenger.of(context).showSnackBar(
                        buildSnackbar('removedFromLibrary'.translate()));
                  }
                },
                child: Text('removeFromLibrary'.translate()),
              )
            ],
            elevation: 8,
          )
        : await showMenu(
            context: context,
            position: RelativeRect.fromLTRB(left, top, left, top),
            items: [
              PopupMenuItem<String>(
                onTap: () {
                  FlutterClipboard.copy(
                    '${Core.app.playlistUrl}${playlist.id}',
                  );
                  showMySnack(
                    context,
                    message: 'linkCopiedToClipboard'.translate(),
                  );
                },
                child: Text('copyLinkToPlaylist'.translate()),
              ),
              PopupMenuItem<String>(
                onTap: () {
                  if (UserHelper.isLoggedInOrReroute(userState, context,
                      'actionManageLibrary'.translate(), Icons.playlist_add)) {
                    // The user is logged in. Save the playlist to the library.
                    context.read<LibraryBloc>().add(AddPlaylistToLibrary(
                        playlistId: playlist.id!,
                        user: context.read<UserBloc>().state.user));
                    ScaffoldMessenger.of(context).showSnackBar(
                        buildSnackbar('savedToLibrary'.translate()));
                  }
                },
                child: Text('addToYourLibrary'.translate()),
              )
              // PopupMenuItem<String>(child: const Text('Rename')),
            ],
            elevation: 8,
          );
  }

  /// THIS ONE IS FOR THE SEARCH SCREEN, and for the playlist screen
  /// (but just for a playlist that you don't own, because there's no delete function)
  /// shows a list of your own playlists you can add the track to.
  static showContextMenuAddToPlaylist(
    BuildContext context,
    Offset offset,
    List<PopupMenuItem> userPlaylistWidgets,
    Track track,
  ) async {
    logger.i('showContextMenuAddToPlaylist');
    final left = offset.dx - 500;
    final top = offset.dy;

    userPlaylistWidgets
      ..insert(
        0,
        const PopupMenuItem<String>(
          enabled: false,
          child: Divider(
            thickness: 2,
          ),
        ),
      )
      ..insert(
        0,
        PopupMenuItem<String>(
          enabled: false,
          child: Text('addToPlaylist'.translate()),
        ),
      )
      ..insert(
        0,
        PopupMenuItem<String>(
          onTap: () {
            FlutterClipboard.copy(
              '${Core.app.trackUrl}${track.uuid}',
            );
            showMySnack(
              context,
              message: 'linkCopiedToClipboard'.translate(),
            );
          },
          child: Text('copyLinkToTrack'.translate()),
        ),
      );

    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(left, top, left + 1, top + 1),
      items: userPlaylistWidgets,
      elevation: 8,
    );
  }

  /// THIS ONE IS for the playlist screen
  /// (for a playlist that youown, because there's a delete function)
  /// shows a list of your own playlists you can add the track to and a delete button.
  static showContextMenuAddOrRemoveToFromPlaylist(
    BuildContext context,
    Offset offset,
    List<PopupMenuItem> userPlaylistWidgets,
    Playlist playlist,
    Track track,
    int index,
  ) async {
    logger.i('showContextMenuAddOrRemoveToFromPlaylist');
    // final isAnonymous = context.read<UserBloc>().state.user.id == '';

    double left;
    double top;

    left = offset.dx - 500;
    top = offset.dy;

    // use the tap position (offset.dx, offset.dy) directly

    // Heads up. these are listed backwards, because you're inserting.
    userPlaylistWidgets
      ..insert(
        0,
        const PopupMenuItem<String>(
          enabled: false,
          child: Divider(
            thickness: 2,
          ),
        ),
      )
      ..insert(
        0,
        PopupMenuItem<String>(
          enabled: false,
          child: Text('addToPlaylist'.translate()),
        ),
      )
      ..insert(
        0,
        PopupMenuBuilder.buildRemoveTrackFromPlaylistPopupMenuItem(
            context, playlist, index),
      )
      ..insert(
        0,
        PopupMenuBuilder.buildSharePopupMenuItem(playlist.id!, context),
      );
    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(left, top, left, top),
      items: userPlaylistWidgets,
      elevation: 8,
    );
  }
}
