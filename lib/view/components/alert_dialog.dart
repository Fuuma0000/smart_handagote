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
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
          content: Text(
            message,
            style: TextStyle(
                color: Theme.of(context).colorScheme.secondary, fontSize: 16),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: <Widget>[
            TextButton(
              onPressed: onPressed!,
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Constant.green,
                  ),
                  child: const Text('戻る',
                      style: TextStyle(
                          color: Constant.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold))),
            ),
          ],
        );
      },
    );
  }
}
