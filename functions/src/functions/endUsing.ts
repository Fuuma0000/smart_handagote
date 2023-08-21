import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
const sendNotification = require('./notification');

// はんだごて使用終了時
export const endUsing = functions.https.onRequest(async (req, res) => {
  try {
    const { log_id } = req.body;

    const logsCollection = await admin.firestore().collection('logs');

    // logsコレクションのend_timeを更新
    const logRef = logsCollection.doc(log_id);
    await logRef.update({ end_time: Timestamp.now() });

    // 一番古い予約を取得
    const reservationDoc = await admin.firestore().collection('reservations').orderBy('reservation_time', 'asc').limit(1).get();

    if (reservationDoc.empty) {
      res.status(200).send('success: no reservation');
      return;
    }

    const nextReservationData = reservationDoc.docs[0].data();
    const device_id = (await logRef.get()).data()!.device_id;

    // 次の順番の人をlogsコレクションに追加
    const logData = {
      user_id: nextReservationData.user_id,
      device_id: device_id,
      start_time: null,
      end_time: null,
      is_turn_off: false,
    };
    await logsCollection.add(logData);

    // 通知を送信
    const userDoc = await admin.firestore().collection('users').doc(nextReservationData.user_id).get();
    const userToken = userDoc.data()!.token;
    const messageTitle = '予約の順番が来ました';
    const messageBody = `デバイスID: ${device_id} が使用可能です`;

    await sendNotification(userToken, messageTitle, messageBody);
    res.status(200).send('operation success');
  } catch (error) {
    functions.logger.error('Error', error);
    res.status(500).send('Internal Server Error');
  }
  return;
});
