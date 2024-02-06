import 'package:flutter/material.dart';

import '../../constant.dart';

class CheckDialogHelper {
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
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: <Widget>[
            Row(
              children: [
                const Spacer(),
                Container(
                  decoration: const BoxDecoration(
                    color: Constant.green,
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                  child: TextButton(
                    onPressed: onPressed!,
                    child: const Text('はい',
                        style: TextStyle(
                            color: Constant.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    border: Border.fromBorderSide(
                        BorderSide(color: Constant.green, width: 2)),
                  ),
                  child: TextButton(
                    child: const Text('いいえ',
                        style: TextStyle(
                            color: Constant.green,
                            fontWeight: FontWeight.w700)),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                const Spacer(),
              ],
            ),
          ],
        );
      },
    );
  }
}
