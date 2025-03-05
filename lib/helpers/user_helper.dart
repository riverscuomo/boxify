import 'package:boxify/app_core.dart';
import 'package:boxify/widgets/login_required_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class UserHelper {
  UserHelper();

  /// Returns true if the user is logged in, or prompts the user to log in if not (and returns false).
  /// The action name passed as a parameter is displayed in the dialog (e.g. 'rate tracks', 'create playlists', etc..).
  static bool isLoggedInOrReroute(
      UserState userState, BuildContext context, String action, IconData icon,
      {bool useRootNavigator = true}) {
    // Is the user logged in?
    if (userState.user.isAnonymous) {
      // Show 'you must be logged in' dialog
      showDialog(
        context: context,
        useRootNavigator: useRootNavigator,
        builder: (BuildContext context) {
          return LoginRequiredDialog(
            icon: icon,
            action: action,
            onLogin: () {
              // User has chosen to log in/sign up
              // Reroute to the login screen.
              GoRouter.of(context).go('/login');

              /// If you don't log out first, the authStatus will never be unauthenticated
              /// and the resetting of the blocs will never be triggered in the myapp.authBloc listener
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            onDismiss: () {
              // User dismissed the dialog (clicked 'NOT NOW')
              Navigator.of(context).pop();
            },
          );
        },
      );

      return false;
    }
    return true;
  }

  /// Returns [bundleCount, trackCount, userBundleCount, userTrackCount]
  /// to display the counts at the top of the Market screen.
  List<int> calculateCounts(User user, List<Bundle> allBundles) {
    final bundleCount = allBundles.length;
    var trackCount = 0;
    var userTrackCount = 0;
    for (final bundle in allBundles) {
      trackCount += bundle.count!;
      if (user.bundleIds.contains(bundle.id)) {
        userTrackCount += bundle.count!;
      }
    }
    final userBundleCount = user.bundleIds
        .where((element) => !Core.app.badBundleIds.contains(element))
        .toList()
        .length;
    return [bundleCount, trackCount, userBundleCount, userTrackCount];
  }

  /// Returns true if the user is authenticated and email is verified and
  /// the user's username is not set, it still has the default value of 'Lurker'.
  bool settingUsername(AuthState state, User user) {
    final settingUsername = state.user?.email != null &&
        state.user?.emailVerified == true &&
        user.username == 'Lurker';
    return settingUsername;
  }

  /// Returns true if the user is authenticated and email is not verified.
  bool verifyingEmail(AuthState state) =>
      state.user?.email != null && state.user?.emailVerified == false;
}
