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
  late Stream<QuerySnapshot>
      _reservationsStream; // Make it 'late' and initialize it

  @override
  void initState() {
    super.initState();
    _reservationsStream = _firestore.collection('reservations').snapshots();
  }

  Future<void> _cancelReservation(String reservationId) async {
    await _firestore.collection('reservations').doc(reservationId).delete();
  }

  Future<List<Map<String, dynamic>>> _fetchReservationsData(
      QuerySnapshot snapshot) async {
    List<Map<String, dynamic>> reservations = [];

    for (QueryDocumentSnapshot doc in snapshot.docs) {
      String userId = doc['user_id'];

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        String userName = userDoc['name'];
        bool isReady = doc['is_ready'] ?? false; // Default to false if not set
        reservations.add({
          'reservationId': doc.id,
          'timestamp': doc['timestamp'],
          'isReady': isReady,
          'userName': userName,
        });
      }
    }

    return reservations;
  }

  Future<void> _makeReservation() async {
    final User? user = FirebaseAuth.instance.currentUser;
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

  Widget _buildReservationList(List<Map<String, dynamic>> reservations) {
    return Expanded(
      child: ListView.builder(
        itemCount: reservations.length,
        itemBuilder: (BuildContext context, int index) {
          String statusText = reservations[index]['isReady'] ? '使用可能' : '予約中';
          return ListTile(
            title: Text('${reservations[index]['userName']} - $statusText'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                _cancelReservation(reservations[index]['reservationId']);
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
            StreamBuilder<QuerySnapshot>(
              stream: _reservationsStream,
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('エラー: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchReservationsData(snapshot.data!),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Map<String, dynamic>>> dataSnapshot) {
                    if (dataSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    List<Map<String, dynamic>> reservations =
                        dataSnapshot.data ?? [];

                    return _buildReservationList(reservations);
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
