import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
import { checkNextReservation } from './checkNextReservation';

// はんだごて使用終了時
export const endUsing = functions.https.onRequest(async (req, res) => {
  try {
    const { log_id } = req.body;

    const logsCollection = await admin.firestore().collection('logs');

    // logsコレクションのend_timeを更新
    const logRef = logsCollection.doc(log_id);
    await logRef.update({ end_time: Timestamp.now() });

    const device_id = (await logRef.get()).data()!.device_id;
    // 次の予約をチェック
    const result = await checkNextReservation(device_id);

    res.status(result.status).send(result.message);
  } catch (error) {
    functions.logger.error('Error', error);
    res.status(500).send('Internal Server Error');
  }
  return;
});

exports = module.exports = {
  endUsing,
};
