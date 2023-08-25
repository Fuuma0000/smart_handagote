import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smart_handagote/constant.dart';
import 'package:smart_handagote/logic/firebase_helper.dart';

import 'components/alertDialog.dart';

class UserEditPage extends StatefulWidget {
  final String userId;
  const UserEditPage({super.key, required this.userId});

  @override
  State<UserEditPage> createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  String _name = '';
  String _studentId = '';

  final Color _textColor = Constant.white;

  Future<void> updateUser() async {
    // 同じ学籍番号の人がいたらダイアログ
    if (await FirebaseHelper()
        .isStudentIdUniqueExceptMe(_studentId, widget.userId)) {
      print('udpate user');
      await FirebaseHelper().updateUser(widget.userId, _name, _studentId);
      AlertDialogHelper.showCustomDialog(
        context: context,
        title: '変更完了',
        message: 'ユーザー情報を変更しました',
        onPressed: () => Navigator.pop(context),
      );
    } else {
      // ignore: use_build_context_synchronously
      AlertDialogHelper.showCustomDialog(
        context: context,
        title: 'エラー',
        message: '同じ学籍番号の人がいます',
        onPressed: () => Navigator.pop(context),
      );
    }
  }

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
      body: FutureBuilder(
        future: FirebaseHelper().getUserDoc(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('データがありません'));
          }

          _name = snapshot.data!['user_name'];
          _studentId = snapshot.data!['student_id'];
          // _email = snapshot.data!['email'];

          return _editUserWidget();
        },
      ),
    );
  }

  Widget _editUserWidget() {
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
              _editForm('名前', _name),
              const SizedBox(height: 20),
              _editForm('学籍番号', _studentId),
              const SizedBox(height: 20),
              // _editForm('メールアドレス', _email),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  await updateUser();
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

  Widget _editForm(String title, String oldText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: TextStyle(color: _textColor, fontSize: 18)),
        ),
        TextFormField(
          initialValue: oldText,
          onChanged: (value) {
            if (title == '名前') {
              _name = value;
            } else {
              _studentId = value;
            }
            // setState(() {
            // });
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
}
