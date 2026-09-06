import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jebby/constants/app_preferences.dart';
import 'package:jebby/constants/color.dart';
import 'package:jebby/views/screens/auth/login.dart';
import 'package:jebby/views/screens/auth/register.dart';

class _GetStartedSlide {
  const _GetStartedSlide({
    required this.imageAsset,
    required this.headline,
    required this.subtext,
  });

  final String imageAsset;
  final String headline;
  final String subtext;
}

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  static const String logoAsset = 'assets/images/splashicon.png';

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  static const List<_GetStartedSlide> _slides = [
    _GetStartedSlide(
      imageAsset: 'assets/images/get-started-slide-1.png',
      headline: 'Rent What You Need.\nEarn From What You Own.',
      subtext:
          'Discover useful items nearby, or list yours and turn what you already own into extra income.',
    ),
    _GetStartedSlide(
      imageAsset: 'assets/images/get-started-slide-2.png',
      headline: 'Find Gear, Tools\n& More Nearby.',
      subtext:
          'Browse party supplies, tools, beach gear, and more from trusted Earners in your area.',
    ),
    _GetStartedSlide(
      imageAsset: 'assets/images/get-started-slide-3.png',
      headline: 'List What You Own.\nStart Earning Today.',
      subtext:
          'Turn idle items into extra income, Jebby handles bookings, messaging, and secure payouts.',
    ),
  ];
  static const Duration _autoPlayInterval = Duration(seconds: 4);
  static const Duration _slideAnimationDuration = Duration(milliseconds: 600);
  static const int _pageCount = 12000;
  static const int _initialPage = 6000; // 6000 % 3 == 0 (slide 1)

  late final PageController _pageController = PageController(
    initialPage: _initialPage,
  );
  Timer? _autoPlayTimer;
  int _pageIndex = _initialPage;
  int _realSlideIndex = 0;
  bool _isUserDragging = false;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(_autoPlayInterval, (_) => _advanceSlide());
  }

  void _advanceSlide() {
    if (!mounted || !_pageController.hasClients || _isUserDragging) return;

    _pageController.animateToPage(
      _pageIndex + 1,
      duration: _slideAnimationDuration,
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _pageIndex = index;
      _realSlideIndex = index % _slides.length;
    });

    if (!_isUserDragging) {
      _startAutoPlay();
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _isUserDragging = true;
      _autoPlayTimer?.cancel();
    } else if (notification is ScrollEndNotification) {
      _isUserDragging = false;
      _startAutoPlay();
    }
    return false;
  }

  Future<void> _openSignup() async {
    await AppPreferences.markRenterGetStartedSeen();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  Future<void> _openLogin() async {
    await AppPreferences.markRenterGetStartedSeen();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const footerHeight = 196.0;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: PageView.builder(
              controller: _pageController,
              physics: const PageScrollPhysics(),
              onPageChanged: _onPageChanged,
              itemCount: _pageCount,
              itemBuilder: (context, index) {
                final slide = _slides[index % _slides.length];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      slide.imageAsset,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF0C1033).withValues(alpha: 0.15),
                            const Color(0xFF0C1033).withValues(alpha: 0.72),
                            const Color(0xFF0C1033).withValues(alpha: 0.94),
                          ],
                          stops: const [0.0, 0.38, 0.62, 1.0],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            0,
                            24,
                            footerHeight + bottomInset,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slide.headline,
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w800,
                                  fontSize: textScale.scale(30),
                                  height: 1.15,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                slide.subtext,
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w400,
                                  fontSize: textScale.scale(15),
                                  height: 1.45,
                                  color: Colors.white.withValues(alpha: 0.92),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(child: _JebbyLogo(textScale: textScale)),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: Colors.transparent,
              child: SafeArea(
                top: false,
                child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _OnboardingDots(activeIndex: _realSlideIndex),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: Semantics(
                        button: true,
                        label: 'Get Started',
                        child: FilledButton(
                          onPressed: _openSignup,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.jebbyBlue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(54),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Get Started',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w700,
                              fontSize: textScale.scale(17),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      button: true,
                      label: 'Log in',
                      child: InkWell(
                        onTap: _openLogin,
                        borderRadius: BorderRadius.circular(8),
                        splashColor: Colors.white.withValues(alpha: 0.14),
                        highlightColor: Colors.white.withValues(alpha: 0.08),
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
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                              children: const [
                                TextSpan(text: 'Already have an account? '),
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
                    SizedBox(height: bottomInset > 0 ? 4 : 12),
                  ],
                ),
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JebbyLogo extends StatelessWidget {
  const _JebbyLogo({required this.textScale});

  final TextScaler textScale;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Jebby',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              GetStartedScreen.logoAsset,
              width: 68,
              height: 68,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Jebby',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: textScale.scale(22),
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingDots extends StatelessWidget {
  const _OnboardingDots({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final active = index == activeIndex;
        return Padding(
          padding: EdgeInsets.only(right: index == 2 ? 0 : 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? AppColors.jebbyAccentOrange
                  : Colors.white.withValues(alpha: 0.45),
            ),
          ),
        );
      }),
    );
  }
}
