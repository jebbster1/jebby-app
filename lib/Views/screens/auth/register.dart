import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/Views/helper/colors.dart';
import 'package:jebby/Views/screens/auth/login.dart';
import 'package:jebby/Views/screens/onboarding/onboarding_scaffold.dart';
import 'package:provider/provider.dart';

import '../../../res/color.dart';
import '../../../view_model/auth_view_model.dart';

class RegisterScreen extends StatefulWidget {
  final bool isGuestUserFlow;
  const RegisterScreen({Key? key, this.isGuestUserFlow = false})
    : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool onlinepay = false;
  bool cod = false;
  int _value = 0; //="User";
  bool obscureText = true;
  bool obscureText1 = true;
  final ValueNotifier<bool> _termsAccepted = ValueNotifier(false);
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmpasswordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  late final Listenable _formFieldsListenable = Listenable.merge([
    _firstNameController,
    _lastNameController,
    _emailController,
    _passwordController,
    _confirmpasswordController,
    _termsAccepted,
  ]);

  static final RegExp _emailPattern = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.(com)",
  );

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    _termsAccepted.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmpasswordController.dispose();
    super.dispose();
  }

  _PasswordRequirements get _passwordRequirements =>
      _PasswordRequirements.evaluate(_passwordController.text);

  bool get _isRegisterEnabled {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmpasswordController.text;

    return firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        email.isNotEmpty &&
        _emailPattern.hasMatch(email) &&
        _passwordRequirements.isComplete &&
        confirm.isNotEmpty &&
        password == confirm &&
        _termsAccepted.value;
  }

  Widget _passwordRequirementRow({
    required String label,
    required bool met,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            met ? '✅' : '❌',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: met ? Colors.green.shade700 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitRegistration(AuthViewModel authViewMode) {
    if (!_isRegisterEnabled || authViewMode.signUpLoading) return;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final fullName = '$firstName $lastName'.trim();

    Map data = {
      "full_name": fullName,
      "email": _emailController.text.toString(),
      "password": _passwordController.text.toString(),
      "source": "simple",
      "role": _value.toString(),
    };
    authViewMode.signUpApi(
      data,
      context,
      isFromGuestFlow: widget.isGuestUserFlow,
    );
  }

  Widget _buildRegisterButton({
    required AuthViewModel authViewMode,
    required double resWidth,
    required bool isLoading,
  }) {
    final enabled = _isRegisterEnabled && !isLoading;

    return SizedBox(
      width: resWidth * 0.9,
      child: OnboardingPrimaryButton(
        label: 'Register',
        isLoading: isLoading,
        onPressed: enabled ? () => _submitRegistration(authViewMode) : null,
      ),
    );
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
        leading: InkWell(
          onTap: () {
            Get.back();
          },
          borderRadius: BorderRadius.circular(50),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
        ),
      ),
      body: Container(
        width: double.infinity,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // SizedBox(
                //   height: res_height * 0.175,
                // ),
                Container(
                  width: res_width * 0.9,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Center(
                      //   child: Image.asset(
                      //     "assets/slicing/logo.png",
                      //     width: 200,
                      //   ),
                      // ),
                      Text(
                        'Create account!',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Signup now to get started',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
                // SizedBox(
                //   height: res_height * 0.05,
                // ),
                // Row(
                //   children: [
                //     // GestureDetector(
                //     //   onTap: () {
                //     //     setState(() {
                //     //       onlinepay = false;
                //     //       if (onlinepay == false) {
                //     //         registerFor = "1";
                //     //       }
                //     //       // cod = false;
                //     //     });
                //     //   },
                //     //   child: Container(
                //     //     height: 19,
                //     //     width: 19,
                //     //     decoration: BoxDecoration(
                //     //         shape: BoxShape.circle, border: Border.all(color: onlinepay == false ? Color(0xff303030) : Colors.black, width: 3)),
                //     //     child: Icon(
                //     //       Icons.circle_rounded,
                //     //       color: onlinepay == false ? Color(0xff303030) : Colors.white,
                //     //       size: 13,
                //     //     ),
                //     //   ),
                //     // ),
                //     Radio(
                //         activeColor: Colors.black,
                //         value: 0,
                //         groupValue: _value,
                //         onChanged: (value) {
                //           setState(() {
                //             _value = int.parse(value.toString());
                //           }); //selected value
                //         }),

                //     Text(
                //       "User",
                //       style: TextStyle(fontSize: 15, color: Colors.black, fontFamily: "Inter, Regular"),
                //     ),
                //     SizedBox(
                //       width: 20,
                //     ),
                //     // GestureDetector(
                //     //   onTap: () {
                //     //     setState(() {
                //     //       onlinepay = true;
                //     //       if (onlinepay == false) {
                //     //         _value = 0;
                //     //       }
                //     //       // cod = true;
                //     //     });
                //     //   },
                //     //   child: Container(
                //     //     height: 19,
                //     //     width: 19,
                //     //     decoration: BoxDecoration(
                //     //         shape: BoxShape.circle, border: Border.all(color: onlinepay == true ? Color(0xff303030) : Colors.black, width: 3)),
                //     //     child: Icon(
                //     //       Icons.circle_rounded,
                //     //       color: onlinepay == true ? Color(0xff303030) : Colors.white,
                //     //       size: 13,
                //     //     ),
                //     //   ),
                //     // ),
                //     Radio(
                //         value: 1,
                //         activeColor: Colors.black,
                //         groupValue: _value,
                //         onChanged: (value) {
                //           setState(() {
                //             _value = int.parse(value.toString());
                //           }); //selected value
                //         }),

                //     Text(
                //       "Provider",
                //       // "Vendor",
                //       style: TextStyle(fontSize: 15, color: Colors.black, fontFamily: "Inter, Regular"),
                //     ),
                //   ],
                // ),

                // Row(
                //   children: [
                //     Icon(Icons.circle_notifications_outlined),
                //     SizedBox(
                //       width: res_width * 0.01,
                //     ),
                //     Container(
                //       child: Text("User"),
                //     ),
                //     SizedBox(
                //       width: res_width * 0.05,
                //     ),
                //     Icon(Icons.circle_notifications_outlined),
                //     SizedBox(
                //       width: res_width * 0.01,
                //     ),
                //     Container(
                //       child: Text("Vender"),
                //     ),
                //   ],
                // ),
                SizedBox(height: res_height * 0.03),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'First name',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(
                      height: res_height * 0.01,
                    ),
                    Container(
                      width: res_width * 0.9,
                      child: TextFormField(
                        controller: _firstNameController,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.darkGreyColor,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.all(
                              Radius.circular(15),
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.primaryColor,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.all(
                              Radius.circular(15),
                            ),
                          ),
                          hintStyle: GoogleFonts.inter(
                            color: AppColors.darkGreyColor,
                            fontWeight: FontWeight.normal,
                          ),
                          hintText: 'John',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: res_height * 0.02),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last name',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(
                      height: res_height * 0.01,
                    ),
                    Container(
                      width: res_width * 0.9,
                      child: TextFormField(
                        controller: _lastNameController,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.darkGreyColor,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.all(
                              Radius.circular(15),
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.primaryColor,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.all(
                              Radius.circular(15),
                            ),
                          ),
                          hintStyle: GoogleFonts.inter(
                            color: AppColors.darkGreyColor,
                            fontWeight: FontWeight.normal,
                          ),
                          hintText: 'Doe',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: res_height * 0.02),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text('Email'),
                    // SizedBox(
                    //   height: res_height * 0.01,
                    // ),
                    Text(
                      'Email',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(
                      height: res_height * 0.01,
                    ),
                    Container(
                      width: res_width * 0.9,
                      child: TextFormField(
                        controller: _emailController,
                        autocorrect: false,
                        // controller: userEmailController,
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
                      //    prefixIcon: Icon(Icons.email, color: darkBlue),
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
                          hintText: "name@emailaddress.com",
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: res_height * 0.02),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text('Password'),
                    // SizedBox(
                    //   height: res_height * 0.01,
                    // ),
                    Text(
                      'Password',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(
                      height: res_height * 0.01,
                    ),
                    Container(
                      width: res_width * 0.9,
                      child: TextFormField(
                        obscureText: obscureText,
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        autocorrect: false,
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                         // prefixIcon: Icon(Icons.lock, color: darkBlue),
                          suffixIcon: InkWell(
                            onTap: () {
                              setState(() {
                                obscureText = !obscureText;
                              });
                            },
                            child: Icon(
                              obscureText
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
                          hintText: "Create a Password",
                          fillColor: Colors.white,
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
                        final showChecklist = !requirements.isComplete &&
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
                            ),
                            _passwordRequirementRow(
                              label: 'At least 1 uppercase letter',
                              met: requirements.hasUppercase,
                            ),
                            _passwordRequirementRow(
                              label: 'At least 1 lowercase letter',
                              met: requirements.hasLowercase,
                            ),
                            _passwordRequirementRow(
                              label: 'At least 1 number',
                              met: requirements.hasNumber,
                            ),
                            _passwordRequirementRow(
                              label: 'At least 1 special character',
                              met: requirements.hasSpecial,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: res_height * 0.02),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text('Confirm Password'),
                    // SizedBox(
                    //   height: res_height * 0.01,
                    // ),
                    Container(
                      width: res_width * 0.9,
                      child: TextFormField(
                        obscureText: obscureText1,
                        controller: _confirmpasswordController,
                        autocorrect: false,
                        // obscureText: true,
                        // controller: userEmailController,
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
                       //   prefixIcon: Icon(Icons.lock, color: darkBlue),
                          suffixIcon: InkWell(
                            onTap: () {
                              setState(() {
                                obscureText1 = !obscureText1;
                              });
                            },
                            child: Icon(
                              obscureText1
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
                          hintText: "Confirm Password",
                          fillColor: Colors.white,

                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: res_height * 0.015),
                ValueListenableBuilder<bool>(
                  valueListenable: _termsAccepted,
                  builder: (context, termsAccepted, _) {
                    return CheckboxListTile(
                      title: Text(
                        "I agree to the Terms of Services and Privacy Policy",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      value: termsAccepted,
                      activeColor: AppColors.primaryColor,
                      onChanged: (newValue) {
                        _termsAccepted.value = newValue ?? false;
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
                SizedBox(height: res_height * 0.02),
                Consumer<AuthViewModel>(
                  builder: (context, authViewMode, _) {
                    return ListenableBuilder(
                      listenable: _formFieldsListenable,
                      builder: (context, __) {
                        return _buildRegisterButton(
                          authViewMode: authViewMode,
                          resWidth: res_width,
                          isLoading: authViewMode.signUpLoading,
                        );
                      },
                    );
                  },
                ),
                SizedBox(height: res_height * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Get.to(() => LoginScreen());
                      },
                      child: Text(
                        'Signin',
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
                SizedBox(height: res_height * 0.08),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TermsController extends GetxController {
  RxBool termsValue = false.obs;
  void chanegValue(data) {
    termsValue.value = data;
    update();
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
      hasSpecial: RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-\[\]\\/`~+=;']''')
          .hasMatch(password),
    );
  }
}
