import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_handagote/constant.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _idController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

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
                    _inputWidget(_nameController, '名前：'),
                    const SizedBox(height: 40),
                    // 学籍番号
                    _inputWidget(_idController, '学籍番号：'),
                    const SizedBox(height: 40),
                    // メールアドレス
                    _inputWidget(_emailController, 'メールアドレス：'),
                    const SizedBox(height: 40),
                    // パスワード
                    _inputWidget(_passwordController, 'パスワード：'),
                    const SizedBox(height: 40),
                    // 登録ボタン
                    Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constant.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text('登録',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputWidget(
      TextEditingController textEditingController, String hintText) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Expanded(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Constant.lightGray,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: TextField(
              controller: textEditingController,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
