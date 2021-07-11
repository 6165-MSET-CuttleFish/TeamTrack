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
  const user = await admin
      .auth()
      .getUserByEmail(data.email);
  if (user == null) {
    console.log("User not found");
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Requested user does not exist"
    );
  }
  const ref = admin.firestore().collection("users").doc(user.uid);
  let tokens:string[] = [];
  const name = data.metaData["name"];
  const sender = data.metaData["senderName"];
  await admin.firestore().runTransaction(async (t) => {
    const doc = await t.get(ref);
    const newInbox = doc?.data()?.inbox;
    tokens = doc?.data()?.FCMtokens;
    newInbox.push(data.metaData);
    console.log(newInbox);
    t.update(ref, {inbox: newInbox});
  });

  const message = {
    data: {name: name, sender: sender},
    tokens: tokens,
  };
  admin.messaging().sendMulticast(message)
      .then((response) => {
        console.log(response.successCount + " messages were sent successfully");
      });
});

export const createUser = functions.auth.user().onCreate(async (user) => {
  return admin.firestore().collection("users").doc(user.uid).set({
    inbox: [],
    events: [],
    blockedUsers: [],
    FCMtokens: [],
  });
});

export const deleteUser = functions.auth.user().onDelete(async (user) => {
  return admin.firestore().collection("users").doc(user.uid).delete();
});
