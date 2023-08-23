import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_handagote/constant.dart';

import '../logic/firebase_helper.dart';
import 'components/dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  // 使用前か確認する関数
  Future<bool> _isLogExists(String userId) async {
    // logのコレクションにuser_idが一致して、end_timeがnullのドキュメントがあるか検索
    bool isLogExists = await FirebaseHelper().isLogExists(userId);
    return isLogExists; //
  }

  // 使用中のログにあるか検索する関数
  Future<bool> _isReservationExists(String userId) async {
    // 使用中のログにあるか検索
    bool isReservationExists =
        await FirebaseHelper().isReservationExists(userId);
    return isReservationExists; // 予約が存在する場合はfalse 予約が存在しない場合はtrue
  }

  // 権限があるかどうかをチェックする関数
  Future<bool> _isAuthorized(userId) async {
    // ユーザーの権限を取得
    int role = await FirebaseHelper().getUserRole(userId);
    if (role == 1 || role == 2) {
      return true; // 研修終了と管理者の場合は権限あり
    }
    return false; // 研修前の場合は権限なし
  }

  // はんだごてが空いているかどうかをチェックする関数
  Future<bool> _isDeviceAvailable() async {
    // はんだごての数を取得
    int numberOfDevices = await FirebaseHelper().getNumberOfDevices();
    // 使用中のログの数を取得
    int numberOfLogs = await FirebaseHelper().getNumberOfLogs();
    if (numberOfLogs < numberOfDevices) {
      return true; // はんだごてが空いている場合はtrue
    }
    return false; // はんだごてが空いていない場合はfalse
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
          'reservation_time': doc['reservation_time'],
          'userName': userName,
        });
      }
    }

    // 予約一覧をタイムスタンプで昇順にソート
    // TODO:_TypeError (type 'Null' is not a subtype of type 'Timestamp' of 'other')になる発生条件が不明
    reservations
        .sort((a, b) => a['reservation_time'].compareTo(b['reservation_time']));
    return reservations;
  }

  // 予約を作成
  Future<void> _makeReservation() async {
    setState(() {
      _isLoadReserving = true;
    });
    String title = '予約不可';
    String message = '';
    try {
      // 現在ログインしているユーザーを取得
      final User? user = FirebaseAuth.instance.currentUser;
      // ユーザーが存在しなかったら処理を終了
      if (user == null) {
        message = 'ログインしていません';
        return;
      }
      bool isAuthorized = await _isAuthorized(user.uid);
      // 権限があるか確認
      if (!isAuthorized) {
        message = '権限がありません';
        return;
      }
      // logに存在する場合は予約不可
      bool isLogExists = await _isLogExists(user.uid);
      if (isLogExists) {
        message = '使用中一覧に存在してます';
        return;
      }
      // すでに予約している場合は予約不可
      bool isReservationAllowed = await _isReservationExists(user.uid);
      if (isReservationAllowed) {
        message = 'すでに予約しています';
        return;
      }
      // はんだごてが空いているか確認
      bool isDeviceAvailable = await _isDeviceAvailable();
      if (isDeviceAvailable) {
        message = 'はんだごてが空いています';
        return;
      }
      // データを追加
      await FirebaseHelper().addReservationEntry(user.uid);
      title = '予約完了';
      message = '予約しました';
    } catch (e) {
      title = 'エラー';
      message = '予約に失敗しました';
      print('Error making reservation: $e');
    } finally {
      DialogHelper.showCustomDialog(
          context: context, title: title, message: message);
      setState(() {
        _isLoadReserving = false;
      });
    }
  }

  // Reservationのキャンセル処理
  Future<void> _cancelReservation(String reservationId) async {
    // 予約を削除
    await FirebaseHelper().cancelReservation(reservationId);
    if (!mounted) return;
    DialogHelper.showCustomDialog(
        context: context, title: '予約をキャンセルしました', message: '');
  }

