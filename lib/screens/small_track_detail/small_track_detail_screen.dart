import 'package:boxify/app_core.dart';
import 'package:boxify/helpers/color_helper.dart';
import 'package:boxify/ui/image_with_color_extraction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'widgets/widgets.dart';

class PlayerSmallTrackDetailScreen extends StatefulWidget {
  const PlayerSmallTrackDetailScreen({super.key});

  @override
  _PlayerSmallTrackDetailScreenState createState() =>
      _PlayerSmallTrackDetailScreenState();
}

class _PlayerSmallTrackDetailScreenState<Track>
    extends State<PlayerSmallTrackDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, MyPlayerState>(
      builder: (context, state) {
        final playerBloc = context.read<PlayerBloc>();
        final playlistBloc = context.read<PlaylistBloc>();
        final track = state.queue[state.player.currentIndex!];

        final enquedPlaylist = playlistBloc.state.enquedPlaylist;

        final imageUrl = assignPlaylistImageUrlToTrack(track, enquedPlaylist);
        final imageFilename =
            assignPlaylistImageFilenameToTrack(track, enquedPlaylist);

        if (imageUrl != null &&
            imageUrl.isNotEmpty &&
            imageUrl != 'assets/images/rc.png') {}
        final size = MediaQuery.of(context).size;
        final height = size.height;
        final width = size.width;

        return Material(
          child: Container(
            decoration: BoxDecoration(
              // add the same color gradient
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  // Ensure the background color (extracted from track image) is neither too light nor too dark
                  ColorHelper.ensureWithinRangeHsl(state.backgroundColor,
                          minLightness: 0.25, maxLightness: 0.7)
                      .toColor(),
                  Core.appColor.widgetBackgroundColor,
                ],
              ),
            ),
            height: height,
            child: ListView(
              children: [
                // const SizedBox(height: 20),
                SmallDetailTopListTile(
                    playlist: playlistBloc.state.enquedPlaylist,
                    track: track,
                    source: state.source),
                const SizedBox(height: 10),

                /// This is the actual up front image for the track
                Padding(
                  padding: const EdgeInsets.only(left: 40, right: 40),
                  child: Column(
                    children: [
                      ImageWithColorExtraction(
                        imageUrl: imageUrl,
                        filename: imageFilename,
                        height: width - 100, // Notice these are both from width
                        width: width - 100,
                        roundedCorners: 8,
                        onColorExtracted: (color) {
                          // Make sure widget is mounted before setting state
                          // This may happen if the user closes the screen before the image is loaded
                          if (!mounted) return;

                          // Update track's backgroundColor
                          playerBloc.add(UpdateTrackBackgroundColor(
                              backgroundColor: HSLColor.fromColor(color)));
                        },
                      ),
                      const SizedBox(height: 20),
                      SongInfoWidget(track: track),
                      const SizedBox(height: 20),
                      SeekBarWidget(),
                      const SizedBox(height: 20),
                      PlayerControls(
                        track: track,
                      ),
                      const SizedBox(height: 10),
                      LyricsWidget(
                          track: track, backgroundColor: state.backgroundColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
