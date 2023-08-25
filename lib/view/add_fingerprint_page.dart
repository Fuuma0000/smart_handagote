import 'package:flutter/material.dart';
import 'package:smart_handagote/constant.dart';

class AddFingerprintPage extends StatefulWidget {
  const AddFingerprintPage({super.key});

  @override
  State<AddFingerprintPage> createState() => _AddFingerprintPageState();
}

class _AddFingerprintPageState extends State<AddFingerprintPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('指紋登録'),
        backgroundColor: Constant.darkGray,
        foregroundColor: Constant.white,
      ),
      backgroundColor: Constant.black,
      body: _addFingerprintWidget(),
    );
  }

  Widget _addFingerprintWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _addBtnWidget('No.1', () {
            // TODO: No.1の指紋登録処理
          }),
          // No.2
          _addBtnWidget('No.2', () {
            // TODO: No.2の指紋登録処理
          }),
        ],
      ),
    );
  }

  Widget _addBtnWidget(String deviceName, GestureTapCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Constant.darkGray,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(deviceName,
                style: const TextStyle(
                    color: Constant.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Icon(Icons.fingerprint, size: 40, color: Constant.white),
          ],
        ),
      ),
    );
  }
}
