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
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          backgroundColor: Constant.darkGray,
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
                  child: const Text('OK',
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
