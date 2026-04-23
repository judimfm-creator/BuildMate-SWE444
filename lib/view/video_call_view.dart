import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class VideoCallView extends StatelessWidget {
  final String callID; // هذا بيكون الـ teamPostId عشان يجمعكم بغرفة وحدة
  final String userID;
  final String userName;

  const VideoCallView({
    super.key,
    required this.callID,
    required this.userID,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ZegoUIKitPrebuiltCall(
        appID: 1561145060,
        appSign: "2d4b9e89e5e3d2dc4625071e52091562ae81fe354f86a6073c9e9c1afcecda3b",
        userID: userID,
        userName: userName,
        callID: callID,

        config: ZegoUIKitPrebuiltCallConfig.groupVideoCall()
          ..bottomMenuBar.buttons = [
            ZegoCallMenuBarButtonName.toggleCameraButton,
            ZegoCallMenuBarButtonName.switchCameraButton,
            ZegoCallMenuBarButtonName.toggleMicrophoneButton,
            ZegoCallMenuBarButtonName.switchAudioOutputButton,
            ZegoCallMenuBarButtonName.toggleScreenSharingButton,
            ZegoCallMenuBarButtonName.hangUpButton,
          ],

        // ✅ التعديل هنا فقط:
        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (event, defaultAction) {
            // نغلق الشاشة ونطلّع اليوزر فقط إذا هو ضغط زر الخروج بيده
            if (event.reason == ZegoUIKitCallEndReason.localHangUp) {
              defaultAction.call();
            }
            // أي سبب ثاني (مثل خروج شخص ثاني وبقاءك لحالك) التطبيق بيتجاهله وتستمر المكالمة
          },
        ),
      ),
    );
  }
}