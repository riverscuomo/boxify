import 'package:boxify/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PopupMenuBuilder {
  static PopupMenuItem<String> buildAddPlaylistToLibraryPopupMenuItem(
      BuildContext context, String playlistId) {
    final userBloc = context.read<UserBloc>();
    return PopupMenuItem<String>(
      onTap: () {
        context.read<LibraryBloc>().add(AddPlaylistToLibrary(
            playlistId: playlistId, user: userBloc.state.user));
        ScaffoldMessenger.of(context)
            .showSnackBar(buildSnackbar('savedToLibrary'.translate()));
      },
      child: Text('addToYourLibrary'.translate()),
    );
  }

  static PopupMenuItem<String> buildCreatePlaylistPopupMenuItem(
      BuildContext context) {
    return PopupMenuItem<String>(
      onTap: () async {
        context.read<LibraryBloc>().add(
              CreatePlaylist(
                user: context.read<UserBloc>().state.user,
              ),
            );
        logger.d(
            'hopefully a listener somewhere will pick up youjustcreatedanewplaylist');
      },
      child: Text('createPlaylist'.translate()),
    );
  }

  static PopupMenuItem<String> buildDeletePlaylistPopupMenuItem(
      BuildContext context, Playlist playlist) {
    // final PlaylistBloc = context.read<PlaylistBloc>() as PlaylistBloc;
    return PopupMenuItem<String>(
      onTap: () {
        // remove it from the library
        context.read<LibraryBloc>().add(RemovePlaylist(
            playlist: playlist, user: context.read<UserBloc>().state.user));
        context
            .read<LibraryBloc>()
            .add(DeletePlaylist(playlistId: playlist.id!));
        ScaffoldMessenger.of(context)
            .showSnackBar(buildSnackbar('playlistDeleted'.translate()));
      },
      child: Text('delete'.translate()),
    );
  }

  // / NO DOWNLOAD ON WEB
  static PopupMenuItem<String> buildDownloadPlaylistPopupMenuItem(
      BuildContext context, Playlist playlist, bool isFullyDownloaded) {
    return PopupMenuItem<String>(
      onTap: () async {
        context
            .read<PlaylistService>()
            .handleDownloadButtonPressed(context, playlist);
      },
      child: Text(isFullyDownloaded ? 'Remove Download' : 'Download'),
    );
  }

  static PopupMenuItem<String> buildEditPlaylistPopupMenuItem(
      BuildContext context, Playlist playlist) {
    return PopupMenuItem<String>(
      onTap: () {
        final playlistBloc = context.read<PlaylistBloc>();
        playlistBloc.add(SetEditingPlaylist(playlist: playlist));
        final trackBloc = context.read<TrackBloc>();
        trackBloc.add(LoadDisplayedTracks(playlist: playlist));
        showEditPlaylistDialog(
          context,
        );
      },
      child: Text('editPlaylist'.translate()),
    );
  }

  static PopupMenuItem<String> buildRemovePlaylistPopupMenuItem(
      BuildContext context, Playlist playlist) {
    return PopupMenuItem<String>(
      onTap: () {
        final userBloc = context.read<UserBloc>();
        final libraryBloc = context.read<LibraryBloc>();
        if (UserHelper.isLoggedInOrReroute(userBloc.state, context,
            'actionEditLibrary'.translate(), Icons.playlist_remove)) {
          libraryBloc.add(
              RemovePlaylist(playlist: playlist, user: userBloc.state.user));
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(buildSnackbar('removedFromLibrary'.translate()));
      },
      child: Text('removeFromLibrary'.translate()),
    );
  }

  static PopupMenuItem<String> buildRemoveTrackFromPlaylistPopupMenuItem(
      BuildContext context, Playlist playlist, int index) {
    return PopupMenuItem<String>(
      onTap: () {
        {
          logger.i('adding RemoveTrackFromPlaylist');
          context.read<PlaylistTracksBloc>().add(
                RemoveTrackFromPlaylist(
                  playlist: playlist,
                  index: index,
                ),
              );
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(buildSnackbar("'removedFromLibrary'".translate()));
      },
      child: Text('removeFromThisPlaylist'.translate()),
    );
  }

  static PopupMenuItem<String> buildSharePopupMenuItem(
      String playlistId, BuildContext context) {
    final url = '${Core.app.playlistUrl}$playlistId';
    return PopupMenuItem<String>(
      onTap: () => ShareHelper.shareContent(
        context: context,
        url: url,
        title: 'playlist',
      ),
      child: Text('copyLinkToPlaylist'.translate()),
    );
  }
}
