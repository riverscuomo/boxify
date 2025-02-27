import 'package:boxify/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:boxify/screens/settings/buttons/remove_all_downloads_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _discordController = TextEditingController();
  bool isLoggedIn = false;
  String? userId;
  User? user;
  String version = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _discordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listener: (context, state) {
        logger.i(
          'SettingsState.listener: ${state.status}=========================',
        );
        if (state.status == SettingsStatus.error) {
          showDialog(
            context: context,
            builder: (context) => ErrorDialog(
              content: state.failure.message.toString(),
            ),
          );
        }
      },
      builder: (context, state) {
        if (context.read<AuthBloc>().state.user == null) {
          logger.i(
              'setttingsScreen: AuthBloc.state.user == null so return CircularProgressIndicator()');
          return const Center(child: CircularProgressIndicator());
        } else if (state.status == SettingsStatus.loading ||
            state.status == SettingsStatus.initial) {
          logger.i(
              'setttingsScreen: ${state.status} so return CircularProgressIndicator()');
          return circularProgressIndicator;
        }
        logger.i('Settings SCREEN build for ${state.user.username}');
        final discordController = TextEditingController();
        final isLoggedIn = !state.user.isAnonymous;
        final user = state.user;

        return Scaffold(
          appBar: AppBar(
            title: Center(
              child: Text('settings'.translate(), style: Core.appStyle.bold),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              key: const Key('setttingsScreenColumn'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20), // Add a space under the app bar
                Core.app.type == AppType.advanced
                    ? ListTile(
                        title: Text('connectToDiscord'.translate(),
                            style: Core.appStyle.bold),
                        subtitle: DiscordFormField(
                          context: context,
                          user: user,
                          discordController: discordController,
                        ),
                      )
                    : Container(),
                SurveyButtonWidget(),
                ListTile(
                  title: Text(
                    'email'.translate(),
                    style: Core.appStyle.bold,
                  ),
                  subtitle: SelectableText(user.email),
                ),
                ListTile(
                  title: Text(
                    'userId'.translate(),
                    style: Core.appStyle.bold,
                  ),
                  subtitle: SelectableText(user.id),
                ),
                if (isLoggedIn)
                  ListTile(
                    title: SelectableText(
                      'logout'.translate(),
                      style: Core.appStyle.bold,
                    ),
                    subtitle: Text(user.username),
                    trailing: LogOutButton(),
                  ),
                if (isLoggedIn || Core.app.type == AppType.basic)
                  ClearCacheText(context: context, id: user.id),
                if (isLoggedIn || Core.app.type == AppType.basic)
                  RemoveAllDownloadsTile(context: context, id: user.id),
                if (isLoggedIn && Core.app.type == AppType.advanced)
                  DeleteAccountTile(
                      context: context, id: user.id, style: Core.appStyle.bold),

                // APP VERSION
                ListTile(
                  title: SelectableText('version'.translate(),
                      style: Core.appStyle.bold),
                  trailing: SelectableText(Core.app.appVersion),
                ),
                // ...List.generate(10, (index) => ListTile(title: Text('test'))),
              ],
            ),
          ),
        );
      },
    );
  }
}

// // DISCORD PROFILE BUTTON
// if (isLoggedIn)
//   Padding(
//     padding: const EdgeInsets.all(0),
//     child: DiscordProfileButton(
//       discordId: user.discordId,
//     ),
//   ),