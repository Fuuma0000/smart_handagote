import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_handagote/logic/nav_bar.dart';
import 'package:smart_handagote/view/sign_in_page.dart';
import 'notification.dart';

import 'constant.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // この行を追加

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()!
      .requestPermission();

  final messaging = FirebaseMessaging.instance;
  // FCMのトークンのIDを取得
  final fcmTocken = await messaging.getToken();
  print('fcmToken: $fcmTocken');

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
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? myId;
  @override
  void initState() {
    super.initState();

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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Constant.black,
      ),
    );

    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        fontFamily: 'NotoSansJP',
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // ロード中
            return const SizedBox();
          }
          if (snapshot.hasData) {
            // サインイン済み：ホーム画面へ
            return NavBar(userID: snapshot.data!.uid);
          }
          // 未サインイン：サインイン画面へ
          return const SignInPage();
        },
      ),
    );
  }
}
