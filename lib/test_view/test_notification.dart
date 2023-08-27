import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

AndroidNotificationChannel channel = const AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

class TestNotificationPage extends StatefulWidget {
  const TestNotificationPage({super.key});

  @override
  State<TestNotificationPage> createState() => _TestNotificationPageState();
}

class _TestNotificationPageState extends State<TestNotificationPage> {
  String token = '';
  Future<void> _setNotification() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()!
        .requestPermission();

    final messaging = FirebaseMessaging.instance;
    // FCMのトークンのIDを取得
    final fcmTocken = await messaging.getToken();
    print('fcmToken: $fcmTocken');
    token = fcmTocken!;

    // final FlutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

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
  void initState() {
    super.initState();

    _setNotification();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        var androidChannelSpecifics = const AndroidNotificationDetails(
          'CHANNEL_ID',
          'CHANNEL_NAME',
          channelDescription: "CHANNEL_DESCRIPTION",
          importance: Importance.max,
          priority: Priority.high,
          playSound: false,
          timeoutAfter: 5000,
          styleInformation: DefaultStyleInformation(true, true),
        );
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: androidChannelSpecifics,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _setNotification(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
              body: Center(
            child: ElevatedButton(
              onPressed: () async {
                print(token);
              },
              child: const Text('notification'),
            ),
          ));
        }

        return const Scaffold(
            body: Center(
          child: Text('loading'),
        ));
      },
    );
  }
}
