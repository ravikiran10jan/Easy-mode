import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onboarding state
class OnboardingState {
  final int currentStep;
  final String? selectedPain;
  final String? selectedGoal;
  final int dailyTimeMinutes;
  final bool isLoading;
  final String? error;

  OnboardingState({
    this.currentStep = 0,
    this.selectedPain,
    this.selectedGoal,
    this.dailyTimeMinutes = 10,
    this.isLoading = false,
    this.error,
  });

  OnboardingState copyWith({
    int? currentStep,
    String? selectedPain,
    String? selectedGoal,
    int? dailyTimeMinutes,
    bool? isLoading,
    String? error,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      selectedPain: selectedPain ?? this.selectedPain,
      selectedGoal: selectedGoal ?? this.selectedGoal,
      dailyTimeMinutes: dailyTimeMinutes ?? this.dailyTimeMinutes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get canProceed {
    switch (currentStep) {
      case 0:
        return true;
      case 1:
        return selectedPain != null;
      case 2:
        return selectedGoal != null;
      case 3:
        return true;
      default:
        return false;
    }
  }

  bool get isComplete =>
      selectedPain != null && selectedGoal != null && dailyTimeMinutes > 0;
}

/// Onboarding notifier
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(OnboardingState());

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void nextStep() {
    if (state.currentStep < 3 && state.canProceed) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setPain(String pain) {
    state = state.copyWith(selectedPain: pain);
  }

  void setGoal(String goal) {
    state = state.copyWith(selectedGoal: goal);
  }

  void setDailyTime(int minutes) {
    state = state.copyWith(dailyTimeMinutes: minutes);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void reset() {
    state = OnboardingState();
  }
}

/// Provider for onboarding state
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});
