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
    const { user_id, device_id } = req.body;
    const reservationCollection = await admin.firestore().collection('reservations');
    const logsCollection = await admin.firestore().collection('logs');
    let log_id;

    // usersコレクションの認証
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

    // logsに追加されているか確認（自分の予約の順番が来ている場合）
    const myLogDoc = await logsCollection.where('user_id', '==', user_id).where('start_time', '==', null).get();
    if (!myLogDoc.empty) {
      const logDocRef = logsCollection.doc(myLogDoc.docs[0].id);
      await logDocRef.update({ device_id: device_id, start_time: Timestamp.now() });
      log_id = myLogDoc.docs[0].id;
    } else {
      // reservationsコレクションのチェック（他の人の予約が来ている場合）
      const reservationDocs = await reservationCollection.get();
      if (!reservationDocs.empty) {
        res.status(403).send('reservation exists');
        return;
      }

      // logsコレクションに追加
      const logData = {
        user_id: user_id,
        device_id: device_id,
        start_time: Timestamp.now(),
        end_time: null,
        is_turn_off: false,
      };
      const logRef = await logsCollection.add(logData);
      log_id = logRef.id;
    }

    res.status(200).json({ log_id: log_id });
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

// 切り忘れ検知時の処理
export const alert = functions.https.onRequest(async (req, res) => {
  try {
    const { user_id, device_id, log_id } = req.body;

    // logs/{log_id}のis_turn_offを更新
    const logDoc = await admin.firestore().collection('logs').doc(log_id);
    await logDoc.update({ is_turn_off: true });

    // 通知
    const adminDocs = await admin.firestore().collection('users').where('role', '==', 2).get();
    const adminTokens = adminDocs.docs.map((doc) => doc.data().token);
    const userDoc = await admin.firestore().collection('users').doc(user_id).get();
    const userToken = userDoc.data()!.token;

    const messageTitle = '切り忘れが発生しました';
    const messageBody = `デバイスID: ${device_id} が切り忘れました`;

    // await Promise.all(adminTokens.map((token) => sendNotification(token, messageTitle, messageBody)));
    await adminTokens.map((token) => sendNotification(token, messageTitle, messageBody));
    await sendNotification(userToken, messageTitle, messageBody);

    res.status(200).send('operation success');
  } catch (error) {
    functions.logger.error('Error', error);
    res.status(500).send('Internal Server Error');
  }

  return;
});

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

  // reservationsコレクション
  const reservations = [
    {
      user_id: '1112',
      reservation_time: Timestamp.fromDate(new Date('2023-09-01 10:00:00.000000')),
      is_ready: false,
    },
  ];

  const reservationsRef = admin.firestore().collection('reservations');
  reservations.forEach(async (reservation) => {
    await reservationsRef.add(reservation);
  });

  const logs = {
    user_id: '1111',
    device_id: 'device_1',
    start_time: Timestamp.fromDate(new Date('2021-09-01 10:00:00.000000')),
    end_time: null,
    is_turn_off: false,
  };
  const logsRef = admin.firestore().collection('logs');
  await logsRef.add(logs);

  res.end();
  return;
});
