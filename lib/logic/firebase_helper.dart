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
      'reservation_time': FieldValue.serverTimestamp(),
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

  // デバイス全てを取得する関数
  Future<Map<String, String>> getAllDevices() async {
    Map<String, String> devices = {};
    QuerySnapshot devicesQuerySnapshot =
        await FirebaseFirestore.instance.collection('devices').get();
    for (var deviceDoc in devicesQuerySnapshot.docs) {
      devices[deviceDoc.id] = deviceDoc['device_name'];
    }
    return devices;
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

  // 使用前or使用中を判定する関数
  Future<bool> isLogExists(String userId) async {
    // logのコレクションにuser_idが一致して、end_timeがnullのドキュメントがあるか検索
    QuerySnapshot logsQuerySnapshot = await FirebaseFirestore.instance
        .collection('logs')
        .where('user_id', isEqualTo: userId)
        .where('end_time', isNull: true)
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

  // usersの自分のドキュメントを取得する関数
  Future<DocumentSnapshot> getUserDoc(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    return userDoc;
  }

  // ユーザをstudent_id で検索する関数
  Future<QuerySnapshot> getUserByStudentId(String studentId) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .where('student_id', isEqualTo: studentId)
        .get();
    return querySnapshot;
  }

  // ユーザーの role を更新する関数
  Future<void> updateRole(String userId, int newRole) async {
    await _firestore.collection('users').doc(userId).update({'role': newRole});
  }

  // 学籍番号が被らないかチェックする関数
  Future<bool> isStudentIdUnique(String studentId) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .where('student_id', isEqualTo: studentId)
        .get();
    if (querySnapshot.size > 0) {
      // 学籍番号が被っていたら false を返す
      return false;
    }
    // 学籍番号が被っていなかったら true を返す
    return true;
  }

  // メールアドレスが被らないかチェックする関数
  Future<bool> isEmailUnique(String email) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    if (querySnapshot.size > 0) {
      // メールアドレスが被っていたら false を返す
      return false;
    }
    // メールアドレスが被っていなかったら true を返す
    return true;
  }

  // 学籍番号が自分以外と被らないかチェックする関数
  Future<bool> isStudentIdUniqueExceptMe(
      String studentId, String userId) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .where('student_id', isEqualTo: studentId)
        // .where('user_id', isNotEqualTo: userId)
        .where(FieldPath.documentId, isNotEqualTo: userId)
        .get();
    return querySnapshot.size <= 0;
  }

  // Firestore にユーザー情報を保存する関数
  Future<void> saveUserInfo(
      String userId, String name, String studentId, String token) async {
    await _firestore.collection('users').doc(userId).set({
      'user_name': name,
      'student_id': studentId,
      'role': 0,
      'token': token,
    });
  }

  // Firestoreにトークンをupdateする関数
  Future<void> updateToken(String userId, String token) async {
    await _firestore.collection('users').doc(userId).update({'token': token});
  }

  // 学籍番号と名前を更新する関数
  Future<void> updateUser(String userId, String name, String studentId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .update({'user_name': name, 'student_id': studentId});
  }
}
