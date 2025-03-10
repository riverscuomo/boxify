import 'package:boxify/app_core.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

enum PlaylistBottomSheetType { longPress, overflow }

void showPlaylistLongPressBottomSheet({
  required BuildContext context,
  required Playlist playlist,
  int? index,
}) {
  String? imageFilename = playlist.imageFilename;
  List<Widget> playlistTiles =
      buildPlaylistTiles(playlist, PlaylistBottomSheetType.longPress);

  showModalBottomSheet(
    context: context,
    builder: (context) => SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              imageOrIcon(
                  imageUrl: playlist.imageUrl,
                  filename: imageFilename,
                  height: 70,
                  width: 70),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.displayTitle!,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${playlist.followerCount} saves',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            color: Colors.grey,
            height: 1,
          ),
          ...playlistTiles,
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

void showPlaylistOverflowBottomSheet({
  required BuildContext context,
  required Playlist playlist,
  int? index,
}) {
  String? imageFilename = playlist.imageFilename;

  final List<Widget> playlistTiles =
      buildPlaylistTiles(playlist, PlaylistBottomSheetType.overflow);

  showModalBottomSheet(
    context: context,
    builder: (context) => SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              imageOrIcon(
                  imageUrl: playlist.imageUrl,
                  filename: imageFilename,
                  height: 70,
                  width: 70),
              const SizedBox(width: 12),
              Column(
                children: [
                  Text(
                    playlist.displayTitle!,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    playlist.owner!['username'].toString(),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            color: Colors.grey,
            height: 1,
          ),
          ...playlistTiles,
          ShareTile(
              url: '${Core.app.playlistUrl}${playlist.id}',
              title: playlist.displayTitle!),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

void showTrackOverflowMenu(
    {required BuildContext context,
    required Track track,
    Playlist? playlist,
    int? index}) {
  String? imageUrl = assignPlaylistImageUrlToTrack(track, playlist);
  String? imageFilename = assignPlaylistImageFilenameToTrack(track, playlist);
  if (imageUrl == null && imageFilename == null) {
    imageFilename = Core.app.placeHolderImageFilename;
  }
  showModalBottomSheet(
    context: context,
    builder: (context) => SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          imageOrIcon(
              imageUrl: imageUrl,
              filename: imageFilename,
              height: 120,
              width: 120),
          const SizedBox(height: 12),
          Text(
            track.displayTitle,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            track.artist!,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 36),
          if (Core.app.type == AppType.advanced &&
              playlist != null &&
              playlist.isOwnPlaylist &&
              index != null)
            RemoveTrackFromPlaylistTile(
                playlist: playlist,
                trackTitle: track.displayTitle,
                index: index),
          if (Core.app.type == AppType.advanced)
            AddTrackToPlaylistTile(
                trackTitle: track.displayTitle,
                text: playlist != null
                    ? 'Add to another playlist'
                    : 'Add to playlist'),
          ShareTile(
              url: '${Core.app.trackUrl}${track.uuid}',
              title: track.displayTitle),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

List<Widget> buildPlaylistTiles(
    Playlist playlist, PlaylistBottomSheetType type) {
  /// Weezify
  if (Core.app.type == AppType.advanced) {
    if (type == PlaylistBottomSheetType.longPress) {
      if (playlist.isOwnPlaylist) {
        return [
          ToggleDownloadTile(playlist: playlist),
          EditPlaylistTile(
              playlist), // Spotify does not have this tile when long pressing a playlist on the Library screen
          DeletePlaylistTile(playlist: playlist),
          ShareTile(
            url: '${Core.app.playlistUrl}${playlist.id}',
            title: playlist.displayTitle!,
          ),
        ];
      } else {
        return [
          ToggleAddRemovePlaylistFromYourLibraryTile(playlist: playlist),
          ToggleDownloadTile(playlist: playlist),
          ShareTile(
            url: '${Core.app.playlistUrl}${playlist.id}',
            title: playlist.displayTitle!,
          ),
        ];
      }
    } else if (type == PlaylistBottomSheetType.overflow) {
      if (playlist.isOwnPlaylist) {
        return [
          AddToThisPlaylistTile(playlist: playlist),
          EditPlaylistTile(playlist),
          DeletePlaylistTile(playlist: playlist),
          ToggleDownloadTile(playlist: playlist),
          ShareTile(
            url: '${Core.app.playlistUrl}${playlist.id}',
            title: playlist.displayTitle!,
          ),
        ];
      } else {
        return [];
      }
    } else {
      return [];
    }
  } else {
    // RiverTunes
    return [
      ToggleAddRemovePlaylistFromYourLibraryTile(playlist: playlist),
      ToggleDownloadTile(playlist: playlist),
      ShareTile(
        url: '${Core.app.playlistUrl}${playlist.id}',
        title: playlist.displayTitle!,
      ),
    ];
  }
}
