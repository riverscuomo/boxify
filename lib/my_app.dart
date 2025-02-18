import 'package:boxify/app_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';
import 'package:boxify/screens/search_user/cubit/search_user_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'my_router.dart';
import 'dart:math';

final router = MyRouter().router;
final connectivityManager = ConnectivityManager();

class AudioPlayerSingleton {
  static final AudioPlayer _instance = AudioPlayer();

  static AudioPlayer get instance => _instance;
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final audioPlayer = AudioPlayerSingleton.instance;

  Track? getInitialTrack(TrackBloc trackBloc, User user) {
    Track? track;

    final availableTracks = trackBloc.state.allTracks
        .where((track) => track.available == true)
        .toList();

    // // Attempt to find the track by ID if one was passed in the URL
    // track = trackBloc.state.allTracks
    //     .firstWhereOrNull((track) => track.available == true);

    // If no track was found by ID, or no ID was passed, select a random track
    // from by the people playlist
    if (availableTracks.isNotEmpty) {
      var randomIndex = Random().nextInt(availableTracks.length);
      track = availableTracks[randomIndex];
    }

    // Handle the case where no suitable track was found
    // e.g., because the list of all tracks was empty
    if (track == null) {
      logger.e('No track found');
      // // Handle this scenario, maybe return a default track or throw an error
      // throw Exception('No tracks found');
      return null;
    }

    return track;
  }

