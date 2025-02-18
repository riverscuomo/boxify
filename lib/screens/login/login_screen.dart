import 'package:boxify/app_core.dart';
import 'package:boxify/cubits/login/login_state.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:boxify/services/google_sign_in_plugin.dart';
import 'package:easy_localization/easy_localization.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({
    super.key,
    this.playlistId,
    this.trackId,
  });
  final String? playlistId;
  final String? trackId;

  final GlobalKey<FormState> _loginformKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) async {
      logger.i('login.onCurrentUserChanged: $account');
      final isSignedIn = await googleSignIn.isSignedIn();
      if (!isSignedIn) {
        if (account != null) {
          await context.read<LoginCubit>().logInWithGoogle();
        }
      }
    });

    return WillPopScope(
      onWillPop: () async => false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: BlocConsumer<LoginCubit, LoginState>(
          listener: (context, state) async {
            final authUser = context.read<AuthBloc>().state.user;
            if (state.status == LoginStatus.success) {
              await _handleSuccessfulLogin(context, state, authUser!);
            } else if (state.status == LoginStatus.error) {
              logger
                  .d('login screen login cubit has detected LoginStatus.error');
              await _showErrorDialog(context, state.failure.message);
            }
          },
          builder: (context, state) {
            /// WTF is this doing here?
            // logger.i(state.status);
            // if (state.status == LoginStatus.submitting ||
            //     state.status == LoginStatus.success) {
            //   return const Center(
            //     child: CircularProgressIndicator(),
            //   );
            // }
            return Scaffold(
              resizeToAvoidBottomInset: false,
              body: SingleChildScrollView(
                child: Center(
                  child: Container(
                    constraints:
                        BoxConstraints(maxWidth: Core.app.signInBoxWidth),
                    child: Padding(
                      padding: edgeInsets24,
                      child: Card(
                        color: Core.appColor.panelColor,
                        child: Padding(
                          padding: edgeInsets24,
                          child: _buildLoginForm(context, state),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Handles the successful login flow.
  ///
  /// This method is called when the user has successfully logged in.
  /// It checks if the user is anonymous, has a verified email, or has a username.
  /// Based on these conditions, it navigates the user to the appropriate screen.
  ///
  /// [context] is the BuildContext used for navigation and accessing repositories.
  /// [state] is the current LoginState of the LoginCubit.
  /// [authUser] is the authenticated User object containing user details.
  Future<void> _handleSuccessfulLogin(
    BuildContext context,
    LoginState state,
    auth.User authUser,
  ) async {
    logger.d('login: _handleSuccessfulLogin');
    // logger.i(authUser);

    /// USER PRESSED 'Maybe Later'
    if (authUser.isAnonymous) {
      logger.i(
          'authUser pressed Maybe Later  and authUser.isAnonymouse so naving to home screen');
      context.read<LoginCubit>().reset();
      GoRouter.of(context).go('/');
    }

    /// USER PRESSED 'LOG IN'
    ///
    /// - EMAIL is already verified
    else if (authUser.emailVerified || Core.app.type == AppType.basic) {
      logger.i(
        'login: authUser.emailVerified so fetching user record to check their username',
      );
      final user = await context
          .read<UserRepository>()
          .getUserWithId(userId: authUser.uid);
      // logger.i('login: user fetched from firestore = $user');

      /// User still does not have a username or has the username 'Lurker'
      if (Core.app.type == AppType.advanced &&
          (user.username.isEmpty || user.username == 'Lurker')) {
        logger.i(
          'login: u.username.isEmpty or "Lurker" so naving to username screen',
        );
        GoRouter.of(context).go('/username');
      }

      /// USER IS a completed User, has a verified email and a valid username
      else {
        logger.i(
          'login: user is a completed user so naving to home screen',
        );
        context.read<LoginCubit>().reset();
        if (Core.app.type == AppType.advanced) {
          final artistBloc = context.read<ArtistBloc>();
          final userBloc = context.read<UserBloc>();
          artistBloc.add(
              LoadArtist(viewer: userBloc.state.user, userId: authUser.uid));
        }

        // If they entered a playlist into the URL bar
        if (playlistId != null) {
          logger.i(
            'login: now authenticated so pushing to player with playlistId $playlistId',
          );

          GoRouter.of(context).push('/playlist/$playlistId');

          context.read<LoginCubit>().reset();
        }
        // If they entered a track into the URL bar
        else if (trackId != null) {
          logger.i(
            'login: now authenticated so pushing to player with playlistId $trackId',
          );
          GoRouter.of(context).go('/track/$trackId');
          context.read<LoginCubit>().reset();
        }

        /// They didnt enter anything into the URL bar
        else {
          GoRouter.of(context).go('/');
          // context.read<LoginCubit>().reset();
        }
      }
    }

    /// - EMAIL IS UNVERIFIED
    else {
      logger.d(
        'login: authUser.emailVerified is false so sending verification email',
      );
      await authUser.sendEmailVerification();
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('unverifiedEmail'.translate()),
          content: Text(
            'pleaseClickEmailLink'.translate(),
          ),
        ),
      );
    }
  }

  Future<void> _showErrorDialog(BuildContext context, String? message) async {
    await showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        content: message ?? 'genericError'.translate(),
        onPressed: () {
          logger.e('pressed ok on loginscreen error dialog');
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Form _buildLoginForm(BuildContext context, LoginState state) {
    // logger.i('login: _buildLoginForm');

    List<Widget> children = [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            Core.app.placeHolderImageFilename,
            height: 50,
          ),
          const SizedBox(width: 16),
          Text(
            Core.app.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Core.appColor.primary,
            ),
          )
        ],
      ),
      sizedBox16,
      TextFormField(
        key: const Key('loginForm_emailInput_textField'),
        onChanged: (email) => context.read<LoginCubit>().emailChanged(email),
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        autofillHints: const [AutofillHints.email, AutofillHints.username],
        decoration: InputDecoration(
          labelText: 'email'.tr(),
          helperText: '',
          errorText: state.showValidation && !state.isEmailValid ? 'invalidEmail'.tr() : null,
        ),
      ),
      sizedBox16,
      TextFormField(
        key: const Key('loginForm_passwordInput_textField'),
        onChanged: (password) => context.read<LoginCubit>().passwordChanged(password),
        obscureText: !state.showPassword,
        autofillHints: const [AutofillHints.password],
        decoration: InputDecoration(
          labelText: 'password'.tr(),
          helperText: '',
          errorText: state.showValidation && !state.isPasswordValid ? 'invalidPassword'.tr() : null,
        ),
      ),
      _buildTogglePasswordButton(context, state),
      sizedBox28,
      _buildLoginButton(context, state),
    ];

    // This conditional block adds the widgets for the 'advanced' app type only
    if (Core.app.type == AppType.advanced) {
      if (UniversalPlatform.isAndroid || UniversalPlatform.isWeb) {
        children.addAll([
          sizedBox16,
          _buildGoogleSignInButton(),
        ]);
      }
      children.addAll([
        sizedBox16,
        signUpButton(context),
        sizedBox12,
        _buildMaybeLaterButton(context),
        sizedBox50,
        Text(
          'resetPasswordInstructions'.translate(),
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        sizedBox12,
        _buildResetPasswordButton(context, state),
        // ... Add any other advanced widgets here
      ]);
    }

    return Form(
      key: _loginformKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  /// This method returns a `TextButton` that toggles the password visibility when pressed.
  /// The text of the button changes based on the current state of the `showPassword` property in the `LoginState`.
  TextButton _buildTogglePasswordButton(
    BuildContext context,
    LoginState state,
  ) {
    return TextButton(
      onPressed: () => context.read<LoginCubit>().toggleShowPassword(),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          state.showPassword
              ? 'showPassword'.translate()
              : 'hidePassword'.translate(),
          style: TextStyle(fontSize: 10, color: Core.appColor.primary),
        ),
      ),
    );
  }

  /// Builds the login button with proper onPressed behavior based on the login status.
  ///
  /// If the login status is submitting, the onPressed event will be null, which disables the button.
  /// Otherwise, the onPressed event will call the _submitForm method.
  ElevatedButton _buildLoginButton(BuildContext context, LoginState state) {
    return ElevatedButton(
        onPressed: state.status == LoginStatus.submitting
            ? null
            : () => _submitForm(context),
        child: Text('logIn'.translate()),
        style: ElevatedButton.styleFrom(
          backgroundColor: Core.appColor.primary,
        ));
  }

  // // This is the on-click handler for the Sign In button that is rendered by Flutter.
  // //
  // // On the web, the on-click handler of the Sign In button is owned by the JS
  // // SDK, so this method can be considered mobile only.
  // Future<void> _handleSignIn() async {
  //   try {
  //     await _googleSignIn.signIn();
  //   } catch (error) {
  //     logger.ierror);
  //   }
  // }

  Widget _buildGoogleSignInButton() {
    // if (kIsWeb) {
    //   return WebGoogleSignInButton();
    // } else {
    //   return const GoogleMobileSignInButton();
    // }
    // This method is used to separate mobile from web code with conditional exports.
    // See: src/sign_in_button.dart
    // return buildSignInButton(
    //   onPressed: _handleSignIn,
    // );
    return const GoogleMobileSignInButton();
  }

  /// Builds the "Maybe later" button.
  ///
  /// This button is used to allow users to proceed without logging in.
  /// When clicked, the app navigates to the next screen.
  ///
  /// In Firebase, an "Anonymous" user is a type of user that is authenticated
  /// but doesn't require providing any user data, such email, password or a username.
  /// When a user chooses to use the app anonymously by pressing,
  /// for example, a "Maybe Later" button, Firebase creates a new user account with a
  /// unique ID. The user can be treated as an authenticated user,
  /// but without any personal information stored in Firebase.
  ///
  /// The [BuildContext] parameter, [context], is required to perform
  /// navigation and read the LoginCubit.
  ///
  /// Returns an [ElevatedButton] widget.
  ElevatedButton _buildMaybeLaterButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _submitAnonymous(context),
      child: Text('maybeLater'.translate()),
    );
  }

  /// Builds the "Reset Password" button.
  ///
  /// This button triggers a password reset for the provided email address.
  /// If the email address is invalid, the button will be disabled.
  ///
  /// [context] is the BuildContext to be used for navigation and reading the context.
  /// [state] is the current state of the LoginCubit.
  ElevatedButton _buildResetPasswordButton(
    BuildContext context,
    LoginState state,
  ) {
    return ElevatedButton(
      onPressed: state.email.contains('@')
          ? () => context.read<LoginCubit>().resetPassword(state.email)
          : null,
      child: Text('resetPassword'.translate()),
    );
  }

  void _submitForm(BuildContext context) {
    final loginCubit = context.read<LoginCubit>();
    if (loginCubit.state.status != LoginStatus.submitting) {
      loginCubit.logInWithCredentials();
    }
  }

  void _submitAnonymous(BuildContext context) {
    logger.i('_submitAnonymous');
    context.read<LoginCubit>().signInAnonymously();
  }
}

class GoogleMobileSignInButton extends StatelessWidget {
  const GoogleMobileSignInButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        context.read<LoginCubit>().logInWithGoogle();
      },
      icon: Image.asset(
        'assets/images/google.png',
        height: 18,
        package: 'boxify',
      ),
      label: Text('logInWithGoogle'.translate()),
      style: ElevatedButton.styleFrom(
        backgroundColor: Core.appColor.primary,
      ),
    );
  }
}
