import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/constants/app_preferences.dart';
import 'package:jebby/views/screens/auth/login.dart';
import 'package:jebby/views/screens/navigation/home_main.dart';
import 'package:jebby/views/screens/auth/get_started.dart';
import 'package:jebby/view_models/auth_view_model.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/fcm_service.dart';
import 'services/provider/internet_provider.dart';
import 'services/provider/sign_in_provider.dart';
import 'view_models/reservation_view_model.dart';
import 'view_models/user_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  const envFile = String.fromEnvironment(
    'ENV_FILE',
    defaultValue: '.env.development',
  );
  await dotenv.load(fileName: envFile);
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'].toString();

  await FCMService().initialize();

  runApp(
    OverlaySupport.global(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.grey.shade100,
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()..getUserName()),
        ChangeNotifierProvider(create: ((context) => SignInProvider())),
        ChangeNotifierProvider(create: ((context) => InternetProvider())),
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => ReservationViewModel()),
      ],
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Jebby',
        theme: baseTheme.copyWith(
          textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
        ),
        home: const AppBootstrap(),
      ),
    );
  }
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _routeInitialScreen());
  }

  Future<void> _routeInitialScreen() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('fullname') ?? '';
      final hasSession = await UserViewModel.hasActiveSession();
      final isGuest =
          name == 'Guest' && (prefs.getString('role')?.trim() ?? '') == 'Guest';

      if (user != null && hasSession) {
        _goTo(const MainScreen());
        return;
      }

      if (!mounted) return;
      context.read<AuthViewModel>().userName = name;

      if (isGuest) {
        _goTo(const MainScreen());
        return;
      }

      if (hasSession) {
        _goTo(const MainScreen());
        return;
      }

      final hasSeenGetStarted = await AppPreferences.hasSeenRenterGetStarted();
      if (!hasSeenGetStarted) {
        _goTo(const GetStartedScreen());
        return;
      }

      _goTo(const LoginScreen());
    } catch (_) {
      _goTo(const LoginScreen());
    }
  }

  void _goTo(Widget page) {
    Get.offAll(() => page);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: Colors.grey.shade100);
  }
}
