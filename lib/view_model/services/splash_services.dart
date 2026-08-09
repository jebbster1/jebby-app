import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jebby/Views/helper/global.dart';
import 'package:jebby/Views/screens/auth/login.dart';
import 'package:jebby/Views/screens/mainfolder/homemain.dart';
import 'package:jebby/model/user_model.dart';
import 'package:jebby/view_model/user_view_model.dart';

class SplashServices {
  Future<void> checkAuthentication(BuildContext context) async {
    try {
      final hasSession = await UserViewModel.hasActiveSession();
      await Future.delayed(const Duration(seconds: 2));

      if (!hasSession) {
        Get.offAll(() => LoginScreen());
        return;
      }

      loginType = "user";
      Get.offAll(() => MainScreen());
    } catch (error) {
      if (kDebugMode) {}
      Get.offAll(() => LoginScreen());
    }
  }
}

class DataUsers {
  Future<UserModel> getUserDate() => UserViewModel().getUser();

  String? token;
  String? id;
  String? fullname;
  String? email;
  String? phoneNumber;
  String? role;
  void profileData() async {
    getUserDate()
        .then((value) async {
          token = value.token?.toString();
          id = value.id?.toString();
          fullname = value.name?.toString();
          email = value.email?.toString();
          phoneNumber = value.phoneNumber?.toString();
          role = value.role?.toString();
        })
        .onError((error, stackTrace) {});
  }
}
