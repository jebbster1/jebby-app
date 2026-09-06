import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jebby/constants/color.dart';
import 'package:jebby/utils/show_snackbar.dart';
import 'package:jebby/view_models/auth_view_model.dart';
import 'package:jebby/views/screens/auth/login.dart';
import 'package:provider/provider.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  const CreateNewPasswordScreen({super.key, this.email, this.otp});

  final String? email;
  final String? otp;

  static const String heroAsset = LoginScreen.heroAsset;
  static const String logoAsset = LoginScreen.logoAsset;

  @override
  State<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  static Color get _rippleSplash => AppColors.jebbyBlue.withValues(alpha: 0.12);

  static Color get _rippleHighlight =>
      AppColors.jebbyBlue.withValues(alpha: 0.06);

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  _PasswordRequirements get _passwordRequirements =>
      _PasswordRequirements.evaluate(_passwordController.text);

  bool get _canSave {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    return _passwordRequirements.isComplete &&
        confirm.isNotEmpty &&
        password == confirm;
  }

  void _submit(AuthViewModel authViewModel) {
    if (authViewModel.signUpLoading) return;

    if (_passwordController.text.isEmpty) {
      showAppErrorSnackbar('Enter your password', title: 'Required');
      return;
    }
    if (!_passwordRequirements.isComplete) {
      showAppErrorSnackbar(
        'Password should be minimum of 8 characters and contain uppercase, lowercase, number, and special character',
      );
      return;
    }
    if (_confirmPasswordController.text.isEmpty) {
      showAppErrorSnackbar('Enter confirm password', title: 'Required');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      showAppErrorSnackbar('Password doesn\'t match');
      return;
    }

    authViewModel.changePasswordAPi({
      'email': widget.email.toString(),
      'otp': widget.otp.toString(),
      'password': _passwordController.text,
    }, context);
  }

  Widget _passwordRequirementRow({
    required String label,
    required bool met,
    required TextScaler textScale,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: met ? Colors.green.shade600 : AppColors.jebbyTextMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: textScale.scale(13),
                fontWeight: FontWeight.w500,
                color: met ? Colors.green.shade700 : AppColors.jebbyTextMuted,
              ),
            ),
          ),
        ],
      ),
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
    const logoLift = 15.0;
    const heroImageLift = 40.0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final cardHeight = constraints.maxHeight * 0.72;

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Transform.translate(
                  offset: const Offset(0, -heroImageLift),
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Image.asset(
                      CreateNewPasswordScreen.heroAsset,
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
                            CreateNewPasswordScreen.logoAsset,
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
                            'Create new password',
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
                            'Create a new password for your account.',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w400,
                              fontSize: textScale.scale(15),
                              color: AppColors.jebbyTextMuted,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _PasswordField(
                            label: 'Password',
                            controller: _passwordController,
                            hintText: 'Create a password',
                            textScale: textScale,
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            focusNode: _passwordFocusNode,
                            suffixIcon: IconButton(
                              onPressed:
                                  () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.jebbyTextMuted,
                                size: 20,
                              ),
                            ),
                          ),
                          ListenableBuilder(
                            listenable: Listenable.merge([
                              _passwordController,
                              _passwordFocusNode,
                            ]),
                            builder: (context, _) {
                              final password = _passwordController.text;
                              final requirements =
                                  _PasswordRequirements.evaluate(password);
                              final showChecklist =
                                  !requirements.isComplete &&
                                  (password.isNotEmpty ||
                                      _passwordFocusNode.hasFocus);

                              if (!showChecklist) {
                                return const SizedBox.shrink();
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 12),
                                  _passwordRequirementRow(
                                    label: 'Minimum 8 characters',
                                    met: requirements.minLength,
                                    textScale: textScale,
                                  ),
                                  _passwordRequirementRow(
                                    label: 'At least 1 uppercase letter',
                                    met: requirements.hasUppercase,
                                    textScale: textScale,
                                  ),
                                  _passwordRequirementRow(
                                    label: 'At least 1 lowercase letter',
                                    met: requirements.hasLowercase,
                                    textScale: textScale,
                                  ),
                                  _passwordRequirementRow(
                                    label: 'At least 1 number',
                                    met: requirements.hasNumber,
                                    textScale: textScale,
                                  ),
                                  _passwordRequirementRow(
                                    label: 'At least 1 special character',
                                    met: requirements.hasSpecial,
                                    textScale: textScale,
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _PasswordField(
                            label: 'Confirm password',
                            controller: _confirmPasswordController,
                            hintText: 'Re-enter your password',
                            textScale: textScale,
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              if (_canSave) _submit(authViewModel);
                            },
                            suffixIcon: IconButton(
                              onPressed:
                                  () => setState(
                                    () =>
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword,
                                  ),
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.jebbyTextMuted,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ListenableBuilder(
                            listenable: Listenable.merge([
                              _passwordController,
                              _confirmPasswordController,
                            ]),
                            builder: (context, _) {
                              final enabled =
                                  _canSave && !authViewModel.signUpLoading;

                              return SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed:
                                      enabled
                                          ? () => _submit(authViewModel)
                                          : null,
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
                                            'Save Password',
                                            style: TextStyle(
                                              fontFamily: 'Nunito',
                                              fontWeight: FontWeight.w700,
                                              fontSize: textScale.scale(16),
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
          Icon(Icons.lock, size: 16, color: AppColors.jebbyAccentOrange),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.textScale,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.textInputAction,
    this.focusNode,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final TextScaler textScale;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
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
          focusNode: focusNode,
          autocorrect: false,
          obscureText: obscureText,
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
            prefixIcon:
                prefixIcon == null
                    ? null
                    : Icon(
                      prefixIcon,
                      color: AppColors.jebbyTextMuted,
                      size: 20,
                    ),
            suffixIcon: suffixIcon,
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

class _PasswordRequirements {
  final bool minLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSpecial;

  const _PasswordRequirements({
    required this.minLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSpecial,
  });

  bool get isComplete =>
      minLength && hasUppercase && hasLowercase && hasNumber && hasSpecial;

  static _PasswordRequirements evaluate(String password) {
    return _PasswordRequirements(
      minLength: password.length >= 8,
      hasUppercase: RegExp(r'[A-Z]').hasMatch(password),
      hasLowercase: RegExp(r'[a-z]').hasMatch(password),
      hasNumber: RegExp(r'\d').hasMatch(password),
      hasSpecial: RegExp(
        r'''[!@#$%^&*(),.?":{}|<>_\-\[\]\\/`~+=;']''',
      ).hasMatch(password),
    );
  }
}