// logsのキャンセル処理
  Future<void> _cancelLog(String logId) async {
    // 予約を削除
    await FirebaseHelper().cancelLog(logId);
    if (!mounted) return;
    DialogHelper.showCustomDialog(
        context: context, title: '予約をキャンセルしました', message: '');
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
            'deviceId': doc['device_id'],
            'deviceName': deviceName,
            'startTime': doc['start_time'],
            'isTurnOff': doc['is_turn_off'],
          });
        }
      }
    }
    return logs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constant.black,
      body: Center(
        child: Column(
          children: [
            // はんだごて一覧テキスト
            _titleWidget('はんだごて一覧'),
            // はんだごて一覧
            _usingWidget(),
            const SizedBox(height: 20),
            // 予約一覧テキスト
            _titleWidget('予約一覧'),
            // 予約一覧
            _allreservationWidget(),
          ],
        ),
      ),
    );
  }

  Widget _titleWidget(String title) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white)),
      ),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, color: Constant.lightGray),
      ),
    );
  }

  // はんだごて一覧
  Widget _usingWidget() {
    return StreamBuilder<QuerySnapshot>(
      stream: _logsStream, // リアルタイムで予約データを取得するストリーム
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('エラー: ${snapshot.error}',
              style: const TextStyle(
                  color: Colors.white)); // エラーが発生した場合にエラーメッセージを表示
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // データがロード中の間、進行中のインジケータを表示
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchLogsData(snapshot.data!), // スナップショットから予約データを非同期で取得
          builder: (BuildContext context,
              AsyncSnapshot<List<Map<String, dynamic>>> dataSnapshot) {
            if (dataSnapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(); // データがロード中の間、進行中のインジケータを表示
            }

            List<Map<String, dynamic>> logs =
                dataSnapshot.data ?? []; // ロードされた予約データ

            // TODO: はんだごて表示
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _handagoteWidget(logs[0]),
                _handagoteWidget(logs[1]),
              ],
            );
          },
        );
      },
    );
  }

  Widget _handagoteWidget(Map<String, dynamic> log) {
    String timeText = '未定';
    if (log['startTime'] != null) {
      String formattedTime =
          DateFormat('HH:mm').format(log['startTime'].toDate());
      timeText = '$formattedTime ~';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Constant.darkGray,
      ),
      child: Column(
        children: [
          // はんだごて名
          Text(
            log['deviceName'],
            style: const TextStyle(
              fontSize: 18,
              color: Constant.lightGray,
            ),
          ),
          const SizedBox(height: 10),
          // 空き状況
          Text(
            log['isTurnOff'] ? '切り忘れ' : '使用中',
            style: const TextStyle(
              fontSize: 18,
              color: Constant.lightGray,
            ),
          ),
          // 名前
          Text(
            log['userName'],
            style: const TextStyle(
              fontSize: 18,
              color: Constant.lightGray,
            ),
          ),
          // 時間
          Text(
            timeText,
            style: const TextStyle(
              fontSize: 16,
              color: Constant.lightGray,
            ),
          ),
        ],
      ),
    );
  }

  // 予約一覧全体
  Widget _allreservationWidget() {
    return StreamBuilder<QuerySnapshot>(
      stream: _reservationsStream, // リアルタイムで予約データを取得するストリーム
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
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
              _fetchReservationsData(snapshot.data!), // スナップショットから予約データを非同期で取得
          builder: (BuildContext context,
              AsyncSnapshot<List<Map<String, dynamic>>> dataSnapshot) {
            if (dataSnapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(); // データがロード中の間、進行中のインジケータを表示
            }

            List<Map<String, dynamic>> reservations =
                dataSnapshot.data ?? []; // ロードされた予約データ

            // TODO: 予約者一覧！
            return _buildReservationList(reservations); // 予約データを表示するウィジェットを返す
          },
        );
      },
    );
  }

  // 予約一覧を表示するウィジェット
  Widget _buildReservationList(List<Map<String, dynamic>> reservations) {
    return Expanded(
      child: ListView.builder(
        itemCount: reservations.length,
        itemBuilder: (BuildContext context, int index) {
          // Firestoreから取得したタイムスタンプを変換
          final dynamic timestamp = reservations[index]['reservation_time'];

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
          DateTime reservationTime =
              reservations[index]['reservation_time'].toDate();

          // 予約時間を指定のフォーマットで表示
          String formattedTime =
              DateFormat('yyyy/MM/dd HH:mm').format(reservationTime);

          return _reservationWidget(reservations[index], index + 1);
        },
      ),
    );
  }

  // 予約者一覧
  Widget _reservationWidget(Map<String, dynamic> reservation, int index) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Constant.darkGray,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Constant.black,
            ),
            child: Text(
              index.toString(),
              style: const TextStyle(color: Constant.lightGray, fontSize: 18),
            ),
          ),
          const SizedBox(width: 20),
          Text(reservation['userName'],
              style: const TextStyle(color: Constant.lightGray, fontSize: 18))
        ],
      ),
    );
  }
}
