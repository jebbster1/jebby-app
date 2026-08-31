import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:jebby/Views/helper/global.dart';
import 'package:jebby/Views/screens/auth/Otp.dart';
import 'package:jebby/Views/screens/auth/createnewpassword.dart';
import 'package:jebby/Views/screens/auth/login.dart';
import 'package:jebby/Views/screens/profile/userprofile.dart';
import 'package:jebby/Views/screens/vendors/vendorhome.dart';
import 'package:jebby/model/user_model.dart';
import 'package:jebby/repository/auth_repository.dart';
import 'package:jebby/utils/show_snackbar.dart';
import 'package:jebby/view_model/user_view_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Views/screens/mainfolder/homemain.dart';
import '../utils/overlay_support.dart';

class AuthViewModel with ChangeNotifier {
  final _myRepo = AuthRepository();

  bool _loading = false;
  bool get loading => _loading;

  bool _signUpLoading = false;
  bool get signUpLoading => _signUpLoading;

  bool _resendOtpLoading = false;
  bool get resendOtpLoading => _resendOtpLoading;

  bool _accountDeletionLoading = false;
  bool get accountDeletionLoading => _accountDeletionLoading;

  String userName = "";
  setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void getUserName() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String _name = sharedPreferences.getString('fullname') ?? "";

