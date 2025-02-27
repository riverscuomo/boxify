import 'package:boxify/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RemoveAllDownloadsTile extends StatelessWidget {
  const RemoveAllDownloadsTile({
    super.key, 
    required this.context, 
    required this.id
  });

  final BuildContext context;
  final String id;

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('removeAllDownloadsQuestion'.translate()),
          content: Text('areYouSureRemoveAllDownloads'.translate()),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              child: Text('cancelSmall'.translate()),
            ),
            TextButton(
              onPressed: () async {
                // Dispatch the RemoveAllDownloads event
                BlocProvider.of<DownloadBloc>(context).add(
                  RemoveAllDownloads(userId: id),
                );

                Navigator.of(dialogContext).pop(); // Close the dialog

                showMySnack(
                  context,
                  message: 'allDownloadsRemoved'.translate(),
                );
              },
              child: Text('remove'.translate()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return id != ''
        ? ListTile(
            title: Text(
              'removeAllDownloads'.translate(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              'thisWillRemoveAllYourDownloadedTracks'.translate(),
              style: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            trailing: ElevatedButton(
              style: roundedButtonStyleBlack,
              child: Text(
                'removeAll'.translate(),
                // style: boldWhite12,
              ),
              onPressed: () {
                _showConfirmationDialog(context);
              },
            ),
          )
        : Container();
  }
}
