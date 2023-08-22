import * as functions from 'firebase-functions';
import { checkNextReservation } from './checkNextReservation';

/**
 * 予約のキャンセル処理
 */
export const cancelReservation = functions.firestore.document('logs/{log_id}').onDelete(async (snap, context) => {
  // 削除されたデータからdevice_idを取得
  const reservationData = snap.data();
  const device_id = reservationData!.device_id;

  // 次の予約が入っているかどうかをチェック
  checkNextReservation(device_id);
});
