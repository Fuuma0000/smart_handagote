import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smart_handagote/constant.dart';
import 'package:smart_handagote/view/components/checkDialog.dart';
import 'package:smart_handagote/view/components/inputDialog.dart';
import 'package:smart_handagote/view/sign_in_page.dart';
import 'package:smart_handagote/view/test_notification.dart';
import 'package:smart_handagote/view/user_edit_page.dart';

import 'add_device_page.dart';

class SettingPage extends StatefulWidget {
  String myID;
  SettingPage({super.key, required this.myID});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  String name = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constant.black,
      body: Column(
        children: [
          const SizedBox(height: 40),
          _userSettingBtnWidget(),
          _settingBtnWidget(
            '指紋',
            FontAwesomeIcons.fingerprint,
            Constant.grey,
            () {
              // TODO: 指紋追加
            },
          ),
          _settingBtnWidget(
            'はんだごて追加',
            FontAwesomeIcons.circlePlus,
            Constant.grey,
            () async {
              // TODO: はんだごて追加
            },
          ),
          _settingBtnWidget(
            'ユーザー承認',
            FontAwesomeIcons.check,
            Constant.grey,
            () async {
              // TODO: ユーザー承認
              final result = await DialogUtils.showEditingDialog(context, name);
              setState(() {
                name = result ?? name;
              });
            },
          ),
          // ログアウト
          _settingBtnWidget(
              'ログアウト', FontAwesomeIcons.arrowRightFromBracket, Constant.pink,
              () {
            CheckDialogHelper.showCustomDialog(
                context: context,
                title: 'ログアウトしますか？',
                message: '',
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignInPage()));
                });
          }),
        ],
      ),
    );
  }

  Widget _userSettingBtnWidget() {
    return InkWell(
      onTap: () {
        // TODO: ユーザー設定
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => (UserEditPage(
                      userId: widget.myID,
                    ))));
      },
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Constant.grey,
          borderRadius: const BorderRadius.all(Radius.circular(14)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: const Row(
          children: [
            Icon(FontAwesomeIcons.solidUser),
            Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ユーザー設定',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                SizedBox(height: 4),
                Text('名前・メールアドレス・パスワード・学籍番号', style: TextStyle(fontSize: 12)),
              ],
            ),
            Spacer(),
            Icon(FontAwesomeIcons.angleRight),
          ],
        ),
      ),
    );
  }

  Widget _settingBtnWidget(String title, IconData icon, Color backgroundColor,
      GestureTapCallback onPressed) {
    Color textColor =
        (backgroundColor == Constant.pink) ? Constant.white : Constant.black;

    return InkWell(
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.all(Radius.circular(14)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Icon(icon),
            const Spacer(flex: 1),
            Text(title,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: textColor)),
            const Spacer(flex: 4),
            const Icon(FontAwesomeIcons.angleRight),
          ],
        ),
      ),
    );
  }
}
