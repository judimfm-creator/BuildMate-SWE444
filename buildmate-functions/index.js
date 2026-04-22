const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendJoinRequestNotification = onDocumentCreated(
    "join_requests/{id}",
    async (event) => {
      const data = event.data.data();

      const teamPostId = data.teamPostId;
      const requesterId = data.requesterId;

      const teamDoc = await admin.firestore()
          .collection("team_posts")
          .doc(teamPostId)
          .get();

      const leaderId = teamDoc.data().createdBy;

      const userDoc = await admin.firestore()
          .collection("users")
          .doc(requesterId)
          .get();

      const name = userDoc.data().fullName || userDoc.data().name || "Someone";

      const leaderDoc = await admin.firestore()
          .collection("users")
          .doc(leaderId)
          .get();

      const token = leaderDoc.data().fcmToken;

      if (!token) return;

      await admin.messaging().send({
        token: token,
        notification: {
          title: "New Join Request 🔔",
          body: `${name} wants to join your team`,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "high_importance_channel",
          },
        },
      });
    },
);
