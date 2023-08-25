import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_handagote/view/sign_in_page.dart';
import 'package:smart_handagote/view/test_reservation_page.dart';

import '../logic/firebase_helper.dart';
import 'package:smart_handagote/constant.dart';
import 'components/alertDialog.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  String _name = '';
  String _studentId = '';
  String _email = '';
  String _password = '';
  bool _isLoadSigningIn = false; // 処理中かどうかを管理するフラグ
  bool _showPassword = false;

  TextEditingController _nameController = TextEditingController();
  TextEditingController _studentIdController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

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
        AlertDialogHelper.showCustomDialog(
            context: context, title: '学籍番号が被っています', message: '学籍番号を確認してください');
        return;
      }

      // メールアドレスが被らないかチェック
      bool isEmailUnique = await FirebaseHelper().isEmailUnique(_email);
      // メールアドレスが被っていたら処理を終了
      if (!isEmailUnique) {
        if (!mounted) return;
        AlertDialogHelper.showCustomDialog(
          context: context,
          title: 'メールアドレスが被っています',
          message: 'メールアドレスを確認してください',
        );
        return;
      }

      // ユーザー登録
      final User? user = (await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                  email: _email, password: _password))
          .user;
      // ユーザー登録に成功したら Firestore にユーザー情報を保存
      if (user != null) {
        String token = FirebaseMessaging.instance.getToken() as String;
        await FirebaseHelper().saveUserInfo(
          user.uid,
          _name,
          _studentId,
          token,
        );
        if (!mounted) return;
        func() async {
          final User? user = (await FirebaseAuth.instance
                  .signInWithEmailAndPassword(
                      email: _email, password: _password))
              .user;
          // 端末にuser_idを保存
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('user_id', user!.uid);

          await Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const TestReservationPage()));
        }

        AlertDialogHelper.showCustomDialog(
            context: context,
            title: 'ユーザー登録しました',
            message: '',
            onPressed: func);
      }
    } catch (e) {
      if (!mounted) return;
      AlertDialogHelper.showCustomDialog(
          context: context, title: 'エラー', message: e.toString());
      print(e);
    } finally {
      setState(() {
        _isLoadSigningIn = false; // 処理完了後に処理中フラグをfalseにセット
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
                    const SizedBox(height: 60),
                    Container(
                      margin: const EdgeInsets.only(bottom: 30.0),
                      padding: const EdgeInsets.all(3.0),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.white)),
                      ),
                      child: const Text('新規登録',
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                          )),
                    ),
                    // 名前
                    _inputWidget(_nameController, '名前：', false),
                    const SizedBox(height: 40),
                    // 学籍番号
                    _inputWidget(_studentIdController, '学籍番号：', false),
                    const SizedBox(height: 40),
                    // メールアドレス
                    _inputWidget(_emailController, 'メールアドレス：', false),
                    const SizedBox(height: 40),
                    // パスワード
                    _inputWidget(_passwordController, 'パスワード：', true),
                    const SizedBox(height: 40),
                    // 登録ボタン
                    Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: ElevatedButton(
                        onPressed: () async {
                          _name = _nameController.text;
                          _studentId = _studentIdController.text;
                          _email = _emailController.text;
                          _password = _passwordController.text;

                          if (!_isLoadSigningIn) {
                            await registerUser();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constant.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: _isLoadSigningIn
                            ? const CircularProgressIndicator()
                            : const Text('登録',
                                style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    // ログインはこちら
                    TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignInPage()));
                        },
                        icon: const Icon(
                          FontAwesomeIcons.angleLeft,
                          color: Constant.white,
                          size: 14,
                        ),
                        label: const Text('アカウントをお持ちのかたはこちら',
                            style: TextStyle(
                                color: Constant.white, fontSize: 14))),
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
          color: Constant.white,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            obscureText: isObscure ? !_showPassword : false,
            controller: textEditingController,
            decoration: InputDecoration(
              suffixIcon: isObscure
                  ? IconButton(
                      icon: Icon(
                        _showPassword
                            ? FontAwesomeIcons.solidEye
                            : FontAwesomeIcons.solidEyeSlash,
                        size: 18,
                      ),
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
