import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestLoginPage extends StatefulWidget {
  const TestLoginPage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _TestLoginPage createState() => _TestLoginPage();
}

class _TestLoginPage extends State<TestLoginPage> {
  // 入力したメールアドレス・パスワード
  String _name = '';
  String _email = '';
  String _password = '';

  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    initializeSharedPreferences();
  }

  Future<void> initializeSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'ニックネーム'),
                onChanged: (String value) {
                  setState(() {
                    _name = value;
                  });
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'メールアドレス'),
                onChanged: (String value) {
                  setState(() {
                    _email = value;
                  });
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'パスワード'),
                obscureText: true,
                onChanged: (String value) {
                  setState(() {
                    _password = value;
                  });
                },
              ),
              ElevatedButton(
                child: const Text('ユーザ登録'),
                onPressed: () async {
                  try {
                    print("try start");
                    final User? user = (await FirebaseAuth.instance
                            .createUserWithEmailAndPassword(
                                email: _email, password: _password))
                        .user;
                    if (user != null) {
                      // usersコレクションにユーザ情報を登録
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .set({
                        'name': _name,
                        'userID': user.uid,
                        'groupID': null
                      });
                      await prefs.setString('userID', user.uid);
                    }
                    print("try end");
                  } catch (e) {
                    print(e);
                  }
                },
              ),
              ElevatedButton(
                child: const Text('ログイン'),
                onPressed: () async {
                  try {
                    // メール/パスワードでログイン
                    final User? user = (await FirebaseAuth.instance
                            .signInWithEmailAndPassword(
                                email: _email, password: _password))
                        .user;
                    if (user != null) print("ログイン成功");
                  } catch (e) {
                    print(e);
                  }
                },
              ),
              ElevatedButton(
                  child: const Text('グループを作成'),
                  // グループを作成する処理を書く
                  onPressed: () async {
                    // groupsを作成
                    DocumentReference docRef = await FirebaseFirestore.instance
                        .collection('groups')
                        .add({});
                    // 作成したドキュメントIDを取得
                    String documentID = docRef.id;
                    // ドキュメントIDに対してgroupIDフィールドを更新
                    await FirebaseFirestore.instance
                        .collection('groups')
                        .doc(documentID)
                        .update({
                      'groupID': documentID,
                    });
                    await prefs.setString('groupID', documentID);
                  }),
              ElevatedButton(
                  child: const Text('userIDを表示'),
                  // グループを作成する処理を書く
                  onPressed: () {
                    print(prefs.getString('userID'));
                  }),
              ElevatedButton(
                  child: const Text('groupIDを表示'),
                  // グループを作成する処理を書く
                  onPressed: () {
                    print(prefs.getString('groupID'));
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
