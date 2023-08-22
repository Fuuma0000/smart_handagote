import * as admin from 'firebase-admin';
import { deleteTest, insertTestData, userTest } from './functions/test';
import { checkNextReservation } from './functions/checkNextReservation';
import { endUsing } from './functions/endUsing';
import { startUsing } from './functions/startUsing';

admin.initializeApp();

// 本番用
exports.startUsing = startUsing;
exports.endUsing = endUsing;
exports.checkNextReservation = checkNextReservation;

// テスト用
exports.userTest = userTest;
exports.insertTestData = insertTestData;
exports.deleteTest = deleteTest;
