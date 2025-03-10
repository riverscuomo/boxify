import 'package:boxify/app_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Helper class for building the Draggable and non-Draggable
/// large screen rows for [SearchMusicScreen] and [PlaylistMouseScreen].
/// These rows can be dragged onto [DraggablePlaylistTile] in the left side large web
class TrackMouseRowHelper {
  UserRepository userRepository = UserRepository(
    firebaseFirestore: FirebaseFirestore.instance,
    cacheHelper: CacheHelper(),
  );

  int indexForItemBeingDragged = 0;

  /// Returns a List of Widgets for each track row. This is the new way of doing it.
  /// Already used in [PlaylistMouseScreen] but needs to be used in [SearchMusicScreen] and

  /// Returns a List of Widgets for each track row with dragging capability.
  List<Widget> getTrackMouseRowItems(
    BuildContext context, {
    bool showArtist = true,
    bool showYear = true,
    bool compact = false,
    bool canDrag = true,
    bool canBeADragTarget = true,
    bool replaceSelectedTracksWithSearchResultsOnTap = false,
    TrackRowType? trackRowType = TrackRowType.displayedTracks,
  }) {
    final List<Widget> rowItems = [];
    final userBloc = context.read<UserBloc>();
    final trackBloc = context.read<TrackBloc>();
    final playerBloc = context.read<PlayerBloc>();
    final playlistBloc = context.read<PlaylistBloc>();
    final playlistTracksBloc = context.read<PlaylistTracksBloc>();
    final searchBloc = context.read<SearchBloc>();
    PlayerService playerService =
        PlayerService(playerBloc, trackBloc, playlistBloc);
    final state = userBloc.state;
    var indexWithinPlayableTracks =
        -1; // hoisted out of the loop so it won't reset

    final tracks = (trackRowType == TrackRowType.displayedTracks)
        ? trackBloc.state.displayedTracks
        : (trackRowType == TrackRowType.searchResultsForAddToPlaylist) ||
                (trackRowType == TrackRowType.searchResultsForSearchScreen)
            ? searchBloc.state.searchResultsTracks
            : trackBloc.state.allTracks;

    for (int i = 0; i < tracks.length; i++) {
      final track = tracks[i];
      indexWithinPlayableTracks++;

      bool isInsertAboveTarget = false;
      bool isInsertBelowTarget = false;
      bool isTappingRow = false;
      bool isDoubleTappingRow = false;

      // Wrap the trackMouseRow in a Builder
      Widget trackMouseRow = Builder(
        builder: (context) {
          // // // Use context.watch or context.select to listen for changes
          // final currentIndex = context
          //     .select((PlayerBloc bloc) => bloc.state.player.currentIndex);

          // final trackPlayingState = context.select(
          //   (PlayerService service) => service.getPlayingState(track),
          // );

          // Calculate the title color based on the current state
          Color titleColor = TrackHelper.getTitleColor(
            context: context,
            // indexWithinPlayableTracks: indexWithinPlayableTracks,
            track: track,
            // currentIndex: currentIndex,
            // trackPlayingState: trackPlayingState,
          );

          // // Debugging statements
          // print('--- Debug Info ---');
          // print('Track Title: ${track.title}');
          // print('IndexWithinPlayableTracks: $indexWithinPlayableTracks');
          // print('Current Index: $currentIndex');
          // print('Track Playing State: $trackPlayingState');
          // print('--- End Debug Info ---');

          return TrackMouseRow(
            track: track,
            i: i,
            fontColor: titleColor,
            isInsertAboveTarget: isInsertAboveTarget,
            isInsertBelowTarget: isInsertBelowTarget,
            isTappingRow: isTappingRow,
            isDoubleTappingRow: isDoubleTappingRow,
            onTapRow: (track, i, context) {
              return onTapRow(track, i, context);
            },
            onDoubleTapRow: (track, i, context) {
              if (replaceSelectedTracksWithSearchResultsOnTap) {
                trackBloc.add(
                  ReplaceSelectedTracksWithSearchResults(
                    searchBloc.state.searchResultsTracks,
                  ),
                );
              }
              return onDoubleTapRow(track, i, context);
            },
            showLeadingWidget:
                trackRowType != TrackRowType.searchResultsForAddToPlaylist,
            showDurationAndRating:
                trackRowType != TrackRowType.searchResultsForAddToPlaylist,
            showAddButton:
                trackRowType == TrackRowType.searchResultsForAddToPlaylist,
            showOverflowIcon:
                trackRowType != TrackRowType.searchResultsForAddToPlaylist,
          );
        },
      );

      if (canDrag && canBeADragTarget) {
        final playlistPopupMenu = buildPlaylistPopupMenu(context, track);
        rowItems.add(Builder(
          builder: (context) {
            final draggingCubit = BlocProvider.of<DraggingCubit>(context);
            return DragTarget(
              onWillAcceptWithDetails: (DragTargetDetails details) {
                final oldIndex = details.data!['oldIndex'] as int;
                final newIndex = i;

                if (newIndex > oldIndex) {
                  draggingCubit.updateBelowTarget(true, newIndex);
                } else if (newIndex < oldIndex) {
                  draggingCubit.updateAboveTarget(true, newIndex);
                }
                return true;
              },
              onLeave: (data) {
                draggingCubit.updateAboveTarget(false, i);
                draggingCubit.updateBelowTarget(false, i);
              },
              onAcceptWithDetails: (DragTargetDetails details) {
                if (isOwnPlaylist(
                    playlistBloc.state.viewedPlaylist!, state.user)) {
                  final oldIndex = details.data['oldIndex'];
                  final newIndex = i;
                  if (oldIndex == newIndex) {
                    return;
                  }
                  playlistTracksBloc.add(
                    MoveTrack(
                      newIndex: newIndex,
                      oldIndex: oldIndex,
                      playlist: playlistBloc.state.viewedPlaylist!,
                    ),
                  );
                  draggingCubit.updateAboveTarget(false, newIndex);
                  draggingCubit.updateBelowTarget(false, newIndex);
                }
              },
              builder: (BuildContext context, List<dynamic> accepted,
                  List<dynamic> rejected) {
                return GestureDetector(
                  key: Key('largeScreenrow$i'),
                  onSecondaryTapDown: (TapDownDetails details) {
                    if (isOwnPlaylist(
                        playlistBloc.state.viewedPlaylist!, state.user)) {
                      PopupMenuActions.showContextMenuAddOrRemoveToFromPlaylist(
                        context,
                        details.globalPosition,
                        playlistPopupMenu,
                        playlistBloc.state.viewedPlaylist!,
                        track,
                        i,
                      );
                    } else {
                      PopupMenuActions.showContextMenuAddToPlaylist(
                        context,
                        details.globalPosition,
                        playlistPopupMenu,
                        track,
                      );
                    }
                  },
                  child: Draggable(
                    data: {'track': track, 'oldIndex': i},
                    rootOverlay: true,
                    key: Key('draggableLargeScreenrow$i'),
                    affinity: Axis.vertical,
                    feedback: isOwnPlaylist(
                            playlistBloc.state.viewedPlaylist!, state.user)
                        ? DraggedFeedback(track: track)
                        : Container(),
                    child: trackMouseRow,
                  ),
                );
              },
            );
          },
        ));
      } else if (canDrag && !canBeADragTarget) {
        rowItems.add(Draggable(
          data: {'track': track, 'oldIndex': i},
          rootOverlay: true,
          key: Key('draggableLargeScreenrow$i'),
          feedback: DraggedFeedback(track: track),
          child: trackMouseRow,
        ));
      } else {
        rowItems.add(trackMouseRow);
      }
    }

    return rowItems;
  }

