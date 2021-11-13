import admin = require("firebase-admin");
import * as functions from "firebase-functions";
import {ftcAPIKey} from "./api/ftcAPIKey";
// Start writing Firebase Functions
// https://firebase.google.com/docs/functions/typescript
admin.initializeApp();

// put event in desired user's inbox
export const shareEvent = functions.https.onCall(async (data, context) => {
  functions.logger.info("Event share", {structuredData: true});
  if (!context.auth) { // if not authenticated
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
  if (recipient == null) { // if recipient doesn't exist
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Requested user does not exist"
    );
  }
  if (sender.uid == recipient.uid) { // if sender and recipient are the same
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Cannot send an event to yourself"
    );
  }
  let allowSend = true;
  await admin.database().ref()
      .child(`Events/${data.gameName}/${data.id}/Permissions`)
      .transaction((transaction) => {
        console.log(transaction);
        // only admins may send events
        allowSend = transaction[sender.uid].role == "admin";
        if (allowSend) {
          transaction[recipient.uid] = {
            "role": data.role,
            "name": recipient.displayName,
            "email": recipient.email,
            "photoURL": recipient.photoURL,
          }; // update permissions for recepient
        }
        return transaction;
      });
  if (!allowSend) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "You do not have admin access to your document"
    );
  }
  const meta = {
    "id": data.id,
    "name": data.name,
    "author": data.author,
    "sender": sender.toJSON(),
    "sendTime": admin.firestore.FieldValue.serverTimestamp(),
    "type": data.type,
    "gameName": data.gameName,
  };
  const ref = admin.firestore().collection("users").doc(recipient.uid);
  let tokens:string[] = [];
  const returnVal = await admin.firestore().runTransaction(async (t) => {
    const doc = await t.get(ref);
    const newInbox = doc?.data()?.inbox;
    // save the fcm tokens to send to
    tokens = doc?.data()?.FCMtokens;
    const blocked = doc?.data()?.blockedUsers;
    // allow send if not blocked and not in inbox and not already shared
    allowSend = blocked[sender.uid] == null && newInbox[data.id] == null &&
      doc?.data()?.events[data.id] == null;
    if (allowSend) {
      newInbox[data.id] = meta;
    }
    t.update(ref, {inbox: newInbox});
  });
  if (!allowSend) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Unable to send event"
    );
  }
  const notification = {
    title: "New Event",
    body: `${sender.displayName ?? "Unknown"} shared "${meta.name}" with you`,
  };
  const message = {
    tokens: tokens,
    notification: notification,
  };
  if (tokens.length != 0 && allowSend) {
    await admin.messaging().sendMulticast(message); // send notifications
  }
  return returnVal;
});

// update creator's permissions and add the new event to creator's events list
export const nativizeEvent = functions.database
    .ref("/Events/{gameName}/{event}")
    .onCreate(async (snap, context) => {
      const event = snap.val();
      const ref = admin.firestore().collection("users")
          .doc(context.auth?.uid ?? "");
      const user = await admin.auth().getUser(context.auth?.uid ?? "");
      snap.ref.child("Permissions").child(context.auth?.uid ?? "").set({
        "role": "admin",
        "name": user.displayName,
        "email": user.email,
        "photoURL": user.photoURL,
      });
      return admin.firestore().runTransaction(async (t) => {
        const doc = await t.get(ref);
        const events = doc.data()?.events;
        events[event.id] = {
          "name": event.name,
          "sendDate": admin.database.ServerValue.TIMESTAMP,
          "authorName": event.authorName,
          "authorEmail": event.authorEmail,
          "id": event.id,
          "type": event.type,
          "gameName": event.gameName,
        };
        t.update(doc.ref, {events: events});
      });
    });

// Delete event from user's inbox
export const removeUser = functions.database
    .ref("/Events/{gameName}/{eventID}/Permissions/{uid}")
    .onDelete(async (snap, context) => {
      const ref = admin.firestore().collection("users")
          .doc(context.params.uid);
      return admin.firestore().runTransaction(async (t) => {
        const doc = await t.get(ref);
        const events = doc.data()?.events;
        delete events[context.params.eventID];
        t.update(ref, {events: events});
      });
    });

export const createUser = functions.auth.user().onCreate(async (user) => {
  return admin.firestore().collection("users").doc(user.uid).set({
    inbox: {},
    events: {},
    blockedUsers: {},
    FCMtokens: [],
  });
});

// Delete user's document
export const deleteUser = functions.auth.user().onDelete(async (user) => {
  return admin.firestore().collection("users").doc(user.uid).delete();
});

export const fetchAPI = functions.https.onCall((data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "User not logged in"
    );
  }
  const url = new URL(`https://ftc-api.firstinspires.org/v2.0/2021/matches/${data.eventCode}`);
  return fetch(url.toString(), {
    headers: {Authorization: `Basic ${ftcAPIKey}`},
  });
});

export const remoteConfigToDatabase = functions.remoteConfig
    .onUpdate(async () => {
      const temp = await admin.remoteConfig().getTemplate();
      return admin.database().ref().child("config")
          .ref.set(temp.parameters);
    });

// functions.pubsub.schedule("every 1 week")
//     .onRun(async () => {
//       const db = admin.firestore();
//       const now = admin.firestore.Timestamp.now();
//       const ts = admin.firestore.Timestamp
//           .fromMillis(now.toMillis() - 86400000);
//       const snap = await db.collection("templates")
//           .where("sendTime", "<", ts).get();
//       const promises: Promise<FirebaseFirestore.WriteResult>[] = [];
//       snap.forEach((snap) => {
//         promises.push(snap.ref.delete());
//       });
//       return Promise.all(promises);
//     });
