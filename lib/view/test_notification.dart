import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TestNotificationPage extends StatefulWidget {
  const TestNotificationPage({super.key});

  @override
  State<TestNotificationPage> createState() => _TestNotificationPageState();
}

class _TestNotificationPageState extends State<TestNotificationPage> {
  Future<void> _setNotification() async {
    final messaging = FirebaseMessaging.instance;
    // FCMのトークンのIDを取得
    final fcmTocken = await messaging.getToken();
    print(fcmTocken);

    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _setNotification(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
              body: Center(
            child: Text('success'),
          ));
        }

        return Scaffold(
            body: Center(
          child: Text('loading'),
        ));
      },
    );
  }
}
