import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_handagote/view/sign_up_page.dart';

import '../constant.dart';
import 'components/dialog.dart';
import 'home_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  String _email = '';
  String _password = '';
  bool _isLoadingLoggingIn = false; // 処理中かどうかを管理するフラグ
  bool _showPassword = false;
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

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
        onPressed() async {
          // 端末にuser_idを保存
          SharedPreferences sharedPreferences =
              await SharedPreferences.getInstance();
          sharedPreferences.setString('user_id', user.uid);

          // ホーム画面に遷移
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const HomePage()));
        }

        DialogHelper.showCustomDialog(
            context: context,
            title: 'ログインしました',
            message: '',
            onPressed: onPressed);
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
      resizeToAvoidBottomInset: false,
      backgroundColor: Constant.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Constant.darkGray,
              ),
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    Container(
                      margin: const EdgeInsets.only(bottom: 30.0),
                      padding: const EdgeInsets.all(3.0),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.white)),
                      ),
                      child: const Text('ログイン',
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                          )),
                    ),
                    const SizedBox(height: 40),
                    // メールアドレス
                    _inputWidget(_emailController, 'メールアドレス：', false),
                    const SizedBox(height: 60),
                    // パスワード
                    _inputWidget(_passwordController, 'パスワード：', true),
                    const SizedBox(height: 60),
                    // 登録ボタン
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: ElevatedButton(
                        onPressed: () async {
                          _email = _emailController.text;
                          _password = _passwordController.text;

                          if (!_isLoadingLoggingIn) {
                            await loginUser();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constant.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: _isLoadingLoggingIn // 処理中フラグに基づいてボタンの表示を切り替え
                            ? const CircularProgressIndicator() // グルグル回るアニメーション
                            : const Text('ログイン',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18)), // 処理中の場合はボタンを無効に
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 新規登録はこちら
                    TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignUpPage()));
                        },
                        icon: const Icon(FontAwesomeIcons.angleLeft,
                            color: Constant.lightGray),
                        label: const Text('新規登録はこちら',
                            style: TextStyle(
                                color: Constant.lightGray, fontSize: 16))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputWidget(TextEditingController textEditingController,
      String hintText, bool isObscure) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Constant.lightGray,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            obscureText: isObscure ? !_showPassword : false,
            controller: textEditingController,
            decoration: InputDecoration(
              suffixIcon: isObscure
                  ? IconButton(
                      icon: Icon(_showPassword
                          ? FontAwesomeIcons.solidEye
                          : FontAwesomeIcons.solidEyeSlash),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    )
                  : null,
              labelText: hintText,
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}
