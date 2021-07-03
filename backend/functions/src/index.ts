import {firestore} from "firebase-admin";
import * as functions from "firebase-functions";

// Start writing Firebase Functions
// https://firebase.google.com/docs/functions/typescript

export const helloWorld = functions.https.onRequest((request, response) => {
  functions.logger.info("Hello logs!", {structuredData: true});
  response.send("Hello from Firebase!");
});

export const shareEvent = functions.https.onRequest(async (req, res) => {
  functions.logger.info("Event shared!", {structuredData: true});
  const uid = await firestore().doc("emails/" + req.params.email).get();
  firestore().collection("users/" + uid + "/inboxes").add({
    "s": req.params.metaData,
  });
  res.send("Success!");
});
