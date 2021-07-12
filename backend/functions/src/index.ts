import admin = require("firebase-admin");
import * as functions from "firebase-functions";
// Start writing Firebase Functions
// https://firebase.google.com/docs/functions/typescript
admin.initializeApp();
export const shareEvent = functions.https.onCall(async (data, context) => {
  functions.logger.info("Event share", {structuredData: true});
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "User not logged in"
    );
  }
  const sender = await admin
      .auth()
      .getUser(context.auth.uid);
  const recipient = await admin
      .auth()
      .getUserByEmail(data.email);
  if (recipient == null) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Requested user does not exist"
    );
  }
  const meta = {
    "id": data.id,
    "name": data.name,
    "authorEmail": data.authorEmail,
    "authorName": data.authorName,
    "senderName": sender.displayName,
    "senderEmail": sender.email,
    "sendTime": admin.firestore.FieldValue.serverTimestamp(),
    "type": data.type,
  };
  const ref = admin.firestore().collection("users").doc(recipient.uid);
  return admin.firestore().runTransaction(async (t) => {
    const doc = await t.get(ref);
    const newInbox = doc?.data()?.inbox;
    const allowSend = !(doc?.data()?.blockedUsers as Array<string>)
        .includes(sender.email ?? "");
    if (allowSend) {
      newInbox[data.id] = meta;
    }
    t.update(ref, {inbox: newInbox});
  });
});

export const createUser = functions.auth.user().onCreate(async (user) => {
  return admin.firestore().collection("users").doc(user.uid).set({
    inbox: {},
    events: {},
    blockedUsers: [],
  });
});

export const deleteUser = functions.auth.user().onDelete(async (user) => {
  return admin.firestore().collection("users").doc(user.uid).delete();
});
