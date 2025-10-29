
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';


final isSignUpProvider = StateProvider<bool>((ref) => false);


final obscurePasswordProvider = StateProvider.autoDispose<bool>((ref) => true);
final obscureConfirmProvider = StateProvider.autoDispose<bool>((ref) => true);


final emailControllerProvider =
    Provider<TextEditingController>((ref) {
  final controller = TextEditingController();

  // Dispose when the whole ProviderScope is disposed (not on route/layout change)
  ref.onDispose(() {
    try {
      controller.dispose();
    } catch (_) {}
  });

  return controller;
});

final passwordControllerProvider =
    Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() {
    try {
      controller.dispose();
    } catch (_) {}
  });
  return controller;
});

final nameControllerProvider =
    Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() {
    try {
      controller.dispose();
    } catch (_) {}
  });
  return controller;
});

final confirmPasswordControllerProvider =
    Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() {
    try {
      controller.dispose();
    } catch (_) {}
  });
  return controller;
});
