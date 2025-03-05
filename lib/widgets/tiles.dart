import 'package:boxify/app_core.dart';
import 'package:charcode/charcode.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/src/provider.dart';

/// Used in the [SmallTrackDetailScreen] and [showTrackOverflowMenu]
class AddTrackToPlaylistTile extends StatelessWidget {
  const AddTrackToPlaylistTile({
    super.key,
    required this.trackTitle,
    this.text = 'Add to other playlist',
  });

  final String trackTitle;
  final String text;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        logger.i('Add to playlist tile tapped');

        // Ensure user is logged in
        if (UserHelper.isLoggedInOrReroute(userState, context,
            'actionCreatePlaylists'.translate(), Icons.playlist_add)) {
          // close the overflow screen
          context.pop();

          // If you're on the small track detail screen, pop it
          if (context.canPop()) {
            context.pop();
          }

        // If you're on the small track detail screen, pop it
        if (context.canPop()) {
          context.pop();
        }

        context.push('/smallAddToPlaylist');
      },
      leading: const Icon(
        Icons.add,
        color: Colors.grey,
      ),
      title: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          // fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// TODO: should nav you to a
/// screen where you can select
/// tracks to add to a playlist
class AddToThisPlaylistTile extends StatelessWidget {
  const AddToThisPlaylistTile({
    super.key,
    required this.playlist,
  });

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        // context.read<PlaylistTracksBloc>().add(
        //       AddTrackToPlaylist(
        //         playlist: playlist,
        //         trackTitle: trackTitle,
        //         index: index,
        //       ),
        //     );
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          buildSnackbar('Added to ${playlist.name}'),
        );
      },
      leading: const Icon(
        Icons.add,
        color: Colors.grey,
      ),
      title: Text(
        'addToThisPlaylist'.translate(),
        style: TextStyle(
          fontSize: 14,
          // fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class DeletePlaylistTile extends StatelessWidget {
  const DeletePlaylistTile({
    super.key,
    required this.playlist,
  });

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        context.read<LibraryBloc>().add(
              RemovePlaylist(
                playlist: playlist,
                user: context.read<UserBloc>().state.user,
              ),
            );
        context.read<LibraryBloc>().add(
              DeletePlaylist(
                playlistId: playlist.id!,
              ),
            );
        // close the overflow screen
        context.pop();

        // // close the deleted playlist screen
        // context.pop(); // This was cauasing a 'nothing to pop' error

        showMySnack(context, message: 'Deleted ${playlist.name} playlist');
      },
      leading: const Icon(
        Icons.cancel_outlined,
        color: Colors.grey,
      ),
      title: Text(
        'deletePlaylist'.translate(),
        style: TextStyle(
          fontSize: 14,
          // fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class EditPlaylistTile extends StatelessWidget {
  const EditPlaylistTile(
    this.playlist, {
    super.key,
  });

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        final playlistBloc = context.read<PlaylistBloc>();
        playlistBloc.add(SetEditingPlaylist(playlist: playlist));
        playlistBloc.add(SetViewedPlaylist(playlist: playlist));
        // final trackBloc = context.read<TrackBloc>();
        // trackBloc.add(LoadDisplayedTracks(playlist: playlist));
        context.pop();
        showEditPlaylistDialog(
          context,
        );
      },
      leading: const Icon(
        Icons.edit_outlined,
        color: Colors.grey,
      ),
      title: Text(
        'editPlaylist'.translate(),
        style: TextStyle(
          fontSize: 14,
          // fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Not used in left side Library panel. See [DraggablePlaylistTile] for that?
class PlaylistTile extends StatelessWidget {
  const PlaylistTile({
    super.key,
    required this.playlist,
  });

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final playlistBloc = context.read<PlaylistBloc>();
    // ignore: unused_local_variable
    final downloadBloc = context.watch<
        DownloadBloc>(); // Need this here so the widget rebuilds when the downloadBloc state changes
    final searchBloc = context.read<SearchBloc>();
    final playlistService = context.read<PlaylistService>();
    final playlistTracks = playlistService.getPlaylistTracks(playlist);
    final playlistHelper = PlaylistHelper();
    final bool isFullyDownloaded =
        playlistHelper.isFullyDownloaded(playlistTracks);
    final bool isViewedPlaylist =
        playlist.id == playlistBloc.state.viewedPlaylist?.id;
    return
        // on web you'll be able to open a pop up menu by right clicking
        GestureDetector(
      onSecondaryTap: () => showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            actions: <Widget>[
              ShareTile(
                  url: '${Core.app.playlistUrl}${playlist.id}',
                  title: playlist.displayTitle!),
              playlist.isOwnPlaylist == true
                  ? DeletePlaylistTile(
                      playlist: playlist,
                    )
                  : StopFollowingPlaylistTile(playlist: playlist)
            ],
          );
        },
      ),
      child: ListTile(
        onLongPress: () {
          if (Core.app.type == AppType.advanced) {
            playlistBloc.state.playlistToRemove = playlist.id!;
            showPlaylistLongPressBottomSheet(
              context: context,
              playlist: playlist,
            );
          }
        },
        key: playlist.id != null
            ? Key('smallplaylist${playlist.id!}')
            : Key('smallplaylist${playlist.name!}'),
        leading: imageOrIcon(
          imageUrl: playlist.imageUrl,
          filename: playlist.imageFilename,
          height: 60,
          width: 60,
        ),
        title: Text(
          playlist.displayTitle ?? '',
          style: isViewedPlaylist
              ? const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                )
              : const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
        ),
        subtitle: Row(
          children: [
            /// 'Playlist' is only shown on the Home Screen (rather than Library) and only
            /// when you don't have the 'Playlist' filter on. It's to let the user know
            /// that the playlist is a playlist and not an album or artist.
            // Text(
            //   'Playlist ${String.fromCharCode($bull)} ',
            //   style: TextStyle(color: Colors.grey[400], fontSize: 12),
            // ),

            DownloadedIcon(
              isFullyDownloaded: isFullyDownloaded,
              size: 14,
            ),

            Core.app.type == AppType.advanced
                ? Text(
                    playlist.owner?['username'].toString() ?? '',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  )
                : SizedBox(),
          ],
        ),
        onTap: () {
          searchBloc.add(ResetSearch());
          GoRouter.of(context).push('/playlist/${playlist.id}');
          playlistBloc.add(
            SetViewedPlaylist(
              playlist: playlist,
            ),
          );
        },
      ),
    );
  }
}

