import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cicada/pages/setup/logic/setup_state.dart';

void main() {
  group('SetupState', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should have correct defaults', () {
      final state = container.read(setupStateProvider);

      expect(state.currentStep, 0);
      expect(state.nodeInstalled, false);
      expect(state.openclawInstalled, false);
      expect(state.detecting, true);
      expect(state.installing, false);
      expect(state.selectedMirror, 'https://registry.npmmirror.com');
      expect(state.logLines, isEmpty);
    });

    test('setCurrentStep should update current step', () {
      final notifier = container.read(setupStateProvider.notifier);

      notifier.setCurrentStep(2);

      final state = container.read(setupStateProvider);
      expect(state.currentStep, 2);
    });

    test('setSelectedMirror should update mirror URL', () {
      final notifier = container.read(setupStateProvider.notifier);

      notifier.setSelectedMirror('https://registry.npmjs.org');

      final state = container.read(setupStateProvider);
      expect(state.selectedMirror, 'https://registry.npmjs.org');
    });

    test('overallProgress should calculate correctly', () {
      final state = SetupStateData.initial().copyWith(
        detecting: false,
        currentStep: 0,
        bundledAvailable: false,
      );

      // After detection (step 0 complete)
      expect(state.overallProgress, closeTo(0.2, 0.01)); // 1/5 steps
    });

    test('getStepStatus should return correct status for detection step', () {
      final detectingState = SetupStateData.initial().copyWith(
        detecting: true,
      );
      expect(detectingState.getStepStatus(0), StepStatus.inProgress);

      final detectedState = SetupStateData.initial().copyWith(
        detecting: false,
      );
      expect(detectedState.getStepStatus(0), StepStatus.completed);
    });

    test('getStepStatus should return correct status for Node.js step', () {
      final state = SetupStateData.initial().copyWith(
        detecting: false,
        bundledAvailable: false,
        currentStep: 2,
        nodeInstalled: false,
      );

      expect(state.getStepStatus(2), StepStatus.inProgress);

      final installedState = state.copyWith(nodeInstalled: true);
      expect(installedState.getStepStatus(2), StepStatus.completed);
    });

    test('nodeStepIndex should adjust based on bundled availability', () {
      final withBundled = SetupStateData.initial().copyWith(
        bundledAvailable: true,
      );
      expect(withBundled.nodeStepIndex, 1);

      final withoutBundled = SetupStateData.initial().copyWith(
        bundledAvailable: false,
      );
      expect(withoutBundled.nodeStepIndex, 2);
    });

    test('totalSteps should adjust based on bundled availability', () {
      final withBundled = SetupStateData.initial().copyWith(
        bundledAvailable: true,
      );
      expect(withBundled.totalSteps, 4);

      final withoutBundled = SetupStateData.initial().copyWith(
        bundledAvailable: false,
      );
      expect(withoutBundled.totalSteps, 5);
    });

    test('overallProgress should reach 100% when all installed', () {
      final state = SetupStateData.initial().copyWith(
        detecting: false,
        nodeInstalled: true,
        openclawInstalled: true,
        currentStep: 4,
        bundledAvailable: false,
      );

      expect(state.overallProgress, 1.0);
    });
  });

  group('SetupStateData', () {
    test('copyWith should update only specified fields', () {
      final initial = SetupStateData.initial();
      final updated = initial.copyWith(
        currentStep: 3,
        nodeInstalled: true,
      );

      expect(updated.currentStep, 3);
      expect(updated.nodeInstalled, true);
      expect(updated.openclawInstalled, false); // unchanged
      expect(updated.selectedMirror, initial.selectedMirror); // unchanged
    });

    test('copyWith should handle null values correctly', () {
      final initial = SetupStateData.initial();
      final updated = initial.copyWith();

      expect(updated.currentStep, initial.currentStep);
      expect(updated.nodeInstalled, initial.nodeInstalled);
      expect(updated.selectedMirror, initial.selectedMirror);
    });
  });
}
