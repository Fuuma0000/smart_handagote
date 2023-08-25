import * as admin from 'firebase-admin';
import { sendNotification } from './notification';
import * as functions from 'firebase-functions';

export const checkNextReservation = async (device_id: string) => {
  const logsCollection = await admin.firestore().collection('logs');
  // 一番古い予約を取得
  const reservationDoc = await admin.firestore().collection('reservations').orderBy('reservation_time', 'asc').limit(1).get();

  if (reservationDoc.empty) {
    //   res.status(200).send('success: no reservation');
    return {
      status: 200,
      message: 'success: no reservation',
    };
  }
  // 一番古い予約を削除
  const nextReservationData = reservationDoc.docs[0].data();
  await reservationDoc.docs[0].ref.delete();

  // 次の順番の人をlogsコレクションに追加
  const logData = {
    user_id: nextReservationData.user_id,
    device_id: device_id,
    start_time: null,
    end_time: null,
    is_turn_off: false,
  };
  await logsCollection.add(logData);
  functions.logger.info('次の人を追加しました');

  // device_idからdevice_nameを取得
  const deviceDoc = await admin.firestore().collection('devices').doc(device_id).get();
  const deviceName = deviceDoc.data()!.device_name;

  // 通知を送信
  const userDoc = await admin.firestore().collection('users').doc(nextReservationData.user_id).get();
  const userToken = userDoc.data()!.token;
  const messageTitle = '予約の順番が来ました';
  const messageBody = `デバイス: ${deviceName} が使用可能です`;

  await sendNotification(userToken, messageTitle, messageBody);

  return {
    status: 200,
    message: 'success: check next reservation',
  };
};

exports = module.exports = {
  checkNextReservation,
};
