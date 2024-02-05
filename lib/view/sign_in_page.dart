import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_handagote/logic/nav_bar.dart';
import 'package:smart_handagote/view/sign_up_page.dart';

import '../constant.dart';
import '../logic/firebase_helper.dart';
import 'components/alert_dialog.dart';

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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ログインの処理
  Future<void> loginUser() async {
    String errorMessage = 'ログインに失敗しました';

    setState(() {
      _isLoadingLoggingIn = true;
    });

    // メールアドレスとパスワードが入力されているかチェック
    if (_email.isEmpty || _password.isEmpty) {
      AlertDialogHelper.showCustomDialog(
          context: context, title: 'エラー', message: 'メールアドレスとパスワードを入力してください');
      setState(() {
        _isLoadingLoggingIn = false;
      });
      return;
    }

    try {
      // ログイン
      final User? user = (await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: _email, password: _password))
          .user;
      // ログインに成功したらダイアログを表示
      if (user != null) {
        if (!mounted) return;
        onPressed() async {
          // トークンをfirebaseに保存
          String token = await FirebaseMessaging.instance.getToken() as String;
          await FirebaseHelper().updateToken(user.uid, token);

          // 端末にuser_idを保存
          SharedPreferences sharedPreferences =
              await SharedPreferences.getInstance();
          sharedPreferences.setString('user_id', user.uid);
        }

        AlertDialogHelper.showCustomDialog(
            context: context,
            title: 'ログインしました',
            message: '',
            onPressed: () {
              // ホーム画面に遷移
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NavBar(userID: user.uid),
                ),
              );
            });
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'invalid-email') {
        errorMessage = 'メールアドレスが正しくありません';
      } else if (e.code == 'user-not-found') {
        errorMessage = 'ユーザーが見つかりませんでした';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'パスワードが正しくありません';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'このメールアドレスは無効になっています';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'アクセスが集中しています。しばらくしてから再度お試しください';
      } else if (e.code == 'operation-not-allowed') {
        errorMessage = 'メールアドレスとパスワードでのログインは有効になっていません';
      } else {
        errorMessage = '予期せぬエラーが発生しました';
      }

      AlertDialogHelper.showCustomDialog(
          context: context, title: 'ログイン失敗', message: errorMessage);
    } catch (e) {
      if (!mounted) return;

      AlertDialogHelper.showCustomDialog(
          context: context, title: 'エラー', message: errorMessage);
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
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Theme.of(context).colorScheme.onBackground,
              ),
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    Container(
                      margin: const EdgeInsets.only(bottom: 30.0),
                      padding: const EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color:
                                    Theme.of(context).colorScheme.secondary)),
                      ),
                      child: Text('ログイン',
                          style: TextStyle(
                            fontSize: 22,
                            color: Theme.of(context).colorScheme.secondary,
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
                        icon: Icon(FontAwesomeIcons.angleLeft,
                            color: Theme.of(context).colorScheme.secondary),
                        label: Text('新規登録はこちら',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 16))),
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
          // 外枠
          // themeがlightだったら
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 1.2,
          ),
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
                        color: Constant.darkGray,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    )
                  : null,
              labelText: hintText,
              labelStyle: TextStyle(color: Constant.darkGray),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}
