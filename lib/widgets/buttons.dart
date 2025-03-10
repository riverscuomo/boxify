import 'package:boxify/app_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

class AddBundleButton extends StatelessWidget {
  const AddBundleButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Card(
        shape: beveledRectangleBorder,
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                onPressed();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: const Icon(Icons.add),
            ),
            Center(
              child: Text(
                'add'.translate(),
                style: TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddThisPlaylistButton extends StatelessWidget {
  const AddThisPlaylistButton({
    super.key,
    required this.track,
    required this.playlistId,
    this.showTextInsteadOfIcon = true,
  });

  final Track track;
  final String playlistId;
  final bool showTextInsteadOfIcon;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        backgroundColor: Colors.black12,
        side: const BorderSide(color: Colors.white), // set the background color
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      onPressed: () {
        context.read<LibraryBloc>().add(AddPlaylistToLibrary(
            playlistId: playlistId, user: context.read<UserBloc>().state.user));
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 8, 18, 8),
        child: Text('addCap'.translate()),
      ),
    );
  }
}

/// Adds a track to a playlist, both of which are passed in.
/// For a [TrackTouchRow] at the bottom of a [PlaylistTouchScreen]
class AddThisTrackButton extends StatelessWidget {
  const AddThisTrackButton({
    super.key,
    required this.track,
    required this.playlist,
    this.showTextInsteadOfIcon = true,
  });

  final Track track;
  final Playlist playlist;
  final bool showTextInsteadOfIcon;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: Colors.black12,
          side:
              const BorderSide(color: Colors.white), // set the background color
          textStyle: TextStyle(
            fontSize: Core.app.subtitleFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        onPressed: () {
          context.read<PlaylistTracksBloc>().add(
                AddTrackToPlaylist(
                  playlist: playlist,
                  track: track,
                ),
              );
        },
        child: showTextInsteadOfIcon
            ? Padding(
                padding: EdgeInsets.fromLTRB(18, 8, 18, 8),
                child: Text('addA'.translate()),
              )
            : Icon(Icons.add));
  }
}

class AdminControlsButton extends StatelessWidget {
  const AdminControlsButton({
    super.key,
    required this.adminControlsOpened,
  });

  final bool adminControlsOpened;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () {
            // adminControlsOpened = !adminControlsOpened; // TODO
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                adminControlsOpened ? Colors.grey[700] : Colors.blueAccent,
          ),
          child: Text('adminControls'.translate()),
        ),
      ],
    );
  }
}

class CircleArtistAvatar extends StatelessWidget {
  CircleArtistAvatar({
    super.key,
    required this.user,
    required this.artistBloc,
    required this.profileImageUrl,
    this.radius = 18,
  });

  final User user;
  final ArtistBloc artistBloc;
  String profileImageUrl;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    /// For some reason these were corrupt
    // CachedNetworkImage.evictFromCache(Core.app.riversPicUrl);
    // CachedNetworkImage.evictFromCache(Core.app.pianoPicUrl);

    if (profileImageUrl.isEmpty) {
      profileImageUrl = Core.app.placeHolderImageUrl;
    }
    // logger.d('CircleArtistAvatar build profileImageUrl: $profileImageUrl');
    CachedNetworkImageProvider backgroundImage; // caused errors when fixed
    try {
      backgroundImage = CachedNetworkImageProvider(profileImageUrl);
    } catch (e) {
      logger.e('CircleArtistAvatar build error: $e');
      backgroundImage = CachedNetworkImageProvider(
        Core.app.placeHolderImageUrl,
      );
    }
    return GestureDetector(
      onTap: () {
        artistBloc.add(LoadArtist(userId: user.id, viewer: user));
        // if (Core.app.type == AppType.advanced) {
        GoRouter.of(context).push('/user/${user.id}');
        // context.read<NavBloc>().add(PushEvent('/user/$userId'));
        // }
      },
      child: CircleAvatar(
        radius: radius,
        backgroundImage: backgroundImage,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}

class CreatePlaylistButton extends StatelessWidget {
  final Color? iconColor;
  final VoidCallback onPressed;

  CreatePlaylistButton(
      {this.iconColor = Colors.white, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.add, color: iconColor),
      onPressed: onPressed,
      tooltip: 'Create Playlist',
      hoverColor: Colors.white,
    );
  }
}

class HomeButton extends StatelessWidget {
  HomeButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: 180,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Core.appColor.primary,
          ),
          onPressed: () => GoRouter.of(context).go('/'),
          child: Text('home'.translate()),
        ),
      ),
    );
  }
}

