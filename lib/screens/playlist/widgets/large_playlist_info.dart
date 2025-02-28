import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:boxify/app_core.dart';
import 'song_count.dart';

class LargePlaylistInfo extends StatefulWidget {
  const LargePlaylistInfo({
    super.key,
  });

  @override
  _LargePlaylistInfoState createState() => _LargePlaylistInfoState();
}

class _LargePlaylistInfoState extends State<LargePlaylistInfo>
    with EditPlaylistMixin {
  Future<dynamic> _editDetails(Playlist playlist) {
    logger.i('playlist_Screen_editDetails');
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;
    const width = 540;
    const height = 400;
    double horizontalInset;
    double verticalInset;
    double editWidth;

    final state = context.read<PlaylistBloc>().state;
    final playlist = state.viewedPlaylist;

    if (deviceWidth > 1000) {
      horizontalInset = (deviceWidth - width) / 2;
      verticalInset = (deviceHeight - height) / 2;
      editWidth = 250.0;
    } else {
      horizontalInset = 0;
      verticalInset = 0;
      editWidth = (deviceWidth / 2) - 32;
    }

    titleController.text = playlist!.name!;
    descriptionController.text = playlist.description!;

    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        insetPadding: EdgeInsets.fromLTRB(
          horizontalInset,
          verticalInset,
          horizontalInset,
          verticalInset,
        ),
        title: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('editDetails'.translate()),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                ),
              ],
            )
          ],
        ),
        content: Row(
          children: [
            // PLAYLIST IMAGE
            BlocBuilder<PlaylistBloc, PlaylistState>(
              builder: (context, state) {
                return GestureDetector(
                  onTap: () => selectPlaylistImage(context),
                  child: Container(
                    height: 170,
                    width: 170,
                    color: Colors.grey[900],
                    child: imageForEditDetails(playlist),
                  ),
                );
              },
            ),
            // PLAYLIST NAME
            SizedBox(
              height: 170,
              width: editWidth,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: TextFormField(
                      // initialValue: titleController.text,
                      controller: titleController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white, // couldn't use Core in const
                            width: 2.0
                          ),
                        ),
                        // hintText: state.viewedPlaylist!.name,
                      ),
                    ),
                  ),
                  // PLAYLIST DESCRIPTION
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: TextFormField(
                      // initialValue: descriptionController.text,
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white, // couldn't use core in const
                            width: 2.0
                          ),
                        ),
                        hintText: 'Add an optional description',
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
        actions: <Widget>[
          Column(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100], // This is what you need!
                  textStyle: const TextStyle(color: Colors.black),
                ),
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'save'.translate(),
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                onPressed: () {
                  if (titleController.text == '') {
                    return;
                  }
                  kIsWeb
                      ? context.read<PlaylistInfoBloc>().add(
                            SubmitOnWeb(
                              playlist: playlist,
                              description: descriptionController.text,
                              name: titleController.text,
                              userId: context.read<UserBloc>().state.user.id,
                            ),
                          )
                      : context.read<PlaylistInfoBloc>().add(
                            Submit(
                              playlist: context
                                  .read<PlaylistBloc>()
                                  .state
                                  .viewedPlaylist!,
                              description: descriptionController.text,
                              name: titleController.text,
                              userId: context.read<UserBloc>().state.user.id,
                            ),
                          );
                  Navigator.of(context, rootNavigator: true).pop();
                },
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'byProceeding'.translate(),
                  style: TextStyle(fontSize: 11),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // logger.i('buildLargePlaylistInfo');
    var ownerName = '';
    var ownerImage = Core.app.funko;
    var ownerId = userIds['rivers'] ?? '8';

    bool isFollowing = true;

    String playlistString = 'PLAYLIST';
    final userBloc = context.read<UserBloc>();
    final playlistBloc = context.read<PlaylistBloc>();
    final trackBloc = context.read<TrackBloc>();
    final user = userBloc.state.user;
    final playlist = playlistBloc.state.viewedPlaylist ?? Playlist.empty;

    /// Special cases for Weezify which has a user in the PlayerState
    if (Core.app.type == AppType.advanced) {
      if (!user.playlistIds.contains(playlist.id)) {
        isFollowing = false;
      }

      if (user.admin && playlist.id != null) {
        playlistString = 'PLAYLIST: ${playlist.id!}';
      }

      if (playlist.owner != null && playlist.owner!.containsKey('username')) {
        ownerName = playlist.owner!['username'].toString();
      }
      if (playlist.owner != null &&
          playlist.owner!.containsKey('profileImageUrl')) {
        ownerImage = playlist.owner!['profileImageUrl'].toString();
      }
      if (playlist.owner != null && playlist.owner!.containsKey('id')) {
        ownerId = playlist.owner!['id'].toString();
      }
    }
    return GestureDetector(
      onTap: () {
        if (user.id == playlist.owner!['id']) _editDetails(playlist);
      },
      child: SizedBox(
        height: 320,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: 16),
            // IMAGE
            Container(
              decoration: boxDecorationBlack,
              child: AspectRatio(
                aspectRatio: 1,
                child: imageOrIcon(
                  imageUrl: playlist.imageUrl,
                  filename: playlist.imageFilename,
                  height: 200,
                  width: 200,
                ),
              ),
            ),
            SizedBox(width: 16),
            // INFO
            Expanded(
              flex: 2,
              child: Scrollbar(
                child: ListView(
                  children: [
                    SelectableText(
                      playlistString,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          playlist.displayTitle ??
                              playlist.name ??
                              'unnamedPlaylist'.translate(),
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge!
                              .copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                    // DESCRIPTION

                    MyLinkify(
                      text: playlist.description!,
                    ),
                    // OWNER ROW & Song count
                    FittedBox(
                      fit: BoxFit.none,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          if (Core.app.type == AppType.advanced)
                            PlaylistOwnerRow(
                              isFollowing: isFollowing,
                              followerCount: playlist.followerCount,
                              ownerImage: ownerImage,
                              ownerName: ownerName,
                              playlist: playlist,
                              userId: ownerId,
                            )
                          else
                            Container(),
                          if (trackBloc.state.displayedTracks.isNotEmpty)
                            SongCount()
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

