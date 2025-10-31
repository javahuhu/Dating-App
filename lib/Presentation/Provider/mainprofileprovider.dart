// lib/presentation/provider/mainprofileprovider.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';

// -------------------- Global profile state --------------------

final isEditingprofilepageProvider = StateProvider<bool>((_) => false);
final tagsprofilepageProvider = StateProvider<List<String>>((_) => []);
final avatarprofilepageProvider = StateProvider<ImageProvider?>((_) => null);

// -------------------- Helper factory for TextEditingControllers --------------------

// Each controller will be automatically disposed when no longer used
Provider<TextEditingController> _textControllerProviderFactory() {
  return Provider.autoDispose<TextEditingController>((ref) {
    final controller = TextEditingController();
    ref.onDispose(controller.dispose);
    return controller;
  });
}

// -------------------- Controller providers --------------------

final nameprofilepageControllerProvider = _textControllerProviderFactory();
final roleControllerProvider = _textControllerProviderFactory();
final ageprofilepageControllerProvider = _textControllerProviderFactory();
final locationControllerProvider = _textControllerProviderFactory();
final archetypeControllerProvider = _textControllerProviderFactory();
final bioprofilepageControllerProvider = _textControllerProviderFactory();
final quoteControllerProvider = _textControllerProviderFactory();
final genderControllerProvider = _textControllerProviderFactory();

final newTraitLeftControllerProvider = _textControllerProviderFactory();
final newTraitRightControllerProvider = _textControllerProviderFactory();
final newFrustrationControllerProvider = _textControllerProviderFactory();
final newTagControllerProvider = _textControllerProviderFactory();

// -------------------- Personality model + provider --------------------

class PersonalityItem {
  String left;
  String right;
  double value;
  PersonalityItem({
    required this.left,
    required this.right,
    required this.value,
  });
}

final personalityListProvider = StateProvider<List<PersonalityItem>>((ref) {
  return [
    PersonalityItem(left: 'Introvert', right: 'Extravert', value: 0.25),
  ];
});
