import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../constant.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _studentId = '';
  int _role = 0; // 初期値を設定

  // 権限の選択肢
  final List<Map<String, dynamic>> _roleOptions = [
    {'value': 0, 'label': '研修前'},
    {'value': 1, 'label': '研修終了'},
    {'value': 2, 'label': '管理者'},
  ];

  Future<void> updateUserRoleByStudentId(String studentId, int newRole) async {
    try {
      // 自分がに管理者の権限があるかチェック
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // ダイアログを表示
        await _showDialog('ログインしていません', 'ログインしてください');
        return;
      }
      // 自分のドキュメントを取得
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      // 管理者権限がない場合は処理を終了
      if (userDoc['role'] != 2) {
        // ダイアログを表示
        await _showDialog('管理者権限がありません', '管理者に連絡してください');
        return;
      }

      // 入力した学籍番号が存在するかチェック
      // ユーザーを student_id で検索
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('student_id', isEqualTo: studentId)
          .get();
      // 学籍番号が見つからない場合は処理を終了
      if (querySnapshot.size == 0) {
        // ダイアログを表示
        await _showDialog('学籍番号が見つかりません', '学籍番号を確認してください');
        return;
      }

      // ユーザのroleを更新する処理
      // 該当するユーザーのドキュメントIDを取得
      String userId = querySnapshot.docs[0].id;
      // ユーザーの role を更新
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'role': newRole});
      // ダイアログを表示
      await _showDialog(
          '権限を更新しました', _roleOptions[newRole]['label'] + 'に更新しました');
    } catch (e) {
      // ダイアログを表示
      await _showDialog('エラー', '権限の更新に失敗しました');
      print('Error updating user role: $e');
    }
  }

  // ダイアログを表示する関数
  Future<void> _showDialog(String title, String message) async {
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constant.black,
      body: Center(
        // 学籍番号入力と権限選択を追加
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              decoration: const InputDecoration(
                labelText: '学籍番号',
                labelStyle: TextStyle(color: Colors.white),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (String value) {
                setState(() {
                  _studentId = value;
                });
              },
            ),
            ElevatedButton(
              onPressed: () {
                // ここで学籍番号と新しい role を指定
                updateUserRoleByStudentId(_studentId, _role);
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
              ),
              child: const Text('Update User Role'),
            ),
          ],
        ),
      ),
    );
  }
}
