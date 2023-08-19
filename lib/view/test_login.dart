import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestLoginPage extends StatefulWidget {
  const TestLoginPage({Key? key}) : super(key: key);

  @override
  _TestLoginPage createState() => _TestLoginPage();
}

class _TestLoginPage extends State<TestLoginPage> {
  String _name = '';
  String _studentId = '';
  String _email = '';
  String _password = '';

  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    initializeSharedPreferences();
  }

  Future<void> initializeSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> registerUser() async {
    try {
      // 学籍番号が被らないかチェック
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('student_id', isEqualTo: _studentId)
          .get();
      if (querySnapshot.size > 0) {
        print('学籍番号が被っています');
        return;
      }
      final User? user = (await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                  email: _email, password: _password))
          .user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _name,
          'student_id': _studentId,
          'role': 0,
        });
        await prefs.setString('userID', user.uid);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> loginUser() async {
    try {
      final User? user = (await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: _email, password: _password))
          .user;
      if (user != null) {
        print("ログイン成功");
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: '名前'),
                onChanged: (String value) {
                  setState(() {
                    _name = value;
                  });
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '学籍番号'),
                onChanged: (String value) {
                  setState(() {
                    _studentId = value;
                  });
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'メールアドレス'),
                onChanged: (String value) {
                  setState(() {
                    _email = value;
                  });
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'パスワード'),
                obscureText: true,
                onChanged: (String value) {
                  setState(() {
                    _password = value;
                  });
                },
              ),
              ElevatedButton(
                child: const Text('ユーザ登録'),
                onPressed: () => registerUser(),
              ),
              ElevatedButton(
                child: const Text('ログイン'),
                onPressed: () => loginUser(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