class PlaylistToBeAddedToTile extends StatelessWidget {
  const PlaylistToBeAddedToTile({
    super.key,
    required this.playlist,
  });

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final playlistBloc = context.read<PlaylistBloc>();
    final state = playlistBloc.state;
    return ListTile(
      key: Key('${playlist.id}'),
      leading: imageOrIcon(
        imageUrl: playlist.imageUrl,
        filename: playlist.imageFilename,
        height: 60,
        width: 60,
      ),
      title: Text(
        playlist.name ?? '',
        style: playlist.id == state.viewedPlaylist?.id
            ? const TextStyle(
                color: Colors.blueAccent,
                fontSize: 15,
              )
            : const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
      ),
      subtitle: Row(
        children: [
          Text(
            'Playlist ${String.fromCharCode($bull)} ',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          Text(
            playlist.owner?['username'] ?? 'Rivers',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
      onTap: () {
        final playlistTracksBloc = context.read<PlaylistTracksBloc>();
        playlistTracksBloc.add(
          AddTrackToPlaylist(
            playlist: playlist,
            track: playlistTracksBloc.state.trackToAdd!,
          ),
        );
        context.pop();
        showMySnack(context, message: 'Added to ${playlist.name}');
      },
    );
  }
}

class RemoveTrackFromPlaylistTile extends StatelessWidget {
  const RemoveTrackFromPlaylistTile({
    super.key,
    required this.playlist,
    required this.trackTitle,
    required this.index,
  });

  final Playlist playlist;
  final String trackTitle;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        context.read<PlaylistTracksBloc>().add(
              RemoveTrackFromPlaylist(
                playlist: playlist,
                index: index,
              ),
            );
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          buildSnackbar('Removed from ${playlist.name}'),
        );
      },
      leading: const Icon(
        Icons.close,
        color: Colors.grey,
      ),
      title: Text(
        'removeFromThisPlaylist'.translate(),
        style: TextStyle(
          fontSize: 14,
          // fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Returns a [ListTile] for sharing.
/// Used for both [Playlist] and [Track].
class ShareTile extends StatelessWidget {
  const ShareTile({
    super.key,
    required this.url,
    required this.title,
  });

  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => ShareHelper.shareContent(
        context: context,
        url: url,
        title: title,
      ),
      leading: const Icon(
        Icons.share,
        color: Colors.grey,
      ),
      title: Text(
        'share'.translate(),
        style: TextStyle(
          fontSize: 14,
          // fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class ToggleDownloadTile extends StatelessWidget {
  final Playlist playlist;
  const ToggleDownloadTile({
    super.key,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context) {
    // final libraryBloc = context.read<LibraryBloc>();
    // final playlistBloc = context.read<PlaylistBloc>();
    // final trackBloc = context.read<TrackBloc>();
    // final userBloc = context.read<UserBloc>();

    final playlistService = context.read<PlaylistService>();
    final playlistTracks = playlistService.getPlaylistTracks(playlist);
    final playlistHelper = PlaylistHelper();
    final bool isFullyDownloaded =
        playlistHelper.isFullyDownloaded(playlistTracks);

    return ListTile(
      onTap: () {
        if (isFullyDownloaded) {
          playlistService.handleRemoveDownloadButtonPressed(
            context,
            playlist,
          );
        } else {
          playlistService.handleDownloadButtonPressed(
            context,
            playlist,
          );
        }
        context.pop();
      },
      leading: Icon(
        isFullyDownloaded ? Icons.cancel_outlined : Icons.download_outlined,
        color: isFullyDownloaded ? Core.appColor.primary : Colors.grey,
      ),
      title: Text(
        isFullyDownloaded
            ? 'removeDownload'.translate()
            : 'download'.translate(),
        style: TextStyle(
          fontSize: 14,
          // fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class StopFollowingPlaylistTile extends StatelessWidget {
  const StopFollowingPlaylistTile({
    super.key,
    required this.playlist,
  });

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final libraryBloc = context.read<LibraryBloc>();
    final userBloc = context.read<UserBloc>();
    return ListTile(
      leading: const Icon(Icons.close, color: Colors.blueAccent),
      title: Text('stopFollowing'.translate()),
      onTap: () {
        // Ensure user is logged in
        if (UserHelper.isLoggedInOrReroute(userBloc.state, context,
            'actionEditLibrary'.translate(), Icons.playlist_remove)) {
          libraryBloc.add(
            RemovePlaylist(
              playlist: playlist,
              user: userBloc.state.user,
            ),
          );
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            buildSnackbar('removedFromLibrary'.translate()),
          );
        }
      },
    );
  }
}

class ToggleAddRemovePlaylistFromYourLibraryTile extends StatelessWidget {
  const ToggleAddRemovePlaylistFromYourLibraryTile({
    super.key,
    required this.playlist,
  });

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final libraryBloc = context.read<LibraryBloc>();
    final playlistBloc = context.read<PlaylistBloc>();
    final userBloc = context.read<UserBloc>();

    /// Now I'm worried this will mess up weezify button update because it's not
    /// listening to the bloc
    final playlistIsAlreadyFollowed = userBloc.state.user.playlistIds
        .any((element) => element == playlist.id);

    // You can't follow/unfollow a playlist you created, including the Liked Songs playlist
    // I'm not sure why, but the playlist.isfollowable is returning false for default playlists
    final playlistIsFollowUnfollowable = playlist.id != null &&
        playlist.owner != null &&
        playlist.owner!['id'] != userBloc.state.user.id;

    return !playlistIsFollowUnfollowable
        ? Container()
        : !playlistIsAlreadyFollowed
            ? ListTile(
                onTap: () {
                  // Ensure user is logged in
                  if (UserHelper.isLoggedInOrReroute(userBloc.state, context,
                      'actionEditLibrary'.translate(), Icons.playlist_add)) {
                    context.pop();
                    libraryBloc.add(AddPlaylistToLibrary(
                        playlistId: playlist.id!, user: userBloc.state.user));
                    showMySnack(context,
                        message: 'addedToYourLibrary'.translate());
                  }
                },
                leading: const Icon(Icons.add, color: Colors.blueAccent),
                title: Text('addToYourLibrary'.translate()),
              )
            : ListTile(
                onTap: () {
                  // Ensure user is logged in
                  if (UserHelper.isLoggedInOrReroute(userBloc.state, context,
                      'actionEditLibrary'.translate(), Icons.playlist_remove)) {
                    context.pop();
                    libraryBloc.add(RemovePlaylist(
                        playlist: playlist, user: userBloc.state.user));
                    showMySnack(context,
                        message: 'removedFromLibrary'.translate());
                  }
                },
                leading: const Icon(Icons.close, color: Colors.blueAccent),
                title: Text('removeFromLibrary'.translate()),
              );
    // : Container();
  }
}

class DownloadedIcon extends StatelessWidget {
  const DownloadedIcon({
    super.key,
    required this.isFullyDownloaded,
    this.size = 18,
  });

  final bool isFullyDownloaded;
  final double size;

  @override
  Widget build(BuildContext context) {
    return isFullyDownloaded
        ? Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Icon(
              Icons.arrow_circle_down_outlined,
              color: Core.appColor.primary,
              size: size,
            ),
          )
        : SizedBox();
  }
}
