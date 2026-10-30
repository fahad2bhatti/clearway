"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.claimAdCoins = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
exports.claimAdCoins = functions.https.onCall(async (data, context) => {
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