/// if (state.isCurrentUser && _isLoggedIn)
class LogOutButton extends StatelessWidget {
  const LogOutButton({super.key});

  @override
  Widget build(BuildContext context) {
    final artistBloc = context.read<ArtistBloc>();
    final userBloc = context.read<UserBloc>();
    if ((!artistBloc.state.isCurrentUser ||
        artistBloc.state.user.username == 'Lurker')) {
      return const SizedBox.shrink();
    }
    return IconButton(
      icon: const Icon(Icons.exit_to_app),
      onPressed: () {
        logger.f('logout');

        // Reset player state before logging out
        context.read<PlayerBloc>().add(PlayerReset());

        context.read<AuthBloc>().add(AuthLogoutRequested());

        GoRouter.of(context).go(
          '/login',
        );
      },
    );
  }
}

class LyricsButton extends StatelessWidget {
  final Track track;
  LyricsButton({
    required this.track,
  });

  @override
  Widget build(BuildContext context) {
    if (track.lyrics == null || track.lyrics!.isEmpty) {
      return Container();
    }

    final goRouter = GoRouter.of(context);
    final routerDelegate = goRouter.routerDelegate;
    final currentRoute = routerDelegate.currentConfiguration;
    final isLyricsScreenVisible = currentRoute.fullPath == '/lyrics';

    final color = isLyricsScreenVisible ? Colors.blue : Colors.grey;
    // final hasLyrics = track.lyrics != null && track.lyrics!.isNotEmpty;
    // Expanded to ensure the widget takes up space, with conditional content
    return Align(
      alignment: Alignment.centerRight,
      child: IconButton(
        icon: Icon(Icons.mic, color: color),
        onPressed: () {
          if (isLyricsScreenVisible) {
            goRouter.push('/');
          } else {
            // If the lyrics screen is not visible, navigate to the lyrics screen
            GoRouter.of(context).go('/lyrics');
          }
        },
      ),
    );
  }
}

class LoopButton extends StatelessWidget {
  LoopButton({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerBloc>().state.player;
    return StreamBuilder<LoopMode>(
      stream: player.loopModeStream,
      builder: (context, snapshot) {
        final loopMode = snapshot.data ?? LoopMode.off;
        final icons = [
          const Icon(Icons.repeat, color: Colors.grey),
          Icon(Icons.repeat, color: Core.appColor.primary),
          Icon(Icons.repeat_one, color: Core.appColor.primary),
        ];
        const cycleModes = [
          LoopMode.off,
          LoopMode.all,
          LoopMode.one,
        ];
        final index = cycleModes.indexOf(loopMode);
        return IconButton(
          icon: icons[index],
          onPressed: () {
            player.setLoopMode(
              cycleModes[
                  (cycleModes.indexOf(loopMode) + 1) % cycleModes.length],
            );
          },
        );
      },
    );
  }
}

Center logInButton(BuildContext context) {
  return Center(
    child: SizedBox(
      width: 180,
      child: ElevatedButton(
        onPressed: () {
          GoRouter.of(context).go('/login');

          /// If you don't log out first, the authStatus will never be unauthenticated
          /// and the resetting of the blocs will never be triggered in the myapp.authBloc listener
          context.read<AuthBloc>().add(AuthLogoutRequested());
        },
        child: Text('logIn'.translate()),
      ),
    ),
  );
}

/// A Play, Pause, or Replay button that changes based on the player's state.
///
/// Shows a Play button when the player is not playing.
/// Shows a Pause button when the player is not completed.
/// Shows a Replay button when the player has completed.
///
/// Used in [LeadingWidgetForTrackMouseRow]
class PlayButtonUnpadded extends StatelessWidget {
  const PlayButtonUnpadded({
    super.key,
    this.size = 44,
    this.isPlaying = false,
    this.isHovering = false,
    this.isMouseClicked = false,
    this.alignment = Alignment.center,
    this.index = 0,
  });

  final double? size;
  final bool isPlaying;
  final bool isHovering;
  final bool isMouseClicked;
  final Alignment alignment;
  final int index;

