import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'components/dialog.dart';

class TestReservationPage extends StatefulWidget {
  const TestReservationPage({Key? key}) : super(key: key);

  @override
  _TestReservationPageState createState() => _TestReservationPageState();
}

class _TestReservationPageState extends State<TestReservationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _reservationsStream;
  bool _isLoadReserving = false; // 予約中かどうかを管理するフラグ

  @override
  void initState() {
    super.initState();
    _reservationsStream = _firestore.collection('reservations').snapshots();
  }

  // キャンセルボタンを押したときの処理
  Future<void> _cancelReservation(String reservationId) async {
    // 予約を削除
    await _firestore.collection('reservations').doc(reservationId).delete();
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
      String userId = doc['user_id'];

      // ユーザー名を取得
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      // ユーザーが削除されていたらスキップ
      if (userDoc.exists) {
        String userName = userDoc['name'];
        reservations.add({
          'reservationId': doc.id,
          'timestamp': doc['timestamp'],
          'userName': userName,
        });
      }
    }

    // 予約一覧をタイムスタンプで昇順にソート
    // TODO:_TypeError (type 'Null' is not a subtype of type 'Timestamp' of 'other')
    reservations.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
    return reservations;
  }

  // Logsの方から現在使用中

  // 予約を作成
  // TODO: 押した時にlogsのend_timeがnullのやつの数がはんだごての個数以下ならlogsに追加
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
            await _firestore.collection('reservations').add({
              'user_id': user.uid,
              'timestamp': FieldValue.serverTimestamp(),
            });
            if (!mounted) return;
            DialogHelper.showCustomDialog(context, '予約しました', '');
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
              subtitle:
                  const Text('Invalid timestamp'), // Display an error message
              trailing: IconButton(
                icon: const Icon(Icons.delete),
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
            title: Text('${reservations[index]['userName']}'),
            subtitle: Text('予約時間: $formattedTime'), // 予約時間を表示
            trailing: IconButton(
              icon: const Icon(Icons.delete),
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
    QuerySnapshot logsQuerySnapshot = await FirebaseFirestore.instance
        .collection('logs')
        .where('user_id', isEqualTo: user.uid)
        .where('start_time', isNull: true)
        .where('end_time', isNull: true)
        .get();
    if (logsQuerySnapshot.size > 0) {
      if (!mounted) return false;
      DialogHelper.showCustomDialog(context, '開始前です', '');
      return false;
    }

    // reservationsのコレクションにuser_idが一致するドキュメントがあるか検索
    QuerySnapshot reservationsQuerySnapshot = await FirebaseFirestore.instance
        .collection('reservations')
        .where('user_id', isEqualTo: user.uid)
        .get();
    if (reservationsQuerySnapshot.size > 0) {
      if (!mounted) return false;
      DialogHelper.showCustomDialog(context, 'すでに予約しています', '');
      return false;
    }
    return true;
  }

  // 権限があるかどうかをチェックする関数
  Future<bool> _isAuthorized(userId) async {
    // ユーザーの権限を取得
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      int role = userDoc['role'];
      if (role == 1 || role == 2) {
        return true; // 研修終了と管理者の場合は権限あり
      }
    }
    if (!mounted) return false;
    DialogHelper.showCustomDialog(context, '権限がありません', '');

    return false; // 研修前の場合は権限なし
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reservation')),
      body: Center(
        child: Column(
          children: <Widget>[
            const Text('新しい予約を作成'),
            ElevatedButton(
              onPressed:
                  _isLoadReserving ? null : _makeReservation, // ボタンを押したときの処理
              child: _isLoadReserving
                  ? const CircularProgressIndicator() // クルクル回るインジケータを表示
                  : const Text('予約する'),
            ),

            const SizedBox(height: 20),
            const Text('予約一覧'),
            // StreamBuilder で Firestore のデータを監視
            StreamBuilder<QuerySnapshot>(
              stream: _reservationsStream, // リアルタイムで予約データを取得するストリーム
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text(
                      'エラー: ${snapshot.error}'); // エラーが発生した場合にエラーメッセージを表示
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
