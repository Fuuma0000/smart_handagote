import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_handagote/logic/nav_bar.dart';
import 'package:smart_handagote/view/sign_in_page.dart';
import 'package:smart_handagote/view/sign_up_page.dart';
import 'package:smart_handagote/view/test_reservation_page.dart';
import 'package:smart_handagote/view/test_update_role_page.dart';

import 'constant.dart';
import 'firebase_options.dart';
import 'view/test_login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // この行を追加

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          useMaterial3: true,
        ),
        // home: const TestLoginPage(),
        // home: const UserManagementPage(),
        // home: const MyHomePage(),
        // home: const TestReservationPage(),
        // home: const NavBar(),
        home: const SignInPage());
  }
}