  @override
  Widget build(BuildContext context) {
    final playerBloc = context.read<PlayerBloc>();

    return StreamBuilder<PlayerState>(
      stream: playerBloc.state.player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        if (playerState == null) {
          return MyIndex(index: index);
        }
        if (isHovering || isMouseClicked) {
          // logger.i('isHovering: $isHovering');
          if (isPlaying) {
            return MyPause(playerBloc: playerBloc, size: size);
          } else if (!isPlaying) {
            // logger.i('isPlaying: $isPlaying');
            return MyPlayButton(index: index, size: size);
          } else {
            return MyIndex(index: index);
          }
        }
        if (!isHovering && !isMouseClicked) {
          if (isPlaying) {
            if (playerState.playing) {
              return Spectrum(size: size);
            } else if (processingState == ProcessingState.completed) {
              return MyReplay(playerBloc: playerBloc, size: size);
            } else {
              return MyIndex(index: index);
            }
          } else {
            return MyIndex(index: index);
          }
        }
        return MyIndex(index: index);
      },
    );
  }
}

class MyIndex extends StatelessWidget {
  const MyIndex({
    super.key,
    required this.index,
  });

  final int index;

  @override
  Widget build(BuildContext context) {
    return FixedWidthIconWrapper(
      child: Text(
        (index + 1).toString(),
        textAlign: TextAlign.right,
      ),
    );
  }
}

class MyPause extends StatelessWidget {
  const MyPause({
    super.key,
    required this.playerBloc,
    required this.size,
  });

  final PlayerBloc playerBloc;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return FixedWidthIconWrapper(
      child: InkWell(
        onTap: playerBloc.state.player.pause,
        child: Container(
          child: Icon(Icons.pause, size: size, color: Colors.white),
        ),
      ),
    );
  }
}

class MyReplay extends StatelessWidget {
  const MyReplay({
    super.key,
    required this.playerBloc,
    required this.size,
  });

  final PlayerBloc playerBloc;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return FixedWidthIconWrapper(
      child: InkWell(
        onTap: () => playerBloc.state.player.seek(Duration.zero,
            index: context
                .read<PlayerBloc>()
                .state
                .player
                .effectiveIndices!
                .first),
        child: Container(
          child: Icon(Icons.replay, size: size, color: Colors.white),
        ),
      ),
    );
  }
}

class Spectrum extends StatelessWidget {
  final double? size;

  const Spectrum({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return FixedWidthIconWrapper(
      child: Icon(
        Icons.graphic_eq,
        size: size,
        color: Core.appColor.primary,
      ),
    );
  }
}

class MyPlayButton extends StatelessWidget {
  const MyPlayButton({
    super.key,
    required this.index,
    required this.size,
  });

  final int? index;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return FixedWidthIconWrapper(
      child: InkWell(
        onTap: () {
          context.read<PlayerService>().handlePlay(
                tracks: context.read<TrackBloc>().state.displayedTracks,
                playlist: context.read<PlaylistBloc>().state.viewedPlaylist,
                index: index,
                source: 'PLAYLIST',
              );
        },
        child: Icon(
          Icons.play_arrow,
          color: Colors.white,
          size: size, // Your icon size
        ),
      ),
    );
  }
}

/// A Play, Pause, or Replay button that changes based on the player's state.
///
/// Shows a Play button when the player is not playing.
/// Shows a Pause button when the player is not completed.
/// Shows a Replay button when the player has completed.
///
/// Seems to be used in [LargeControlButtons], [SmallPlayer], [PlayerControls]
///
/// original playbutton uses iconbutton which has  intrinsic padding within the `IconButton` itself, which is not removed by setting its padding to zero.
// In Flutter, an `IconButton` internally uses padding to hit minimum touch targets as per Material Design guidelines, making it difficult to completely eliminate spacing without an alternative approach.
class PlayButton extends StatelessWidget {
  const PlayButton({
    super.key,
    this.size = 44,
    this.alignment = Alignment.center,
  });

  final double? size;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final playerBloc = context.read<PlayerBloc>();

