import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'components/dialog.dart';

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

  @override
  void initState() {
    super.initState();
  }

  // ユーザー登録の処理
  Future<void> registerUser() async {
    try {
      // 学籍番号が被らないかチェック
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('student_id', isEqualTo: _studentId)
          .get();
      // 学籍番号が被っていたら処理を終了
      if (querySnapshot.size > 0) {
        if (!mounted) return;
        DialogHelper.showCustomDialog(context, '学籍番号が被っています', '学籍番号を確認してください');
        return;
      }

      // メールアドレスが被らないかチェック
      querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _email)
          .get();
      // メールアドレスが被っていたら処理を終了
      if (querySnapshot.size > 0) {
        if (!mounted) return;
        DialogHelper.showCustomDialog(
            context, 'メールアドレスが被っています', 'メールアドレスを確認してください');
        return;
      }

      // ユーザー登録
      final User? user = (await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                  email: _email, password: _password))
          .user;
      // ユーザー登録に成功したら Firestore にユーザー情報を保存
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _name,
          'student_id': _studentId,
          'role': 0,
          // TODO: 通知用トークンをここに保存
        });
        if (!mounted) return;
        DialogHelper.showCustomDialog(context, 'ユーザー登録しました', '');
      }
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showCustomDialog(context, 'エラー', '');
      print(e);
    }
  }

  // ログインの処理
  Future<void> loginUser() async {
    try {
      // ログイン
      final User? user = (await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: _email, password: _password))
          .user;
      // ログインに成功したらダイアログを表示
      if (user != null) {
        if (!mounted) return;
        DialogHelper.showCustomDialog(context, 'ログインしました', '');
      }
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showCustomDialog(context, 'エラー', '');
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
