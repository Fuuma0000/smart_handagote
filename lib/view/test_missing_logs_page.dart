import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:smart_handagote/logic/firebase_helper.dart';

import '../constant.dart';

class MissingLogsPage extends StatefulWidget {
  const MissingLogsPage({Key? key}) : super(key: key);

  @override
  _MissingLogsPageState createState() => _MissingLogsPageState();
}

class _MissingLogsPageState extends State<MissingLogsPage> {
  late Stream<QuerySnapshot> _missingLogsStream;

  @override
  void initState() {
    super.initState();
    _missingLogsStream = FirebaseFirestore.instance
        .collection('logs')
        .where(
          'is_turn_off',
          isEqualTo: true,
        ) // 未終了のログをクエリ
        .snapshots();
  }

  // Logsの方から開始前と使用中のユーザーを取得
  Future<List<Map<String, dynamic>>> _fetchMissingLogsData(
      QuerySnapshot snapshot) async {
    // 予約一覧を格納する配列
    List<Map<String, dynamic>> missingLogs = [];

    // 予約一覧を整形
    for (QueryDocumentSnapshot doc in snapshot.docs) {
      dynamic deviceName;
      // ユーザー名を取得
      String userName = await FirebaseHelper().getUserName(doc['user_id']);

      if (doc['device_id'] != null) {
        // はんだごて名を取得
        deviceName = await FirebaseHelper().getDeviceName(doc['device_id']);
      }

      // ユーザーが削除されていたらスキップ
      if (userName != '') {
        missingLogs.add({
          'logId': doc.id,
          'userName': userName,
          'deviceName': deviceName,
          'startTime': doc['start_time'],
        });
      }
    }
    return missingLogs;
  }

  Widget _buildMissingLogList(List<Map<String, dynamic>> logs) {
    return Expanded(
      child: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (BuildContext context, int index) {
          // Firestoreから取得したタイムスタンプを変換
          final dynamic startTime = logs[index]['startTime'];
          String timeText;

          // startTimeがnullじゃない場合は開始時間を表示
          if (startTime != null) {
            // タイムスタンプをDateTimeに変換
            DateTime startTime = logs[index]['startTime'].toDate();

            // 予約時間を指定のフォーマットで表示
            String formattedTime = DateFormat('yyyy/MM/dd').format(startTime);
            timeText = formattedTime;
          } else {
            timeText = '時間の読み込みに失敗しました';
          }

          return ListTile(
            title: Text('ユーザ名: ${logs[index]['userName']}',
                style: const TextStyle(color: Colors.white)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timeText,
                    style: const TextStyle(color: Colors.white)), // Start time
                Text('デバイス名: ${logs[index]['deviceName']}',
                    style: const TextStyle(color: Colors.white)), // Device name
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constant.black,
      body: Center(
        child: Column(
          children: <Widget>[
            const SizedBox(
              height: 50,
            ),
            const Text('切り忘れ一覧', style: TextStyle(color: Colors.white)),
            StreamBuilder<QuerySnapshot>(
              stream: _missingLogsStream,
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('エラー: ${snapshot.error}',
                      style: const TextStyle(
                          color: Colors.white)); // エラーが発生した場合にエラーメッセージを表示
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(); // データがロード中の間、進行中のインジケータを表示
                }
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchMissingLogsData(
                      snapshot.data!), // スナップショットから予約データを非同期で取得
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Map<String, dynamic>>> dataSnapshot) {
                    if (dataSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const CircularProgressIndicator(); // データがロード中の間、進行中のインジケータを表示
                    }

                    List<Map<String, dynamic>> reservations =
                        dataSnapshot.data ?? []; // ロードされた予約データ

                    return _buildMissingLogList(
                        reservations); // 予約データを表示するウィジェットを返す
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
