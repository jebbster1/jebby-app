import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jebby/res/color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../utils/show_snackbar.dart';
import '../../../view_model/auth_view_model.dart';

class ForgotScreen extends StatefulWidget {
  const ForgotScreen({Key? key}) : super(key: key);

  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
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
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 22,
          ),
        ),
      ),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // Upper section: padlock illustration on grey background
            Expanded(
              flex: 45,
              child: Center(
                child: Image.asset(
                  'assets/images/padlock.png',
                  width: res_width * 0.5,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Lower section: white card with form
            Expanded(
              flex: 55,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    28,
                    24,
                    24 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Forgot Password',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "No worries. Enter your email address below and we'll send you a 4-digit verification code to reset your password.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        autocorrect: false,
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
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: "Email Address",
                          hintStyle: GoogleFonts.inter(
                            color: AppColors.darkGreyColor,
                            fontWeight: FontWeight.normal,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.darkGreyColor,
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
                        ),
                      ),
                      SizedBox(height: 28),
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
                                if (_emailController.text.isEmpty) {
                                  showAppErrorSnackbar(
                                    'Please enter email',
                                    title: 'Required',
                                  );
                                } else {
                                  authViewMode.forgetPasswordApi(
                                    {
                                      'email': _emailController.text.toString(),
                                    },
                                    context,
                                    'forgot',
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
                                'Continue',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
