import 'package:boxify/app_core.dart';
import 'package:boxify/services/bundles_manager.dart';
import 'package:flutter/material.dart';

const fireUrl = "https://www.dropbox.com/s/wfycymz8txb9zcp/fire.jpg?raw=1";
const summerUrl = fireUrl;
const ramsayUrl =
    "https://www.dropbox.com/s/4labks7ga1ymswb/494px-Hugh_Ramsay_-_The_four_seasons_-_Google_Art_Project.jpg?raw=1";
const springUrl = 'https://www.dropbox.com/s/ncahf99tx3fn5ud/unnamed.jpg?raw=1';
const autumDancersUrls =
    'https://www.dropbox.com/s/j0igjm7f6negshq/Evgh_WaWgAAYYqt.jpg?raw=1';
const autumnUrl = 'https://www.dropbox.com/s/dzxu01syuvhbk1y/autumn.jpg?raw=1';
const winterUrl =
    'https://www.dropbox.com/s/zwvi42bhcjx08gr/saint-man-white-robe-looking-sadly-camera-upset-humanity-mistakes-saint-man-white-robe-looking-sadly-camera-upset-157312502.jpg?raw=1';

Image rcImage =
    Image.asset('images/boxify.jpg', height: 60, width: 60, fit: BoxFit.cover);
Image rcImage132 = Image.asset(
  'images/boxify.png',
  height: 132,
  width: 132,
  fit: BoxFit.cover,
);

Image funkoImage =
    Image.asset('images/funko.jpg', height: 60, width: 60, fit: BoxFit.cover);

/// Returns the imageFilename for the track from the playlist if any.
///
/// If the track doesn't have an imageFilename, and the playlist image isn't the placeholder image,
/// then use the playlist imageFilename.
/// For By The People playlist, never use the playlist image because we want to use the
/// individual track images instead. They have the user's profileImageUrl.
String? assignPlaylistImageFilenameToTrack(Track track, Playlist? playlist) {
  if (playlist == null) {
    return null;
  }
  if (playlist.id == Core.app.byThePeoplePlaylistId ||
      playlist.id == Core.app.newReleasesPlaylistId) {
    return null;
  }
  if (track.imageFilename != null &&
      track.imageFilename != '' &&
      track.imageFilename != Core.app.placeHolderImageFilename) {
    return track.imageFilename;
  } else if (playlist.imageFilename != null &&
      playlist.imageFilename != '' &&
      playlist.imageFilename != Core.app.placeHolderImageFilename) {
    return playlist.imageFilename;
  } else {
    return null;
  }
}

/// Returns the imageUrl for the track from the playlist if any.
///
/// If the track doesn't have an imageUrl, and the playlist image isn't the placeholder image,
/// then use the playlist imageUrl.
/// For By The People playlist, never use the playlist image because we want to use the
/// individual track images instead. They have the user's profileImageUrl.
String? assignPlaylistImageUrlToTrack(Track track, Playlist? playlist) {
  if (track.imageUrl != null &&
      track.imageUrl != '' &&
      track.imageUrl != Core.app.defaultImageUrl) {
    return track.imageUrl;
  } else if (playlist == null) {
    // Track doesn't have an image and isn't in a playlist
    // Try returning bundle image
    return assignBundleImageUrlToTrack(track);
  } else if (playlist.imageUrl != null &&
      playlist.imageUrl != '' &&
      playlist.imageUrl != Core.app.defaultImageUrl) {
    return playlist.imageUrl;
  } else {
    // Track is in a playlist but doesn't have an image
    // Try returning bundle image
    return assignBundleImageUrlToTrack(track);
  }
}

/// Returns the imageUrl of the track's bundle.
///
/// If the track isn't part of a bundle or the bundle doesn't have any image, null will be returned.
String? assignBundleImageUrlToTrack(Track track) {
  final bundle = BundleManager().getBundle(track.bundleId);
  if (bundle == null || bundle.image == null) return null;
  return bundle.image;
}
