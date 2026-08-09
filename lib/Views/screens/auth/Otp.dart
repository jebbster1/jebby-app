import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jebby/Views/helper/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/res/color.dart';
import 'package:otp_text_field/otp_text_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:provider/provider.dart';

import '../../../utils/show_snackbar.dart';
import '../../../view_model/auth_view_model.dart';

class OTPSCREEN extends StatefulWidget {
  final String? email;
  final dynamic name;
  final dynamic password;
  final dynamic role;
  final bool isForgotPasswordFlow;

  OTPSCREEN({
    super.key,
    this.email,
    this.name,
    this.password,
    this.role,
    this.isForgotPasswordFlow = false,
  });

  @override
  State<OTPSCREEN> createState() => _OTPSCREENState();
}

class _OTPSCREENState extends State<OTPSCREEN> {
  OtpFieldController otpController = OtpFieldController();
  final TextEditingController _emailAutofillController = TextEditingController();
  String? OtpValue;

  @override
  void dispose() {
    _emailAutofillController.dispose();
    super.dispose();
  }

  void _syncEmailOtpFromAutofill(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      otpController.clear();
      OtpValue = null;
      return;
    }

    final code = digits.length > 4 ? digits.substring(0, 4) : digits;
    final chars = code.split('');
    while (chars.length < 4) {
      chars.add('');
    }

    otpController.set(chars);
    OtpValue = code.length == 4 ? code : null;

    if (_emailAutofillController.text != code) {
      _emailAutofillController.value = TextEditingValue(
        text: code,
        selection: TextSelection.collapsed(offset: code.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double res_width = MediaQuery.of(context).size.width;
    double res_height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'OTP Verification',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        leading: InkWell(
          onTap: () => Get.back(),
          borderRadius: BorderRadius.circular(50),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: res_height * 0.02),
              Center(
                child: Image.asset(
                  'assets/images/otp.png',
                  width: res_width * 0.5,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: res_height * 0.04),
              Text(
                'Enter confirmation code',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'A 4-digit code was sent to ${widget.email}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              SizedBox(height: res_height * 0.05),
              AutofillGroup(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IgnorePointer(
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          textSelectionTheme: TextSelectionThemeData(
                            cursorColor: AppColors.primaryColor,
                            selectionColor:
                                AppColors.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: OTPTextField(
                          controller: otpController,
                          length: 4,
                          width: res_width,
                          textFieldAlignment: MainAxisAlignment.spaceEvenly,
                          fieldWidth: 56,
                          fieldStyle: FieldStyle.box,
                          otpFieldStyle: OtpFieldStyle(
                            backgroundColor: Colors.white,
                            borderColor: Colors.grey.shade300,
                            enabledBorderColor: Colors.grey.shade300,
                            focusBorderColor: AppColors.primaryColor,
                          ),
                          outlineBorderRadius: 12,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                          onChanged: (pin) {},
                          onCompleted: (pin) {
                            OtpValue = pin;
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: res_width,
                      height: 56,
                      child: TextField(
                        controller: _emailAutofillController,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        maxLength: 4,
                        showCursor: false,
                        enableSuggestions: true,
                        autocorrect: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          color: Colors.transparent,
                          fontSize: 1,
                          height: 1,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: _syncEmailOtpFromAutofill,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: res_height * 0.04),
              Consumer<AuthViewModel>(
                builder: (context, authViewMode, _) {
                  final isResending = authViewMode.resendOtpLoading;
                  final isVerifying = authViewMode.signUpLoading;

                  return InkWell(
                    onTap: (isResending || isVerifying)
                        ? null
                        : () {
                            if (widget.isForgotPasswordFlow) {
                              authViewMode.resendForgotPasswordOtp(
                                widget.email.toString(),
                              );
                            } else if ((widget.password ?? '')
                                .toString()
                                .isEmpty) {
                              showAppErrorSnackbar(
                                'Go back and sign in again to request a new code.',
                              );
                            } else {
                              authViewMode.resendRegistrationOtp(
                                email: widget.email.toString(),
                                password: widget.password.toString(),
                              );
                            }
                          },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isResending) ...[
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Sending code...',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ] else
                            Text(
                              'Resend code',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: darkBlue,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: res_height * 0.04),
              Consumer<AuthViewModel>(
                builder: (context, authViewMode, _) {
                  final isVerifying = authViewMode.signUpLoading;
                  final isResending = authViewMode.resendOtpLoading;

                  if (isVerifying) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    );
                  }

                  return SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isResending
                          ? null
                          : () {
                              if (OtpValue == null || OtpValue!.isEmpty) {
                                showAppErrorSnackbar(
                                  'Please Enter Otp',
                                  title: 'Required',
                                );
                              } else if (widget.isForgotPasswordFlow) {
                                authViewMode.otpForgetPasswordApi(
                                  {
                                    "email": widget.email,
                                    "otp": OtpValue,
                                  },
                                  context,
                                );
                              } else {
                                authViewMode.otpRegisterApi(
                                  {
                                    "email": widget.email,
                                    "otp": OtpValue,
                                    "password": widget.password,
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
                        'Continue',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: res_height * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}
