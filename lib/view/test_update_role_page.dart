import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../constant.dart';
import '../logic/firebase_helper.dart';
import 'components/alertDialog.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
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
      backgroundColor: Constant.black,
      body: Center(
        // 学籍番号入力と権限選択を追加
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 300, // コンテナの幅を調整
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: '学籍番号',
                        labelStyle: TextStyle(color: Colors.white),
                        // border: InputBorder.none, // 枠線を隠す
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (String value) {
                        setState(() {
                          _studentId = value;
                        });
                      },
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Theme(
                      data: Theme.of(context).copyWith(
                        canvasColor: Constant.darkGray, // 背景色を変更
                      ),
                      child: DropdownButtonFormField<int>(
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
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // ここで学籍番号と新しい role を指定
                        updateUserRoleByStudentId(_studentId, _role);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Constant.green,
                      ),
                      child: const Text('Update User Role'),
                    ),
                    // SizedBox(
                    //   height: 10,
                    // )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
