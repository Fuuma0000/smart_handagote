import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      // ユーザーを student_id で検索
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('student_id', isEqualTo: studentId)
          .get();

      // 該当するユーザーのドキュメントIDを取得
      if (querySnapshot.size > 0) {
        String userId = querySnapshot.docs[0].id;

        // ユーザーの role を更新
        await _firestore
            .collection('users')
            .doc(userId)
            .update({'role': newRole});
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user role: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: Center(
        // 学籍番号入力と権限選択を追加
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              decoration: const InputDecoration(labelText: '学籍番号'),
              onChanged: (String value) {
                setState(() {
                  _studentId = value;
                });
              },
            ),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: '権限'),
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
            ElevatedButton(
              onPressed: () {
                // ここで学籍番号と新しい role を指定
                updateUserRoleByStudentId(_studentId, _role);
              },
              child: const Text('Update User Role'),
            ),
          ],
        ),
      ),
    );
  }
}
