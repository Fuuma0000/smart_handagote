import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';

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
    if (userData!.role == 0) {
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
