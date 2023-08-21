import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_handagote/logic/firebase_helper.dart';

import '../constant.dart';
import 'components/dialog.dart';

class TestReservationPage extends StatefulWidget {
  const TestReservationPage({Key? key}) : super(key: key);

  @override
  _TestReservationPageState createState() => _TestReservationPageState();
}

class _TestReservationPageState extends State<TestReservationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _reservationsStream;
  late Stream<QuerySnapshot> _logsStream;
  bool _isLoadReserving = false; // 予約中かどうかを管理するフラグ

  @override
  void initState() {
    super.initState();
    _reservationsStream = _firestore.collection('reservations').snapshots();
    _logsStream = _firestore.collection('logs').snapshots();
  }

  // Reservationのキャンセル処理
  Future<void> _cancelReservation(String reservationId) async {
    // 予約を削除
    await FirebaseHelper().cancelReservation(reservationId);
    if (!mounted) return;
    DialogHelper.showCustomDialog(context, '予約をキャンセルしました', '');
  }

  // logsのキャンセル処理
  Future<void> _cancelLog(String logId) async {
    // 予約を削除
    await FirebaseHelper().cancelLog(logId);
    if (!mounted) return;
    DialogHelper.showCustomDialog(context, '予約をキャンセルしました', '');
  }

  // 予約一覧を取得 (Firestore から取得したデータを整形)
  Future<List<Map<String, dynamic>>> _fetchReservationsData(
      QuerySnapshot snapshot) async {
    // 予約一覧を格納する配列
    List<Map<String, dynamic>> reservations = [];

    // 予約一覧を整形
    for (QueryDocumentSnapshot doc in snapshot.docs) {
      // ユーザー名を取得
      String userName = await FirebaseHelper().getUserName(doc['user_id']);
      // ユーザーが存在していたら予約一覧に追加
      if (userName != '') {
        reservations.add({
          'reservationId': doc.id,
          'timestamp': doc['timestamp'],
          'userName': userName,
        });
      }
    }

    // 予約一覧をタイムスタンプで昇順にソート
    // TODO:_TypeError (type 'Null' is not a subtype of type 'Timestamp' of 'other')になる発生条件が不明
    reservations.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
    return reservations;
  }

  // Logsの方から開始前と使用中のユーザーを取得
  Future<List<Map<String, dynamic>>> _fetchLogsData(
      QuerySnapshot snapshot) async {
    // 予約一覧を格納する配列
    List<Map<String, dynamic>> logs = [];

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
        if (doc['end_time'] == null) {
          logs.add({
            'logId': doc.id,
            'userName': userName,
            'deviceName': deviceName,
            'startTime': doc['start_time'],
            'isTunrOff': doc['is_turn_off'],
          });
        }
      }
    }
    return logs;
  }

  // 予約を作成
  Future<void> _makeReservation() async {
    setState(() {
      _isLoadReserving = true;
    });
    // 現在ログインしているユーザーを取得
    final User? user = FirebaseAuth.instance.currentUser;
    // ユーザーが存在していたら予約を作成
    if (user != null) {
      try {
        // 権限があるか確認
        if (await _isAuthorized(user.uid)) {
          // すでに予約している場合は予約不可
          if (await _isReservationAllowed()) {
            int numberOfLogs = await FirebaseHelper().getNumberOfLogs();
            int numberOfDevices = await FirebaseHelper().getNumberOfDevices();

            if (numberOfLogs < numberOfDevices) {
              if (!mounted) return;
              DialogHelper.showCustomDialog(context, '予約せずに使用可能です', '');
            } else {
              await FirebaseHelper().addReservationEntry(user.uid);
              if (!mounted) return;
              DialogHelper.showCustomDialog(context, '予約しました', '');
            }
          }
        }
      } catch (e) {
        if (!mounted) return;
        DialogHelper.showCustomDialog(context, 'エラー', '');
        print('Error making reservation: $e');
      } finally {
        setState(() {
          _isLoadReserving = false;
        });
      }
    }
  }

  // 予約一覧を表示するウィジェット
  Widget _buildReservationList(List<Map<String, dynamic>> reservations) {
    return Expanded(
      child: ListView.builder(
        itemCount: reservations.length,
        itemBuilder: (BuildContext context, int index) {
          // Firestoreから取得したタイムスタンプを変換
          final dynamic timestamp = reservations[index]['timestamp'];

          // タイムスタンプがnullの場合はエラーメッセージを表示
          if (timestamp == null || timestamp is! Timestamp) {
            return ListTile(
              title: Text('${reservations[index]['userName']}'),
              subtitle: const Text('Invalid timestamp',
                  style: TextStyle(
                      color: Colors.white)), // Display an error message
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () {
                  _cancelReservation(reservations[index]
                      ['reservationId']); // Cancel reservation
                },
              ),
            );
          }
          // タイムスタンプをDateTimeに変換
          DateTime reservationTime = reservations[index]['timestamp'].toDate();

          // 予約時間を指定のフォーマットで表示
          String formattedTime =
              DateFormat('yyyy/MM/dd HH:mm').format(reservationTime);

          return ListTile(
            title: Text('${reservations[index]['userName']}',
                style: const TextStyle(color: Colors.white)),
            subtitle: Text('予約時間: $formattedTime',
                style: const TextStyle(color: Colors.white)), // 予約時間を表示
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () {
                _cancelReservation(
                    reservations[index]['reservationId']); // 予約をキャンセル
              },
            ),
          );
        },
      ),
    );
  }

  // 使用中一覧を表示するウィジェット
  Widget _buildLogList(List<Map<String, dynamic>> logs) {
    return Expanded(
      child: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (BuildContext context, int index) {
          // Firestoreから取得したタイムスタンプを変換
          final dynamic startTime = logs[index]['startTime'];
          String statusMessage = startTime != null
              ? (logs[index]['isTunrOff'] ? '切り忘れ' : '使用中')
              : '開始前';
          String timeText = '開始時間: ';

          // startTimeがnullじゃない場合は開始時間を表示
          if (startTime != null) {
            // タイムスタンプをDateTimeに変換
            DateTime startTime = logs[index]['startTime'].toDate();

            // 予約時間を指定のフォーマットで表示
            String formattedTime =
                DateFormat('yyyy/MM/dd HH:mm').format(startTime);
            timeText = '$timeText$formattedTime';
          } else {
            timeText = '$timeText未定';
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
                Text('ステータス: $statusMessage',
                    style:
                        const TextStyle(color: Colors.white)), // Status message
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () {
                _cancelLog(logs[index]['logId']); // Cancel reservation
              },
            ),
          );
        },
      ),
    );
  }

  // 予約可能かどうかをチェックする関数
  Future<bool> _isReservationAllowed() async {
    // 現在ログインしているユーザーを取得
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return false;
      DialogHelper.showCustomDialog(context, 'ログインしていません', '');
      return false; // ユーザーがログインしていない場合は予約不可
    }

    // logのコレクションにuser_idが一致して、start_timeとent_timeがnullのドキュメントがあるか検索
    bool isLogExists = await FirebaseHelper().isLogExists(user.uid);
    if (isLogExists) {
      if (!mounted) return false;
      DialogHelper.showCustomDialog(context, '開始前です', '');
      return false;
    }

    // reservationsのコレクションにuser_idが一致するドキュメントがあるか検索
    bool isReservationExists =
        await FirebaseHelper().isReservationExists(user.uid);
    if (isReservationExists) {
      if (!mounted) return false;
      DialogHelper.showCustomDialog(context, 'すでに予約しています', '');
      return false;
    }
    return true;
  }

  // 権限があるかどうかをチェックする関数
  Future<bool> _isAuthorized(userId) async {
    // ユーザーの権限を取得
    int role = await FirebaseHelper().getUserRole(userId);
    if (role == 1 || role == 2) {
      return true; // 研修終了と管理者の場合は権限あり
    }
    if (!mounted) return false;
    DialogHelper.showCustomDialog(context, '権限がありません', '');
    return false; // 研修前の場合は権限なし
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constant.black,
      body: Center(
        child: Column(
          children: <Widget>[
            const SizedBox(
              height: 20,
            ),
            const Text('新しい予約を作成', style: TextStyle(color: Colors.white)),
            ElevatedButton(
              onPressed:
                  _isLoadReserving ? null : _makeReservation, // ボタンを押したときの処理
              child: _isLoadReserving
                  ? const CircularProgressIndicator() // クルクル回るインジケータを表示
                  : const Text('予約する', style: TextStyle(color: Colors.black)),
            ),

            const SizedBox(height: 20),
            const Text('使用中一覧', style: TextStyle(color: Colors.white)),
            StreamBuilder<QuerySnapshot>(
              stream: _logsStream, // リアルタイムで予約データを取得するストリーム
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
                  future:
                      _fetchLogsData(snapshot.data!), // スナップショットから予約データを非同期で取得
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Map<String, dynamic>>> dataSnapshot) {
                    if (dataSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const CircularProgressIndicator(); // データがロード中の間、進行中のインジケータを表示
                    }

                    List<Map<String, dynamic>> logs =
                        dataSnapshot.data ?? []; // ロードされた予約データ

                    return _buildLogList(logs); // 予約データを表示するウィジェットを返す
                  },
                );
              },
            ),
            const Text('予約一覧', style: TextStyle(color: Colors.white)),
            // StreamBuilder で Firestore のデータを監視
            StreamBuilder<QuerySnapshot>(
              stream: _reservationsStream, // リアルタイムで予約データを取得するストリーム
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
                  future: _fetchReservationsData(
                      snapshot.data!), // スナップショットから予約データを非同期で取得
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Map<String, dynamic>>> dataSnapshot) {
                    if (dataSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const CircularProgressIndicator(); // データがロード中の間、進行中のインジケータを表示
                    }

                    List<Map<String, dynamic>> reservations =
                        dataSnapshot.data ?? []; // ロードされた予約データ

                    return _buildReservationList(
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
