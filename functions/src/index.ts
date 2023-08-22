import * as admin from 'firebase-admin';
import { deleteTest, insertTestData, userTest } from './functions/test';
import { checkNextReservation } from './functions/checkNextReservation';
import { endUsing } from './functions/endUsing';
import { startUsing } from './functions/startUsing';
import { cancelReservation } from './functions/cancelReservation';

admin.initializeApp();

// 本番用
exports.startUsing = startUsing;
exports.endUsing = endUsing;
exports.checkNextReservation = checkNextReservation;
exports.cancelReservation = cancelReservation;

// テスト用
exports.userTest = userTest;
exports.insertTestData = insertTestData;
exports.deleteTest = deleteTest;
