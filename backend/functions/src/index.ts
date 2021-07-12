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
  let tokens:string[] = [];
  const _name = data.metaData["name"];
  const _sender = data.metaData["sender"];
  return admin.firestore().runTransaction(async (t) => {
    const doc = await t.get(ref);
    const newInbox = doc?.data()?.inbox;
    tokens = doc?.data()?.FCMtokens;
    const allowSend = !(doc?.data()?.blockedUsers as Array<string>)
        .includes(sender.email ?? "");
    let instancesOfUser = 0;
    (doc?.data()?.blockedUsers as Array<string>).forEach((element) => {
      if (element === sender.email) {
        instancesOfUser++;
      }
    });
    if (allowSend && instancesOfUser < 5) {
      newInbox[data.id] = meta;
    }
    t.update(ref, {inbox: newInbox});
    const message = {
      data: {name: _name, sender: _sender},
      tokens: tokens,
    };
    admin.messaging().sendMulticast(message)
        .then((response) => {
          console.log(response.successCount +
            " messages were sent successfully");
        });
  });
});

export const createUser = functions.auth.user().onCreate(async (user) => {
  return admin.firestore().collection("users").doc(user.uid).set({
    inbox: {},
    events: {},
    blockedUsers: [],
    FCMtokens: [],
  });
});

export const deleteUser = functions.auth.user().onDelete(async (user) => {
  return admin.firestore().collection("users").doc(user.uid).delete();
});
