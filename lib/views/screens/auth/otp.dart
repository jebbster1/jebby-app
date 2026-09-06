import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jebby/constants/color.dart';
import 'package:jebby/utils/show_snackbar.dart';
import 'package:jebby/view_models/auth_view_model.dart';
import 'package:jebby/views/screens/auth/login.dart';
import 'package:otp_text_field/otp_text_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:provider/provider.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    this.email,
    this.name,
    this.password,
    this.role,
    this.isForgotPasswordFlow = false,
  });

  final String? email;
  final dynamic name;
  final dynamic password;
  final dynamic role;
  final bool isForgotPasswordFlow;

  static const String heroAsset = LoginScreen.heroAsset;
  static const String logoAsset = LoginScreen.logoAsset;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static Color get _rippleSplash => AppColors.jebbyBlue.withValues(alpha: 0.12);

  static Color get _rippleHighlight =>
      AppColors.jebbyBlue.withValues(alpha: 0.06);

  final OtpFieldController _otpController = OtpFieldController();
  final TextEditingController _emailAutofillController =
      TextEditingController();
  String? _otpValue;

  @override
  void dispose() {
    _emailAutofillController.dispose();
    super.dispose();
  }

  void _syncEmailOtpFromAutofill(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      _otpController.clear();
      _otpValue = null;
      return;
    }

    final code = digits.length > 4 ? digits.substring(0, 4) : digits;
    final chars = code.split('');
    while (chars.length < 4) {
      chars.add('');
    }

    _otpController.set(chars);
    _otpValue = code.length == 4 ? code : null;

    if (_emailAutofillController.text != code) {
      _emailAutofillController.value = TextEditingValue(
        text: code,
        selection: TextSelection.collapsed(offset: code.length),
      );
    }
  }

  void _handleResend(AuthViewModel authViewModel) {
    if (widget.isForgotPasswordFlow) {
      authViewModel.resendForgotPasswordOtp(widget.email.toString());
      return;
    }

    if ((widget.password ?? '').toString().isEmpty) {
      showAppErrorSnackbar('Go back and sign in again to request a new code.');
      return;
    }

    authViewModel.resendRegistrationOtp(
      email: widget.email.toString(),
      password: widget.password.toString(),
    );
  }

  void _handleVerify(AuthViewModel authViewModel) {
    if (_otpValue == null || _otpValue!.isEmpty) {
      showAppErrorSnackbar(
        'Please enter the verification code',
        title: 'Required',
      );
      return;
    }

    if (widget.isForgotPasswordFlow) {
      authViewModel.otpForgetPasswordApi({
        'email': widget.email,
        'otp': _otpValue,
      }, context);
      return;
    }

    authViewModel.otpRegisterApi({
      'email': widget.email,
      'otp': _otpValue,
      'password': widget.password,
    }, context);
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final textScale = MediaQuery.textScalerOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final logoSize = keyboardOpen ? 74.0 : 88.0;
    final logoRadius = keyboardOpen ? 17.0 : 20.0;
    final wordmarkSize = keyboardOpen ? 21.0 : 24.0;
    const logoLift = 32.0;
    const heroImageLift = 40.0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final cardHeight = constraints.maxHeight * 0.68;

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Transform.translate(
                  offset: const Offset(0, -heroImageLift),
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Image.asset(
                      OtpScreen.heroAsset,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.08),
                        Colors.black.withValues(alpha: 0.28),
                        Colors.black.withValues(alpha: 0.55),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8),
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: Get.back,
                        customBorder: const CircleBorder(),
                        splashColor: _rippleSplash,
                        highlightColor: _rippleHighlight,
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.black,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: cardHeight + logoLift,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(logoRadius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(logoRadius),
                          child: Image.asset(
                            OtpScreen.logoAsset,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: keyboardOpen ? 4 : 5),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w800,
                          fontSize: textScale.scale(wordmarkSize),
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                        child: const Text('Jebby'),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: cardHeight,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        24,
                        24,
                        16 + bottomInset,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _VerificationIcon(),
                          const SizedBox(height: 16),
                          Text(
                            'Enter confirmation code',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800,
                              fontSize: textScale.scale(28),
                              color: AppColors.jebbyTextPrimary,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'A 4-digit code was sent to ${widget.email ?? 'your email'}.',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w400,
                              fontSize: textScale.scale(15),
                              color: AppColors.jebbyTextMuted,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 28),
                          AutofillGroup(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                IgnorePointer(
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      textSelectionTheme:
                                          TextSelectionThemeData(
                                            cursorColor: AppColors.jebbyBlue,
                                            selectionColor: AppColors.jebbyBlue
                                                .withValues(alpha: 0.3),
                                          ),
                                    ),
                                    child: OTPTextField(
                                      controller: _otpController,
                                      length: 4,
                                      width: screenWidth - 48,
                                      textFieldAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      fieldWidth: 56,
                                      fieldStyle: FieldStyle.box,
                                      otpFieldStyle: OtpFieldStyle(
                                        backgroundColor: Colors.white,
                                        borderColor: Colors.grey.shade300,
                                        enabledBorderColor:
                                            Colors.grey.shade300,
                                        focusBorderColor: AppColors.jebbyBlue,
                                      ),
                                      outlineBorderRadius: 12,
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: textScale.scale(24),
                                        color: AppColors.jebbyTextPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      onChanged: (_) {},
                                      onCompleted: (pin) {
                                        _otpValue = pin;
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: screenWidth - 48,
                                  height: 56,
                                  child: TextField(
                                    controller: _emailAutofillController,
                                    autofillHints: const [
                                      AutofillHints.oneTimeCode,
                                    ],
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
                          const SizedBox(height: 20),
                          Center(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap:
                                    (authViewModel.resendOtpLoading ||
                                            authViewModel.signUpLoading)
                                        ? null
                                        : () => _handleResend(authViewModel),
                                borderRadius: BorderRadius.circular(8),
                                splashColor: _rippleSplash,
                                highlightColor: _rippleHighlight,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child:
                                      authViewModel.resendOtpLoading
                                          ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color:
                                                          AppColors.jebbyBlue,
                                                    ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                'Sending code...',
                                                style: TextStyle(
                                                  fontFamily: 'Nunito',
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: textScale.scale(15),
                                                  color:
                                                      AppColors.jebbyTextMuted,
                                                ),
                                              ),
                                            ],
                                          )
                                          : Text(
                                            'Resend code',
                                            style: TextStyle(
                                              fontFamily: 'Nunito',
                                              fontWeight: FontWeight.w700,
                                              fontSize: textScale.scale(15),
                                              color: AppColors.jebbyBlue,
                                            ),
                                          ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed:
                                  (authViewModel.signUpLoading ||
                                          authViewModel.resendOtpLoading)
                                      ? null
                                      : () => _handleVerify(authViewModel),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.jebbyBlue,
                                disabledBackgroundColor: AppColors.jebbyBlue
                                    .withValues(alpha: 0.55),
                                foregroundColor: Colors.white,
                                disabledForegroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child:
                                  authViewModel.signUpLoading
                                      ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : Text(
                                        'Continue',
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontWeight: FontWeight.w700,
                                          fontSize: textScale.scale(16),
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VerificationIcon extends StatelessWidget {
  const _VerificationIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 44,
            color: AppColors.jebbyBlue.withValues(alpha: 0.85),
          ),
          Icon(Icons.pin, size: 16, color: AppColors.jebbyAccentOrange),
        ],
      ),
    );
  }
}