    return StreamBuilder<PlayerState>(
      stream: playerBloc.state.player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing;

        // The UI (build method) should only be responsible for deciding what to display,
        // not how the application data should be handled.
        // This would make your code more maintainable and easier to reason about,
        // because you are separating business logic from UI logic, which is one of the primary reasons to use the BLoC pattern.
        if (playing != true) {
          // Display play button
          return IconButton(
              color: Colors.white,
              icon: const Icon(Icons.play_arrow),
              iconSize: size,
              onPressed: () {
                context.read<PlayerService>().handlePlay(
                      // tracks: context.read<TrackBloc>().state.displayedTracks,
                      // playlist:
                      //     context.read<PlaylistBloc>().state.viewedPlaylist,
                      source: 'PLAYLIST',
                    );
              });
        } else if (processingState != ProcessingState.completed) {
          // If Playing
          // If hovering, Display pause button
          return Row(
            children: [
              IconButton(
                color: Colors.white,
                icon: const Icon(Icons.pause),
                iconSize: size,
                onPressed: playerBloc.state.player.pause,
                // alignment: alignment,
              ),
            ],
          );
        } else {
          // Display replay button
          return IconButton(
            color: Colors.white,
            icon: const Icon(Icons.replay),
            iconSize: size,
            onPressed: () => playerBloc.state.player.seek(
              Duration.zero,
              index: context
                  .read<PlayerBloc>()
                  .state
                  .player
                  .effectiveIndices!
                  .first,
            ),
            // alignment: alignment,
          );
        }
      },
    );
  }
}

enum CircleButtonType {
  home,
  playlist,
  track,
}

/// Used in [PlaylistMouseScreen], [PlaylistTouchScreen] (in weezify),  [BaseTrackScren], and [TappablePlaylistWidget]
///  in the [LibraryScreen].
///
/// Use cases:
/// BEFORE FIRST TAP:
/// If the queue does not match the playlist, then show a play button.
/// If the queue matches the playlist, and it is playing, then show a pause button.
///
/// FIRST TAP:
/// 1. Playing a [Playlist] from the [HomeScreen]: should select the playlist, select the first track, and play the track.
/// 2. Playing a [Playlist] from the [BasePlaylistScreen]: should select the playlist, select the first track, and play the track.
/// 3. Playing a [Track] from the [TrackScreen]: should select the track and play the track.
///
/// LATER TAPS:
/// If the queue matches the playlist, then the play button should simply toggle between play and pause.
/// If the queue does not match the playlist, then the play button should behave as in the first tap.
class PlayButtonInCircle extends StatefulWidget {
  const PlayButtonInCircle({
    super.key,
    this.track,
    this.playlist,
    this.size = 75,
    this.type = CircleButtonType.home,
  });

  final Track? track;
  final Playlist? playlist;
  final CircleButtonType? type;
  final double size;

  @override
  State<PlayButtonInCircle> createState() => _PlayButtonInCircleState();
}

class _PlayButtonInCircleState extends State<PlayButtonInCircle> {
  late double size;

  @override
  void initState() {
    super.initState();
    size = widget.size;
  }

  @override
  Widget build(BuildContext context) {
    final trackBloc = context.read<TrackBloc>();
    final playerBloc = context.read<PlayerBloc>();

    return MouseRegion(
      onEnter: (e) {
        setState(() {
          size = widget.size + 1;
        });
      },
      onExit: (e) {
        setState(() {
          size = widget.size;
        });
      },
      child: SizedBox(
        height: widget.size + 1,
        width: widget.size + 1,
        child: Align(
          alignment: Alignment.centerRight,
          child: StreamBuilder<PlayerState>(
            stream: playerBloc.state.player.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final processingState = playerState?.processingState;
              final playing = playerState?.playing;
              final playlistBloc = context.read<PlaylistBloc>();
              final enquedPlaylist = playlistBloc.state.enquedPlaylist;
              // Returns a PLAY BUTTON
              // - if connected to a different playlist
              // - or same playlist but NOT ALREADY PLAYING
              if (widget.playlist != enquedPlaylist ||
                  (playing != true ||
                      processingState == ProcessingState.completed)) {
                return CustomIconButtonWithFilledBackground(
                    iconData: Icons.play_circle_filled_rounded,
                    size: size,
                    onPressed: () {
                      onPressedCirclePlayButton(context, trackBloc);
                    });

                // Returns a PAUSE BUTTON
                // If already playling the same playlist
              } else {
                return CustomIconButtonWithFilledBackground(
                    iconData: Icons.pause_circle_filled_sharp,
                    size: size,
                    onPressed: playerBloc.state.player.pause);
              }
            },
          ),
        ),
      ),
    );
  }

  void onPressedCirclePlayButton(BuildContext context, TrackBloc trackBloc) {
    List<Track> tracks = [];

    final playlistService = context.read<PlaylistService>();

    /// switch between the 3 types of play buttons
    switch (widget.type) {
      case CircleButtonType.home:
        tracks = playlistService.getPlaylistTracks(widget.playlist!);
        break;
      case CircleButtonType.playlist:
        tracks = playlistService.getPlaylistTracks(widget.playlist!);
        break;
      case CircleButtonType.track:
        tracks = trackBloc.state.displayedTracks;
        break;
      default:
        tracks = trackBloc.state.displayedTracks;
    }
    final canPlay = context.read<PlayerService>().handlePlay(
          tracks: tracks,
          playlist: widget.playlist,
          source: 'PLAYLIST',
        );

    if (!canPlay && Core.app.type == AppType.advanced) {
      if (widget.track != null) {
        showTrackSnack(context, widget.track!.bundleName!);
      } else {
        showTrackSnack(context, '');
      }
    }
  }
}

