import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const claimAdCoins = functions.https.onCall(async (data, context) => {
  if (!context?.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  const requestId = data.requestId;
  const userId = context.auth.uid;

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const ledgerRef = admin.firestore().collection(`users/${userId}/ledger`);
  const todayLedgerEntries = await ledgerRef.where('type', '==', 'ad-coins').where('timestamp', '>=', today).get();

  if (!todayLedgerEntries.empty) {
    throw new Error('already-claimed');
  }

  await ledgerRef.add({
    type: 'ad-coins',
    amount: 50,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    requestId: requestId,
  });

  await admin.firestore().collection(`users/${userId}/economy/state`).doc('state').update({
    coins: admin.firestore.FieldValue.increment(50),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});