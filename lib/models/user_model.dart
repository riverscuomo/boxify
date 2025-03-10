import 'package:boxify/app_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

// import 'package:app_core/app_core.dart';  //

class User extends Equatable {
  final String id;
  final String username;
  final String email;
  final bool isAnonymous;
  final String profileImageUrl;
  final String bio;
  final String discordId;
  final Timestamp?
      registeredOn; // set in onSignUp. DISPLAY ON PROFILE AND USED FOR OG BADGE/ROLE? discordbot: add_og_role_from_firestore_user.
  final Timestamp? lastSeen;
  int lastPlaylistNumber;
  final bool admin;
  final bool banned;
  final String imageFile;
  final List<String> bundleIds;
  final List<String> bundleDirectories;
  final List<String> playlistIds;
  final List<dynamic> badges;
  final List<dynamic> purchases;

  /// The roles array determines what tracks a user can access in the basic app type.
  /// (Note: Roles are not used in the advanced app type)
  ///
  /// Role-based access is implemented entirely through Firestore:
  /// 1. Users have a roles array in their Firestore document
  /// 2. Tracks have a role field in their Firestore document
  /// 3. Users can only access tracks where the track's role matches one of their roles
  /// 4. If a user has no roles, they cannot access any tracks
  final List<String>? roles;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.isAnonymous,
    required this.profileImageUrl,
    required this.bio,
    required this.discordId,
    required this.registeredOn,
    required this.lastSeen,
    required this.admin,
    required this.banned,
    required this.imageFile,
    required this.bundleIds,
    required this.bundleDirectories,
    required this.playlistIds,
    required this.badges,
    required this.purchases,
    required this.lastPlaylistNumber,
    required this.roles,
  });

  static User empty = User(
    id: '',
    username: 'Lurker',
    email: '',
    isAnonymous: true,
    profileImageUrl: Core.app.riversPicUrl,
    bio:
        "You take your car to work, I'll take my board. And when you're out of fuel, I'm still afloat.",
    discordId: '',
    registeredOn: null,
    lastSeen: null,
    admin: false,
    banned: false,
    imageFile: '',
    bundleIds: [], // const [Core.app.byThePeopleBundleId],
    bundleDirectories: const [],
    playlistIds: Core.app.defaultPlaylistIds,
    badges: const [],
    purchases: const [],
    lastPlaylistNumber: 0,
    roles: const [],
  );

  @override
  List<Object> get props => [
        id,
        username,
        email,
        isAnonymous,
        admin,
        discordId,
        banned,
        imageFile,
        bundleIds,
        bundleDirectories,
        playlistIds,
        badges,
        purchases,
        lastPlaylistNumber,
      ];

  @override
  User copyWith({
    int? lastPlaylistNumber,
    String? id,
    String? username,
    bool? isAnonymous,
    String? email,
    String? profileImageUrl,
    String? bio,
    String? discordId,
    Timestamp? registeredOn,
    Timestamp? lastSeen,
    bool? admin,
    bool? banned,
    double? negativityThreshold,
    String? imageFile,
    List<String>? bundleIds,
    List<String>? bundleDirectories,
    List<String>? playlistIds,
    List<dynamic>? badges,
    List<dynamic>? purchases,
    List<String>? roles,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      discordId: discordId ?? this.discordId,
      registeredOn: registeredOn ?? this.registeredOn,
      lastSeen: lastSeen ?? this.lastSeen,
      admin: admin ?? this.admin,
      banned: banned ?? this.banned,
      imageFile: imageFile ?? this.imageFile,
      // bundleIds: this.bundleIds + [Core.app.byThePeopleBundleId],
      // bundleDirectories: this.bundleDirectories,
      // playlistIds: this.playlistIds,
      bundleIds: bundleIds ?? this.bundleIds,
      bundleDirectories: bundleDirectories ?? this.bundleDirectories,
      playlistIds: playlistIds ?? this.playlistIds,
      badges: badges ?? this.badges,
      purchases: purchases ?? this.purchases,
      lastPlaylistNumber: lastPlaylistNumber ?? this.lastPlaylistNumber,
      roles: roles ?? this.roles,
    );
  }

  Map<String, dynamic> toDocument() {
    return {
      'username': username,
      'email': email,
      'isAnonymous': email == '',
      // 'emailVerified': emailVerified,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'discordId': discordId,
      'registeredOn': registeredOn,
      // 'lastSignInTimeStamp': lastSignInTimeStamp,
      'lastSeen': lastSeen,
      'admin': admin,
      'banned': banned,
      'imageFile': imageFile,
      'bundleIds': bundleIds,
      'playlistIds': playlistIds,
      'badges': badges,
      'lastPlaylistNumber': lastPlaylistNumber,
      'roles': roles,
    };
  }

  factory User.fromDocument(DocumentSnapshot doc) {
    // logger.i('User.fromDocument');
    final s = Stopwatch()..start();
    final data = doc.data()! as Map;
    // logger.i(doc.id.toString() + data['bundleIds'].toString());
    final bundleIds = Utils.convertDynamicsToStrings(data['bundleIds']) +
        [Core.app.byThePeopleBundleId];
    final badges = Utils.convertDynamicsToStrings(data['badges'] ?? []);
    final playlistIds =
        Utils.convertDynamicsToStrings(data['playlistIds'] ?? []);
    final purchases = Utils.convertDynamicsToStrings(data['purchases'] ?? []);
    final bundleDirectories = _getBundleDirectories(bundleIds);
    logDuration(s, 0, 'User.fromDocument');
    return User(
      id: doc.id,
      username: data['username'].toString(),
      email: data['email'].toString(),
      isAnonymous: data['email'].toString() == '',
      profileImageUrl: data.containsKey('profileImageUrl') &&
              data['profileImageUrl'] != null &&
              data['profileImageUrl'].isNotEmpty
          ? Utils.sanitizeUrl(data['profileImageUrl'])
          : Core.app.riversPicUrl,
      bio: data['bio'] ?? '',
      discordId: data['discordId'] ?? '',
      registeredOn: data['registeredOn'] ?? Timestamp.fromDate(DateTime.now()),
      lastSeen: Timestamp.fromDate(DateTime.now()),
      admin: data['admin'] ?? false,
      banned: data['banned'] ?? false,
      imageFile: data['image_file'] ?? Core.app.riversPicUrl,
      bundleIds: bundleIds,
      bundleDirectories: bundleDirectories,
      playlistIds: playlistIds,
      badges: badges, //?? [],
      purchases: purchases, //?? [],
      lastPlaylistNumber: data['lastPlaylistNumber'] ?? 0,
      roles: Utils.convertDynamicsToStrings(data['roles'] ?? []),
    );
  }

  // ahh, this is for getting it from the flask server
  // Why were most of these missing?
  // static User fromJson(data) {
  //   return User.empty.copyWith(
  //     id: data['id'],
  //     username: data['username'],
  //     // email: data['email'],
  //     profileImageUrl: data['profileImageUrl'] ?? Core.app.riversPicUrl,
  //     // discordId: data['discordId'],
  //     // registeredOn: data['registeredOn'],
  //     // banned: data['banned'] ?? false,
  //     // bundleIds: data['bundleIds'],
  //     // badges: data['badges'] ?? [],
  //   );
  // }
  static User fromJson(Map<String, dynamic> data) {
    final bundleIds = Utils.convertDynamicsToStrings(data['bundleIds']) +
        [Core.app.byThePeopleBundleId];
    final badges = Utils.convertDynamicsToStrings(data['badges'] ?? []);
    final playlistIds =
        Utils.convertDynamicsToStrings(data['playlistIds'] ?? []);
    final purchases = Utils.convertDynamicsToStrings(data['purchases'] ?? []);
    final bundleDirectories = _getBundleDirectories(bundleIds);
    final registeredOn = _getRegisteredOn(data);
    return User(
      id: data['id'],
      username: data['username'].toString(),
      email: data['email'].toString(),
      isAnonymous: data['email'].toString() == '',
      profileImageUrl: data.containsKey('profileImageUrl') &&
              data['profileImageUrl'] != null &&
              data['profileImageUrl'].isNotEmpty
          ? Utils.sanitizeUrl(data['profileImageUrl'])
          : Core.app.riversPicUrl,
      bio: data['bio'] ?? '',
      discordId: data['discordId'] ?? '',
      registeredOn: registeredOn,
      lastSeen: Timestamp.fromDate(DateTime.now()),
      admin: data['admin'] ?? false,
      banned: data['banned'] ?? false,
      imageFile: data['image_file'] ?? Core.app.riversPicUrl,
      bundleIds: bundleIds,
      bundleDirectories: bundleDirectories,
      playlistIds: playlistIds,
      badges: badges, //?? [],
      purchases: purchases, //?? [],
      lastPlaylistNumber: data['lastPlaylistNumber'] ?? 1,
      roles: Utils.convertDynamicsToStrings(data['roles'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    // logger.i('iUser.toJson');
    // logger.i('iid: $id');
    // logger.i('iusername: $username');
    // logger.i('iemail: $email');

    // logger.i('iprofileImageUrl: $profileImageUrl');
    // logger.i('ibio: $bio');
    // logger.i('idiscordId: $discordId');
    // logger.i('iregisteredOn: $registeredOn');
    // logger.i('ilastSeen: $lastSeen');
    // logger.i('iadmin: $admin');
    // logger.i('ibanned: $banned');
    // logger.i('iimageFile: $imageFile');
    // logger.i('ibundleIds: $bundleIds');
    // logger.i('ibundleDirectories: $bundleDirectories');
    // logger.i('iplaylistIds: $playlistIds');
    // logger.i('ibadges: $badges');
    // logger.i('ipurchases: $purchases');
    // logger.i('ilastPlaylistNumber: $lastPlaylistNumber');

    final json = <String, dynamic>{
      'id': id,
      'username': username,
      'email': email,
      'isAnonymous': isAnonymous,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'discordId': discordId,
      'registeredOn': registeredOn?.millisecondsSinceEpoch,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'admin': admin,
      'banned': banned,
      'imageFile': imageFile,
      'bundleIds': bundleIds,
      'bundleDirectories': bundleDirectories,
      'playlistIds': playlistIds,
      'badges': badges,
      'purchases': purchases,
      'lastPlaylistNumber': lastPlaylistNumber,
      'roles': roles,
    };
    // logger.i('ijson: $json');

    return json;
  }
}

List<String> _getBundleDirectories(List<String> bundleIds) {
  // logger.i('getBundleDirectories');

  // Make a list of all the bundles owned by this user
  // List<dynamic> bundleIds = data['bundleIds'];
  // logger.i(bundleIds);

  // STarting with by the people
  final bundleDirectories = <String>[
    'By The People',
  ];
  // Convert each bundle id to a string title
  // because that's how they're stored in the demo docs.
  for (final x in bundleIds) {
    if (x == '30') {
      // logger.i('match');
      bundleDirectories.add('The White Years');
    }
    if (x == '34') {
      // logger.i('match');
      bundleDirectories.add('EWBAITE');
    }
    if (x == '35') {
      // logger.i('match');
      bundleDirectories.add('Pre-Weezer');
    }
    if (x == '36') {
      // logger.i('match');
      bundleDirectories.add('The Blue-Pinkerton Years');
    }
    if (x == '37') {
      // logger.i('match');
      bundleDirectories.add('The Black Room');
    }
    if (x == '38') {
      // logger.i('match');
      bundleDirectories.add('The Green Years');
    }
    if (x == '42') {
      // logger.i('match');
      bundleDirectories.add('The Make Believe Years');
    }
    if (x == '40') {
      // logger.i('match');
      bundleDirectories.add('The Red-Raditude-Hurley Years');
    }
    if (x == '39') {
      // logger.i('match');
      bundleDirectories.add('The Maladroit Years');
    }

    // if (x == '43') {
    //   // logger.i('match');
    //   bundleDirectories.add('The Best Of The Demos');
    // }
  }

  // logger.i(bundleDirectories);
  return bundleDirectories;
}

/// Returns a `Timestamp` object based on the `registeredOn` field in the given `data` map.
/// If the `registeredOn` field is not present in the map, returns the current timestamp.
///
/// The `registeredOn` field can be either a `String` (in the format "EEE, dd MMM yyyy HH:mm:ss 'GMT'")
/// or an `int` (in milliseconds since epoch).
///
/// @param data The input map containing the `registeredOn` field.
/// @return A `Timestamp` object representing the `registeredOn` date-time, or the current timestamp if `registeredOn` is not present.
Timestamp? _getRegisteredOn(Map<String, dynamic> data) {
  // Check if the 'registeredOn' field is present in the input data
  if (data.containsKey('registeredOn')) {
    // If the 'registeredOn' field is a String, parse it with the given format
    if (data['registeredOn'] is String) {
      final dateFormat = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'");
      return Timestamp.fromDate(dateFormat.parse(data['registeredOn']));
    }
    // If the 'registeredOn' field is an int, treat it as milliseconds since epoch
    else if (data['registeredOn'] is int) {
      return Timestamp.fromMillisecondsSinceEpoch(data['registeredOn']);
    }
  }

  // If the 'registeredOn' field is not present or its type is not supported, return the current timestamp
  return Timestamp.fromDate(DateTime.now());
}
