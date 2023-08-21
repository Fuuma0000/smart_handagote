import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export async function sendNotification(userToken: string, messageTitle: string, messageBody: string) {
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
