import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/Services/provider/sign_in_provider.dart';
import 'package:jebby/Views/helper/colors.dart';
import 'package:jebby/Views/helper/global.dart';
import 'package:jebby/Views/screens/auth/forgot.dart';
import 'package:jebby/Views/screens/auth/register.dart';
import 'package:jebby/Views/screens/mainfolder/homemain.dart';
import 'package:jebby/model/user_model.dart';
import 'package:jebby/res/color.dart';
import 'package:jebby/view_model/user_view_model.dart';
import 'package:provider/provider.dart';

import 'package:rounded_loading_button_plus/rounded_loading_button.dart';

import '../../../Services/provider/internet_provider.dart';
import '../../../utils/show_snackbar.dart';
import '../../../view_model/auth_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<UserModel> getUserDate() => UserViewModel().getUser();
  final GlobalKey _scaffoldKey = GlobalKey<ScaffoldState>();
  final RoundedLoadingButtonController googleController =
      RoundedLoadingButtonController();
  final RoundedLoadingButtonController facebookController =
      RoundedLoadingButtonController();
  final RoundedLoadingButtonController AppleController =
      RoundedLoadingButtonController();

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  int _value = 0;

  bool obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  String? role;

  @override
  void initState() {
    super.initState();
    getUserDate()
        .then((value) async {
          role = value.role;
        })
        .onError((error, stackTrace) {
          if (kDebugMode) {}
        });
  }

  @override
  Widget build(BuildContext context) {
    final authViewMode = Provider.of<AuthViewModel>(context);
    double res_width = MediaQuery.of(context).size.width;
    double res_height = MediaQuery.of(context).size.height;
    final isTablet = res_width > 600;
    // Compact layout so content fits without overflow on all iPhone sizes
    final isCompact = res_height < 800;
    final spacing1 = isCompact ? 0.008 : 0.022;
    final spacing2 = isCompact ? 0.012 : 0.03;
    final spacing3 = isCompact ? 0.008 : 0.02;
    final spacing4 = isCompact ? 0.004 : 0.05;
    final topImageHeight = isCompact ? res_height * 0.17 : res_height * 0.25;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.greyColor,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [
              SizedBox(height: res_height * spacing1),
              Container(
                width: res_width * 0.9,
                height: topImageHeight,
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/welcomeloginimage.png',
                  width: res_width * 0.95,
                  height: topImageHeight - 8,
                  fit: BoxFit.contain,
                ),
              ),
              Expanded(
                child: Container(
                  width: res_width,
                  decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    SizedBox(height: res_height * spacing2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: res_width * 0.9,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                'Welcome Back',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isCompact ? 24 : 30,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                'Login to your account',
                                style: GoogleFonts.inter(
                                  fontSize: isCompact ? 14 : 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: res_height * spacing2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        Container(
                          width: res_width * 0.9,

                          child: TextFormField(
                            autocorrect: false,
                            controller: _emailController,
                            validator: (text) {
                              if (text == null ||
                                  text.isEmpty ||
                                  !text.contains("@")) {
                                return 'Enter correct email';
                              }
                              return null;
                            },
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: isCompact ? 12 : 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: AppColors.darkGreyColor,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(15),
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: AppColors.primaryColor,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(15),
                                ),
                              ),
                              filled: true,
                              hintStyle: GoogleFonts.inter(
                                color: AppColors.darkGreyColor,
                                fontWeight: FontWeight.normal,
                              ),
                              hintText: "Email Address",
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: res_height * spacing2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: res_width * 0.9,
                          child: TextFormField(
                            controller: _passwordController,
                            autocorrect: false,
                            obscureText: obscure,
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: isCompact ? 12 : 16,
                              ),
                              suffixIcon: InkWell(
                                onTap: () {

                                  setState(() {
                                    obscure = !obscure;
                                  });

                                },
                                child: Icon(
                                  obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.darkGreyColor,
                                ),
                              ),

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: AppColors.darkGreyColor,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(15),
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: AppColors.primaryColor,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(15),
                                ),
                              ),
                              filled: true,
                              hintStyle: GoogleFonts.inter(
                                color: AppColors.darkGreyColor,
                                fontWeight: FontWeight.normal,
                              ),
                              hintText: "Password",
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: res_height * spacing3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: res_width * 0.9,
                          child: InkWell(
                            onTap: () {
                              Get.to(() => ForgotScreen());
                            },
                            child: Text(
                              'Forgot Password?',
                              style: GoogleFonts.inter(
                                color: darkBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: res_height * spacing2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            if (_emailController.text
                                    .toString()
                                    .toLowerCase() ==
                                "vendor") {
                              setState(() {
                                loginType = "vendor";
                              });
                            }
                            if (_emailController.text.isEmpty ||
                                !_emailController.text.contains("@")) {
                              showAppErrorSnackbar('Please enter email', title: 'Required');
                            } else if (_passwordController.text.isEmpty) {
                              showAppErrorSnackbar('Please enter password', title: 'Required');
                            } else if (_passwordController.text.length < 6) {
                              showAppErrorSnackbar('Please enter 6 digit password', title: 'Required');
                            } else {
                              Map data = {
                                'email': _emailController.text.toString(),
                                'password': _passwordController.text.toString(),
                              };
                              authViewMode.loginApi(data, context);
                            }
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            height: isCompact ? res_height * 0.046 : res_height * 0.055,
                            width: res_width * 0.9,
                            child: Center(
                              child: Text(
                                'Login',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: res_height * spacing2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Not a member? ",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Get.to(() => RegisterScreen());
                          },
                          child: Text(
                            'Register now',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              decoration: TextDecoration.underline,
                              decorationColor: darkBlue,
                              color: darkBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: res_height * spacing3),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: res_width * 0.87,
                          child: Divider(

                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: res_height * spacing3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: _socialButtonSize,
                          height: _socialButtonSize,
                          child: RoundedLoadingButton(
                            onPressed: () => handleGoogleSignIn(_value),
                            controller: googleController,
                            successColor: Colors.red,
                            width: _socialButtonSize,
                            elevation: 0,
                            borderRadius: _socialButtonRadius,
                            valueColor: darkBlue,
                            color: Colors.white,
                            child: Center(
                              child: Image.asset(
                                'assets/images/google.png',
                                width: 36,
                                height: 36,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        SizedBox(
                          width: _socialButtonSize,
                          height: _socialButtonSize,
                          child: RoundedLoadingButton(
                            onPressed: () => handleFacebookAuth(_value),
                            controller: facebookController,
                            successColor: Colors.blue,
                            width: _socialButtonSize,
                            elevation: 0,
                            borderRadius: _socialButtonRadius,
                            valueColor: darkBlue,
                            color: Colors.white,
                            child: Center(
                              child: Image.asset(
                                'assets/images/fb.png',
                                width: 36,
                                height: 36,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        if (GetPlatform.isIOS) ...[
                          SizedBox(width: 16),
                          IOSButton(res_width, isTablet),
                        ],
                        SizedBox(width: 16),
                        SizedBox(
                          width: _socialButtonSize,
                          height: _socialButtonSize,
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(_socialButtonRadius),
                            elevation: 0,
                            child: InkWell(
                              onTap: () {
                                authViewMode.loginAsGuest(context);
                              },
                              borderRadius: BorderRadius.circular(_socialButtonRadius),
                              child: Center(
                                child: Icon(Icons.person, size: 36, color: AppColors.primaryColor),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: res_height * spacing3),
                    SizedBox(height: res_height * spacing4),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                    ],
                ),
              ),
            ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Future handleGoogleSignIn(value) async {
    final sp = context.read<SignInProvider>();
    final ip = context.read<InternetProvider>();
    await ip.checkInternetConnection();

    if (ip.hasInternet == false) {
      showAppErrorSnackbar("Check your Internet connection");
      googleController.reset();
      return;
    }

    try {
      await sp.signInWithGoogle(value, context);
      googleController.reset();
      if (sp.hasError == true) {
        showAppErrorSnackbar(sp.errorCode.toString());
      }
    } catch (e) {
      showAppErrorSnackbar(e.toString());
      googleController.reset();
    }
  }

  Future handleFacebookAuth(value) async {
    final sp = context.read<SignInProvider>();
    final ip = context.read<InternetProvider>();
    await ip.checkInternetConnection();

    if (ip.hasInternet == false) {
      showAppErrorSnackbar("Check your Internet connection");
      facebookController.reset();
    } else {
      await sp
          .signInWithFacebook(value, context)
          .then((value) {
            facebookController.reset();
            if (sp.hasError == true) {
              showAppErrorSnackbar(sp.errorCode.toString());
              facebookController.reset();
            }
          })
          .catchError((error) {
            print(error.toString());
            facebookController.reset();
          });
    }
  }

  Future handleAppleAuth(value) async {
    final sp = context.read<SignInProvider>();
    final ip = context.read<InternetProvider>();
    await ip.checkInternetConnection();

    if (ip.hasInternet == false) {
      showAppErrorSnackbar("Check your Internet connection");
      AppleController.reset();
      return;
    }

    await sp
        .signInWithApple(value, context)
        .then((value) {
          AppleController.reset();
          if (sp.hasError == true) {
            showAppErrorSnackbar(sp.errorCode.toString());
            AppleController.reset();
          }
        })
        .catchError((error) {
          print(error.toString());
          AppleController.reset();
        });
  }

  Random random = Random();

  int generateUniqueNumber() {
    int randomNumber = random.nextInt(1000000);

    // Get the current timestamp in milliseconds
    int timestamp = DateTime.now().millisecondsSinceEpoch;

    int uniqueNumber = int.parse('$randomNumber$timestamp');

    return uniqueNumber;
  }

  handleAfterSignIn() {
    Future.delayed(const Duration(milliseconds: 1000)).then((value) {
      Get.offAll(() => MainScreen());
    });
  }

  static const double _socialButtonSize = 75.0;
  static const double _socialButtonRadius = 37.5;

  Widget IOSButton(res_width, isTablet) {
    if (GetPlatform.isIOS) {
      return SizedBox(
        width: _socialButtonSize,
        height: _socialButtonSize,
        child: RoundedLoadingButton(
          onPressed: () {
            handleAppleAuth(_value);
          },
          controller: AppleController,
          successColor: Colors.black,
          width: _socialButtonSize,
          valueColor: darkBlue,
          elevation: 0,
          borderRadius: _socialButtonRadius,
          color: Colors.white,
          child: Center(
            child: Image.asset(
              'assets/images/aple.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }
    return SizedBox(width: _socialButtonSize, height: _socialButtonSize);
  }
}
