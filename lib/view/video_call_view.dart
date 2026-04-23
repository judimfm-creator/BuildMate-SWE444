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
        appID: 1561145060, // خلي أرقامك زي ما هي
        appSign: "2d4b9e89e5e3d2dc4625071e52091562ae81fe354f86a6073c9e9c1afcecda3b",
        userID: userID,
        userName: userName,
        callID: callID,

        // التعديل هنا: أضفنا زر مشاركة الشاشة مع الأزرار الأساسية
        config: ZegoUIKitPrebuiltCallConfig.groupVideoCall()
          ..bottomMenuBar.buttons = [
            ZegoCallMenuBarButtonName.toggleCameraButton,
            ZegoCallMenuBarButtonName.toggleMicrophoneButton,
            ZegoCallMenuBarButtonName.switchAudioOutputButton,
            ZegoCallMenuBarButtonName.toggleScreenSharingButton, // 👈 زر مشاركة الشاشة
            ZegoCallMenuBarButtonName.hangUpButton,
          ],
      ),
    );
  }
}