    userName = _name;
  }

  setSignUpLoading(bool value) {
    _signUpLoading = value;
    notifyListeners();
  }

  void setResendOtpLoading(bool value) {
    _resendOtpLoading = value;
    notifyListeners();
  }

  void setAccountDeletionLoading(bool value) {
    _accountDeletionLoading = value;
    notifyListeners();
  }

  String _accountDeletionErrorMessage(Object error) {
    final raw = error.toString();
    final jsonStart = raw.indexOf('{');
    if (jsonStart != -1) {
      try {
        final decoded = jsonDecode(raw.substring(jsonStart));
        if (decoded is Map && decoded['message'] != null) {
          return decoded['message'].toString();
        }
      } catch (_) {}
    }
    return raw.replaceFirst('Invalid request', '').trim();
  }

  Future<void> loginApi(
    dynamic data,
    BuildContext context,
  ) async {
    setLoading(true);
    Loader.show();

    _myRepo.loginApi(data).then((value) {
      setLoading(false);
      Loader.hide();
      final userPreference = Provider.of<UserViewModel>(context, listen: false);
      if (value["message"].toString() == "Incorrect password") {
        showAppErrorSnackbar('Incorrect password');
      } else if (value["message"].toString() == "enter valid email") {
        showAppErrorSnackbar('Email doesn\'t exist');
      } else if (value["message"].toString() == "account is not verified") {
        _openRegistrationOtpFromLogin(
          context: context,
          email: data['email'].toString(),
          password: data['password'].toString(),
          name: value['name']?.toString(),
          role: value['role']?.toString(),
        );
      } else {
        userPreference.saveUser(UserModel(
          token: value['token'].toString(),
          name: value['name'].toString(),
          email: value['email'].toString(),
          id: value['id'].toString(),
          role: value['role'].toString(),
          address: value['address'].toString(),
          source: value['source']?.toString() ?? 'simple',
        ));
        userName = value['name'].toString();

        // Save user data to SharedPreferences
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('stripe_verification_status', value['stripe_verification_status'] ?? "");
          prefs.setBool('is_identity_verified', value['is_identity_verified'] == 1 || value['is_identity_verified'] == "1");
        });

        loginType = "user";
        final userRole = value['role'].toString();
        if (userRole == "1") {
          Get.offAll(() => VendrosHomeScreen());
        } else {
          Get.offAll(() => MainScreen());
        }
      }
    }).onError((error, stackTrace) {
      Loader.hide();
      setLoading(false);
      showAppErrorSnackbar(error.toString());
      if (kDebugMode) {
        
      }
    });
  }

  Future<void> resendRegistrationOtp({
    required String email,
    required String password,
    BuildContext? context,
    bool openOtpScreen = false,
    String? name,
    String? role,
  }) async {
    if (_resendOtpLoading) return;
    setResendOtpLoading(true);

    try {
      final value = await _myRepo.resendRegistrationOtpApi({
        'email': email,
        'password': password,
      });

      if (value['message'].toString() == 'OTP send') {
        showAppSuccessSnackbar('Verification code sent');
        if (openOtpScreen && context != null) {
          Get.to(
            () => OTPSCREEN(
              email: email,
              name: name ?? '',
              password: password,
              role: role ?? '0',
            ),
          );
        }
      } else if (value['message'].toString() == 'Incorrect password') {
        showAppErrorSnackbar('Incorrect password');
      } else if (value['message'].toString() == 'Email Already Registered') {
        showAppErrorSnackbar('This email is already verified. Try signing in.');
      } else {
        showAppErrorSnackbar(
          value['message']?.toString() ?? 'Could not resend verification code',
        );
      }
    } catch (error) {
      showAppErrorSnackbar(error.toString());
    } finally {
      setResendOtpLoading(false);
    }
  }

  Future<void> resendForgotPasswordOtp(String email) async {
    if (_resendOtpLoading) return;
    setResendOtpLoading(true);

    try {
      final value = await _myRepo.forgetPasswordApi({'email': email});

      if (value['message'].toString() == 'Otp Send') {
        showAppSuccessSnackbar('OTP sent successfully');
      } else if (value['message'].toString() == 'Email not Found') {
        showAppErrorSnackbar('Email not Found');
      } else if (value['message'].toString() == 'this is a social auth account') {
        showAppErrorSnackbar(
          'This email is linked to a social sign-in account. Sign in with Google, Facebook, or Apple instead.',
        );
      } else {
        showAppErrorSnackbar('Something went wrong');
      }
    } catch (error) {
      showAppErrorSnackbar(error.toString());
    } finally {
      setResendOtpLoading(false);
    }
  }

  void _openRegistrationOtpFromLogin({
    required BuildContext context,
    required String email,
    required String password,
    String? name,
    String? role,
  }) {
    resendRegistrationOtp(
      email: email,
      password: password,
      context: context,
      openOtpScreen: true,
      name: name,
      role: role,
    );
  }

  Future<void> signUpApi(
    dynamic data,
    BuildContext context,
  ) async {
    if (_signUpLoading) return;
    setSignUpLoading(true);

    _myRepo
        .signUpApi(data)
        .then((value) async {
          setSignUpLoading(false);
          if (value["message"].toString() == "OTP send") {
            showAppSuccessSnackbar('Otp sent');
            Get.to(
              () => OTPSCREEN(
                email: data["email"],
                name: data["name"],
                password: data["password"],
                role: data["role"],
              ),
            );
          } else if (value["message"].toString() == "Signin successfull") {
            showAppSuccessSnackbar('Signin Successful');

        // Save Data To SharedPrefrences
        SharedPreferences updatePrefrences = await SharedPreferences.getInstance();
        
        
        updatePrefrences.setString('fullname', value["data"]["name"].toString());
        updatePrefrences.setString('email', value["data"]["email"].toString());
        updatePrefrences.setString('id', value["data"]["id"].toString());
        if (value['token'] != null) {
          updatePrefrences.setString('token', value['token'].toString());
        }
        updatePrefrences.setString('phoneNumber', value["data"]["phone_number"].toString());
        updatePrefrences.setString('latitude', value["data"]["latitude"].toString());
        updatePrefrences.setString('longitude', value["data"]["longitude"].toString());
        updatePrefrences.setString('role', value["data"]["role"].toString());
        updatePrefrences.setString(
          'source',
          value["data"]["source"]?.toString() ?? 'simple',
        );
        
        // Save stripe verification status for future use
        updatePrefrences.setString('stripe_verification_status', value["data"]["stripe_verification_status"] ?? "");
        updatePrefrences.setBool('is_identity_verified', value["data"]["is_identity_verified"] == 1 || value["data"]["is_identity_verified"] == "1");
        
        // Always go to MainScreen after signup - Stripe onboarding will be handled when user becomes provider
        Get.offAll(() => MainScreen());
      } else if (value["message"].toString() == "Email Already Registered") {
        showAppErrorSnackbar('Email Already Registered');
      } else {
        showAppErrorSnackbar('Something went wrong');
      }
      if (kDebugMode) {
        
      }
    }).onError((error, stackTrace) {
      setSignUpLoading(false);
      showAppErrorSnackbar(error.toString());
      if (kDebugMode) {
        
      }
    });
  }

  Future<void> otpRegisterApi(
    dynamic data,
    BuildContext context,
  ) async {
    setSignUpLoading(true);

    _myRepo.otpRegisterApi(data).then((value) {
      setSignUpLoading(false);
      if (value["message"].toString() == "Successfully signup") {
        showAppSuccessSnackbar('Signup Successfully');
        
        // Save user data to SharedPreferences
        SharedPreferences.getInstance().then((prefs) async {
          final data = value["data"];
          // Save basic user information
          prefs.setString('fullname', data["name"].toString());
          prefs.setString('email', data["email"].toString());
          prefs.setString('id', data["id"].toString());
          if (value['token'] != null) {
            prefs.setString('token', value['token'].toString());
          }
          prefs.setString('phoneNumber', data["phone_number"].toString());
          prefs.setString('latitude', data["latitude"].toString());
          prefs.setString('longitude', data["longitude"].toString());
          prefs.setString('role', data["role"].toString());
          prefs.setString(
            'source',
            data["source"]?.toString() ?? 'simple',
          );
          
          // Save stripe verification status for future use
          prefs.setString('stripe_verification_status', data["stripe_verification_status"] ?? "");
          prefs.setBool('is_identity_verified', data["is_identity_verified"] == 1 || data["is_identity_verified"] == "1");
        });
        
        // After successful signup, go to MainScreen - Stripe onboarding will be handled when user becomes provider
        Get.offAll(() => MainScreen());
      } else if (value["message"].toString() == "invalid OTP") {
        showAppErrorSnackbar('Invalid OTP');
      } else if (value["message"].toString() == "OTP expired") {
        showAppErrorSnackbar('OTP expired. Request a new code.');
      } else {
        showAppErrorSnackbar('Something went wrong');
      }
      if (kDebugMode) {
        
      }
    }).onError((error, stackTrace) {
      print("Error in otpRegisterApi: $error");
      setSignUpLoading(false);
      showAppErrorSnackbar("Please Enter Otp");

          if (kDebugMode) {}
        });
  }

  Future<void> signUpApiWithSocials(dynamic data, BuildContext context) async {
    setSignUpLoading(true);

    _myRepo
        .signUpApiWithSocial(data)
        .then((value) async {
          setSignUpLoading(false);
          if (value["message"].toString() == "Signin successfull") {
            showAppSuccessSnackbar('Signin Successful');

        // Save Data To SharedPrefrences
        SharedPreferences updatePrefrences = await SharedPreferences.getInstance();
        
        
        updatePrefrences.setString('fullname', value["data"]["name"].toString());
        updatePrefrences.setString('email', value["data"]["email"].toString());
        updatePrefrences.setString('id', value["data"]["id"].toString());
        if (value['token'] != null) {
          updatePrefrences.setString('token', value['token'].toString());
        }
        updatePrefrences.setString('latitude', value["data"]["latitude"].toString());
        updatePrefrences.setString('longitude', value["data"]["longitude"].toString());
        updatePrefrences.setString('role', value["data"]["role"].toString());
        updatePrefrences.setString(
          'source',
          value["data"]["source"]?.toString() ?? '',
        );
        
        // Save stripe verification status for future use
        updatePrefrences.setString('stripe_verification_status', value["data"]["stripe_verification_status"] ?? "");
        updatePrefrences.setBool('is_identity_verified', value["data"]["is_identity_verified"] == 1 || value["data"]["is_identity_verified"] == "1");
        
        if (context.mounted) {
          await Provider.of<UserViewModel>(context, listen: false).getUser();
        }
        
        // Always go to MainScreen after social signup - Stripe onboarding will be handled when user becomes provider
        Get.offAll(() => MainScreen());
      } else {
        showAppErrorSnackbar('Something went wrong');
      }

          if (kDebugMode) {}
        })
        .onError((error, stackTrace) {
          setSignUpLoading(false);
          showAppErrorSnackbar(error.toString());
          if (kDebugMode) {}
        });
  }

  Future<void> forgetPasswordApi(
    dynamic data,
    BuildContext context,
    route,
  ) async {
    if (_signUpLoading) return;
    setSignUpLoading(true);

    _myRepo
        .forgetPasswordApi(data)
        .then((value) {
          setSignUpLoading(false);
          if (value["message"].toString() == "Otp Send") {
            showAppSuccessSnackbar('OTP sent successfully');
            route == "forgot"
                ? Get.to(
                  () => OTPSCREEN(
                    email: data["email"],
                    name: "",
                    password: "",
                    role: "",
                    isForgotPasswordFlow: true,
                  ),
                )
                : Get.to(
                  () => OTPSCREEN(
                    email: data["email"],
                    name: "",
                    password: data["password"],
                    role: "",
                  ),
                );
          } else if (value["message"].toString() == "Email not Found") {
            showAppErrorSnackbar('Email not Found');
          } else if (value["message"].toString() == "this is a social auth account") {
            showAppErrorSnackbar(
              'This email is linked to a social sign-in account. Sign in with Google, Facebook, or Apple instead.'
            );
          } else {
            showAppErrorSnackbar('Something went wrong');
          }
          if (kDebugMode) {}
        })
        .onError((error, stackTrace) {
          setSignUpLoading(false);
          showAppErrorSnackbar(error.toString() + "Ameer");
          if (kDebugMode) {}
        });
  }

  Future<void> otpForgetPasswordApi(dynamic data, BuildContext context) async {
    if (_signUpLoading) return;
    setSignUpLoading(true);

    _myRepo.ForgetPasswordotpApi(data)
        .then((value) {
          setSignUpLoading(false);
          if (value["message"].toString() == "otp correct") {
            Get.to(() => CreatePasswordScreen(
                  email: data["email"],
                  otp: data["otp"],
                ));
          } else if (value["message"].toString() == "otp incorrect") {
            showAppErrorSnackbar('Invalid OTP');
          } else if (value["message"].toString() == "OTP expired") {
            showAppErrorSnackbar('OTP expired. Request a new code.');
          } else {
            showAppErrorSnackbar('Something went wrong');
          }
          if (kDebugMode) {}
        })
        .onError((error, stackTrace) {
          setSignUpLoading(false);
          showAppErrorSnackbar("Please Enter Otp");
          if (kDebugMode) {}
        });
  }

  Future<void> changePasswordAPi(dynamic data, BuildContext context) async {
    if (_signUpLoading) return;
    setSignUpLoading(true);

    _myRepo
        .changePasswordApi(data)
        .then((value) {
          setSignUpLoading(false);
          if (value["message"].toString() == "Password Updated") {
            showAppSuccessSnackbar('Password Changed Successfully');
            Get.offAll(() => LoginScreen());
          } else if (value["message"].toString() == "Email not Found") {
            showAppErrorSnackbar('email  not found');
          } else if (value["message"].toString() ==
              "this is a social auth account") {
            showAppErrorSnackbar(
              'This is a social auth account'
            );
          } else if (value["message"].toString() == "invalid OTP") {
            showAppErrorSnackbar('Invalid OTP');
          } else if (value["message"].toString() == "OTP expired") {
            showAppErrorSnackbar('OTP expired. Request a new code.');
          } else {
            showAppErrorSnackbar('Something went wrong');
          }
          if (kDebugMode) {}
        })
        .onError((error, stackTrace) {
          setSignUpLoading(false);
          showAppErrorSnackbar(error.toString());
          if (kDebugMode) {}
        });
  }

  Future<void> editProfileApi(dynamic data, BuildContext context) async {
    setSignUpLoading(true);

    _myRepo
        .editProfileApi(data)
        .then((value) {
          setSignUpLoading(false);
          if (value["result"].toString() == data["file"].toString()) {
            showAppSuccessSnackbar('Otp sent');
            Get.to(() => MyProfileScreen());
          } else if (value["message"].toString() == "Please upload a file!") {
            showAppErrorSnackbar('Please upload a file!');
          } else {
            showAppErrorSnackbar('Something went wrong');
          }
          if (kDebugMode) {}
        })
        .onError((error, stackTrace) {
          setSignUpLoading(false);
          showAppErrorSnackbar(error.toString());
          if (kDebugMode) {}
        });
  }

  Future<void> requestAccountDeletion({
    required BuildContext context,
    String contactNumber = '',
  }) async {
    if (_accountDeletionLoading) return;
    setAccountDeletionLoading(true);

    final payload = contactNumber.trim().isNotEmpty
        ? {'contact_number': contactNumber.trim()}
        : <String, dynamic>{};

    _myRepo
        .submitAccountDeletionRequest(payload)
        .then((value) {
          setAccountDeletionLoading(false);
          final message = value['message']?.toString() ?? '';
          if (message == 'Inserted') {
            showAppSuccessSnackbar(
              'Your account deletion request has been submitted. Our team will review it shortly.'
            );
          } else {
            showAppErrorSnackbar(
              message.isNotEmpty ? message : 'Something went wrong'
            );
          }
        })
        .onError((error, stackTrace) {
          setAccountDeletionLoading(false);
          showAppErrorSnackbar(
            _accountDeletionErrorMessage(error ?? 'Something went wrong'),
          );
        });
  }

  /// login will  be done as a guest
  Future<void> loginAsGuest(BuildContext context) async {
    final userPreference = Provider.of<UserViewModel>(context, listen: false);
    userName = "Guest";
    await userPreference.saveUser(
      UserModel(
        token: "",
        name: "Guest",
        email: "",
        id: "Guest",
        role: "Guest",
        isGuest: true,
      ),
    );

    loginType = "user";
    Get.offAll(() => MainScreen());
  }
}
