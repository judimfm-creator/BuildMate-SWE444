const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendJoinRequestNotification = functions.firestore
  .document("join_requests/{requestId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();

    const leaderId = data.leaderId;
    const senderName = data.fullName || "Someone";
    const teamName = data.teamName || "your team";

    if (!leaderId) return null;

    const leaderDoc = await admin
      .firestore()
      .collection("users")
      .doc(leaderId)
      .get();

    if (!leaderDoc.exists) return null;

    const token = leaderDoc.data().fcmToken;

    if (!token) return null;

    const message = {
      notification: {
        title: "New Join Request",
        body: `${senderName} requested to join ${teamName}`,
      },
      data: {
        type: "join_request",
        leaderId: leaderId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      token: token,
    };

    await admin.messaging().send(message);
    return null;
  });