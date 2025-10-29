// providers/profile_providers.dart
import 'package:dating_app/Core/Auth/auth_storage.dart';
import 'package:dating_app/Data/API/profile_api.dart';
import 'package:dating_app/Data/Models/userinformation_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';

// Global providers for profile setup that are shared across all screen sizes
final nameprofileControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
      final controller = TextEditingController();

      ref.onDispose(() {
        try {
          controller.dispose();
        } catch (_) {}
      });
      return controller;
    });

final ageControllerProvider = Provider.autoDispose<TextEditingController>((
  ref,
) {
  final controller = TextEditingController();

  ref.onDispose(() {
    try {
      controller.dispose();
    } catch (_) {}
  });

  return controller;
});

final bioControllerProvider = Provider.autoDispose<TextEditingController>((
  ref,
) {
  final controller = TextEditingController();

  ref.onDispose(() {
    try {
      controller.dispose();
    } catch (_) {}
  });

  return controller;
});

// store picked file - global across all screen sizes
final selectedFileProvider = StateProvider<PlatformFile?>((ref) => null);
final hoverProvider = StateProvider<bool>((ref) => false);

// Helper function to clear all profile state when needed
void clearProfileState(WidgetRef ref) {
  ref.read(nameprofileControllerProvider).clear();
  ref.read(ageControllerProvider).clear();
  ref.read(bioControllerProvider).clear();
  ref.read(selectedFileProvider.notifier).state = null;
  ref.read(hoverProvider.notifier).state = false;
}


final profileFutureProvider = FutureProvider<UserinformationModel?>((
  ref,
) async {
  final token = await readToken();
  if (token == null || token.isEmpty) return null;

  final api = ProfileApi();
  return await api.fetchProfile(token);
});
