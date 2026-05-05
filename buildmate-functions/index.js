const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendRequestStatusNotification = onDocumentCreated(
    "notifications/{id}",
    async (event) => {
      const data = event.data.data();

      const type = data.type;
      if (type !== "request_accepted" && type !== "request_rejected" && type !== "task_deadline") return;

      const receiverId = data.receiverId;
      if (!receiverId) return;

      const userDoc = await admin.firestore()
          .collection("users")
          .doc(receiverId)
          .get();

      const token = userDoc.data()?.fcmToken;
      if (!token) return;

      await admin.messaging().send({
        token: token,
        notification: {
          title: data.title || (type === "request_accepted" ? "Request Accepted! 🎉" : "Request Not Accepted"),
          body: data.message || "",
        },
        android: {
          priority: "high",
          notification: {channelId: "high_importance_channel"},
        },
      });
    },
);

exports.sendTaskDeadlineReminder = onSchedule(
    {schedule: "0 * * * *", timeZone: "Asia/Riyadh"},
    async () => {
      const now = new Date();
      // window: tasks due between 24h and 25h from now
      const windowStart = new Date(now.getTime() + 24 * 60 * 60 * 1000);
      const windowEnd = new Date(now.getTime() + 25 * 60 * 60 * 1000);

      const snapshot = await admin.firestore()
          .collectionGroup("tasks")
          .where("deadline", ">=", admin.firestore.Timestamp.fromDate(windowStart))
          .where("deadline", "<=", admin.firestore.Timestamp.fromDate(windowEnd))
          .get();

      if (snapshot.empty) return;

      const sends = [];

      for (const doc of snapshot.docs) {
        const task = doc.data();
        if (task.status === "done" || task.status === "completed") continue;
        if (task.reminderSent === true) continue;

        const assignedTo = task.assignedTo || [];
        if (assignedTo.length === 0) continue;

        const title = task.title || "Task";

        // mark as reminded so it doesn't fire again next hour
        sends.push(doc.ref.update({reminderSent: true}));

        for (const uid of assignedTo) {
          sends.push(
              admin.firestore().collection("users").doc(uid).get().then((userDoc) => {
                const token = userDoc.data()?.fcmToken;
                if (!token) return;
                return admin.messaging().send({
                  token,
                  notification: {
                    title: "Task Deadline in 24 Hours ⏰",
                    body: `"${title}" is due in 24 hours. Don't forget to complete it!`,
                  },
                  android: {
                    priority: "high",
                    notification: {channelId: "high_importance_channel"},
                  },
                }).catch(() => null);
              }),
          );
        }
      }

      await Promise.all(sends);
    },
);

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
