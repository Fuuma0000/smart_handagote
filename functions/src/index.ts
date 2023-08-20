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
