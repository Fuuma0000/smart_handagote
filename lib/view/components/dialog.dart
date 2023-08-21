import 'package:flutter/material.dart';

import '../../constant.dart';

class DialogHelper {
  static Future<void> showCustomDialog(
      BuildContext context, String title, String message) async {
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
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
