import {database} from "firebase-admin";
import admin = require("firebase-admin");
import * as functions from "firebase-functions";
// Start writing Firebase Functions
// https://firebase.google.com/docs/functions/typescript

export const helloWorld = functions.https.onRequest((request, response) => {
  functions.logger.info("Hello logs!", {structuredData: true});
  response.send("Hello from Firebase!");
});

export const shareEvent = functions.https.onCall(async (data, context) => {
  functions.logger.info("Event shared!", {structuredData: true});
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "User not logged in"
    );
  }
  const snapshot = await admin.database().ref()
      .child("usernames/" + data.username)
      .get();
  if (snapshot == null) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Requested user does not exist"
    );
  }
  const uid = snapshot;// as string;
  return admin.firestore().collection("users/" + uid + "/inboxes").add({
    "s": data.metaData,
  });
});

export const createUser = functions.auth.user().onCreate(async (user) => {
  const username = user.customClaims?.username as string;
  const uid = user.uid;
  const ref = database().ref().child("usernames/" + username);
  if (await ref.get() == null) {
    return ref.update(uid);
  }
});
