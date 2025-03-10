import 'package:boxify/app_core.dart';
import 'package:boxify/screens/playlist/widgets/track_touch_row_skeleton.dart';
import 'package:charcode/charcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'small_playlist_tools.dart';

class PlaylistTouchScreen extends StatefulWidget {
  const PlaylistTouchScreen(
      {super.key,
      required this.playlist,
      required this.containsDownloaded,
      required this.containsAvailable,
      required this.isPlaylistLoaded});

  final Playlist playlist;
  final bool containsDownloaded;
  final bool containsAvailable;
  final bool isPlaylistLoaded;

  @override
  State<PlaylistTouchScreen> createState() => _PlaylistTouchScreenState();
}

class _PlaylistTouchScreenState extends State<PlaylistTouchScreen> {
  final TextEditingController textController = TextEditingController();
  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlist = widget.playlist;
    final containsDownloaded = widget.containsDownloaded;
    final containsAvailable = widget.containsAvailable;
    return SliverToBoxAdapter(
      child: Center(
        child: Column(
          children: [
            /// DISPLAY NAME
            PlaylistdisplayTitle(playlist: playlist),

            /// PLAYLIST DESCRIPTION
            playlist.description != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              MyLinkify(text: playlist.description ?? ''),
                            ],
                          ),
                        )),
                  )
                : SizedBox(),
            OwnerAvatarAndName(
              imageUrl: playlist.owner?['profileImageUrl'],
              ownerName: playlist.owner?['username'],
              type: OwnerAvatarAndNameType.smallPlaylistInfo,
              userId: playlist.owner?['id'],
            ),
            const SizedBox(height: 8),
            playlist.type == PlaylistType.playlist
                ? PlaylistStats(playlist: playlist)
                : SingleInfo(playlist: playlist),
            SmallPlaylistTools(
              containsDownloaded: containsDownloaded,
              containsAvailable: containsAvailable,
              isPlaylistLoaded: widget.isPlaylistLoaded,
            ),

            // TrackTouchRowS
            BlocBuilder<TrackBloc, TrackState>(
              builder: (context, state) {
                /// Keep track of the index of of this track withing the playable tracks,
                /// so that we can highlight the currently playing track.
                var indexWithinPlayableTracks = -1;
                return
                    // Are tracks in the playlist loaded?
                    widget.isPlaylistLoaded
                        ? state.displayedTracks.isEmpty && // Is playlist empty?
                                playlist.id == Core.app.newReleasesPlaylistId
                            ? CenteredText('noNewReleasesMessage'.translate())
                            : state.displayedTracks.isEmpty
                                ? CenteredText('noTracksMessage'.translate())
                                : ListView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: state.displayedTracks.length,
                                    itemBuilder: (context, index) {
                                      final track =
                                          state.displayedTracks[index];

                                      if (track.available!) {
                                        indexWithinPlayableTracks++;
                                      }

                                      return TrackTouchRow(
                                        i: index,
                                        indexWithinPlayableTracks:
                                            indexWithinPlayableTracks,
                                        track: track,
                                        playlist: playlist,
                                        onTap: () async {
                                          final canPlay = context
                                              .read<PlayerService>()
                                              .handlePlay(
                                                tracks: state.displayedTracks,
                                                index: index,
                                                playlist: playlist,
                                                source: 'PLAYLIST',
                                              );
                                          if (!canPlay) {
                                            showTrackSnack(
                                                context, track.bundleName!);
                                          }
                                        },
                                        showBundleArtistText: true,
                                        showOverflowScreen: true,
                                      );
                                    },
                                  )
                        : ListView.builder(
                            // Tracks in the playlist are not loaded; display skeletonized tracks
                            itemCount: 6,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              return TrackTouchRowSkeleton();
                            });
              },
            ),

            /// LET'S ADD SOMETHING TO YOUR PLAYLIST
            if (Core.app.type == AppType.advanced &&
                widget.isPlaylistLoaded &&
                isOwnPlaylist(playlist, context.read<UserBloc>().state.user))
              LetsAddSomethingTouch()
            else if (playlist.type == PlaylistType.single) ...[
              SizedBox(height: 10),
              OwnerAvatarAndName(
                imageUrl: playlist.owner?['profileImageUrl'],
                ownerName: playlist.owner?['username'],
                type: OwnerAvatarAndNameType.bottomOfSmallTrackScreen,
                userId: playlist.owner?['id'],
              )
            ] else
              const SizedBox(),
          ],
        ),
      ),
    );
  }
}

/// Returns a [Row] with the [Playlist]'s saves and songCount.
class PlaylistStats extends StatelessWidget {
  const PlaylistStats({
    super.key,
    required this.playlist,
  });

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Row(
        children: [
          Text(
            '${playlist.followerCount} saves',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(String.fromCharCode($bull)),
          const SizedBox(width: 8),
          Text(
            '${playlist.total} songs',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Returns a [Row] with the [Playlist]'s saves and songCount.
class SingleInfo extends StatelessWidget {
  const SingleInfo({
    super.key,
    required this.playlist,
  });

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Row(
        children: [
          Text(
            'Single'.translate(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(String.fromCharCode($bull)),
          const SizedBox(width: 8),
          Text(
            playlist.year ?? DateTime.now().year.toString(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Returns a [Row] with the [Playlist]'s name.
class PlaylistdisplayTitle extends StatelessWidget {
  const PlaylistdisplayTitle({
    super.key,
    required this.playlist,
  });

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          playlist.displayTitle ?? playlist.name ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}

class PlaylistImage extends StatelessWidget {
  const PlaylistImage({
    super.key,
    required this.playlist,
  });

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: imageOrIcon(
        imageUrl: playlist.imageUrl,
        filename: playlist.imageFilename,
        // height: 200,
        // width: 200,
      ),
    );
  }
}

/// Returns a [Row] with a [ShuffleButton] and a [PlayButtonInCircle]
class SmallPlaylistPlayerControls extends StatelessWidget {
  const SmallPlaylistPlayerControls(
      {super.key, required this.isPlaylistLoaded});

  final bool isPlaylistLoaded;

  @override
  Widget build(BuildContext context) {
    final playlistBloc = context.read<PlaylistBloc>();
    final trackBloc = context.read<TrackBloc>();

    if (trackBloc.state.displayedTracks.isEmpty && isPlaylistLoaded) {
      return Container();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ShuffleButton(),
        isPlaylistLoaded
            ? PlayButtonInCircle(
                // PLAY button
                playlist: playlistBloc.state.viewedPlaylist,
                size: 60,
                type: CircleButtonType.playlist,
              )
            : Container(
                // Loading indicator
                height: 50,
                width: 50,
                padding: const EdgeInsets.all(13),
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Core.appColor.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Core.appColor.primaryColor,
                  ),
                ),
              ),
      ],
    );
  }
}
