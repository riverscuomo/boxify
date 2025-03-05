import 'package:boxify/app_core.dart';
import 'package:flutter/material.dart';

/// A dialog that prompts the user to log in or sign up to perform an action.
/// The action is passed as a parameter and is displayed in the dialog (e.g. 'rate tracks', 'create playlists', etc..).
class LoginRequiredDialog extends StatelessWidget {
  /// The action that the user is trying to perform.
  final String action;

  /// The icon to display in the dialog.
  final IconData icon;

  // The callback to execute when the user chooses to log in or sign up.
  final VoidCallback onLogin;

  // The callback to execute when the user dismisses the dialog.
  final VoidCallback onDismiss;

  const LoginRequiredDialog({
    super.key,
    required this.action,
    required this.icon,
    required this.onLogin,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Display icon passed as parameter
          Icon(
            icon,
            size: 60,
            color: Core.appColor.primary,
          ),
          const SizedBox(height: 16),

          // Title text (with action name)
          Text(
            'mustLogInDialogTitle'.translate(namedArgs: {'actionName': action}),
            // If the action name is long, use a slightly smaller font size
            style: action.length > 18
                ? Core.appStyle.medium.bold
                : Core.appStyle.header,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description text
          Text(
            'mustLogInDialogMessage'.translate(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // 'Login or sign up' button
          ElevatedButton(
            onPressed: onLogin,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'logInOrSignUp'.translate(),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),

          // 'Not Now' button
          ElevatedButton(
            onPressed: onDismiss,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'notNow'.translate(),
              style: TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}
