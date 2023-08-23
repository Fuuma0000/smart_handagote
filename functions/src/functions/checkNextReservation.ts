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
  // const device_id = (await logRef.get()).data()!.device_id;

  // すでにlogsコレクションに追加されているか確認
  const logDoc = await logsCollection.where('user_id', '==', nextReservationData.user_id).where('start_time', '==', null).get();
  if (!logDoc.empty) {
    // res.status(200).send('success: already added');
    return {
      status: 200,
      message: 'success: already added',
    };
  }

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

  // 通知を送信
  const userDoc = await admin.firestore().collection('users').doc(nextReservationData.user_id).get();
  const userToken = userDoc.data()!.token;
  const messageTitle = '予約の順番が来ました';
  const messageBody = `デバイスID: ${device_id} が使用可能です`;

  await sendNotification(userToken, messageTitle, messageBody);

  return {
    status: 200,
    message: 'success: check next reservation',
  };
};

exports = module.exports = {
  checkNextReservation,
};
