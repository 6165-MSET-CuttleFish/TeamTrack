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
  return admin.firestore().runTransaction(async (t) => {
    const doc = await t.get(ref);
    const newInbox = doc?.data()?.inbox;
    newInbox.push(data.metaData);
    console.log(newInbox);
    t.update(ref, {inbox: newInbox});
  });
});

export const createUser = functions.auth.user().onCreate(async (user) => {
  return admin.firestore().collection("users").doc(user.uid).set({
    inbox: [],
    events: [],
    blockedUsers: [],
  });
});

export const deleteUser = functions.auth.user().onDelete(async (user) => {
  return admin.firestore().collection("users").doc(user.uid).delete();
});
