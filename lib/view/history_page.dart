import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_handagote/constant.dart';

import '../logic/firebase_helper.dart';

class HistoryPage extends StatefulWidget {
  String myID;
  HistoryPage({super.key, required this.myID});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
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
          'userId': doc['user_id'],
          'userName': userName,
          'deviceName': deviceName,
          'startTime': doc['start_time'],
        });
      }
    }
    missingLogs.sort((a, b) => b['startTime'].compareTo(a['startTime']));
    return missingLogs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constant.black,
      body: _missingLogWidget(),
    );
  }

  Widget _missingLogWidget() {
    return StreamBuilder<QuerySnapshot>(
      stream: _missingLogsStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('エラー: ${snapshot.error}',
              style: const TextStyle(
                  color: Colors.white)); // エラーが発生した場合にエラーメッセージを表示
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator()); // データがロード中の間、進行中のインジケータを表示
        }
        return FutureBuilder<List<Map<String, dynamic>>>(
          future:
              _fetchMissingLogsData(snapshot.data!), // スナップショットから予約データを非同期で取得
          builder: (BuildContext context,
              AsyncSnapshot<List<Map<String, dynamic>>> dataSnapshot) {
            if (dataSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child:
                      CircularProgressIndicator()); // データがロード中の間、進行中のインジケータを表示
            }

            List<Map<String, dynamic>> reservations =
                dataSnapshot.data ?? []; // ロードされた予約データ

            return _buildMissingLogList(reservations); // 予約データを表示するウィジェットを返す
          },
        );
      },
    );
  }

  Widget _buildMissingLogList(List<Map<String, dynamic>> logs) {
    return Container(
      padding: EdgeInsets.only(top: 20),
      height: MediaQuery.of(context).size.height * 0.8,
      child: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (context, index) {
          // Firestoreから取得したタイムスタンプを変換
          final dynamic startTime = logs[index]['startTime'];
          String timeText;

          // startTimeがnullじゃない場合は開始時間を表示
          if (startTime != null) {
            // タイムスタンプをDateTimeに変換
            DateTime startTime = logs[index]['startTime'].toDate();

            // 予約時間を指定のフォーマットで表示
            String formattedTime = DateFormat('MM/dd  HH:MM').format(startTime);
            timeText = formattedTime;
          } else {
            timeText = '時間の読み込みに失敗しました';
          }

          Color indexColor = (logs[index]['userId'] == widget.myID)
              ? Constant.green
              : Constant.darkGray;

          return Row(
            children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: indexColor,
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Text(timeText,
                      style: const TextStyle(
                          color: Constant.white, fontSize: 20))),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    logs[index]['userName'],
                    style: const TextStyle(color: Constant.white, fontSize: 20),
                  )),
            ],
          );
        },
      ),
    );
  }
}
