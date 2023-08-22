import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
const { sendNotification } = require('./notification');

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

exports = module.exports = {
  alert,
};
