import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jebby/Services/provider/sign_in_provider.dart';
import 'package:jebby/Views/helper/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/res/color.dart';
import 'package:otp_text_field/otp_text_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:provider/provider.dart';

import '../../../utils/utils.dart';
import '../../../view_model/auth_view_model.dart';

class OTPSCREEN extends StatefulWidget {
  final String? email;
  final dynamic name;
  final dynamic password;
  final dynamic role;
  final bool isGuestUserFlow;
  final bool isForgotPasswordFlow;
  final bool fromPhoneAuth;
  final dynamic verificationId;
  final dynamic phoneNumber;

  OTPSCREEN({
    super.key,
    this.email,
    this.name,
    this.password,
    this.role,
    this.isGuestUserFlow = false,
    this.isForgotPasswordFlow = false,
    this.fromPhoneAuth = false,
    this.verificationId = null,
    this.phoneNumber = null,
  });

  @override
  State<OTPSCREEN> createState() => _OTPSCREENState();
}

class _OTPSCREENState extends State<OTPSCREEN> {
  OtpFieldController otpController = OtpFieldController();
  TextEditingController _otpController = TextEditingController();
  final TextEditingController _emailAutofillController = TextEditingController();
  String? OtpValue;
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
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
    final authViewMode = Provider.of<AuthViewModel>(context);
    double res_width = MediaQuery.of(context).size.width;
    double res_height = MediaQuery.of(context).size.height;

    final sentTo = widget.fromPhoneAuth
        ? widget.phoneNumber.toString()
        : widget.email.toString();

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
                  'assets/slicing/otp.png',
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
                'A 4-digit code was sent to $sentTo',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              SizedBox(height: res_height * 0.05),
              if (!widget.fromPhoneAuth)
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
                )
              else
                AutofillGroup(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      controller: _otpController,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      maxLength: 6,
                    style: GoogleFonts.inter(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.primaryColor,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Enter code',
                      hintStyle: GoogleFonts.inter(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              ),
              SizedBox(height: res_height * 0.04),
              InkWell(
                onTap: () async {
                  if (widget.fromPhoneAuth) {
                    final sp = context.read<SignInProvider>();
                    await sp.signInWithPhone(widget.phoneNumber, context);
                  } else if (widget.isForgotPasswordFlow) {
                    Map data = {"email": widget.email.toString()};
                    authViewMode.forgetPasswordApi(data, context, "forgot");
                  } else {
                    Map data = {"email": widget.email.toString()};
                    authViewMode.forgetPasswordApi(
                      data,
                      context,
                      "register",
                      isGuestUserFlow: widget.isGuestUserFlow,
                    );
                  }
                },
                child: Text(
                  'Resend code',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: darkBlue,
                  ),
                ),
              ),
              SizedBox(height: res_height * 0.04),
              _isLoading
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(color: AppColors.primaryColor),
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (widget.fromPhoneAuth) {
                            if (_otpController.text.isEmpty) {
                              Utils.flushBarErrorMessage(
                                  "Please Enter Otp", context);
                            } else {
                              final sp = context.read<SignInProvider>();
                              setState(() => _isLoading = true);
                              await sp.signInWithPhoneCode(
                                widget.verificationId,
                                _otpController.text,
                                context,
                              );
                              if (mounted) setState(() => _isLoading = false);
                            }
                          } else {
                            if (OtpValue == null || OtpValue!.isEmpty) {
                              Utils.flushBarErrorMessage(
                                  "Please Enter Otp", context);
                            } else if (widget.isForgotPasswordFlow) {
                              Map data = {
                                "email": widget.email,
                                "otp": OtpValue,
                              };
                              authViewMode.otpForgetPasswordApi(data, context);
                            } else {
                              Map data = {
                                "email": widget.email,
                                "otp": OtpValue,
                                "password": widget.password,
                              };
                              authViewMode.otpRegisterApi(
                                data,
                                context,
                                isGuestUserFlow: widget.isGuestUserFlow,
                              );
                            }
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
                    ),
              SizedBox(height: res_height * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}
