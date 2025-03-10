import 'package:boxify/app_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SmallTrackScreen extends StatefulWidget {
  final Track track;

  const SmallTrackScreen({
    super.key,
    required this.track,
  });

  @override
  _SmallTrackScreenState createState() => _SmallTrackScreenState();
}

class _SmallTrackScreenState extends State<SmallTrackScreen> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      playTrack(); // Modern web browsers enforce a policy that restricts autoplaying audio or video to enhance user experience and prevent unwanted content from playing without a user's explicit interaction. This policy requires some form of user interaction—like a click or tap—before any audio or video can play.
    }
  }

  @override
  void didUpdateWidget(covariant SmallTrackScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.track.uuid != oldWidget.track.uuid) {
      playTrack();
    }
  }

  void playTrack() {
    final trackBloc = context.read<TrackBloc>();

    try {
      // track =
      //     trackBloc.state.allTracks.firstWhere((t) => t.uuid == widget.trackId);
      final track = widget.track;
      // trackBloc.add(SetDisplayedTracksWithTracks(tracks: [track]));

      // if (width < Core.app.largeSmallBreakpoint) {
      final canPlay = context.read<PlayerService>().handlePlay(
            index: 0,
            tracks: [track],
            source: 'PLAYLIST',
          );
      if (!canPlay) {
        showTrackSnack(context, track.bundleName!);
      }

      /// Create the playlist on the fly over in the [BasePlaylistScreen]
    } catch (e) {
      // logger.e('Error finding track with id: ${widget.trackId}  $e');
      // Instead of redirecting, you might show an error widget or state here.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return BasePlaylistScreen with context, passing it the playlist
    // derived from the single track, assuming BasePlaylistScreen accepts an
    // argument `playlist` which determines what to display.
    return BasePlaylistScreen(
      playlistId: widget.track.uuid!,
    );
  }
}