  @override
  Widget build(BuildContext context) {
    Core.app.postInit();
    final myBlocProviders = [
      BlocProvider<AuthBloc>(
        create: (context) =>
            AuthBloc(authRepository: context.read<AuthRepository>()),
      ),
      BlocProvider<DownloadBloc>(
        create: (context) => DownloadBloc(),
      ),
      BlocProvider<LibraryBloc>(
        create: (context) => LibraryBloc(
          authBloc: context.read<AuthBloc>(),
          userRepository: context.read<UserRepository>(),
          trackRepository: context.read<TrackRepository>(),
          playlistRepository: context.read<PlaylistRepository>(),
          metaDataRepository: context.read<MetaDataRepository>(),
          storageRepository: context.read<StorageRepository>(),
          bundleRepository: context.read<BundleRepository>(),
        ),
      ),
      BlocProvider<LoginCubit>(
        create: (context) => LoginCubit(
          authRepository: context.read<AuthRepository>(),
        ),
      ),
      BlocProvider<MarketBloc>(
        create: (context) => MarketBloc(
          authBloc: context.read<AuthBloc>(),
          userRepository: context.read<UserRepository>(),
          trackRepository: context.read<TrackRepository>(),
          playlistRepository: context.read<PlaylistRepository>(),
          metaDataRepository: context.read<MetaDataRepository>(),
          storageRepository: context.read<StorageRepository>(),
          bundleRepository: context.read<BundleRepository>(),
        ),
      ),
      BlocProvider<MetaDataCubit>(
        create: (context) => MetaDataCubit(
          context.read<MetaDataRepository>(),
        ),
      ),
      BlocProvider<NavCubit>(
        //create: (_) => NavCubit( 
          //Core.app.type == AppType.advanced
              //? bottomNavigationBarItemAdvanced(context).length - 1
              //: bottomNavigationBarItemBasic(context).length - 1,
        //),
        create: (context) => NavCubit(), // applies to all app types
        child: MyApp(), // Your main app widget
      ),
      BlocProvider<PlaylistTracksBloc>(
        create: (context) => PlaylistTracksBloc(
          playlistRepository: context.read<PlaylistRepository>(),
        ),
      ),
      BlocProvider<SearchUserCubit>(
        create: (context) => SearchUserCubit(
          userRepository: context.read<UserRepository>(),
        ),
      ),
      BlocProvider<SignupCubit>(
        create: (context) => SignupCubit(
          authRepository: context.read<AuthRepository>(),
          userRepository: context.read<UserRepository>(),
        ),
      ),
      BlocProvider<UsernameCubit>(
        create: (context) => UsernameCubit(
          userRepository: context.read<UserRepository>(),
        ),
      ),
      BlocProvider<UserBloc>(
        create: (context) => UserBloc(
          authBloc: context.read<AuthBloc>(),
          userRepository: context.read<UserRepository>(),
          trackRepository: context.read<TrackRepository>(),
        ),
      ),
      BlocProvider<PlayerBloc>(
        create: (context) => PlayerBloc(
          audioPlayer: audioPlayer,
        ),
      ),
      BlocProvider<PlaylistBloc>(
        create: (context) => PlaylistBloc(
          authBloc: context.read<AuthBloc>(),
          userRepository: context.read<UserRepository>(),
          trackRepository: context.read<TrackRepository>(),
          playlistRepository: context.read<PlaylistRepository>(),
          metaDataRepository: context.read<MetaDataRepository>(),
          storageRepository: context.read<StorageRepository>(),
          bundleRepository: context.read<BundleRepository>(),
        ),
      ),
      BlocProvider(
        create: (context) => PlaylistInfoBloc(
          playlistRepository: context.read<PlaylistRepository>(),
          storageRepository: context.read<StorageRepository>(),
        ),
      ),
      BlocProvider<ArtistBloc>(
        create: (context) => ArtistBloc(
          marketBloc: context.read<MarketBloc>(),
          authBloc: context.read<AuthBloc>(),
          userRepository: context.read<UserRepository>(),
          storageRepository: context.read<StorageRepository>(),
          playlistRepository: context.read<PlaylistRepository>(),
        ),
      ),
      BlocProvider<SettingsBloc>(
        create: (context) => SettingsBloc(
          marketBloc: context.read<MarketBloc>(),
          authBloc: context.read<AuthBloc>(),
          userRepository: context.read<UserRepository>(),
          storageRepository: context.read<StorageRepository>(),
          playlistRepository: context.read<PlaylistRepository>(),
        ),
      ),
      BlocProvider<SearchBloc>(
        create: (context) => SearchBloc(
          userRepository: context.read<UserRepository>(),
          storageRepository: context.read<StorageRepository>(),
          playlistRepository: context.read<PlaylistRepository>(),
          trackRepository: context.read<TrackRepository>(),
          metaDataRepository: context.read<MetaDataRepository>(),
          bundleRepository: context.read<BundleRepository>(),
        ),
      ),
      BlocProvider<TrackBloc>(
        create: (context) => TrackBloc(
          authBloc: context.read<AuthBloc>(),
          userRepository: context.read<UserRepository>(),
          trackRepository: context.read<TrackRepository>(),
          storageRepository: context.read<StorageRepository>(),
          metaDataRepository: context.read<MetaDataRepository>(),
        ),
      ),
      Provider<PlaylistService>(
        create: (context) => PlaylistService(
          context.read<DownloadBloc>(),
          context.read<TrackBloc>(),
        ),
      ),
      Provider<PlayerService>(
        create: (context) => PlayerService(
          context.read<PlayerBloc>(),
          context.read<TrackBloc>(),
          context.read<PlaylistBloc>(),
        ),
      ),
    ];
    var myRepositoryProviders = [
      RepositoryProvider<AuthRepository>(
        create: (_) => AuthRepository(),
      ),
      RepositoryProvider<UserRepository>(
        create: (_) => UserRepository(
          cacheHelper: CacheHelper(),
          firebaseFirestore: FirebaseFirestore.instance,
        ),
      ),
      RepositoryProvider<TrackRepository>(
        create: (_) => TrackRepository(),
      ),
      RepositoryProvider<StorageRepository>(
        create: (_) => StorageRepository(),
      ),
      RepositoryProvider(
          create: (_) => MetaDataRepository(
              cacheHelper: CacheHelper(),
              firebaseFirestore: FirebaseFirestore.instance)),
      RepositoryProvider(create: (_) => BundleRepository()),
      RepositoryProvider<PlaylistRepository>(
        create: (_) => PlaylistRepository(),
      ),
    ];
    var myBlocListeners = [
      BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.status !=
            current.status, // Only listen when the status changes
        listener: (context, state) {
          logger.i('==================================================');
          final metaDataCubit = context.read<MetaDataCubit>();
          final trackBloc = context.read<TrackBloc>();
          final playlistBloc = context.read<PlaylistBloc>();
          final userBloc = context.read<UserBloc>();
          final libraryBloc = context.read<LibraryBloc>();
          final loginCubit = context.read<LoginCubit>();
          final marketBloc = context.read<MarketBloc>();
          final artistBloc = context.read<ArtistBloc>();
          final playlistTracksBloc = context.read<PlaylistTracksBloc>();
          final searchBloc = context.read<SearchBloc>();
          final searchUserCubit = context.read<SearchUserCubit>();
          final settingsBloc = context.read<SettingsBloc>();
          final signupCubit = context.read<SignupCubit>();
          final usernameCubit = context.read<UsernameCubit>();

          libraryBloc.add(const InitialLibraryState());
          loginCubit.reset();
          metaDataCubit.reset();

          // playerBloc.add(PlayerReset()); /// Was creating a second player as the app started which was causing a memory leak https://github.com/riverscuomo/flutter-apps/issues/104
          playlistBloc.add(InitialPlaylistState());
          playlistTracksBloc.add(PlaylistTracksReset());
          playlistBloc.add(InitialPlaylistState());
          searchBloc.add(ResetSearch());
          signupCubit.reset();
          trackBloc.add(TrackReset());
          userBloc.add(
              InitialState()); // you need to wipe out the user in the player bloc
          usernameCubit.reset();

          if (Core.app.type == AppType.advanced) {
            marketBloc.add(InitialMarketState());
            artistBloc.add(const ArtistReset());
            settingsBloc.add(const SettingsReset());
            searchUserCubit.reset();
          }

          // If the user is authenticated, do the necessary actions
          if (state.status == AuthStatus.authenticated &&
              metaDataCubit.state is! MetaDataLoaded) {
            logger.i(
                'getMetaData because user is authenticated and metaDataCubit.state not already loaded');
            metaDataCubit.getMetaData();
          }
        },
      ),
      BlocListener<DownloadBloc, DownloadState>(
        listener: (context, state) {
          // final status = state.playlistDownloadStatus.values.first;
          final trackBloc = context.read<TrackBloc>();

          final statuses = state.playlistDownloadStatus.values.toList();

          // updating individual playlists
          for (final playlistDownloadStatus in statuses) {
            // logger.i(playlistDownloadStatus);
            if (playlistDownloadStatus == DownloadStatus.undownloaded) {
              trackBloc
                  .add(UpdateTracks(updatedTracks: state.tracksToUnDownload));
              break;
            }
            if (playlistDownloadStatus == DownloadStatus.downloaded ||
                playlistDownloadStatus == DownloadStatus.completed) {
              trackBloc.add(
                UpdateTracks(
                  updatedTracks: state.downloadedTracks.values.toList(),
                ),
              );
              break;
            }
          }

          // Updating all playlists when synced
          if (state.status == DownloadStatus.syncingDownloadsCompleted) {
            trackBloc.add(
              UpdateTracks(
                  updatedTracks: state.downloadedTracks.values.toList()),
            );
          }

          // /// There is a different status for each playlist.
          // /// This is a profligate solution but let's not bother to access the state
          // /// and instead update trackBloc.allTracks whenever
          // /// the DownloadBloc state changes.
          // final List<Track> tracksToDownload =
          //     state.downloadedTracks.values.toList();
          // final List<Track> tracksToUnDownload = state.tracksToUnDownload;

          // final List<Track> tracksToUpdate = [
          //   ...tracksToDownload,
          //   ...tracksToUnDownload
          // ];

          // // Dispatch the UpdateTracks event if there are tracksToUpdate
          // if (tracksToUpdate.isNotEmpty) {
          //   trackBloc.add(UpdateTracks(updatedTracks: tracksToUpdate));
          // }
        },
      ),
      BlocListener<LibraryBloc, LibraryState>(listener: (context, state) {
        final playlistBloc = context.read<PlaylistBloc>();
        final userBloc = context.read<UserBloc>();

        if (state.status == LibraryStatus.playlistAddedToLibrary ||
            state.status == LibraryStatus.playlistCreated) {
          playlistBloc.add(PlaylistCreated(
            playlist: state.playlistJustCreated!,
          ));
          userBloc.add(
            NewPlaylistCreated(
              playlist: state.playlistJustCreated!,
              lastPlaylistNumber: state.lastPlaylistNumber,
            ),
          );
          // final playlistId = state.playlistJustCreated!.id;
          // logger.f(playlistId);
          // GoRouter.of(context).push('/playlist/$playlistId');
          playlistBloc.add(
            SetViewedPlaylist(playlist: state.playlistJustCreated!),
          );
        } else if (state.status == LibraryStatus.playlistRemoved) {
          playlistBloc.add(PlaylistUnfollowed(
            playlist: state.playlistToRemove!,
          ));
        }
      }),
      BlocListener<MarketBloc, MarketState>(listener: (context, state) {
        if (Core.app.type == AppType.basic) return;
        logger.i('MarketBloc listener called');
        if (state.status == MarketStatus.bundlePurchased) {
          logger.i('getMetaData because bundle purchased');
          final metaDataCubit = context.read<MetaDataCubit>();
          metaDataCubit.getMetaData();
        }
      }),
      BlocListener<MetaDataCubit, MetaDataState>(
          listenWhen: (previous, current) =>
              previous is MetaDataLoading && current is MetaDataLoaded,
          listener: (context, state) {
            // Purchase is already added to Firebase before this point
            logger
                .i('MetaDataCubit listener called with ${state.runtimeType}!');
            final marketBloc = context.read<MarketBloc>();
            if (state is MetaDataLoaded) {
              final userBloc = context.read<UserBloc>();
              if (userBloc.state.status == UserStatus.initial ||
                  marketBloc.state.status == MarketStatus.bundlePurchased) {
                logger.i(
                    'loadUser with clearCache: ${marketBloc.state.status == MarketStatus.bundlePurchased}}');
                userBloc.add(
                  LoadUser(
                      clearCache: marketBloc.state.status ==
                          MarketStatus.bundlePurchased,
                      serverRatingsUpdated:
                          state.serverTimestamps['ratings2']!),
                );
              }
            }
          }),
      BlocListener<PlaylistBloc, PlaylistState>(
        listener: (context, state) {
          // logger.i('PlaylistBloc listener called with ${state.status}');
          final trackBloc = context.read<TrackBloc>();
          final playlistBloc = context.read<PlaylistBloc>();
          final userBloc = context.read<UserBloc>();
          final user = context.read<UserBloc>().state.user;
          if (state.status == PlaylistStatus.playlistsUpdated) {
            logger.i('loadAllPlaylists!');
            playlistBloc.add(LoadAllPlaylists(
              userId: user.id,
              serverPlaylistsUpdated:
                  (context.read<MetaDataCubit>().state as MetaDataLoaded)
                      .serverTimestamps['playlists'],
            ));
          } else if (state.status == PlaylistStatus.playlistsLoaded) {
            logger.i('loadFollowedPlaylists!');
            playlistBloc.add(LoadFollowedPlaylists(user: user));
            // logger.i('Load4And5StarPlaylists!');

            playlistBloc.add(LoadLikedSongsPlaylist(
              user: user,
              ratings: userBloc.state.ratings,
            ));
            // var tracks;
            // if (Core.app.type == AppType.basic) {
            final tracks = trackBloc.state.allTracks
                .where((element) => element.available == true)
                .toList();
            // }

            // playlistBloc.add(Load4And5StarPlaylists(
            //   user: user,
            //   ratings: userBloc.state.ratings,
            //   tracks: tracks,
            // ));

            // playlistBloc.add(LoadAllSongsPlaylist(
            //   user: user,
            //   ratings: userBloc.state.ratings,
            //   tracks: tracks,
            //   // tracks: tracks,
            // ));

            if (Core.app.type == AppType.basic) {
              playlistBloc.add(LoadUnratedPlaylist(
                user: user,
                ratings: userBloc.state.ratings,
                tracks: tracks,
              ));
            }

            if (Core.app.type == AppType.advanced &&
                playlistBloc.state.newReleasesPlaylist.id == '1') {
              logger.i('loadNewReleasesPlaylist!');
              playlistBloc.add(LoadNewReleasesPlaylist());
            }
          } else if (state.status == PlaylistStatus.foundBadPlaylistIds) {
            userBloc.add(BadUserPlaylistIdsFound(
              badPlaylistIds: state.badPlaylistIds!,
            ));
          } else if (state.status == PlaylistStatus.unratedPlaylistLoaded &&
              playlistBloc.state.viewedPlaylist?.id ==
                  playlistBloc.state.unratedPlaylist.id) {
            trackBloc.add(LoadDisplayedTracks(
              playlist: playlistBloc.state.unratedPlaylist,
            ));
          }

          /// Handle in [PlaylistTile] etc
          // else if (state.status == PlaylistStatus.followedPlaylistsLoaded) {
          //   // logger.i('SetViewedPlaylist!');
          //   // final playlist = getPlaylistFromPassedUrl(playlistBloc, user);
          //   // logger.d(playlist.name);
          //   // playlistBloc.add(SetViewedPlaylist(
          //   //   playlist: playlist,
          //   // ));
          // }
          else if ((state.status == PlaylistStatus.viewedPlaylistLoaded
              // ||
              //         state.status == PlaylistStatus.playlistsUpdated ||
              //         state.status == PlaylistStatus.playlistsRemoved
              // ||
              // state.status == PlaylistStatus.fourAndFiveStarPlaylistsLoaded
              )) {
            if (trackBloc.state.allTracks.isEmpty) {
              logger.e('allTracks is empty!');
              return;
            }
            logger.i(
                'LoadDisplayedTracks for playlist: ${state.viewedPlaylist!.name}');
            trackBloc.add(LoadDisplayedTracks(
              playlist: playlistBloc.state.viewedPlaylist!,
            ));
          }
          // // User just rated a track within the 4 or 5 star playlist so
          // // we need to reload the tracks in the playlist
          // else if (state.status ==
          //         PlaylistStatus.fourAndFiveStarPlaylistsLoaded &&
          //     state.viewedPlaylist?.id?.contains(user.id) == true) {
          //   if (state.viewedPlaylist?.id?.contains('_5star') == true) {
          //     trackBloc.add(LoadDisplayedTracks(
          //         playlist: playlistBloc.state.fiveStarPlaylist));
          //   } else if (state.viewedPlaylist?.id?.contains('_4star') == true) {
          //     trackBloc.add(LoadDisplayedTracks(
          //         playlist: playlistBloc.state.fourStarPlaylist));
          //   }
          // }
          // // User just rated a track within the 4 or 5 star playlist so
          // // we need to reload the tracks in the playlist
          // else if (state.status == PlaylistStatus.allSongsPlaylistLoaded &&
          //     state.viewedPlaylist?.id?.contains(user.id) == true) {
          //   trackBloc.add(LoadDisplayedTracks(
          //       playlist: playlistBloc.state.allSongsPlaylist));
          // }
        },
      ),
      BlocListener<PlaylistInfoBloc, PlaylistInfoState>(
        listenWhen: (previous, current) =>
            previous.status !=
            current.status, // Only listen when the status changes
        listener: (context, state) {
          if (Core.app.type == AppType.basic) return;
          logger.i(
              'MYAPP PlaylistInfoBloc: listener called with ${state.status}!');
          final playlistBloc = context.read<PlaylistBloc>();
          final playlistInfoBloc = context.read<PlaylistInfoBloc>();
          if (state.status == PlaylistInfoStatus.updated) {
            logger.i('PlaylistUpdated!');
            playlistBloc.add(PlaylistUpdated(
              playlist: playlistInfoBloc.state.updatedPlaylist!,
            ));
          }
        },
      ),
      BlocListener<PlaylistTracksBloc, PlaylistTracksState>(
        listener: (context, state) {
          final playlistBloc = context.read<PlaylistBloc>();

          if (state.status == PlaylistTracksStatus.updated) {
            playlistBloc.add(PlaylistUpdated(playlist: state.updatedPlaylist!));

            logger.i(
                'SetViewedPlaylist for playlist: ${playlistBloc.state.viewedPlaylist!.name}');
            playlistBloc.add(
              SetViewedPlaylist(playlist: playlistBloc.state.viewedPlaylist!),
            );
          }
        },
      ),
      BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state.status == SettingsStatus.accountDeleted) {
            // Set the metadata to initial so that the user is logged out
            context.read<MetaDataCubit>().reset();
          }
        },
      ),
      BlocListener<TrackBloc, TrackState>(
        listener: (context, state) {
          // logger.i('TrackBloc listener called with ${state.status}');
          final downloadBloc = context.read<DownloadBloc>();
          final playerBloc = context.read<PlayerBloc>();
          // final playlistBloc = context.read<PlaylistBloc>();
          final trackBloc = context.read<TrackBloc>();
          final userBloc = context.read<UserBloc>();
          final user = userBloc.state.user;

          /// Problem is the user is not yet loaded with the ratings. So we need to wait for the user to be loaded before we can map the ratings to the tracks.

          if ((trackBloc.state.status == TrackStatus.allTracksLoaded &&
              userBloc.state.status == UserStatus.loaded)) {
            logger.i(
                'MapRatingsToTracks because trackBloc.state.status == ${trackBloc.state.status} and userBloc.state.status == ${userBloc.state.status}');
            final ratings = userBloc.state.ratings;

            /// So yes, this in here twice, because there are 2 possible flows:
            /// 1. The user is loaded before the tracks
            /// 2. The tracks are loaded before the user
            trackBloc.add(
              MapRatingsToTracks(trackBloc.state.allTracks, ratings),
            );

            // if (Core.app.type == AppType.basic) {
            if (downloadBloc.state.status == DownloadStatus.initial) {
              downloadBloc.add(
                SyncDownloadsWithAllTracks(
                  tracksToDownload: trackBloc.state.allTracks,
                  userId: user.id,
                ),
              );
              // }
            }
          } else if ((state.status == TrackStatus.ratingsMapped &&
                  userBloc.state.status != UserStatus.updatedRating)
              // &&

              // /// If the user is loading a playlist from the url, then do not proceed
              // playlistBloc.state.playlistIdPassedToUrl == null
              ) {
            final playlistBloc = context.read<PlaylistBloc>();
            if (playlistBloc.state.status == PlaylistStatus.initial) {
              final metaDataLoaded =
                  context.read<MetaDataCubit>().state as MetaDataLoaded;

              logger.i('loadAllPlaylists!');
              playlistBloc.add(LoadAllPlaylists(
                userId: user.id,
                serverPlaylistsUpdated:
                    metaDataLoaded.serverTimestamps['playlists'],
              ));
            }

            // if (Core.app.type == AppType.basic) {
            //   final tracks = trackBloc.state.allTracks;
            //   final ratings = userBloc.state.ratings;
            //   playlistBloc.add(
            //     LoadUnratedPlaylist(
            //         user: user, ratings: ratings, tracks: tracks),
            //   );
            // }

            final track = getInitialTrack(trackBloc, user);
            logger.i('SetDisplayedTracksWithTracks');
            if (track != null) {
              trackBloc.add(SetDisplayedTracksWithTracks(tracks: [track]));
              logger.i('LoadPlayer!');
              playerBloc.add(
                LoadPlayer([track]),
              );
            }
          }
        },
      ),
      BlocListener<UserBloc, UserState>(
        /// Had to turn this off because it was preventing ratings mapping in Rivify
        listenWhen: (previous, current) =>
            previous.status !=
            current.status, // Only listen when the status changes
        listener: (context, state) {
          logger.i('MYAPP UserBloc: listener called with ${state.status}!');
          final marketBloc = context.read<MarketBloc>();
          final metaDataCubit = context.read<MetaDataCubit>();
          final playlistBloc = context.read<PlaylistBloc>();
          final settingsBloc = context.read<SettingsBloc>();
          final userBloc = context.read<UserBloc>();
          final user = userBloc.state.user;

          if (state.status == UserStatus.loaded) {
            settingsBloc.add(
              LoadSettings(user: user),
            ); // moved this up out of the block below

            /// I'm trying to move loadalltracks down here so I have access to the user.
            final trackBloc = context.read<TrackBloc>();
            final serverUpdated = (metaDataCubit.state as MetaDataLoaded)
                .serverTimestamps['tracks']!;
            trackBloc.add(
              LoadAllTracks(
                serverUpdated: serverUpdated,
                clearCache:
                    (marketBloc.state.status == MarketStatus.bundlePurchased),
                user: user,
              ),
            );

            // if (trackBloc.state.status == TrackStatus.allTracksLoaded) {
            //   logger.i('MapRatingsToTracks!');

            //   final ratings = userBloc.state.ratings;

            //   /// So yes, this in here twice, because there are 2 possible flows:
            //   /// 1. The user is loaded after the tracks
            //   /// 2. The tracks are loaded after the user
            //   trackBloc.add(
            //     MapRatingsToTracks(trackBloc.state.allTracks, ratings),
            //   );
            // }
            // if (playlistBloc.state.status == PlaylistStatus.initial) {
            //   final metaDataLoaded = metaDataCubit.state as MetaDataLoaded;
            //   logger.i('loadAllPlaylists!');
            //   playlistBloc.add(LoadAllPlaylists(
            //     userId: user.id,
            //     serverPlaylistsUpdated:
            //         metaDataLoaded.serverTimestamps['playlists'],
            //   ));
            // }
            if (Core.app.type == AppType.advanced) {
              // logger.i('loadMarket!');
              final marketBloc = context.read<MarketBloc>();
              final metaDataLoaded = metaDataCubit.state as MetaDataLoaded;
              marketBloc.add(LoadMarket(
                  user: user,
                  serverTimestamp:
                      metaDataLoaded.serverTimestamps['bundles']!));
            }
          }
          // User rated a track so we need to update the ratings in the trackBloc
          // and then reload the tracks in the playlist
          else if (state.status == UserStatus.updatedRating) {
            final trackBloc = context.read<TrackBloc>();
            final ratings = userBloc.state.ratings;
            logger.i('MapRatingsToTracks!');
            trackBloc.add(
              MapRatingsToTracks(trackBloc.state.allTracks, ratings),
            );
            playlistBloc.add(LoadUnratedPlaylist(
              user: user,
              ratings: ratings,
              tracks: trackBloc.state.allTracks,
            ));

            // playlistBloc.add(Load4And5StarPlaylists(
            //     user: user, ratings: ratings, tracks: tracks));
            // playlistBloc.add(LoadAllSongsPlaylist(
            //   user: user,
            //   ratings: ratings,
            //   tracks: tracks,
            // ));
            // playlistBloc.add(
            //     PlaylistUpdated(playlist: playlistBloc.state.viewedPlaylist!));
          }
        },
      ),
    ];

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserData(),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
      ],
      child: MultiRepositoryProvider(
        providers: myRepositoryProviders,
        child: MultiBlocProvider(
          providers: myBlocProviders,
          child: MultiBlocListener(
            listeners: myBlocListeners,
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                // BlocBuilder is now delimited to just build the UI according to the auth state
                if (state.status == AuthStatus.unknown) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (Core.app.type == AppType.basic) {
                  context.read<NavCubit>().updateIndex(2);
                }

                return MaterialApp.router(
                  routerConfig: router,
                  title: Core.app.name,
                  debugShowCheckedModeBanner: false,
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                  locale: context.locale,
                  theme: BoxifyTheme.buildTheme(),
                  builder: (context, child) {
                    return UpgradeAlert(
                      navigatorKey: router.routerDelegate.navigatorKey,
                      child: child,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
