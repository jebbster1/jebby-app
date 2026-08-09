import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jebby/res/color.dart';
import 'package:provider/provider.dart';

import '../../../utils/show_snackbar.dart';
import '../../../view_model/auth_view_model.dart';

class CreatePasswordScreen extends StatefulWidget {
  final String? email;
  final String? otp;
  const CreatePasswordScreen({Key? key, this.email, this.otp}) : super(key: key);

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmpasswordController = TextEditingController();
  bool obscureText = true;
  bool obscureText1 = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmpasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double res_width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.greyColor,
      appBar: AppBar(
        backgroundColor: AppColors.greyColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: InkWell(
          onTap: () {
            Get.back();
          },
          borderRadius: BorderRadius.circular(50),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
        ),
      ),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // Upper section: illustration on light grey background
            Expanded(
              flex: 40,
              child: Center(
                child: Image.asset(
                  'assets/images/createPassword.png',
                  width: res_width * 0.55,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(height: 10),
            // White content card
            Expanded(
              flex: 60,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    28,
                    24,
                    24 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create New Password',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.black87,
                          fontFamily: "Inter, ExtraBold"
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Create a New Password for your account',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                          height: 1.4,
                          fontFamily: "Inter, Regular"
                        ),
                      ),
                      SizedBox(height: 28),
                      TextFormField(
                        obscureText: obscureText,
                        autocorrect: false,
                        controller: _passwordController,
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontFamily: "Inter, Regular"
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter Password',
                          hintStyle: TextStyle(
                            color: AppColors.darkGreyColor,
                            fontWeight: FontWeight.normal,
                            fontFamily: "Inter, Regular"
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.primaryColor,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => obscureText = !obscureText);
                            },
                            icon: Icon(
                              obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.darkGreyColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        obscureText: obscureText1,
                        autocorrect: false,
                        controller: _confirmpasswordController,
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontFamily: "Inter, Regular"
                        ),
                        decoration: InputDecoration(
                          hintText: 'Confirm Password',
                          hintStyle: TextStyle(
                            color: AppColors.darkGreyColor,
                            fontWeight: FontWeight.normal,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.primaryColor,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => obscureText1 = !obscureText1);
                            },
                            icon: Icon(
                              obscureText1
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.darkGreyColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 32),
                      Consumer<AuthViewModel>(
                        builder: (context, authViewMode, _) {
                          final isLoading = authViewMode.signUpLoading;

                          if (isLoading) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 15),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            );
                          }

                          return SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_passwordController.text.isEmpty) {
                                  showAppErrorSnackbar(
                                    'Enter Your Password',
                                    title: 'Required',
                                  );
                                } else if (!_passwordController.text.contains(
                                    RegExp(
                                        r'^(?=.*?[A-Z])(?=.*?[!@#\$&*~]).{8,}$'))) {
                                  showAppErrorSnackbar(
                                    'Password should be minimum of 8 characters and contain small letter, capital letter and special character',
                                  );
                                } else if (_confirmpasswordController
                                    .text.isEmpty) {
                                  showAppErrorSnackbar(
                                    'Enter Confirm Password',
                                    title: 'Required',
                                  );
                                } else if (_passwordController.text !=
                                    _confirmpasswordController.text) {
                                  showAppErrorSnackbar(
                                    'Password doesn\'t match',
                                  );
                                } else {
                                  authViewMode.changePasswordAPi(
                                    {
                                      'email': widget.email.toString(),
                                      'otp': widget.otp.toString(),
                                      'password':
                                          _passwordController.text.toString(),
                                    },
                                    context,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Text(
                                'Save Password',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  fontFamily: 'Inter, Regular',
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
