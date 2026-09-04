import 'dart:convert';

import 'package:get/get.dart';
import 'package:jebby/views/screens/onboarding/all_set.dart';
import 'package:jebby/views/screens/onboarding/bank_account.dart';
import 'package:jebby/views/screens/onboarding/personal_details.dart';
import 'package:jebby/views/screens/onboarding/review_submit.dart';
import 'package:jebby/views/screens/onboarding/start_earning_intro.dart';
import 'package:jebby/views/screens/onboarding/verify_identity.dart';
import 'package:jebby/models/onboarding_state.dart';
import 'package:jebby/models/provider_onboarding_data.dart';
import 'package:jebby/repositories/auth_repository.dart';
import 'package:jebby/repositories/api_repository.dart';
import 'package:jebby/view_models/user_view_model.dart';
import 'package:jebby/services/analytics_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

OnboardingController ensureOnboardingController() {
  if (Get.isRegistered<OnboardingController>()) {
    return Get.find<OnboardingController>();
  }
  return Get.put(OnboardingController());
}

class OnboardingController extends GetxController {
  static const String _keyStep = 'onboarding_step';
  static const String _keyStatus = 'onboarding_status';
  static const String _keyStripeAccountId = 'stripe_account_id';
  static const String _keyStripeComplete = 'is_stripe_onboarding_complete';
  static const String _keyProviderData = 'provider_onboarding_data';
  static const String _keyIntroSeen = 'onboarding_intro_seen';

  OnboardingState _state = const OnboardingState();
  ProviderOnboardingData providerData = ProviderOnboardingData();
  bool _introSeen = false;
  bool get introSeen => _introSeen;
  bool isLoading = false;
  String userId = '';
  String userName = '';
  String userEmail = '';
  String userPhone = '';

  OnboardingState get state => _state;

  Future<void> loadAndReconcile({
    required String userId,
    String? name,
    String? email,
    String? phone,
  }) async {
    this.userId = userId;

    final prefs = await SharedPreferences.getInstance();
    userName = _resolveProfileName(
      name ?? prefs.getString('fullname') ?? '',
    );
    userEmail = _resolveProfileEmail(
      email ?? prefs.getString('email') ?? '',
    );
    userPhone = _sanitizePhone(
      phone ?? prefs.getString('phoneNumber') ?? '',
    );

    isLoading = true;
    update();

    await _loadFromLocalCache();
    await _loadProviderData();
    await _sanitizeLoadedProviderIdentity();
    _prefillProviderDataFromProfile();
    await _reconcileWithServer();
    await _reconcileWithStripeStatus();

    isLoading = false;
    update();
  }

  Future<void> _loadFromLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? '0';
    final identityVerified = prefs.getBool('is_identity_verified') ?? false;

    final rawStep = prefs.getInt(_keyStep) ?? OnboardingSteps.formStart;
    final rawStatus = prefs.getString(_keyStatus);

    final migratedStep = _normalizeStoredStep(rawStep, rawStatus);

    _state = OnboardingState(
      onboardingStep: migratedStep,
      onboardingStatus:
          rawStatus ??
          (identityVerified || role == '1'
              ? OnboardingStatus.complete
              : OnboardingStatus.notStarted),
      stripeAccountId: prefs.getString(_keyStripeAccountId),
      stripeOnboardingComplete: prefs.getBool(_keyStripeComplete) ?? false,
    );
    _introSeen = prefs.getBool(_keyIntroSeen) ?? false;
    if (_state.onboardingStep >= OnboardingSteps.formStart &&
        _state.onboardingStatus != OnboardingStatus.notStarted) {
      _introSeen = true;
    }