  /// Returns [ListView] of [TrackMouseRow]s used in [LargeTrackSearchWidget] and [LargeTrackSearchResults]
  Widget getTrackMouseRows(
    BuildContext context, {
    bool innerItemsAreScrollable = false,
    bool showArtist = true,
    bool showYear = true,
    bool compact = false,
    bool canDrag = true,
    bool canBeADragTarget = true,
    bool replaceSelectedTracksWithSearchResultsOnTap = false,
    TrackRowType? trackRowType = TrackRowType.displayedTracks,
  }) {
    final List tracks;
    final userBloc = context.read<UserBloc>();
    final trackBloc = context.read<TrackBloc>();
    // final playerBloc = context.read<PlayerBloc>();
    final playlistBloc = context.read<PlaylistBloc>();
    final playlistTracksBloc = context.read<PlaylistTracksBloc>();
    final searchBloc = context.read<SearchBloc>();
    final state = userBloc.state;
    var indexWithinPlayableTracks =
        -1; // hoisted out of the loop so it won't reset
    if (trackRowType == TrackRowType.displayedTracks) {
      tracks = trackBloc.state.displayedTracks;
    } else if (trackRowType == TrackRowType.searchResultsForAddToPlaylist ||
        trackRowType == TrackRowType.searchResultsForSearchScreen) {
      tracks = searchBloc.state.searchResultsTracks;
    } else {
      tracks = trackBloc.state.allTracks;
    }
    if (tracks.isEmpty) {
      return const SizedBox.shrink();
    }

    return BlocProvider(
      create: (context) => DraggingCubit(),
      child: ListView.builder(
        physics: innerItemsAreScrollable
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: tracks.length,
        itemBuilder: (context, i) {
          return BlocBuilder<DraggingCubit, DraggingState>(
              builder: (context, draggingState) {
            final track = tracks[i];
            if (track is Track) {
              indexWithinPlayableTracks++;
            }

            // Use context.select to listen for changes in PlayerBloc and PlayerService
            final currentIndex = context
                .select((PlayerBloc bloc) => bloc.state.player.currentIndex);
            final trackPlayingState = context.select(
              (PlayerService service) => service.getPlayingState(track),
            );

            // Debugging statements
            print('--- Debug Info ---');
            print('Track Title: ${track.title}');
            print('IndexWithinPlayableTracks: $indexWithinPlayableTracks');
            print('Current Index: $currentIndex');
            print('Track Playing State: $trackPlayingState');
            print('--- End Debug Info ---');

            Color titleColor = TrackHelper.getTitleColor(
              context: context,
              // indexWithinPlayableTracks: indexWithinPlayableTracks,
              track: track,
              // currentIndex: currentIndex,
              // trackPlayingState: trackPlayingState,
            );

            bool isInsertAboveTarget = false;
            bool isInsertBelowTarget = false;
            bool isTappingRow = false;
            bool isDoubleTappingRow = false;

            if (draggingState is DraggingAboveTarget &&
                draggingState.index == i) {
              isInsertAboveTarget = draggingState.isAboveTarget;
            } else if (draggingState is DraggingBelowTarget &&
                draggingState.index == i) {
              isInsertBelowTarget = draggingState.isBelowTarget;
            } else if (draggingState is TappingRow &&
                draggingState.index == i) {
              isTappingRow = draggingState.isTappingRow;
            } else if (draggingState is DoubleTappingRow &&
                draggingState.index == i) {
              isDoubleTappingRow = draggingState.isDoubleTappingRow;
            }

            // This variable is common to all cases
            final trackMouseRow = TrackMouseRow(
              track: track,
              i: i,
              fontColor: titleColor,
              isInsertAboveTarget: isInsertAboveTarget,
              isInsertBelowTarget: isInsertBelowTarget,
              isTappingRow: isTappingRow,
              isDoubleTappingRow: isDoubleTappingRow,
              onTapRow: (track, i, context) {
                return onTapRow(track, i, context);
              },
              onDoubleTapRow: (track, i, context) async {
                // 1) Dispatch the event that updates the displayedTracks
                if (replaceSelectedTracksWithSearchResultsOnTap) {
                  trackBloc.add(ReplaceSelectedTracksWithSearchResults(
                    searchBloc.state.searchResultsTracks,
                  ));
                }

                // 2) Wait for a rebuild or a short delay for the bloc to process because it was playing before the
                // displayedTracks were updated, playing the previously loaded track. Hack alert.
                await Future.delayed(const Duration(milliseconds: 50));

                // 3) Now call handlePlay, guaranteed the new tracks are in trackBloc.state
                onDoubleTapRow(track, i, context);
              },
              showLeadingWidget:
                  trackRowType != TrackRowType.searchResultsForAddToPlaylist,
              //  &&
              //     trackRowType != TrackRowType.searchResultsForSearchScreen,
              showDurationAndRating:
                  trackRowType != TrackRowType.searchResultsForAddToPlaylist,
              showAddButton:
                  trackRowType == TrackRowType.searchResultsForAddToPlaylist,
              showOverflowIcon:
                  trackRowType != TrackRowType.searchResultsForAddToPlaylist,
            );

            if (canDrag && canBeADragTarget) {
              final playlistPopupMenu = buildPlaylistPopupMenu(
                context,
                track,
              );
              final draggingCubit = BlocProvider.of<DraggingCubit>(context);

              return DragTarget(
                onWillAccept: (Map? data) {
                  final oldIndex = data!['oldIndex'] as int;
                  final newIndex = i;

                  if (newIndex > oldIndex) {
                    // paint the blue border below the box
                    draggingCubit.updateBelowTarget(true, newIndex);
                  } else if (newIndex < oldIndex) {
                    // paint the blue border above the box
                    draggingCubit.updateAboveTarget(true, newIndex);
                  }
                  return true;
                },
                onLeave: (data) {
                  draggingCubit.updateAboveTarget(false, i);
                  draggingCubit.updateBelowTarget(false, i);
                },
                onAccept: (Map data) {
                  if (isOwnPlaylist(
                      playlistBloc.state.viewedPlaylist!, state.user)) {
                    final oldIndex = data['oldIndex'];
                    final newIndex = i;
                    if (oldIndex == newIndex) {
                      return;
                    }
                    playlistTracksBloc.add(
                      MoveTrack(
                        newIndex: newIndex,
                        oldIndex: oldIndex,
                        playlist: playlistBloc.state.viewedPlaylist!,
                      ),
                    );
                    draggingCubit.updateAboveTarget(false, newIndex);
                    draggingCubit.updateBelowTarget(false, newIndex);
                  }
                },
                builder: (
                  BuildContext context,
                  List<dynamic> accepted,
                  List<dynamic> rejected,
                ) {
                  return GestureDetector(
                    key: Key('largeScreenrow$i'),
                    onSecondaryTapDown: (TapDownDetails details) {
                      if (isOwnPlaylist(
                          playlistBloc.state.viewedPlaylist!, state.user)) {
                        PopupMenuActions
                            .showContextMenuAddOrRemoveToFromPlaylist(
                          context,
                          details.globalPosition,
                          playlistPopupMenu,
                          playlistBloc.state.viewedPlaylist!,
                          track,
                          i,
                        );
                      } else {
                        PopupMenuActions.showContextMenuAddToPlaylist(
                          context,
                          details.globalPosition,
                          playlistPopupMenu,
                          track,
                        );
                      }
                    },
                    child: Draggable(
                      data: {'track': track, 'oldIndex': i},
                      rootOverlay: true,
                      key: Key('draggableLargeScreenrow$i'),
                      affinity: Axis.vertical,
                      feedback: isOwnPlaylist(
                              playlistBloc.state.viewedPlaylist!, state.user)
                          ? DraggedFeedback(track: track)
                          : Container(),
                      child: trackMouseRow,
                    ),
                  );
                },
              );
            }

            // Search results at the bottom of the playlist screen can be dragged to
            // other playlists but cannot be drag targets themselves (you cannot drag
            // and drop them within the search results)
            else if (canDrag && !canBeADragTarget) {
              return Draggable(
                data: {'track': track, 'oldIndex': i},
                rootOverlay: true,
                key: Key('draggableLargeScreenrow$i'),
                feedback: DraggedFeedback(track: track),
                child: trackMouseRow,
              );
            } else {
              return trackMouseRow;
            }
          });
        },
      ),
    );
  }

  /// Returns [Color] based on track availability
  void onTapRow(
    Track track,
    int i,
    BuildContext context,
  ) {
    // if (kIsWeb) {
    if (track.available!) {
      logger.i('onTap');
      final trackBloc = context.read<TrackBloc>();
      trackBloc.add(SetMouseClickedTrackId(trackId: track.uuid));
    }
  }

  /// Returns [Color] based on track availability
  /// Plays the track if it is available
  void onDoubleTapRow(
    Track track,
    int i,
    BuildContext context,
  ) {
    logger.i('playlistScreen: onDoubleTap');
    if (track.available!) {
      final trackBloc = context.read<TrackBloc>();
      trackBloc.add(SetMouseClickedTrackId(trackId: track.uuid));
    }

    final playlistBloc = context.read<PlaylistBloc>();

    final canPlay = context.read<PlayerService>().handlePlay(
          index: i,
          tracks: context.read<TrackBloc>().state.displayedTracks,
          playlist: playlistBloc.state.viewedPlaylist,
          source: 'PLAYLIST',
        );

    if (!canPlay) {
      showTrackSnack(context, track.bundleName!);
    }
  }
}
