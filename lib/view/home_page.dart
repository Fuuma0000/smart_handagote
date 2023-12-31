import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:smart_handagote/constant.dart';

import '../logic/firebase_helper.dart';
import 'components/alert_dialog.dart';

class HomePage extends StatefulWidget {
  final String myID;
  const HomePage({super.key, required this.myID});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _reservationsStream;
  late Stream<QuerySnapshot> _logsStream;
  bool _isLoadReserving = false; // 予約中かどうかを管理するフラグ
  List<String> devices = [
    '7c68efdd-a727-4b51-ba18-a3519164875c',
    '87adfa87-751f-4c68-b078-ad2856833945'
  ];

  @override
  void initState() {
    super.initState();
    _reservationsStream = _firestore.collection('reservations').snapshots();
    _logsStream = _firestore
        .collection('logs')
        .where(
          'end_time',
          isNull: true,
        )
        .snapshots();
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
          'userId': doc['user_id'],
          'userName': userName,
        });
      }
    }

    // 予約一覧をタイムスタンプで昇順にソート
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
      AlertDialogHelper.showCustomDialog(
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
    AlertDialogHelper.showCustomDialog(
        context: context, title: '予約をキャンセルしました', message: '');
  }

// logsのキャンセル処理
  Future<void> _cancelLog(String logId) async {
    // 予約を削除
    await FirebaseHelper().cancelLog(logId);
    if (!mounted) return;
    AlertDialogHelper.showCustomDialog(
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
            _titleWidget('機器一覧'),
            // はんだごて一覧
            _usingWidget(),
            const SizedBox(height: 20),
            // 予約一覧テキスト
            _titleWidget('予約一覧'),
            // 予約一覧
            _allreservationWidget(),
            Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Constant.green,
                        foregroundColor: Constant.white,
                        shape: const CircleBorder(),
                        minimumSize: const Size(60, 60)),
                    onPressed: () {
                      _makeReservation();
                    },
                    child: const Icon(FontAwesomeIcons.plus),
                  ),
                ))
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
        border: Border(
          bottom: BorderSide(color: Colors.white),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, color: Constant.white),
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
          return const SizedBox(
              height: 169,
              child: Center(
                  child:
                      CircularProgressIndicator())); // データがロード中の間、進行中のインジケータを表示
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchLogsData(snapshot.data!), // スナップショットから予約データを非同期で取得
          builder: (BuildContext context,
              AsyncSnapshot<List<Map<String, dynamic>>> dataSnapshot) {
            if (dataSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                  height: 169,
                  child: Center(
                      child:
                          CircularProgressIndicator())); // データがロード中の間、進行中のインジケータを表示
            }

            List<Map<String, dynamic>> logs =
                dataSnapshot.data ?? []; // ロードされた予約データ
            List<Map<String, dynamic>> data = [
              {
                'deviceId': devices[0],
                'userName': '',
                'deviceName': 'No.1',
                'startTime': null,
                'state': '空き',
              },
              {
                'deviceId': devices[1],
                'userName': '',
                'deviceName': 'No.2',
                'startTime': null,
                'state': '空き',
              }
            ];
            // はんだごて1・2の使用状況
            // dataのdeviceIdと一致した場合はデータをdataに追加
            for (var log in logs) {
              for (var d in data) {
                if (log['deviceId'] == d['deviceId']) {
                  d['userName'] = log['userName'];
                  d['deviceName'] = log['deviceName'];
                  d['startTime'] = log['startTime'];
                  if (log['isTurnOff']) {
                    d['state'] = '切り忘れ';
                  } else if (log['startTime'] == null) {
                    d['state'] = '使用前';
                  } else if (log['endTime'] == null) {
                    d['state'] = '使用中';
                  } else {
                    d['state'] = '空き';
                  }
                }
              }
            }

            // TODO: はんだごて表示
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _handagoteWidget(data[0]),
                _handagoteWidget(data[1]),
              ],
            );
          },
        );
      },
    );
  }

  Widget _handagoteWidget(Map<String, dynamic> log) {
    String timeText = '';
    if (log['startTime'] != null) {
      String formattedTime =
          DateFormat('HH:mm').format(log['startTime'].toDate());
      timeText = '$formattedTime ~';
    }
    // borderColorをlog['state']によって変更
    Color borderColor;
    if (log['state'] == '使用前') {
      borderColor = Constant.lightGreen;
    } else if (log['state'] == '使用中') {
      borderColor = Constant.orange;
    } else if (log['state'] == '切り忘れ') {
      borderColor = Constant.lightPink;
    } else {
      borderColor = Constant.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 5,
          color: borderColor,
        ),
        color: Colors.transparent,
      ),
      child: Column(
        children: [
          // はんだごて名
          Text(
            log['deviceName'],
            style: const TextStyle(fontSize: 18, color: Constant.white),
          ),
          const SizedBox(height: 10),
          // 空き状況
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              log['state'],
              style: const TextStyle(
                  fontSize: 18,
                  color: Constant.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          // 名前
          Text(
            log['userName'],
            style: const TextStyle(fontSize: 18, color: Constant.white),
          ),
          const SizedBox(height: 8),
          // 時間
          Text(
            timeText,
            style: const TextStyle(fontSize: 16, color: Constant.white),
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
          return const SizedBox(
              height: 169,
              child: Center(
                  child:
                      CircularProgressIndicator())); // データがロード中の間、進行中のインジケータを表示
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future:
              _fetchReservationsData(snapshot.data!), // スナップショットから予約データを非同期で取得
          builder: (BuildContext context,
              AsyncSnapshot<List<Map<String, dynamic>>> dataSnapshot) {
            if (dataSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                  height: 169,
                  child: Center(
                      child:
                          CircularProgressIndicator())); // データがロード中の間、進行中のインジケータを表示
            }

            List<Map<String, dynamic>> reservations =
                dataSnapshot.data ?? []; // ロードされた予約データ

            return _buildReservationList(reservations); // 予約データを表示するウィジェットを返す
          },
        );
      },
    );
  }

  // 予約一覧を表示するウィジェット
  Widget _buildReservationList(List<Map<String, dynamic>> reservations) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.33,
      child: ListView.builder(
        itemCount: reservations.length,
        itemBuilder: (BuildContext context, int index) {
          // Firestoreから取得したタイムスタンプを変換
          final dynamic timestamp = reservations[index]['reservation_time'];

          // TODO: タイムスタンプがnullの場合はエラーメッセージを表示
          if (timestamp == null || timestamp is! Timestamp) {
            return const Text('Invalid timestamp',
                style: TextStyle(color: Colors.white));
          }
          // タイムスタンプをDateTimeに変換
          DateTime reservationTime =
              reservations[index]['reservation_time'].toDate();

          // 予約時間を指定のフォーマットで表示
          reservations[index]['formattedTime'] =
              DateFormat('yyyy/MM/dd HH:mm').format(reservationTime);

          return _reservationWidget(reservations[index], index + 1);
        },
      ),
    );
  }

  // 予約者一覧
  Widget _reservationWidget(Map<String, dynamic> reservation, int index) {
    bool isMyReservation = (reservation['userId'] == widget.myID);
    Color indexColor = isMyReservation ? Constant.orange : Constant.lightGrey;

    print(
        'username: ${reservation['userName']}, state: ${reservation['state']}');

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
              color: indexColor,
            ),
            child: Text(
              index.toString(),
              style: const TextStyle(
                color: Constant.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Text(reservation['userName'],
              style: const TextStyle(color: Constant.white, fontSize: 18)),
          const Spacer(),
          // 自分の予約の場合は削除ボタンを表示
          if (isMyReservation)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  foregroundColor: Constant.orange,
                  backgroundColor: Constant.darkGray,
                  shape: const CircleBorder(),
                  minimumSize: const Size(60, 60)),
              onPressed: () {
                _cancelReservation(reservation['reservationId']);
              },
              child: const Icon(FontAwesomeIcons.trash),
            ),
        ],
      ),
    );
  }
}
