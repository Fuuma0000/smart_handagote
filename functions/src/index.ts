import * as admin from 'firebase-admin';
import { checkNextReservation } from './functions/checkNextReservation';
import { endUsing } from './functions/endUsing';
import { startUsing } from './functions/startUsing';
import { cancelReservation } from './functions/cancelReservation';
import { alert } from './functions/alert';
import { initLogs, insertTestData } from './functions/test';

admin.initializeApp();

// 本番用
exports.startUsing = startUsing;
exports.endUsing = endUsing;
exports.checkNextReservation = checkNextReservation;
exports.cancelReservation = cancelReservation;
exports.alert = alert;

// テスト用
exports.insertTestData = insertTestData;
// exports.userTest = userTest;
// exports.deleteTest = deleteTest;
exports.initLogs = initLogs;
