import 'package:boxify/app_core.dart';
import 'package:flutter/material.dart';

class LargeTitleAndArtist extends StatelessWidget {
  const LargeTitleAndArtist({
    super.key,
    required this.track,
  });
  final Track track;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 20,
            child: TextOrMarquee(
              text: track.displayTitle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (Core.app.type == AppType.advanced) {
                pushToUserArtist(context, track.userId ?? '');
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: HoverText(
                text: track.artist ?? 'Unknown Artist',
                fontSize: 10,
                underlineOnHover: true,
                changeColorOnHover: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
