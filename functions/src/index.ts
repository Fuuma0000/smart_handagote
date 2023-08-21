import * as admin from 'firebase-admin';
import { userTest } from './functions/test';
admin.initializeApp();

exports.userTest = userTest;
