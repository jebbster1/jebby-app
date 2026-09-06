import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jebby/constants/color.dart';
import 'package:jebby/utils/show_snackbar.dart';
import 'package:jebby/view_models/auth_view_model.dart';
import 'package:jebby/views/screens/auth/login.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  static const String heroAsset = LoginScreen.heroAsset;
  static const String logoAsset = LoginScreen.logoAsset;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static Color get _rippleSplash =>
      AppColors.jebbyBlue.withValues(alpha: 0.12);

  static Color get _rippleHighlight =>
      AppColors.jebbyBlue.withValues(alpha: 0.06);

  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit(AuthViewModel authViewModel) {
    if (authViewModel.signUpLoading) return;

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      showAppErrorSnackbar('Please enter your email address', title: 'Required');
      return;
    }
    if (!_emailPattern.hasMatch(email)) {
      showAppErrorSnackbar('Please enter a valid email address', title: 'Required');
      return;
    }

    authViewModel.forgetPasswordApi(
      {'email': email},
      context,
      'forgot',
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final textScale = MediaQuery.textScalerOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final logoSize = keyboardOpen ? 74.0 : 88.0;
    final logoRadius = keyboardOpen ? 17.0 : 20.0;
    final wordmarkSize = keyboardOpen ? 21.0 : 24.0;
    const logoLift = 50.0;
    const heroImageLift = 40.0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final cardHeight = constraints.maxHeight * 0.65;

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Transform.translate(
                  offset: const Offset(0, -heroImageLift),
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Image.asset(
                      ForgotPasswordScreen.heroAsset,
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
                            ForgotPasswordScreen.logoAsset,
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
                          const _SecurityShieldIcon(),
                          const SizedBox(height: 16),
                          Text(
                            'Reset your password',
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
                            'Enter the email connected to your Jebby account. We\'ll send you a 4-digit verification code.',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w400,
                              fontSize: textScale.scale(15),
                              color: AppColors.jebbyTextMuted,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _ForgotPasswordField(
                            label: 'Email address',
                            controller: _emailController,
                            hintText: 'you@example.com',
                            textScale: textScale,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(authViewModel),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: authViewModel.signUpLoading
                                  ? null
                                  : () => _submit(authViewModel),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.jebbyBlue,
                                disabledBackgroundColor:
                                    AppColors.jebbyBlue.withValues(alpha: 0.55),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: authViewModel.signUpLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Send Code',
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w700,
                                        fontSize: textScale.scale(16),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Get.to(() => const LoginScreen()),
                                borderRadius: BorderRadius.circular(8),
                                splashColor: _rippleSplash,
                                highlightColor: _rippleHighlight,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 12,
                                  ),
                                  child: Text.rich(
                                    TextSpan(
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w400,
                                        fontSize: textScale.scale(14),
                                        color: AppColors.jebbyTextMuted,
                                      ),
                                      children: const [
                                        TextSpan(text: 'Remember your password? '),
                                        TextSpan(
                                          text: 'Log in',
                                          style: TextStyle(
                                            color: AppColors.jebbyAccentOrange,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
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

class _SecurityShieldIcon extends StatelessWidget {
  const _SecurityShieldIcon();

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
          Icon(
            Icons.lock,
            size: 16,
            color: AppColors.jebbyAccentOrange,
          ),
        ],
      ),
    );
  }
}

class _ForgotPasswordField extends StatelessWidget {
  const _ForgotPasswordField({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.textScale,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final TextScaler textScale;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            fontSize: textScale.scale(14),
            color: AppColors.jebbyTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          autocorrect: false,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
            fontSize: textScale.scale(15),
            color: AppColors.jebbyTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w400,
              fontSize: textScale.scale(15),
              color: AppColors.jebbyTextMuted,
            ),
            prefixIcon: const Icon(
              Icons.mail_outline,
              color: AppColors.jebbyTextMuted,
              size: 20,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.jebbyBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
