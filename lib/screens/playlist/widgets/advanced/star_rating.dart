import 'package:boxify/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.track,
    this.showRating = true,
  });

  final Track track;
  final bool showRating;

  @override
  Widget build(BuildContext context) {
    if (!track.isRateable) {
      return const SizedBox.shrink();
    } else if (!showRating) {
      return const SizedBox(
        width: 120,
      ); // so the row contents won't move when rating is not shown
    }
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        // If the user is logged in, show the rating bar
        if (!state.user.isAnonymous) {
          // Get the rating from the user's ratings map/list
          final ratingFromUserBloc = state.ratings
              .firstWhere(
                (r) => r.trackUuid == track.uuid,
                orElse: () => Rating(trackUuid: track.uuid!, value: 0),
              )
              .value;
          return RatingBar.builder(
            // initialRating: track.userRating ?? 0.0, // https://github.com/riverscuomo/boxify/issues/108
            initialRating: ratingFromUserBloc ?? 0.0,
            minRating: 0,
            itemCount: 5,
            itemSize: 20,
            itemPadding: const EdgeInsets.symmetric(horizontal: 2),
            itemBuilder: (context, _) => Icon(
              Icons.star,
              color: Core.appColor.primary,
            ),
            onRatingUpdate: (v) {
              if (v > 0) {
                // If we wanted to keep using the track.userRating, we would need to update it here, or somehow have this cascade down to the track.userRating
                context
                    .read<UserBloc>()
                    .add(UpdateRating(trackId: track.uuid!, value: v));
              }
            },
          );
        } else {
          // User is not logged in, show a fake rating bar
          // We do this because RatingBar has no way to disable user interaction
          return Row(
            children: List.generate(
                5,
                (index) => GestureDetector(
                      onTap: () {
                        // Show the 'you must be logged in' dialog
                        UserHelper.isLoggedInOrReroute(state, context,
                            'actionRateTracks'.translate(), Icons.star_rounded,
                            useRootNavigator: false);
                      },
                      child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(Icons.star,
                              color: Theme.of(context).disabledColor,
                              size: 20)),
                    )),
          );
        }
      },
    );
  }
}
