import 'package:flutter/material.dart';
import 'package:smart_handagote/constant.dart';

class UserEditPage extends StatefulWidget {
  String userId;
  UserEditPage({super.key, required this.userId});

  @override
  State<UserEditPage> createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('ユーザー設定'),
        backgroundColor: Constant.darkGray,
        foregroundColor: Constant.white,
      ),
      backgroundColor: Constant.black,
    );
  }
}
