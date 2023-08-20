/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

admin.initializeApp();

export const startUsing = functions.https.onRequest(async (req, res) => {
  functions.logger.info('startUsing');

  try {
    // usersコレクションの認証
    const { user_id, device_id } = req.body;
    const userDoc = await admin.firestore().collection('users').doc(user_id).get();

    if (!userDoc.exists) {
      res.status(404).send('User not found');
      return;
    }

    const userData = userDoc.data();
    if (userData!.role !== 0) {
      res.status(403).send('User not authorized');
      return;
    }

    // reservationコレクションの確認
    const reservationDocs = await admin.firestore().collection('reservations').get();
    if (!reservationDocs.empty) {
      res.status(403).send('Device is not available');
      return;
    }

    // logsに追加
    const logData = {
      user_id: user_id,
      device_id: device_id,
      start_time: Timestamp.now(),
      is_turn_off: false,
    };

    const logRef = await admin.firestore().collection('logs').add(logData);

    res.status(200).json({ log_id: logRef.id });
  } catch (error) {
    functions.logger.error('Error', error);
    res.status(500).send('Internal Server Error');
  }

  return;
});

// はんだごて使用終了時
export const endUsing = functions.https.onRequest(async (req, res) => {
  try {
    const { log_id } = req.body;

    // logsコレクションのend_timeを更新
    const logRef = admin.firestore().collection('logs').doc(log_id);
    await logRef.update({ end_time: Timestamp.now() });

    // 一番古い予約を取得
    const reservationDoc = await admin.firestore().collection('reservations').where('is_ready', '==', false).orderBy('reservation_time', 'asc').limit(1).get();

    if (reservationDoc.empty) {
      res.status(200).send('success: no reservation');
      return;
    }

    const nextReservationData = reservationDoc.docs[0].data();
    const nextReservationId = reservationDoc.docs[0].id;

    await admin.firestore().collection('reservations').doc(nextReservationId).update({ is_ready: true });

    // 通知を送信
    const userDoc = await admin.firestore().collection('users').doc(nextReservationData.user_id).get();
    const userToken = userDoc.data()!.token;
    const device_id = (await logRef.get()).data()!.device_id;
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

async function sendNotification(userToken: string, messageTitle: string, messageBody: string) {
  const message = {
    notification: {
      title: messageTitle,
      body: messageBody,
    },
    token: userToken,
  };

  try {
    const response = await admin.messaging().send(message);
    functions.logger.info('Notification sent successfully', response);
  } catch (error) {
    functions.logger.error('Error sending notification', error);
  }
}

// テスト用データを挿入
export const insertTestData = functions.https.onRequest(async (req, res) => {
  // usersコレクション
  const users = [
    {
      user_id: '1111',
      name: '山田 太郎',
      role: 0,
      token: 'ea0Ag-HbS6mdm3CGU1Wu74:APA91bFUFtzoQ2lPpi1KHfl23yt5EgDIaXyY-P20lqSrnAsbLmpcRmJqVndk8jnOD3KgyRHy2T2VrRWJgwy3H5U1zPCmxzrrC5VVuwFHXKt6w51TbNmoYx2KC7qzoh7WGOlmDYmpBXXd',
    },
    {
      user_id: '1112',
      name: '田中 一郎',
      role: 1,
      token: 'test_token_2',
    },
    {
      user_id: '1113',
      name: '鈴木 三郎',
      role: 2,
      token: 'test_token_3',
    },
  ];

  const usersRef = admin.firestore().collection('users');
  users.forEach(async (user) => {
    await usersRef.doc(user.user_id).set(user);
  });

  return;
});
