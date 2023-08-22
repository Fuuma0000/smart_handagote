import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../logic/firebase_helper.dart';
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
  bool _isLoadSigningIn = false; // 処理中かどうかを管理するフラグ
  bool _isLoadingLoggingIn = false; // 処理中かどうかを管理するフラグ

  @override
  void initState() {
    super.initState();
  }

  // ユーザー登録の処理
  Future<void> registerUser() async {
    setState(() {
      _isLoadSigningIn = true;
    });
    try {
      // 学籍番号が被らないかチェック
      bool isStudentIdUnique =
          await FirebaseHelper().isStudentIdUnique(_studentId);
      // 学籍番号が被っていたら処理を終了
      if (!isStudentIdUnique) {
        if (!mounted) return;
        DialogHelper.showCustomDialog(
            context: context, title: '学籍番号が被っています', message: '学籍番号を確認してください');
        return;
      }

      // メールアドレスが被らないかチェック
      bool isEmailUnique = await FirebaseHelper().isEmailUnique(_email);
      // メールアドレスが被っていたら処理を終了
      if (!isEmailUnique) {
        if (!mounted) return;
        DialogHelper.showCustomDialog(
            context: context,
            title: 'メールアドレスが被っています',
            message: 'メールアドレスを確認してください');
        return;
      }

      // ユーザー登録
      final User? user = (await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                  email: _email, password: _password))
          .user;
      // ユーザー登録に成功したら Firestore にユーザー情報を保存
      if (user != null) {
        await FirebaseHelper().saveUserInfo(user.uid, _name, _studentId);
        if (!mounted) return;
        DialogHelper.showCustomDialog(
            context: context, title: 'ユーザー登録しました', message: '');
      }
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showCustomDialog(
          context: context, title: 'エラー', message: '');
      print(e);
    } finally {
      setState(() {
        _isLoadSigningIn = false; // 処理完了後に処理中フラグをfalseにセット
      });
    }
  }

  // ログインの処理
  Future<void> loginUser() async {
    setState(() {
      _isLoadingLoggingIn = true;
    });
    try {
      // ログイン
      final User? user = (await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: _email, password: _password))
          .user;
      // ログインに成功したらダイアログを表示
      if (user != null) {
        if (!mounted) return;
        DialogHelper.showCustomDialog(
            context: context, title: 'ログインしました', message: '');
      }
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showCustomDialog(
          context: context, title: 'エラー', message: '');
      print(e);
    } finally {
      setState(() {
        _isLoadingLoggingIn = false; // 処理完了後に処理中フラグをfalseにセット
      });
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
                onPressed: _isLoadSigningIn ? null : () => registerUser(),
                child: _isLoadSigningIn // 処理中フラグに基づいてボタンの表示を切り替え
                    ? const CircularProgressIndicator() // グルグル回るアニメーション
                    : const Text('ユーザ登録'), // 処理中の場合はボタンを無効に
              ),
              ElevatedButton(
                onPressed: _isLoadingLoggingIn ? null : () => loginUser(),
                child: _isLoadingLoggingIn // 処理中フラグに基づいてボタンの表示を切り替え
                    ? const CircularProgressIndicator() // グルグル回るアニメーション
                    : const Text('ログイン'), // 処理中の場合はボタンを無効に
              ),
            ],
          ),
        ),
      ),
    );
  }
}
