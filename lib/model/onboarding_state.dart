class OnboardingStatus {
  static const String notStarted = 'not_started';
  static const String inProgress = 'in_progress';
  static const String stripePending = 'stripe_pending';
  static const String complete = 'complete';
}

/// Internal steps 6–10 are the counted form flow (shown as Step 1–5 in UI).
/// Intro screens before step 6 are shown once and are not part of step progress.
class OnboardingSteps {
  static const int formStart = 6;
  static const int formEnd = 10;
  static const int formCount = formEnd - formStart + 1;

  static int normalize(int step) {
    if (step < formStart) return formStart;
    if (step > formEnd) return formEnd;
    return step;
  }

  static int toDisplayStep(int internalStep) {
    return (normalize(internalStep) - formStart + 1).clamp(1, formCount);
  }
}

class OnboardingState {
  final int onboardingStep;
  final String onboardingStatus;
  final String? stripeAccountId;
  final bool stripeOnboardingComplete;

  const OnboardingState({
    this.onboardingStep = OnboardingSteps.formStart,
    this.onboardingStatus = OnboardingStatus.notStarted,
    this.stripeAccountId,
    this.stripeOnboardingComplete = false,
  });

  bool get isComplete =>
      onboardingStatus == OnboardingStatus.complete ||
      stripeOnboardingComplete;

  bool get canResume =>
      onboardingStatus == OnboardingStatus.inProgress ||
      onboardingStatus == OnboardingStatus.stripePending;

  int get stepsRemaining {
    if (isComplete) return 0;
    if (onboardingStatus == OnboardingStatus.notStarted) {
      return OnboardingSteps.formCount;
    }
    final step = OnboardingSteps.normalize(onboardingStep);
    return (OnboardingSteps.formEnd - step).clamp(0, OnboardingSteps.formCount);
  }

  int get resumeStep {
    if (onboardingStatus == OnboardingStatus.notStarted) {
      return OnboardingSteps.formStart;
    }
    if (isComplete) return OnboardingSteps.formEnd;
    return OnboardingSteps.normalize(onboardingStep);
  }

  OnboardingState copyWith({
    int? onboardingStep,
    String? onboardingStatus,
    String? stripeAccountId,
    bool? stripeOnboardingComplete,
  }) {
    return OnboardingState(
      onboardingStep: onboardingStep ?? this.onboardingStep,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      stripeAccountId: stripeAccountId ?? this.stripeAccountId,
      stripeOnboardingComplete:
          stripeOnboardingComplete ?? this.stripeOnboardingComplete,
    );
  }

  factory OnboardingState.fromJson(Map<String, dynamic> json) {
    return OnboardingState(
      onboardingStep: _parseInt(
        json['onboarding_step'],
        fallback: OnboardingSteps.formStart,
      ),
      onboardingStatus:
          json['onboarding_status']?.toString() ??
          OnboardingStatus.notStarted,
      stripeAccountId: json['stripe_account_id']?.toString(),
      stripeOnboardingComplete:
          json['stripe_onboarding_complete'] == true ||
          json['stripe_onboarding_complete'] == 1 ||
          json['stripe_onboarding_complete'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'onboarding_step': onboardingStep,
      'onboarding_status': onboardingStatus,
      'stripe_account_id': stripeAccountId,
      'stripe_onboarding_complete': stripeOnboardingComplete,
    };
  }

  static int _parseInt(dynamic value, {required int fallback}) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }
}
