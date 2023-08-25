import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../constant.dart';
import '../logic/firebase_helper.dart';
import 'components/alertDialog.dart';

class UpdateRolePage extends StatefulWidget {
  const UpdateRolePage({super.key});

  @override
  State<UpdateRolePage> createState() => _UpdateRolePageState();
}

class _UpdateRolePageState extends State<UpdateRolePage> {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  String _studentId = '';
  int _role = 0; // 初期値を設定

  Color _textColor = Constant.white;

  // 権限の選択肢
  final List<Map<String, dynamic>> _roleOptions = [
    {'value': 0, 'label': '研修前'},
    {'value': 1, 'label': '研修終了'},
    {'value': 2, 'label': '管理者'},
  ];

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  // ユーザーの role を更新する関数
  Future<void> updateUserRoleByStudentId(String studentId, int newRole) async {
    try {
      // 自分がに管理者の権限があるかチェック
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // ダイアログを表示
        AlertDialogHelper.showCustomDialog(
            context: context, title: 'ログインしていません', message: 'メッセージ');
        return;
      }
      // 自分のドキュメントを取得
      DocumentSnapshot userDoc = await FirebaseHelper().getUserDoc(user.uid);
      // 管理者権限がない場合は処理を終了
      if (userDoc['role'] != 2) {
        // ダイアログを表示
        if (!mounted) return;
        AlertDialogHelper.showCustomDialog(
            context: context, title: '管理者権限がありません', message: '管理者に連絡してください');
        return;
      }

      // 入力した学籍番号が存在するかチェック
      // ユーザーを student_id で検索
      QuerySnapshot querySnapshot =
          await FirebaseHelper().getUserByStudentId(studentId);
      // 学籍番号が見つからない場合は処理を終了
      if (querySnapshot.size == 0) {
        // ダイアログを表示
        if (!mounted) return;
        AlertDialogHelper.showCustomDialog(
            context: context, title: '学籍番号が見つかりません', message: '学籍番号を確認してください');
        return;
      }

      // ユーザのroleを更新する処理
      // 該当するユーザーのドキュメントIDを取得
      String userId = querySnapshot.docs[0].id;
      // ユーザーの role を更新
      await FirebaseHelper().updateRole(userId, newRole);
      // ダイアログを表示
      if (!mounted) return;
      AlertDialogHelper.showCustomDialog(
          context: context,
          title: '権限を更新しました',
          message: _roleOptions[newRole]['label'] + ' に更新しました');
    } catch (e) {
      // ダイアログを表示
      if (!mounted) return;
      AlertDialogHelper.showCustomDialog(
          context: context, title: 'エラー', message: '権限の更新に失敗しました');
      print('Error updating user role: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('権限変更'),
        backgroundColor: Constant.darkGray,
        foregroundColor: Constant.white,
      ),
      backgroundColor: Constant.black,
      body: Center(
        child: Column(
          children: [
            _inputWidget(),
            // _submitBtnWidget(),
          ],
        ),
      ),
    );
  }

  Widget _inputWidget() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          decoration: BoxDecoration(
            color: Constant.darkGray,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _inputNumWidget('学籍番号', _studentId),
              const SizedBox(height: 20),
              _inputRoleWidget('権限', _role),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  await updateUserRoleByStudentId(_studentId, _role);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constant.green,
                  foregroundColor: Constant.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 60),
                ),
                child: const Text('変更', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputNumWidget(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: TextStyle(color: _textColor, fontSize: 18)),
        ),
        TextFormField(
          initialValue: value,
          onChanged: (value) {
            _studentId = value;
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Constant.white,
            hintStyle: TextStyle(color: Constant.darkGray),
            suffixIcon:
                Icon(FontAwesomeIcons.penToSquare, color: Constant.darkGray),
          ),
        ),
      ],
    );
  }

  Widget _inputRoleWidget(String title, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: TextStyle(color: _textColor, fontSize: 18)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Constant.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonFormField<int>(
              padding: const EdgeInsets.only(left: 20, right: 10),
              decoration: InputDecoration(
                labelText: '権限',
                labelStyle: TextStyle(
                  color: _textColor,
                  fontSize: 20,
                ),
                // 下の線を消す
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent),
                ),
              ),
              style: TextStyle(color: _textColor, fontSize: 18),
              borderRadius: BorderRadius.circular(10),
              dropdownColor: Constant.white,
              value: _role,
              items: _roleOptions.map((option) {
                return DropdownMenuItem<int>(
                  value: option['value'],
                  child: Text(option['label'],
                      style: TextStyle(color: Constant.darkGray)),
                );
              }).toList(),
              onChanged: (int? value) {
                setState(() {
                  if (value != null) {
                    _role = value;
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
