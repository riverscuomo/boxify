import 'package:boxify/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DiscordFormField extends StatelessWidget {
  const DiscordFormField({
    super.key,
    required this.context,
    required this.user,
    required TextEditingController discordController,
  }) : _discordController = discordController;

  final BuildContext context;
  final User user;
  final TextEditingController _discordController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: TextFormField(
        onFieldSubmitted: (String value) {
          var discordId = value;

          if (value!.length < 10) {
            showMySnack(
              context,
              color: Core.appColor.discordColor,
              message: 'discordIDMustBe10Digits'.translate(),
            );
            discordId = '';
          }

          context
              .read<SettingsBloc>()
              .add(SettingsConnectDiscord(user: user, discordId: discordId));

          if (discordId.isNotEmpty) {
            showMySnack(
              context,
              color: Core.appColor.discordColor,
              message: '$discordId has been saved to your account record here.',
            );
          }
        },
        style: const TextStyle(fontSize: 15),
        controller: _discordController,
        decoration: InputDecoration(
          hintMaxLines: 3,
          border: const OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Core.appColor.focusBorder,
              width: 2.0
            ),
          ),
          hintText: user.discordId.isNotEmpty
              ? user.discordId
              : 'discordHintText'.translate(),
          prefixIcon: Image.asset('assets/images/discord.png',
              height: 18,
              package:
                  'boxify'), // Update this path to the location of your actual icon file
        ),
      ),
    );
  }
}

//// DEPRECATED
class DiscordProfileButton extends StatelessWidget {
  const DiscordProfileButton({
    super.key,
    required String discordId,
  }) : _discordId = discordId;

  final String _discordId;

  @override
  Widget build(BuildContext context) {
    return _discordId.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 205,
              child: ElevatedButton(
                onPressed: () =>
                    launchURL('https://discordapp.com/users/$_discordId'),
                style: roundedButtonStyleBlack,
                child: Text(
                  'visitYourDiscordProfile'.translate(),
                ),
              ),
            ),
          )
        : Container();
  }
}

// SliverToBoxAdapter(
//   child: (state.bundles.isNotEmpty || state.viewer.admin)
//       ? Padding(
//           padding: const EdgeInsets.all(8),
//           child: Column(
//             children: [
//               const Padding(
//                 padding: EdgeInsets.all(8),
//                 child: Text('Bundles', style: boldWhite14),
//               ),
//               SizedBox(
//                 height: bundleRowsHeight,
//                 child: GridView.builder(
//                   itemCount: state.bundles.length,
//                   physics: const NeverScrollableScrollPhysics(),
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: crossAxisCount,
//                   ),
//                   itemBuilder: (context, index) => InkWell(
//                     // final badge = state.badges[index];
//                     onTap: () => _openBundlePreview(state.bundles[index]),
//                     child: BundleCardForArtistScreen(bundle: state.bundles[index]),
//                   ),
//                 ),
//               ),
//               // Add remove BUNDLES button
//               if (state.viewer.admin)
//                 SizedBox(
//                   width: 100,
//                   child: Card(
//                     shape: const BeveledRectangleBorder(
//                       side: BorderSide(
//                         color: Colors.blueAccent,
//                         width: .3,
//                       ),
//                     ),
//                     child: Column(
//                       children: [
//                         ElevatedButton(
//                           onPressed: () {
//                             _showBundleController(state);
//                           },
//                           style: ElevatedButton.styleFrom(primary: Colors.blueAccent),
//                           child: const Icon(Icons.add),
//                         ),
//                         const Center(
//                           child: Text(
//                             'add',
//                             style: TextStyle(fontSize: 10),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 )
//               else
//                 Container(),
//             ],
//           ),
//         )
//       : Container(),
// ),
