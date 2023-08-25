import 'package:flutter/material.dart';

import '../../constant.dart';

class AlertDialogHelper {
  static Future<void> showCustomDialog(
      {required BuildContext context,
      required String title,
      required String message,
      GestureTapCallback? onPressed}) async {
    // onPressedがnullの場合はnavigator.pop
    onPressed ??= () {
      Navigator.pop(context);
    };

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Constant.darkGray,
          actions: <Widget>[
            TextButton(
              child: const Text('OK', style: TextStyle(color: Colors.green)),
              onPressed: onPressed!,
            ),
          ],
        );
      },
    );
  }
}
