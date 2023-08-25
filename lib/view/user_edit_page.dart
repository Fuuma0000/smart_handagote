import 'package:flutter/material.dart';
import 'package:smart_handagote/constant.dart';

class UserEditPage extends StatefulWidget {
  final String userId;
  const UserEditPage({super.key, required this.userId});

  @override
  State<UserEditPage> createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  String _name = '';
  String _email = '';
  String _studentId = '';

  TextEditingController _nameController = TextEditingController();
  TextEditingController _studentIdController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  final Color _textColor = Constant.white;

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
      body: _editUserWidget(),
    );
  }

  Widget _editUserWidget() {
    return Center(
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
            _editForm('名前', '名前', _nameController),
            const SizedBox(height: 20),
            _editForm('学籍番号', '学籍番号', _studentIdController),
            const SizedBox(height: 20),
            _editForm('メールアドレス', 'メールアドレス', _emailController),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _email = _emailController.text;
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
    );
  }

  Widget _editForm(
      String title, String oldText, TextEditingController controller) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: _textColor)),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Constant.white,
            hintText: oldText,
            hintStyle: TextStyle(color: Constant.darkGray),
          ),
        ),
      ],
    );
  }
}
