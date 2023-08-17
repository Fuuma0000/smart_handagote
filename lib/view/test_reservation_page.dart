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
  List<Map<String, dynamic>>? _reservations; // Nullable

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    QuerySnapshot querySnapshot =
        await _firestore.collection('reservations').get();
    List<Map<String, dynamic>> reservations = [];

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
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
    setState(() {
      _reservations = reservations;
    });
  }

  Future<void> _cancelReservation(String reservationId) async {
    await _firestore.collection('reservations').doc(reservationId).delete();
    _loadReservations();
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
        _loadReservations();
      } catch (e) {
        if (kDebugMode) {
          print('Error making reservation: $e');
        }
      }
    }
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
            if (_reservations != null)
              Expanded(
                child: ListView.builder(
                  itemCount: _reservations!.length,
                  itemBuilder: (BuildContext context, int index) {
                    String statusText =
                        _reservations![index]['isReady'] ? '使用可能' : '予約中';
                    return ListTile(
                      title: Text(
                          '${_reservations![index]['userName']} - $statusText'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _cancelReservation(
                              _reservations![index]['reservationId']);
                        },
                      ),
                    );
                  },
                ),
              )
            else
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
