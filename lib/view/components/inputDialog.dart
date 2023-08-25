import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_handagote/constant.dart';

import '../../logic/firebase_helper.dart';
import 'dialog.dart';

class InputDialog extends StatefulWidget {
  const InputDialog({Key? key, this.text}) : super(key: key);
  final String? text;

  @override
  State<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  String _studentId = '';
  int _role = 0; // 初期値を設定

  // 権限の選択肢
  final List<Map<String, dynamic>> _roleOptions = [
    {'value': 0, 'label': '研修前'},
    {'value': 1, 'label': '研修終了'},
    {'value': 2, 'label': '管理者'},
  ];

  // ユーザーの role を更新する関数
  Future<void> updateUserRoleByStudentId(String studentId, int newRole) async {
    try {
      // 自分がに管理者の権限があるかチェック
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // ダイアログを表示
        DialogHelper.showCustomDialog(
            context: context, title: 'ログインしていません', message: 'メッセージ');
        return;
      }
      // 自分のドキュメントを取得
      DocumentSnapshot userDoc = await FirebaseHelper().getUserDoc(user.uid);
      // 管理者権限がない場合は処理を終了
      if (userDoc['role'] != 2) {
        // ダイアログを表示
        if (!mounted) return;
        DialogHelper.showCustomDialog(
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
        DialogHelper.showCustomDialog(
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
      DialogHelper.showCustomDialog(
          context: context,
          title: '権限を更新しました',
          message: _roleOptions[newRole]['label'] + ' に更新しました');
    } catch (e) {
      // ダイアログを表示
      if (!mounted) return;
      DialogHelper.showCustomDialog(
          context: context, title: 'エラー', message: '権限の更新に失敗しました');
      print('Error updating user role: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // backgroundColor: Colors.transparent,
      backgroundColor: Constant.lightGrey,
      surfaceTintColor: Constant.darkGray,
      // elevation: 1,
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.3,
        child: Column(
          children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'ユーザー承認',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                // autofocus: true, // ダイアログが開いたときに自動でフォーカスを当てる
                focusNode: focusNode,
                controller: controller,
                decoration: InputDecoration(
                  labelText: '学籍番号',
                  // border
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Constant.darkGray,
                    ),
                  ),
                ),
                onFieldSubmitted: (_) {
                  // TODO: エンターを押した時
                },
              ),
            ),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: '権限',
                labelStyle: TextStyle(color: Colors.white),
              ),
              style: const TextStyle(color: Colors.white),
              value: _role,
              items: _roleOptions.map((option) {
                return DropdownMenuItem<int>(
                  value: option['value'],
                  child: Text(option['label']),
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
          ],
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Constant.green,
            ),
            onPressed: () {
              // TODO: 認証処理
              print(controller.text);
              updateUserRoleByStudentId(_studentId, _role);
            },
            child: Text(
              '完了',
              style: TextStyle(
                fontSize: 16,
                color: Constant.white,
              ),
            ),
          ),
        )
      ],
    );
  }
}

class DialogUtils {
  DialogUtils._();

  /// タイトルのみを表示するシンプルなダイアログを表示する
  static Future<void> showOnlyTitleDialog(
    BuildContext context,
    String title,
  ) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
        );
      },
    );
  }

  /// 入力した文字列を返すダイアログを表示する
  static Future<String?> showEditingDialog(
    BuildContext context,
    String text,
  ) async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return InputDialog(text: text);
      },
    );
  }
}