    if (migratedStep != rawStep) {
      await _persistLocal();
    }
  }

  int _normalizeStoredStep(int step, String? status) {
    if (status == OnboardingStatus.complete || step >= OnboardingSteps.formEnd) {
      return OnboardingSteps.formEnd;
    }
    if (status == OnboardingStatus.stripePending) {
      return step < 8 ? 8 : OnboardingSteps.normalize(step);
    }
    return OnboardingSteps.normalize(step);
  }

  Future<void> _reconcileWithServer() async {
    if (userId.isEmpty) return;

    try {
      await ApiRepository.shared.getOnboardingState(
        userId,
        (data) {
          if (data is Map<String, dynamic> && data.isNotEmpty) {
            final serverState = OnboardingState.fromJson(data);
            _state = _mergeStates(_state, serverState);
            _state = _state.copyWith(
              onboardingStep: _normalizeStoredStep(
                _state.onboardingStep,
                _state.onboardingStatus,
              ),
            );
            _persistLocal();
          }
        },
        (_) {},
      );
    } catch (_) {}
  }

  Future<void> _reconcileWithStripeStatus() async {
    if (userId.isEmpty) return;

    try {
      await ApiRepository.shared.checkStripeAccountStatus(
        userId,
        (response) {
          if (response is! Map) return;

          final status = response['status']?.toString() ?? '';
          final account = response['account'];
          final detailsSubmitted = account is Map
              ? (account['details_submitted'] == true)
              : (response['details_submitted'] == true);
          final isActive = status == 'active' || detailsSubmitted;

          if (isActive) {
            final accountId = account is Map
                ? account['id']?.toString()
                : response['account_id']?.toString();

            _state = _state.copyWith(
              onboardingStep: 10,
              onboardingStatus: OnboardingStatus.complete,
              stripeOnboardingComplete: true,
              stripeAccountId: accountId ?? _state.stripeAccountId,
            );
            _persistLocal(setIdentityVerified: true);
          } else if (_state.onboardingStatus == OnboardingStatus.stripePending) {
            _state = _state.copyWith(
              onboardingStep:
                  _state.onboardingStep < 8 ? 8 : _state.onboardingStep,
            );
            _persistLocal();
          }
        },
        (_) {},
      );
    } catch (_) {}
  }

  OnboardingState _mergeStates(
    OnboardingState local,
    OnboardingState server,
  ) {
    if (server.isComplete) return server;
    if (local.isComplete) return local;
    if (server.onboardingStep > local.onboardingStep) return server;
    if (local.onboardingStep > server.onboardingStep) return local;
    return server;
  }

  Future<void> advanceTo(int step) async {
    String status;
    if (step >= 10) {
      status = OnboardingStatus.complete;
    } else if (_state.onboardingStatus == OnboardingStatus.stripePending) {
      status = OnboardingStatus.stripePending;
    } else {
      status = OnboardingStatus.inProgress;
    }

    _state = _state.copyWith(
      onboardingStep: step,
      onboardingStatus: status,
    );

    await _persistLocal();
    _syncToServer();

    if (step >= OnboardingSteps.formStart && step <= OnboardingSteps.formEnd) {
      AnalyticsService.instance.track(
        'stripe_onboarding_step_completed',
        props: {'step': step},
      );
    }

    update();
  }

  Future<void> markStripePending({String? accountId}) async {
    _state = _state.copyWith(
      onboardingStep: 8,
      onboardingStatus: OnboardingStatus.stripePending,
      stripeAccountId: accountId ?? _state.stripeAccountId,
    );
    await _persistLocal();
    _syncToServer();
    update();
  }

  Future<void> updateProviderData(ProviderOnboardingData data) async {
    providerData = data;
    await _persistProviderData();
    update();
  }

  Future<void> _loadProviderData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyProviderData);
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        final previousSsn = providerData.ssnLast4;
        providerData = ProviderOnboardingData.fromPersistedJson(map);
        final loadedSsn = providerData.ssnLast4;
        if ((loadedSsn == null || loadedSsn.isEmpty) &&
            previousSsn != null &&
            previousSsn.isNotEmpty) {
          providerData.ssnLast4 = previousSsn;
        }
      }
    } catch (_) {}
  }

  Future<void> _persistProviderData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyProviderData,
      jsonEncode(providerData.toPersistedJson()),
    );
  }

  Future<void> _sanitizeLoadedProviderIdentity() async {
    var changed = false;
    if (_isPlaceholderName(providerData.firstName)) {
      providerData.firstName = '';
      changed = true;
    }
    if (!_isValidStoredPhone(providerData.phone)) {
      providerData.phone = '';
      changed = true;
    }
    if (changed) {
      await _persistProviderData();
    }
  }

  void _prefillProviderDataFromProfile() {
    if (providerData.firstName.isEmpty && userName.isNotEmpty) {
      final parts = userName.trim().split(RegExp(r'\s+'));
      providerData.firstName = parts.first;
      if (parts.length > 1) {
        providerData.lastName = parts.sublist(1).join(' ');
      }
    }
    if (providerData.email.isEmpty && userEmail.isNotEmpty) {
      providerData.email = userEmail;
    }
    if (providerData.phone.isEmpty && userPhone.isNotEmpty) {
      providerData.phone = userPhone;
    }
    if (providerData.accountHolderName.isEmpty &&
        providerData.legalFullName.isNotEmpty) {
      providerData.accountHolderName = providerData.legalFullName;
    }
  }

  Future<void> clearSensitiveProviderData() async {
    providerData.clearSensitiveFields();
    await _persistProviderData();
    update();
  }

  Future<void> clearProviderDraft() async {
    providerData = ProviderOnboardingData();
    _prefillProviderDataFromProfile();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProviderData);
    update();
  }

  Future<void> markComplete({String? accountId}) async {
    _state = _state.copyWith(
      onboardingStep: 10,
      onboardingStatus: OnboardingStatus.complete,
      stripeOnboardingComplete: true,
      stripeAccountId: accountId ?? _state.stripeAccountId,
    );
    await _persistLocal(setIdentityVerified: true);
    _syncToServer();
    update();
  }

  Future<void> completeProviderRole() async {
    final prefs = await SharedPreferences.getInstance();
    final email = userEmail.isNotEmpty
        ? userEmail
        : (prefs.getString('email') ?? '');

    try {
      final response = await AuthRepository().updateRoleApi({
        'role': '1',
        'email': email,
      });
      if (response['status'] == 200) {
        await prefs.setString('role', '1');
      }
    } catch (_) {
      await prefs.setString('role', '1');
    }

    final ctx = Get.context;
    if (ctx != null) {
      ctx.read<UserViewModel>().setRole('1');
    }

    await markComplete();
  }

  Future<void> markIntroSeen() async {
    _introSeen = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIntroSeen, true);
    update();
  }

  void navigateToIntroFlow() {
    Get.to(() => const StartEarningIntroScreen());
  }

  void navigateToStep(int step) {
    switch (OnboardingSteps.normalize(step)) {
      case 6:
        Get.to(() => const PersonalDetailsScreen());
        break;
      case 7:
        Get.to(() => const VerifyIdentityScreen());
        break;
      case 8:
        Get.to(() => const BankAccountScreen());
        break;
      case 9:
        Get.to(() => const ReviewSubmitScreen());
        break;
      case 10:
        Get.to(() => const AllSetScreen());
        break;
      default:
        Get.to(() => const PersonalDetailsScreen());
    }
  }

  Future<void> startOrResume() async {
    if (_state.isComplete) return;

    if (_state.onboardingStatus == OnboardingStatus.notStarted) {
      if (!_introSeen) {
        navigateToIntroFlow();
        return;
      }
      await advanceTo(OnboardingSteps.formStart);
      AnalyticsService.instance.track('stripe_onboarding_started');
      navigateToStep(OnboardingSteps.formStart);
      return;
    }

    navigateToStep(_state.resumeStep);
  }

  Future<void> resumeFromStep(int step) async {
    final normalized = OnboardingSteps.normalize(step);
    await advanceTo(normalized);
    navigateToStep(normalized);
  }

  Future<bool> isStripeIdentityVerified() async {
    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getString('stripe_verification_status') ?? '';
    return status == 'verified';
  }

  Future<void> _persistLocal({bool setIdentityVerified = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyStep, _state.onboardingStep);
    await prefs.setString(_keyStatus, _state.onboardingStatus);
    if (_state.stripeAccountId != null) {
      await prefs.setString(_keyStripeAccountId, _state.stripeAccountId!);
    }
    await prefs.setBool(_keyStripeComplete, _state.stripeOnboardingComplete);
    if (setIdentityVerified || _state.isComplete) {
      await prefs.setBool('is_identity_verified', true);
      await prefs.setString('stripe_verification_status', 'verified');
    }
  }

  String _resolveProfileName(String value) {
    final trimmed = value.trim();
    if (_isPlaceholderName(trimmed)) return '';
    return trimmed;
  }

  String _resolveProfileEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return '';
    return trimmed;
  }

  bool _isPlaceholderName(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized == 'guest' ||
        normalized == 'null';
  }

  bool _isValidStoredPhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return ProviderOnboardingData.isValidUsPhone(trimmed);
  }

  String _sanitizePhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final formatted = ProviderOnboardingData.formatPhoneE164(trimmed);
    if (!_isValidStoredPhone(formatted)) return '';
    return formatted;
  }

  void _syncToServer() {
    if (userId.isEmpty) return;

    ApiRepository.shared.updateOnboardingState(
      {
        'user_id': userId,
        'onboarding_step': _state.onboardingStep,
        'onboarding_status': _state.onboardingStatus,
        if (_state.stripeAccountId != null)
          'stripe_account_id': _state.stripeAccountId,
        'is_stripe_onboarding_complete': _state.stripeOnboardingComplete,
      },
      (_) {},
      (_) {},
    );
  }
}
