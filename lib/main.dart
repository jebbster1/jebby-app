import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/provider/prodetail_provider.dart';

import 'package:jebby/view_model/auth_view_model.dart';
import 'package:jebby/Views/screens/mainfolder/homemain.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Services/firebase_authMethod.dart';
import 'Services/provider/internet_provider.dart';
import 'Services/provider/sign_in_provider.dart';
import 'package:provider/provider.dart';

import 'provider/get_products_provider.dart';
import 'view_model/services/splash_services.dart';
import 'view_model/user_view_model.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'Services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'].toString();

  // Initialize FCM service
  await FCMService().initialize();

  runApp(
    OverlaySupport.global(
      child: MyApp(), // Replace with your actual app widget
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
      useMaterial3: true,
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()..getUserName()),
        Provider<FirebaseAuthMethods>(
          create: (_) => FirebaseAuthMethods(FirebaseAuth.instance),
        ),
        StreamProvider(
          create: (context) => context.read<FirebaseAuthMethods>().authState,
          initialData: null,
        ),
        ChangeNotifierProvider(create: ((context) => SignInProvider())),
        ChangeNotifierProvider(create: ((context) => InternetProvider())),
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => UserNameProvider()),
        ChangeNotifierProvider<ProductProvider>(
          create: (context) => ProductProvider(),
        ),
        ChangeNotifierProvider<ProDetailProvider>(
          create: (context) => ProDetailProvider(),
        ),
      ],
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Jebby',
        //   theme: ThemeData(primarySwatch: Colors.blue),
        theme: baseTheme.copyWith(
          textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
        ),
        home: SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  SplashServices splashServices = SplashServices();

  @override
  void initState() {
      isLogin();
    super.initState();
  }

  var Name;

  void isLogin() async {
    // final sp = context.read<SignInProvider>();
    FirebaseAuth auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    Name = sharedPreferences.getString('fullname') ?? "";

    if (user != null) {
      Timer(const Duration(seconds: 2), () {
        Get.offAll(() => MainScreen());
      });
    }
    else
    {

      String _name = sharedPreferences.getString('fullname') ?? "";
      context.read<AuthViewModel>().userName = _name;
      if (_name == "Guest") {
        Timer(const Duration(seconds: 2), () {
          Get.offAll(() => MainScreen());
        });
      } else {
        splashServices.checkAuthentication(context);
      }

    }

  }

  @override
  Widget build(BuildContext context) {
    double res_width = MediaQuery.of(context).size.width;
    double res_height = MediaQuery.of(context).size.height;
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/newpacks/onboarding.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.center,
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: res_height * 0.1),
              Container(
                width: res_width * 0.6,
                child: Image.asset('assets/newpacks/appicon.png'),
              ),
              SizedBox(height: res_height * 0.34),
              Container(
                width: res_width * 0.8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Explore Renting At\nYour Fingertips',
                      textAlign: TextAlign.start,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        fontSize: 23,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: res_height * 0.018),
              Container(
                width: res_width * 0.8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,

                  children: [
                    Container(
                      width: res_width * 0.7,
                      child: Text(
                        'Enjoy these pre-made components and worry only about creating the best product ever.',
                        textAlign: TextAlign.start,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w300,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // SizedBox(height: res_height * 0.058),

              // Container(
              //   width: res_width * 0.8,
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       Text(
              //         'Skip',
              //         textAlign: TextAlign.start,

              //         style: TextStyle(
              //           fontWeight: FontWeight.w900,
              //           fontSize: 16,
              //           color: Colors.white,
              //         ),
              //       ),

              //       GestureDetector(
              //         onTap: () {
              //           // Get.to(() => LoginScreen());
              //           // Get.to(() => MainScreen());
              //         },
              //         child: Container(
              //           width: res_width * 0.15,
              //           decoration: BoxDecoration(
              //             color: AppColors.primaryColor,
              //             borderRadius: BorderRadius.all(Radius.circular(13)),
              //           ),
              //           child: Padding(
              //             padding: const EdgeInsets.all(15.0),
              //             child: Center(
              //               child: Icon(
              //                 Icons.arrow_forward,
              //                 color: Colors.white,
              //                 //size: 30,
              //               ),
              //             ),
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
