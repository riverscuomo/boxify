import 'package:boxify/app_core.dart';
import 'package:boxify/screens/playlist/widgets/track_touch_row_skeleton.dart';
import 'package:boxify/services/bundles_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';

/// Returns a [ListView] of [TrackTouchRow]s. Used by [SmallSearchScreen] and [PlaylistTouchScreen].
/// On the Small Search Screen, each [TrackTouchRow] should have an [overflowScreen].
/// On the Small Playlist Screen, each [TrackTouchRow] should have an [addButton].
/// I set the defaults to the values for the Small Search Screen.
class SmallTrackSearchResults extends StatelessWidget {
  const SmallTrackSearchResults({
    super.key,
    this.screenType = SearchResultType.searchScreen,
    this.showLoadingState = false,
  });

  final SearchResultType screenType;
  final bool showLoadingState;

  @override
  Widget build(BuildContext context) {
    final searchBloc = context.read<SearchBloc>();
    final playlistBloc = context.read<PlaylistBloc>();
    final marketBloc = context.read<MarketBloc>(); // used to get bundle details
    final trackBloc = context.read<TrackBloc>();
    var indexWithinPlayableTracks = -1;

    Widget buildTrackRow(BuildContext context, int i, Track track) {
      if (track.available == true) {
        indexWithinPlayableTracks++;
      }

      return TrackTouchRow(
        i: i,
        indexWithinPlayableTracks: indexWithinPlayableTracks,
        track: track,
        playlist: screenType ==
                SearchResultType
                    .searchScreen // if you're on a search screen, don't take the image from the viewed playlist
            ? null
            : playlistBloc.state.viewedPlaylist,
        onTap: () async {
          onTapTrack(trackBloc, searchBloc, context, i, track);
        },
        showBundleArtistText: true,
        showOverflowScreen: screenType == SearchResultType.searchScreen,
        showAddButton: screenType == SearchResultType.addToPlaylist,
        canLongPress: screenType == SearchResultType.searchScreen,
      );
    }

    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        if (showLoadingState) {
          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, i) {
              return TrackTouchRowSkeleton();
            },
          );
        }
        if (state.status == SearchStatus.error) {
          return Center(child: Text('errorLoadingTracks'.translate()));
        } else if (state.status == SearchStatus.initial) {
          return const SizedBox();
        } else {
          return ListView.builder(
            shrinkWrap: true,
            physics: screenType == SearchResultType.addToPlaylist
                ? NeverScrollableScrollPhysics()
                : AlwaysScrollableScrollPhysics(),
            itemCount: searchBloc.state.searchResultsTracks.length,
            itemBuilder: (context, i) {
              final track = searchBloc.state.searchResultsTracks[i];
              return buildTrackRow(context, i, track);
            },
          );
        }
      },
    );
  }

  void onTapTrack(TrackBloc trackBloc, SearchBloc searchBloc,
      BuildContext context, int i, Track track) {
    if (trackBloc.state.displayedTracks !=
        searchBloc.state.searchResultsTracks) {
      trackBloc.add(ReplaceSelectedTracksWithSearchResults(
          searchBloc.state.searchResultsTracks));
    }
    final canPlay = context.read<PlayerService>().handlePlay(
          index: i,
          tracks: searchBloc.state.searchResultsTracks,
          source: 'SEARCH',
        );
    if (!canPlay) {
      showTrackSnack(context, track.bundleName ?? '?');
    }
  }
}
