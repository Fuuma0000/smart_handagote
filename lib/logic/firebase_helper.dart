import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reservationの予約をキャンセルする関数
  Future<void> cancelReservation(String reservationId) async {
    // 予約を削除
    await _firestore.collection('reservations').doc(reservationId).delete();
  }

  // logsの予約をキャンセルする関数
  Future<void> cancelLog(String logId) async {
    // 予約を削除
    await _firestore.collection('logs').doc(logId).delete();
  }

  // 使用中のログの数を取得
  Future<int> getNumberOfLogs() async {
    QuerySnapshot logsQuerySnapshot = await FirebaseFirestore.instance
        .collection('logs')
        .where('end_time', isNull: true)
        .get();
    return logsQuerySnapshot.size;
  }

  // 利用可能なはんだごての数を取得
  Future<int> getNumberOfDevices() async {
    QuerySnapshot devicesQuerySnapshot =
        await FirebaseFirestore.instance.collection('devices').get();
    return devicesQuerySnapshot.size;
  }

  // 新しい予約エントリを追加
  Future<void> addReservationEntry(String userId) async {
    await _firestore.collection('reservations').add({
      'user_id': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ユーザ名を取得する関数
  Future<String> getUserName(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc['user_name'];
    }
    return '';
  }

  // デバイス名を取得する関数
  Future<String> getDeviceName(String deviceId) async {
    DocumentSnapshot deviceDoc =
        await _firestore.collection('devices').doc(deviceId).get();
    if (deviceDoc.exists) {
      return deviceDoc['device_name'];
    }
    return '';
  }

  // reservationsのコレクションにuser_idが一致するドキュメントがあるか検索する関数
  Future<bool> isReservationExists(String userId) async {
    QuerySnapshot reservationsQuerySnapshot = await FirebaseFirestore.instance
        .collection('reservations')
        .where('user_id', isEqualTo: userId)
        .get();
    if (reservationsQuerySnapshot.size > 0) {
      // 予約がある場合は予約不可
      return true;
    }
    // 予約がない場合は予約可能
    return false;
  }

  // logsのコレクションにuser_idが一致するドキュメントがあるか検索する関数
  Future<bool> isLogExists(String userId) async {
    QuerySnapshot logsQuerySnapshot = await FirebaseFirestore.instance
        .collection('logs')
        .where('user_id', isEqualTo: userId)
        .get();
    if (logsQuerySnapshot.size > 0) {
      // 予約がある場合は予約不可
      return true;
    }
    // 予約がない場合は予約可能
    return false;
  }

  // ユーザーの権限を取得する関数
  Future<int> getUserRole(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc['role'];
    }
    return 0;
  }
}