class CustomIconButtonWithFilledBackground extends StatelessWidget {
  const CustomIconButtonWithFilledBackground({
    super.key,
    required this.iconData,
    required this.onPressed,
    this.size = 44,
    this.color = Colors.white,
    this.backgroundColor = Colors.black,
  });

  final IconData iconData;
  final VoidCallback onPressed;
  final double size;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      Container(
        color: Colors.black,
        height: size * .5,
        width: size * .5,
      ),
      IconButton(
        onPressed: () {
          onPressed();
        },
        icon: Icon(iconData),
        iconSize: size,
        style: IconButton.styleFrom(
          foregroundColor: Core.appColor.primary,
          backgroundColor:
              Colors.transparent, // Remove the button's own background
          minimumSize: Size.zero, // Allows the button to shrink to fit the icon
          padding: EdgeInsets.zero, // Removes any internal padding
        ),
      ),
    ]);
  }
}

/// Player search  and User search button
class SearchButton extends StatelessWidget {
  const SearchButton({
    super.key,
    this.targetPath = '/playerSearch',
    this.toolTipText = 'Search your library',
  });

  final String targetPath;
  final String toolTipText;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.search),
      tooltip: toolTipText,
      iconSize: 30,
      onPressed: () {
        GoRouter.of(context).push(targetPath); // TODO: Fix this for rivify
        // playerbloc.add(SetScreen(targetPath.replaceAll('/', '')));
        // context.read<NavBloc>().add(PushEvent(targetPath));
      },
    );
  }
}

class SeekToNextButton extends StatelessWidget {
  const SeekToNextButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final playerBloc = context.read<PlayerBloc>();
    return StreamBuilder<SequenceState?>(
      stream: playerBloc.state.player.sequenceStateStream,
      builder: (context, snapshot) {
        return IconButton(
          icon: const Icon(Icons.skip_next),
          color: Colors.white,
          onPressed: playerBloc.state.player.hasNext
              ? () => playerBloc.add(const SeekToNext())
              : null,
        );
      },
    );
  }
}

class SeekToPreviousButton extends StatelessWidget {
  const SeekToPreviousButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final playerBloc = context.read<PlayerBloc>();
    return GestureDetector(
      onDoubleTap: () => playerBloc.state.player.hasPrevious
          ? playerBloc.add(const SeekToPrevious())
          : playerBloc.state.player.seek(Duration.zero),
      child: IconButton(
        icon: const Icon(Icons.skip_previous),
        onPressed: () {
          playerBloc.state.player.seek(Duration.zero);
        },
      ),
    );
  }
}

class SettingsButton extends StatelessWidget {
  SettingsButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        onPressed: () => GoRouter.of(context).push('/settings'),
        child: const Icon(Icons.settings),
      ),
    );
  }
}

/// Migrating to passing [Playlist] and [Track] objects instead of [String]s
class ShareButton extends StatelessWidget {
  ShareButton({
    this.url,
    this.title,
    this.playlist,
  });

  String? title;
  String? url;
  final Playlist? playlist;

  @override
  Widget build(BuildContext context) {
    final userBloc = context.read<UserBloc>();
    if (playlist != null) {
      if (playlist!.id == userBloc.state.user.id) {
        return Container();
      }
      url = '${Core.app.playlistUrl}${playlist!.id}';
      title = playlist!.displayTitle!;
    }
    return IconButton(
      onPressed: () => ShareHelper.shareContent(
        context: context,
        url: url!,
        title: title!,
      ),
      icon: const Icon(Icons.share_outlined),
      color: Colors.grey,
    );
  }
}

