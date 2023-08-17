import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TestReservationPage extends StatefulWidget {
  const TestReservationPage({Key? key}) : super(key: key);

  @override
  _TestReservationPageState createState() => _TestReservationPageState();
}

class _TestReservationPageState extends State<TestReservationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _reservationsStream;

  @override
  void initState() {
    super.initState();
    _reservationsStream = _firestore.collection('reservations').snapshots();
  }

  // キャンセルボタンを押したときの処理
  Future<void> _cancelReservation(String reservationId) async {
    // 予約を削除
    await _firestore.collection('reservations').doc(reservationId).delete();
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
        bool isReady = doc['is_ready'];
        reservations.add({
          'reservationId': doc.id,
          'timestamp': doc['timestamp'],
          'isReady': isReady,
          'userName': userName,
        });
      }
    }

    // 予約一覧をタイムスタンプで昇順にソート
    reservations.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
    return reservations;
  }

  // 予約を作成
  Future<void> _makeReservation() async {
    // 現在ログインしているユーザーを取得
    final User? user = FirebaseAuth.instance.currentUser;
    // ユーザーが存在していたら予約を作成
    if (user != null) {
      try {
        await _firestore.collection('reservations').add({
          'user_id': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'is_ready': false,
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error making reservation: $e');
        }
      }
    }
  }

  // 予約一覧を表示するウィジェット
  Widget _buildReservationList(List<Map<String, dynamic>> reservations) {
    return Expanded(
      child: ListView.builder(
        itemCount: reservations.length,
        itemBuilder: (BuildContext context, int index) {
          String statusText =
              reservations[index]['isReady'] ? '使用可能' : '予約中'; // 予約の状態を表すテキスト
          return ListTile(
            title: Text('${reservations[index]['userName']} - $statusText'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reservation')),
      body: Center(
        child: Column(
          children: <Widget>[
            const Text('新しい予約を作成'),
            ElevatedButton(
              onPressed: _makeReservation,
              child: const Text('予約する'),
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