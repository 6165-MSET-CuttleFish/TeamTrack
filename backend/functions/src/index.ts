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
  if (sender.uid == recipient.uid) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "You cannot send an event to yourself"
    );
  }
  await admin.database().ref().child("Events")
      .child(data.gameName).child(data.id)
      .child("Permissions").child(recipient.uid).set(data.role);
  const meta = {
    "id": data.id,
    "name": data.name,
    "authorEmail": data.authorEmail,
    "authorName": data.authorName,
    "senderName": sender.displayName ?? "Unknown",
    "senderEmail": sender.email ?? "Unknown",
    "senderID": sender.uid,
    "sendTime": admin.firestore.FieldValue.serverTimestamp(),
    "type": data.type,
    "gameName": data.gameName,
  };
  const ref = admin.firestore().collection("users").doc(recipient.uid);
  let tokens:string[] = [];
  const returnVal = await admin.firestore().runTransaction(async (t) => {
    const doc = await t.get(ref);
    const newInbox = doc?.data()?.inbox;
    tokens = doc?.data()?.FCMtokens;
    const blocked = doc?.data()?.blockedUsers;
    let allowSend = true;
    if (blocked[sender.uid] != null) allowSend = false;
    if (allowSend) {
      newInbox[data.id] = meta;
    } else {
      throw new functions.https.HttpsError(
          "cancelled",
          `${recipient.displayName ?? "Unknown"} has blocked you.`
      );
    }
    t.update(ref, {inbox: newInbox});
  });
  const message = {
    data: {name: data.name, sender: sender.displayName ?? "Unknown"},
    tokens: tokens,
  };
  if (tokens.length != 0) {
    const response = await admin.messaging().sendMulticast(message);
    console.log(response.successCount + " messages were sent successfully");
  }
  return returnVal;
});

export const createUser = functions.auth.user().onCreate(async (user) => {
  return admin.firestore().collection("users").doc(user.uid).set({
    inbox: {},
    events: {},
    blockedUsers: {},
    FCMtokens: [],
  });
});

export const deleteUser = functions.auth.user().onDelete(async (user) => {
  return admin.firestore().collection("users").doc(user.uid).delete();
});