class ShuffleButton extends StatelessWidget {
  final double? size;
  const ShuffleButton({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerBloc>().state.player;
    return StreamBuilder<bool>(
      stream: player.shuffleModeEnabledStream,
      builder: (context, snapshot) {
        final shuffleModeEnabled = snapshot.data ?? false;
        return IconButton(
          iconSize: size,
          icon: shuffleModeEnabled
              ? Icon(Icons.shuffle, color: Core.appColor.primary)
              : const Icon(Icons.shuffle, color: Colors.grey),
          onPressed: () async {
            final enable = !shuffleModeEnabled;
            if (enable) {
              await player.shuffle();
            }
            await player.setShuffleModeEnabled(enable);
          },
        );
      },
    );
  }
}

Center signUpButton(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: 180,
        child: ElevatedButton(
          onPressed: () {
            logger.i('signup button pressed');
            return GoRouter.of(context).go('/signup');
          },
          child: Text('noAccountSignUp'.translate()),
        ),
      ),
    ),
  );
}

/// Don't seem to be using this anywhere
class RoundedButton extends StatelessWidget {
  RoundedButton({super.key, this.title, this.colour, required this.onPressed});
  final Color? colour;
  final String? title;
  final Function onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Material(
        elevation: 5.0,
        color: colour,
        borderRadius: BorderRadius.circular(30.0),
        child: MaterialButton(
          onPressed: onPressed as void Function()?,
          minWidth: 200.0,
          height: 42.0,
          child: Text(
            title!,
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class ToggleDownloadPlaylistButton extends StatelessWidget {
  final Playlist playlist;
  final double size;
  ToggleDownloadPlaylistButton(this.playlist, {this.size = 24});

  double getPlaylistDownloadProgress(
      String playlistId, List<Track> playlistTracks, Map downloadProgress) {
    if (playlistTracks.isEmpty) {
      return 0.0;
    }

    // Sum of individual track progress
    double cumulativeProgress = playlistTracks.fold(
      0.0,
      (sum, track) => sum + (downloadProgress[track.uuid!] ?? 0.0),
    );

    // Calculate average progress
    return cumulativeProgress / playlistTracks.length;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadBloc, DownloadState>(
      builder: (context, downloadState) {
        // logger.f(downloadState.playlistDownloadStatus);
        final playlistDownloadStatus =
            downloadState.playlistDownloadStatus[playlist.id] ??
                DownloadStatus.initial;
        final userBloc = context.read<UserBloc>();
        final downloadBloc = context.read<DownloadBloc>();
        final trackBloc = context.read<TrackBloc>();
        final playlistHelper = PlaylistHelper();
        final playlistTracks = trackBloc.state.displayedTracks;
        bool isFullyDownloaded =
            playlistHelper.isFullyDownloaded(playlistTracks);
        final playlistDownloadProgress = getPlaylistDownloadProgress(
            playlist.id!, playlistTracks, downloadState.downloadProgress);

        switch (playlistDownloadStatus) {
          case DownloadStatus.downloading:
            // Button to stop the download with progress displayed
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    value: playlistDownloadProgress,
                    strokeWidth: 1.0,
                    // backgroundColor: Colors.grey.shade300,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Core.appColor.primary),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Logic to stop the download
                    downloadBloc.add(
                      StopDownload(
                        playlistId: playlist.id!,
                        playlistTracks: playlistTracks,
                        userId: userBloc.state.user.id,
                      ),
                    );
                    downloadBloc.add(RemoveDownloadedTracks(
                      tracksToUnDownload: playlistTracks,
                      userId: userBloc.state.user.id,
                      playlistId: playlist.id!,
                    ));
                  },
                  icon: Icon(
                    Icons.stop,
                    color: Colors.grey,
                    size: size - 4,
                  ),
                ),
              ],
            );
          case DownloadStatus.paused:
          case DownloadStatus.error:
            // Button to resume/retry the download
            return IconButton(
              onPressed: () {
                // TODO: Replace with logic to resume or retry the download
              },
              icon: Icon(
                Icons.download_for_offline_outlined,
                color: Colors.grey,
                size: size,
              ),
            );

          default:
            // Button to start the download
            return !isFullyDownloaded
                ? IconButton(
                    iconSize: size,
                    icon: Icon(
                      Icons.download_for_offline_outlined,
                      color: Colors.grey,
                      size: size,
                    ),
                    onPressed: () {
                      context
                          .read<PlaylistService>()
                          .handleDownloadButtonPressed(context, playlist);
                    },
                  )
                : IconButton(
                    onPressed: () async {
                      // Show a warning dialog before proceeding
                      final proceed = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Remove Download'),
                            content: Text(
                              'If you remove this playlist, you won\'t be able to listen to it offline. Do you want to proceed?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(
                                    false), // Return false when "Cancel" is pressed
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(
                                    true), // Return true when "Remove" is pressed
                                child: Text('Remove'),
                              ),
                            ],
                          );
                        },
                      );

                      // If the user cancels, return early
                      if (proceed != true) {
                        return;
                      }

                      // Proceed with removal if the user confirmed
                      final trackBloc = context.read<TrackBloc>();
                      final tracksToUnDownload = trackBloc.state.displayedTracks
                          .where(
                            (track) => isDownloaded(track.downloadedUrl),
                          )
                          .toList();
                      final userId = userBloc.state.user.id;
                      downloadBloc.add(
                        RemoveDownloadedTracks(
                          tracksToUnDownload: tracksToUnDownload,
                          userId: userId,
                          playlistId: playlist.id!,
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.arrow_circle_down_outlined,
                      color: Core.appColor.primary,
                      size: size + 10,
                    ));
        }
      },
    );
  }
}

