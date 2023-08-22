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

// テスト用データを挿入
export const insertTestData = functions.https.onRequest(async (req, res) => {
  // usersコレクション
  const users = [
    {
      user_id: '1111',
      user_name: '山田 太郎',
      role: 0,
      token: 'ea0Ag-HbS6mdm3CGU1Wu74:APA91bFUFtzoQ2lPpi1KHfl23yt5EgDIaXyY-P20lqSrnAsbLmpcRmJqVndk8jnOD3KgyRHy2T2VrRWJgwy3H5U1zPCmxzrrC5VVuwFHXKt6w51TbNmoYx2KC7qzoh7WGOlmDYmpBXXd',
    },
    {
      user_id: '1112',
      user_name: '田中 一郎',
      role: 1,
      token: 'test_token_2',
    },
    {
      user_id: '1113',
      user_name: '鈴木 三郎',
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

// deleteのテスト
// logsのデータが削除されたら、繰り上げ
export const deleteTest = functions.firestore.document('logs/{log_id}').onDelete(async (snap, context) => {
  const logData = snap.data();
  const device_id = logData!.device_id;
  // device_idを出力
  functions.logger.info('device_id: ', device_id);
  return;
});

// テスト用
export const userTest = functions.https.onRequest(async (req, res) => {
  try {
    const { user_id } = req.body;

    const userCollection = await admin.firestore().collection('users');
    const userDoc = await userCollection.doc(user_id).get();
    // user_name
    const user_name = userDoc.data()!.user_name;

    res.status(200).json({ user_name: user_name });
  } catch (error) {
    functions.logger.error('Error', error);
    res.status(500).send('Internal Server Error');
  }
});

exports = module.exports = {
  insertTestData,
  deleteTest,
  userTest,
};