// Widget buildTrackDownloadIndicator(BuildContext context, Track track) {
//   return BlocBuilder<DownloadBloc, DownloadState>(
//     builder: (context, downloadState) {
//       logger.e(downloadState.downloadProgress);
//       final progress = downloadState.downloadProgress[track.uuid] ?? 0.0;
//       return LinearProgressIndicator(value: progress);
//     },
//   );
// }

/// Returns an [ElevatedButton] for following or unfollowing a [Playlist].
class ToggleFollowUnfollowButton extends StatelessWidget {
  final double size;
  const ToggleFollowUnfollowButton({
    super.key,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final libraryBloc = context.read<LibraryBloc>();
    final playlistBloc = context.read<PlaylistBloc>();
    final userBloc = context.read<UserBloc>();
    final playlist = playlistBloc.state.viewedPlaylist!;

    /// Now I'm worried this will mess up weezify button update because it's not
    /// listening to the bloc
    final playlistIsAlreadyFollowed = userBloc.state.user.playlistIds
        .any((element) => element == playlist.id);

    return playlist.isFollowable && !playlistIsAlreadyFollowed
        ? IconButton(
            onPressed: () {
              libraryBloc.add(AddPlaylistToLibrary(
                  playlistId: playlistBloc.state.viewedPlaylist!.id!,
                  user: userBloc.state.user));
            },
            icon: Icon(
              Icons.add_circle_outline,
              color: Colors.grey,
              size: size,
            ))
        : playlist.isFollowable && !playlistIsAlreadyFollowed
            ? IconButton(
                onPressed: () {
                  libraryBloc.add(RemovePlaylist(
                      playlist: playlistBloc.state.viewedPlaylist!,
                      user: userBloc.state.user));
                },
                icon: Icon(
                  Icons.check_circle,
                  color: Core.appColor.primary,
                  size: size,
                ))
            : Container();
  }
}
// return playlist.isFollowable
//         ? IconButton(
//             onPressed: () {
//               libraryBloc.add(
//                 AddPlaylistToLibrary(
//                     playlistId: playlistBloc.state.viewedPlaylist!.id!,
//                     user: userBloc.state.user),
//               );
//             },
//             icon: Icon(
//               Icons.add_circle_outline,
//               color: Colors.grey,
//             ))
//         : IconButton(
//             onPressed: () {
//               libraryBloc.add(RemovePlaylist(
//                   playlist: playlistBloc.state.viewedPlaylist!,
//                   user: userBloc.state.user));
//             },
//             icon: Icon(
//               Icons.check_circle,
//               color: Core.appColor.primary,
//               size: 24,
//             ));

// class RemoveDownloadedPlaylistButton extends StatelessWidget {
//   const RemoveDownloadedPlaylistButton();

//   @override
//   Widget build(BuildContext context) {
//     return IconButton(
//       icon: Icon(
//         Icons.cancel,
//         color: Core.appColor.primary,
//       ),
//       onPressed: () => context
//           .read<PlaylistService>()
//           .handleRemoveDownloadButtonPressed(context, playlist),
//     );
//   }
// }
