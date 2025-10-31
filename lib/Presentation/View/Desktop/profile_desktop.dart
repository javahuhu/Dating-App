
import 'dart:io';
import 'dart:convert';
import 'package:dating_app/Core/AuthStorage/auth_storage.dart';
import 'package:dating_app/Presentation/Provider/mainprofileprovider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dating_app/Core/Theme/colors.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:dating_app/Data/API/profile_api.dart';
import 'package:dating_app/Data/API/social_api.dart';

// ---------------- Local providers used for orchestration ----------------
final profileLoadedProvider = StateProvider<bool>((ref) => false);
final localSelectedFileProvider = StateProvider<PlatformFile?>((ref) => null);
final profileCacheProvider = StateProvider<Map<String, dynamic>?>(
  (ref) => null,
);

// ---------------- Models used by UI ----------------
class MotiveItem {
  String label;
  double value;
  MotiveItem({required this.label, required this.value});
}

final motivationsProvider = StateProvider<List<MotiveItem>>((ref) {
  return [
    MotiveItem(label: 'Adventure', value: 0.85),
    MotiveItem(label: 'Romance', value: 0.75),
    MotiveItem(label: 'Connection', value: 0.9),
    MotiveItem(label: 'Fun', value: 0.7),
    MotiveItem(label: 'Long-term', value: 0.65),
  ];
});

final frustrationsProvider = StateProvider<List<String>>((ref) {
  return [
    "Looking for genuine connections",
    "Tired of superficial conversations",
    "Want someone who shares my values",
  ];
});

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
    PersonalityItem(left: 'Homebody', right: 'Adventurer', value: 0.65),
    PersonalityItem(left: 'Planner', right: 'Spontaneous', value: 0.45),
    PersonalityItem(left: 'Reserved', right: 'Outgoing', value: 0.70),
    PersonalityItem(left: 'Serious', right: 'Playful', value: 0.60),
  ];
});

// -------------------- Page Widget --------------------

class ProfileDesktop extends HookConsumerWidget {
  const ProfileDesktop({super.key});

  BoxDecoration _cardDecoration({Color? color, double radius = 16}) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    bool isDense = false,
    double scale = 1.0,
  }) {
    return InputDecoration(
      labelText: label,
      isDense: isDense,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12 * scale),
        borderSide: const BorderSide(color: kBodyTextColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12 * scale),
        borderSide: const BorderSide(color: kBodyTextColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12 * scale),
        borderSide: BorderSide(color: kPrimaryColor, width: 2 * scale),
      ),
      contentPadding: isDense
          ? EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 10 * scale)
          : EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 12 * scale),
    );
  }

  Future<void> _pickAndSetAvatar(WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: false,
      );

      if (result == null) return;

      final file = result.files.single;

      ImageProvider provider;

      if (kIsWeb) {
        final bytes = file.bytes;
        if (bytes == null) return;
        provider = MemoryImage(bytes);
      } else {
        final path = file.path;
        if (path != null && path.isNotEmpty) {
          provider = FileImage(File(path));
        } else if (file.bytes != null) {
          provider = MemoryImage(file.bytes!);
        } else {
          return;
        }
      }

      ref.read(avatarprofilepageProvider.notifier).state = provider;
      ref.read(localSelectedFileProvider.notifier).state = file;
    } catch (e) {
      print('pick avatar error: $e');
    }
  }

  Future<File> _platformFileToFile(PlatformFile pf) async {
    if (pf.path != null && pf.path!.isNotEmpty) {
      return File(pf.path!);
    }
    final tmp = await getTemporaryDirectory();
    final f = File('${tmp.path}/${pf.name}');
    await f.writeAsBytes(pf.bytes!, flush: true);
    return f;
  }

  void _applyUserDataToUI(WidgetRef ref, dynamic user) {
    final nameCtl = ref.read(nameprofilepageControllerProvider);
    final ageCtl = ref.read(ageprofilepageControllerProvider);
    final bioCtl = ref.read(bioprofilepageControllerProvider);

    // Only update if controllers are empty or have default values
    if (nameCtl.text.isEmpty || nameCtl.text == 'Jill Anderson') {
      nameCtl.text = user.name ?? 'Jill Anderson';
    }

    if (ageCtl.text.isEmpty || ageCtl.text == '26') {
      ageCtl.text = user.age?.toString() ?? '26';
    }

    if (bioCtl.text.isEmpty ||
        bioCtl.text.contains('Looking for someone special')) {
      bioCtl.text =
          user.bio ??
          'Looking for someone special to share life\'s adventures with. Love good conversations, weekend getaways, and trying new things!';
    }

    final pic = (user.profilePictureUrl ?? user.profilePicture) ?? '';
    if (pic.isNotEmpty) {
      final provider = NetworkImage(pic);
      ref.read(avatarprofilepageProvider.notifier).state = provider;
    }

    // Load personality data
    try {
      String? personalityData;
      if (user.personality != null && user.personality.isNotEmpty) {
        personalityData = user.personality;
      } else if (user.saferPersonality != null &&
          user.saferPersonality.isNotEmpty) {
        personalityData = user.saferPersonality;
      }

      if (personalityData != null && personalityData.isNotEmpty) {
        String cleanedData = personalityData.trim();
        if (cleanedData.endsWith(',')) {
          cleanedData = cleanedData.substring(0, cleanedData.length - 1);
        }

        final dynamic parsed = jsonDecode(cleanedData);
        if (parsed is List) {
          final list = parsed
              .map((e) {
                if (e is Map) {
                  final map = Map<String, dynamic>.from(e);
                  if (map.containsKey('left') &&
                      map.containsKey('right') &&
                      map.containsKey('value')) {
                    return PersonalityItem(
                      left: '${map['left']}',
                      right: '${map['right']}',
                      value: (map['value'] as num).toDouble(),
                    );
                  }
                }
                return null;
              })
              .whereType<PersonalityItem>()
              .toList();
          if (list.isNotEmpty) {
            ref.read(personalityListProvider.notifier).state = list;
          }
        }
      }
    } catch (e) {
      print('parse personality failed: $e');
    }

    // Load motivations data
    try {
      String? motivationData;
      if (user.motivation != null && user.motivation.isNotEmpty) {
        motivationData = user.motivation;
      } else if (user.safetyKivation != null &&
          user.safetyKivation.isNotEmpty) {
        motivationData = user.safetyKivation;
      }

      if (motivationData != null && motivationData.isNotEmpty) {
        String cleanedData = motivationData.trim();
        if (cleanedData.endsWith(',')) {
          cleanedData = cleanedData.substring(0, cleanedData.length - 1);
        }

        final dynamic parsed = jsonDecode(cleanedData);
        if (parsed is List) {
          final list = parsed
              .map((e) {
                if (e is Map) {
                  final map = Map<String, dynamic>.from(e);
                  if (map.containsKey('label') && map.containsKey('value')) {
                    return MotiveItem(
                      label: '${map['label']}',
                      value: (map['value'] as num).toDouble(),
                    );
                  }
                }
                return null;
              })
              .whereType<MotiveItem>()
              .toList();
          if (list.isNotEmpty) {
            ref.read(motivationsProvider.notifier).state = list;
          }
        }
      }
    } catch (e) {
      print('parse motivations failed: $e');
    }

    // Load frustrations data
    try {
      String? frustrationData;
      if (user.frustration != null && user.frustration.isNotEmpty) {
        frustrationData = user.frustration;
      } else if (user.saferDistraction != null &&
          user.saferDistraction.isNotEmpty) {
        frustrationData = user.saferDistraction;
      }

      if (frustrationData != null && frustrationData.isNotEmpty) {
        String cleanedData = frustrationData.trim();
        if (cleanedData.endsWith(',')) {
          cleanedData = cleanedData.substring(0, cleanedData.length - 1);
        }

        final dynamic parsed = jsonDecode(cleanedData);
        if (parsed is List) {
          final list = parsed.whereType<String>().toList();
          if (list.isNotEmpty) {
            ref.read(frustrationsProvider.notifier).state = list;
          }
        }
      }
    } catch (e) {
      print('parse frustrations failed: $e');
    }

    // Load tags data
    try {
      final dynamic tagsVal = user.tags ?? user.interests;
      if (tagsVal != null) {
        if (tagsVal is List && tagsVal.isNotEmpty) {
          final t = tagsVal.map((e) => e.toString()).toList();
          ref.read(tagsprofilepageProvider.notifier).state = t;
        } else if (tagsVal is String && tagsVal.isNotEmpty) {
          try {
            final parsed = jsonDecode(tagsVal);
            if (parsed is List) {
              final t = parsed.map((e) => e.toString()).toList();
              ref.read(tagsprofilepageProvider.notifier).state = t;
            }
          } catch (_) {
            final t = tagsVal
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
            if (t.isNotEmpty) {
              ref.read(tagsprofilepageProvider.notifier).state = t;
            }
          }
        }
      }
    } catch (e) {
      print('parse tags failed: $e');
    }
  }

  Future<void> _loadProfileIfNeeded(WidgetRef ref, BuildContext context) async {
    final loaded = ref.read(profileLoadedProvider);

    // If already loaded, use cached data immediately
    if (loaded) {
      final cached = ref.read(profileCacheProvider);
      if (cached != null) {
        return;
      }
    }

    // Add debouncing to prevent multiple rapid calls
    await Future.delayed(const Duration(milliseconds: 50));

    // Check again after delay in case another call already started loading
    if (ref.read(profileLoadedProvider)) return;

    try {
      final token = kIsWeb ? await SocialAuth().readToken() : await readToken();
      if (token == null) {
        ref.read(profileLoadedProvider.notifier).state = true;
        return;
      }

      final api = ProfileApi();
      final user = await api.fetchProfile(token);

      if (user == null) {
        ref.read(profileLoadedProvider.notifier).state = true;
        return;
      }

      // Cache the user data
      final userMap = {
        'name': user.name,
        'age': user.age,
        'bio': user.bio,
        'profilePicture': user.profilePicture,
        'personality': user.personality,
        'motivation': user.motivation,
        'frustration': user.frustration,
        'tags': user.tags,
      };
      ref.read(profileCacheProvider.notifier).state = userMap;

      _applyUserDataToUI(ref, user);
    } catch (e) {
      print('Profile load failed: $e');
    } finally {
      ref.read(profileLoadedProvider.notifier).state = true;
    }
  }

  void _refreshProfile(WidgetRef ref) {
    ref.read(profileLoadedProvider.notifier).state = false;
    ref.read(profileCacheProvider.notifier).state = null;
  }

  Future<void> _saveProfile(WidgetRef ref, BuildContext context) async {
    final nameCtl = ref.read(nameprofilepageControllerProvider);
    final ageCtl = ref.read(ageprofilepageControllerProvider);
    final bioCtl = ref.read(bioprofilepageControllerProvider);
    final tags = ref.read(tagsprofilepageProvider);

    final personalityList = ref.read(personalityListProvider);
    final motivations = ref.read(motivationsProvider);
    final frustrations = ref.read(frustrationsProvider);

    final picked = ref.read(localSelectedFileProvider);

    if (nameCtl.text.trim().isEmpty ||
        bioCtl.text.trim().isEmpty ||
        (int.tryParse(ageCtl.text.trim()) ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Name, age and bio are required'),
          backgroundColor: kPrimaryColor,
        ),
      );
      return;
    }

    final uploadingSnack = SnackBar(
      content: Row(
        children: const [
          SizedBox(width: 4),
          CircularProgressIndicator(strokeWidth: 2),
          SizedBox(width: 12),
          Expanded(child: Text('Uploading profile...')),
        ],
      ),
      backgroundColor: kPrimaryColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(minutes: 5),
    );
    ScaffoldMessenger.of(context).showSnackBar(uploadingSnack);

    try {
      final token = kIsWeb ? await SocialAuth().readToken() : await readToken();
      if (token == null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You must be logged in'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final api = ProfileApi();
      final name = nameCtl.text.trim();
      final age = int.tryParse(ageCtl.text.trim()) ?? 0;
      final bio = bioCtl.text.trim();

      final personalityJson = jsonEncode(
        personalityList
            .map((p) => {'left': p.left, 'right': p.right, 'value': p.value})
            .toList(),
      );
      final motivationsJson = jsonEncode(
        motivations.map((m) => {'label': m.label, 'value': m.value}).toList(),
      );
      final frustrationsJson = jsonEncode(frustrations);
      final tagsJson = jsonEncode(tags);

      if (picked != null) {
        if (kIsWeb) {
          final bytes = picked.bytes;
          final filename = picked.name;
          if (bytes == null || bytes.isEmpty)
            throw Exception('Selected file has no bytes (web).');
          await api.uploadProfile(
            token: token,
            name: name,
            age: age,
            bio: bio,
            personality: personalityJson,
            motivation: motivationsJson,
            frustration: frustrationsJson,
            tags: tagsJson,
            imageBytes: bytes,
            filename: filename,
          );
        } else {
          final file = await _platformFileToFile(picked);
          await api.uploadProfile(
            token: token,
            name: name,
            age: age,
            bio: bio,
            personality: personalityJson,
            motivation: motivationsJson,
            frustration: frustrationsJson,
            tags: tagsJson,
            imageFile: file,
          );
        }
      } else {
        await api.uploadProfile(
          token: token,
          name: name,
          age: age,
          bio: bio,
          personality: personalityJson,
          motivation: motivationsJson,
          frustration: frustrationsJson,
          tags: tagsJson,
        );
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✨ Profile saved'),
          backgroundColor: kPrimaryColor,
        ),
      );

      // Refresh profile data after successful save
      _refreshProfile(ref);
      ref.read(localSelectedFileProvider.notifier).state = null;
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      print('Profile save failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use a more controlled approach for loading
    final loaded = ref.watch(profileLoadedProvider);

    // Load profile only once when needed
    if (!loaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProfileIfNeeded(ref, context);
      });
    }

    final isEditing = ref.watch(isEditingprofilepageProvider);
    final tags = ref.watch(tagsprofilepageProvider);
    final avatarImage = ref.watch(avatarprofilepageProvider);

    final nameCtrl = ref.watch(nameprofilepageControllerProvider);
    final roleCtrl = ref.watch(roleControllerProvider);
    final ageCtrl = ref.watch(ageprofilepageControllerProvider);
    final locCtrl = ref.watch(locationControllerProvider);
    final archetypeCtrl = ref.watch(archetypeControllerProvider);
    final bioCtrl = ref.watch(bioprofilepageControllerProvider);

    final newTraitLeftCtrl = ref.watch(newTraitLeftControllerProvider);
    final newTraitRightCtrl = ref.watch(newTraitRightControllerProvider);
    final newFrustrationCtrl = ref.watch(newFrustrationControllerProvider);

    final personalityList = ref.watch(personalityListProvider);
    final personalityNotifier = ref.read(personalityListProvider.notifier);

    final motivations = ref.watch(motivationsProvider);
    final motivationsNotifier = ref.read(motivationsProvider.notifier);

    final frustrations = ref.watch(frustrationsProvider);
    final frustrationsNotifier = ref.read(frustrationsProvider.notifier);

    // Set default values only if empty
    if (nameCtrl.text.isEmpty) nameCtrl.text = 'Jill Anderson';
    if (roleCtrl.text.isEmpty) roleCtrl.text = 'Creative Professional';
    if (ageCtrl.text.isEmpty) ageCtrl.text = '26';
    if (locCtrl.text.isEmpty) locCtrl.text = 'Brooklyn, NY';
    if (archetypeCtrl.text.isEmpty) archetypeCtrl.text = 'Hopeless Romantic';
    if (bioCtrl.text.isEmpty) {
      bioCtrl.text =
          'Looking for someone special to share life\'s adventures with. Love good conversations, weekend getaways, and trying new things!';
    }

    final defaultAvatarProvider = const AssetImage('assets/image/coupl2.jpg');
    final displayedAvatar = avatarImage ?? defaultAvatarProvider;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double contentWidth = screenWidth.clamp(
      1000.0,
      2000.0,
    ); // Smaller max width

    final double baseline = 1366.0;
    double scale = (contentWidth / baseline);
    scale = scale.clamp(0.7, 1.3); // Smaller scale range

    double s(double v) => v * scale;

    final Color leftCardBg = const Color(0xFFFFF2EE);
    final Color infoBoxBg = const Color(0xFFF6DCD8);

    return WillPopScope(
    
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        body: SafeArea(
          top: false,
          child: Row(
            children: [
             
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height,
                    ),
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: contentWidth,
                      child: Padding(
                        padding: EdgeInsets.all(s(16)), // Smaller padding
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left profile card - Smaller
                            SizedBox(
                              width: s(320), // Smaller width
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    height: isEditing
                                        ? s(680)
                                        : s(555), // Smaller height
                                    decoration: _cardDecoration(
                                      color: leftCardBg,
                                      radius: 16,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: s(16),
                                      horizontal: s(16),
                                    ),
                                    child: Column(
                                      children: [
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: s(100), // Smaller avatar
                                              height: s(100),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.06),
                                                    blurRadius: 8 * scale,
                                                    offset: Offset(
                                                      0,
                                                      4 * scale,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: isEditing
                                                  ? () => _pickAndSetAvatar(ref)
                                                  : null,
                                              child: CircleAvatar(
                                                radius: s(44), // Smaller
                                                backgroundImage:
                                                    displayedAvatar,
                                              ),
                                            ),
                                            if (isEditing)
                                              Positioned(
                                                right: s(4),
                                                bottom: s(4),
                                                child: Material(
                                                  elevation: 2,
                                                  color: Colors.white,
                                                  shape: const CircleBorder(),
                                                  child: InkWell(
                                                    customBorder:
                                                        const CircleBorder(),
                                                    onTap: () =>
                                                        _pickAndSetAvatar(ref),
                                                    child: Padding(
                                                      padding: EdgeInsets.all(
                                                        s(5),
                                                      ),
                                                      child: Icon(
                                                        Icons.camera_alt,
                                                        size: s(12), // Smaller
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),

                                        SizedBox(height: s(10)),

                                        _editableTextField(
                                          isEditing,
                                          nameCtrl,
                                          'Name',
                                          s(16), // Smaller font
                                          true,
                                          scale: scale,
                                        ),
                                        SizedBox(height: s(4)),
                                        _editableTextField(
                                          isEditing,
                                          roleCtrl,
                                          'Role',
                                          s(12), // Smaller font
                                          false,
                                          color: kPrimaryColor,
                                          scale: scale,
                                        ),

                                        SizedBox(height: s(10)),

                                        Container(
                                          width: s(30),
                                          height: s(4),
                                          decoration: BoxDecoration(
                                            color: kPrimaryColor,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),

                                        SizedBox(height: s(10)),

                                        Text(
                                          bioCtrl.text,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: kBodyTextColor,
                                            height: 1.4,
                                            fontSize: s(12), // Smaller font
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        SizedBox(height: s(12)),

                                        Container(
                                          width: double.infinity,
                                          decoration: _cardDecoration(
                                            color: infoBoxBg,
                                            radius: 12,
                                          ),
                                          padding: EdgeInsets.all(s(12)),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _infoRow(
                                                'Age',
                                                ageCtrl,
                                                isEditing,
                                                scale,
                                              ),
                                              SizedBox(height: s(6)),
                                              _infoRow(
                                                'Status',
                                                TextEditingController()
                                                  ..text = 'Single',
                                                false,
                                                scale,
                                              ),
                                              SizedBox(height: s(6)),
                                              _infoRow(
                                                'Location',
                                                locCtrl,
                                                isEditing,
                                                scale,
                                              ),
                                              SizedBox(height: s(6)),
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width:
                                                        80 * scale, // Smaller
                                                    child: Text(
                                                      'Archetype:',
                                                      style: TextStyle(
                                                        fontSize:
                                                            12 *
                                                            scale, // Smaller
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: isEditing
                                                        ? TextField(
                                                            controller:
                                                                archetypeCtrl,
                                                            decoration:
                                                                _inputDecoration(
                                                                  'Archetype',
                                                                  isDense: true,
                                                                  scale: scale,
                                                                ).copyWith(
                                                                  contentPadding:
                                                                      EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            10 *
                                                                            scale,
                                                                        vertical:
                                                                            12 *
                                                                            scale,
                                                                      ),
                                                                ),
                                                          )
                                                        : Text(
                                                            archetypeCtrl.text,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  kTitleColor,
                                                              fontSize:
                                                                  12 *
                                                                  scale, // Smaller
                                                            ),
                                                          ),
                                                  ),
                                                ],
                                              ),

                                              SizedBox(height: s(12)),

                                              Wrap(
                                                spacing: s(6),
                                                runSpacing: s(6),
                                                children: tags.isEmpty
                                                    ? [
                                                            'Travel',
                                                            'Coffee',
                                                            'Movies',
                                                            'Fitness',
                                                            'Music',
                                                            'Cooking',
                                                          ]
                                                          .map(
                                                            (e) =>
                                                                _styledInterestChip(
                                                                  e,
                                                                  kPrimaryColor,
                                                                  s,
                                                                ),
                                                          )
                                                          .toList()
                                                    : tags
                                                          .map(
                                                            (
                                                              e,
                                                            ) => _styledInterestChip(
                                                              e,
                                                              kPrimaryColor,
                                                              s,
                                                              onDeleted:
                                                                  isEditing
                                                                  ? () {
                                                                      final updated =
                                                                          List<
                                                                              String
                                                                            >.from(
                                                                              tags,
                                                                            )
                                                                            ..remove(
                                                                              e,
                                                                            );
                                                                      ref
                                                                              .read(
                                                                                tagsprofilepageProvider.notifier,
                                                                              )
                                                                              .state =
                                                                          updated;
                                                                    }
                                                                  : null,
                                                            ),
                                                          )
                                                          .toList(),
                                              ),

                                              if (isEditing)
                                                SizedBox(height: s(10)),
                                              if (isEditing)
                                                _addTagField(
                                                  ref,
                                                  kPrimaryColor,
                                                  scale,
                                                ),
                                            ],
                                          ),
                                        ),

                                        SizedBox(height: s(60)),

                                        Align(
                                          alignment: Alignment.center,
                                          child: ElevatedButton.icon(
                                            icon: Icon(
                                              isEditing
                                                  ? Icons.save
                                                  : Icons.edit,
                                              size: s(12), // Smaller
                                            ),
                                            label: Text(
                                              isEditing
                                                  ? 'Save Changes'
                                                  : 'Edit Profile',
                                              style: TextStyle(
                                                fontSize: s(12),
                                              ), // Smaller
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: kPrimaryColor,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: s(16),
                                                vertical: s(12),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            onPressed: () async {
                                              if (isEditing) {
                                                await _saveProfile(
                                                  ref,
                                                  context,
                                                );
                                                ref
                                                        .read(
                                                          isEditingprofilepageProvider
                                                              .notifier,
                                                        )
                                                        .state =
                                                    false;
                                              } else {
                                                ref
                                                        .read(
                                                          isEditingprofilepageProvider
                                                              .notifier,
                                                        )
                                                        .state =
                                                    true;
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: s(12)),
                                ],
                              ),
                            ),

                            SizedBox(width: s(16)),

                            // Middle section - Bio & Personality
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: s(1200),
                                  ), // Smaller
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Bio card
                                      Container(
                                        height: s(180), // Smaller
                                        decoration: _cardDecoration(),
                                        padding: EdgeInsets.all(s(16)),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Bio',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: headingViolet,
                                                fontSize: s(14), // Smaller
                                              ),
                                            ),
                                            SizedBox(height: s(8)),
                                            Expanded(
                                              child: isEditing
                                                  ? TextField(
                                                      controller: bioCtrl,
                                                      maxLines:
                                                          4, // Fewer lines
                                                      decoration:
                                                          _inputDecoration(
                                                            'Bio',
                                                            scale: scale,
                                                          ).copyWith(
                                                            contentPadding:
                                                                EdgeInsets.all(
                                                                  s(10),
                                                                ),
                                                          ),
                                                    )
                                                  : Text(
                                                      bioCtrl.text,
                                                      style: TextStyle(
                                                        color: kBodyTextColor,
                                                        height: 1.5,
                                                        fontSize: s(
                                                          12,
                                                        ), // Smaller
                                                      ),
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: s(12)),

                                      // Personality card
                                      Container(
                                        decoration: _cardDecoration(),
                                        padding: EdgeInsets.all(s(14)),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Personality',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: headingViolet,
                                                fontSize: s(14), // Smaller
                                              ),
                                            ),
                                            SizedBox(height: s(12)),
                                            ...personalityList.map((item) {
                                              final index = personalityList
                                                  .indexOf(item);
                                              return Container(
                                                margin: EdgeInsets.only(
                                                  bottom: s(8),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        if (isEditing)
                                                          SizedBox(
                                                            width: s(
                                                              100,
                                                            ), // Smaller
                                                            child: TextField(
                                                              controller:
                                                                  TextEditingController(
                                                                    text: item
                                                                        .left,
                                                                  ),
                                                              style: TextStyle(
                                                                fontSize: s(
                                                                  11,
                                                                ), // Smaller
                                                              ),
                                                              decoration:
                                                                  _inputDecoration(
                                                                    'Left',
                                                                    isDense:
                                                                        true,
                                                                    scale:
                                                                        scale,
                                                                  ),
                                                              onChanged: (val) =>
                                                                  item.left =
                                                                      val,
                                                            ),
                                                          )
                                                        else
                                                          Text(
                                                            item.left,
                                                            style: TextStyle(
                                                              fontSize: s(
                                                                11,
                                                              ), // Smaller
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        if (isEditing)
                                                          SizedBox(
                                                            width: s(
                                                              100,
                                                            ), // Smaller
                                                            child: TextField(
                                                              controller:
                                                                  TextEditingController(
                                                                    text: item
                                                                        .right,
                                                                  ),
                                                              style: TextStyle(
                                                                fontSize: s(
                                                                  11,
                                                                ), // Smaller
                                                              ),
                                                              decoration:
                                                                  _inputDecoration(
                                                                    'Right',
                                                                    isDense:
                                                                        true,
                                                                    scale:
                                                                        scale,
                                                                  ),
                                                              onChanged: (val) =>
                                                                  item.right =
                                                                      val,
                                                            ),
                                                          )
                                                        else
                                                          Text(
                                                            item.right,
                                                            style: TextStyle(
                                                              fontSize: s(
                                                                11,
                                                              ), // Smaller
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    SizedBox(height: s(6)),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: isEditing
                                                              ? Slider(
                                                                  value: item
                                                                      .value,
                                                                  min: 0,
                                                                  max: 1,
                                                                  activeColor:
                                                                      kPrimaryColor,
                                                                  onChanged: (val) {
                                                                    final updated =
                                                                        List<
                                                                          PersonalityItem
                                                                        >.from(
                                                                          personalityList,
                                                                        );
                                                                    updated[index] = PersonalityItem(
                                                                      left: item
                                                                          .left,
                                                                      right: item
                                                                          .right,
                                                                      value:
                                                                          val,
                                                                    );
                                                                    personalityNotifier
                                                                            .state =
                                                                        updated;
                                                                  },
                                                                )
                                                              : _buildPersonalityBar(
                                                                  item.value,
                                                                ),
                                                        ),
                                                        if (isEditing)
                                                          IconButton(
                                                            icon: Icon(
                                                              Icons.delete,
                                                              size: s(
                                                                16,
                                                              ), // Smaller
                                                            ),
                                                            color: Colors
                                                                .redAccent,
                                                            onPressed: () {
                                                              final updated =
                                                                  List<
                                                                      PersonalityItem
                                                                    >.from(
                                                                      personalityList,
                                                                    )
                                                                    ..removeAt(
                                                                      index,
                                                                    );
                                                              personalityNotifier
                                                                      .state =
                                                                  updated;
                                                            },
                                                          ),
                                                      ],
                                                    ),
                                                    if (index <
                                                        personalityList.length -
                                                            1)
                                                      Divider(height: s(16)),
                                                  ],
                                                ),
                                              );
                                            }),

                                            if (isEditing)
                                              Container(
                                                margin: EdgeInsets.only(
                                                  top: s(10),
                                                ),
                                                padding: EdgeInsets.all(s(8)),
                                                decoration: BoxDecoration(
                                                  color: kBackgroundColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        8 * scale,
                                                      ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      'Add New Trait',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: headingViolet,
                                                        fontSize: s(
                                                          12,
                                                        ), // Smaller
                                                      ),
                                                    ),
                                                    SizedBox(height: s(6)),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: TextField(
                                                            controller:
                                                                newTraitLeftCtrl,
                                                            style: TextStyle(
                                                              fontSize: s(
                                                                11,
                                                              ), // Smaller
                                                            ),
                                                            decoration:
                                                                _inputDecoration(
                                                                  'Left trait',
                                                                  isDense: true,
                                                                  scale: scale,
                                                                ),
                                                          ),
                                                        ),
                                                        SizedBox(width: s(6)),
                                                        Expanded(
                                                          child: TextField(
                                                            controller:
                                                                newTraitRightCtrl,
                                                            style: TextStyle(
                                                              fontSize: s(
                                                                11,
                                                              ), // Smaller
                                                            ),
                                                            decoration:
                                                                _inputDecoration(
                                                                  'Right trait',
                                                                  isDense: true,
                                                                  scale: scale,
                                                                ),
                                                          ),
                                                        ),
                                                        SizedBox(width: s(6)),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            if (newTraitLeftCtrl
                                                                    .text
                                                                    .trim()
                                                                    .isNotEmpty &&
                                                                newTraitRightCtrl
                                                                    .text
                                                                    .trim()
                                                                    .isNotEmpty) {
                                                              final updated =
                                                                  List<PersonalityItem>.from(
                                                                    personalityList,
                                                                  )..add(
                                                                    PersonalityItem(
                                                                      left: newTraitLeftCtrl
                                                                          .text,
                                                                      right: newTraitRightCtrl
                                                                          .text,
                                                                      value:
                                                                          0.5,
                                                                    ),
                                                                  );
                                                              personalityNotifier
                                                                      .state =
                                                                  updated;
                                                              newTraitLeftCtrl
                                                                  .clear();
                                                              newTraitRightCtrl
                                                                  .clear();
                                                            }
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                kPrimaryColor,
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal: s(
                                                                    10,
                                                                  ),
                                                                  vertical: s(
                                                                    10,
                                                                  ),
                                                                ),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    10 * scale,
                                                                  ),
                                                            ),
                                                          ),
                                                          child: Text(
                                                            'Add',
                                                            style: TextStyle(
                                                              fontSize: s(
                                                                12,
                                                              ), // Smaller
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                            SizedBox(height: s(12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(width: s(16)),

                            // Right section - Motivations & Goals
                            SizedBox(
                              width: s(300), // Smaller
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Motivations
                                  Container(
                                    decoration: _cardDecoration(),
                                    padding: EdgeInsets.all(s(12)),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Motivations',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: headingViolet,
                                            fontSize: s(14), // Smaller
                                          ),
                                        ),
                                        SizedBox(height: s(8)),
                                        ...motivations.map((m) {
                                          final idx = motivations.indexOf(m);
                                          return Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: s(5),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    isEditing
                                                        ? SizedBox(
                                                            width: s(
                                                              120,
                                                            ), // Smaller
                                                            child: TextField(
                                                              controller:
                                                                  TextEditingController(
                                                                    text:
                                                                        m.label,
                                                                  ),
                                                              decoration:
                                                                  _inputDecoration(
                                                                    'Label',
                                                                    isDense:
                                                                        true,
                                                                    scale:
                                                                        scale,
                                                                  ),
                                                              onChanged: (val) {
                                                                final updated =
                                                                    List<
                                                                      MotiveItem
                                                                    >.from(
                                                                      motivations,
                                                                    );
                                                                updated[idx] =
                                                                    MotiveItem(
                                                                      label:
                                                                          val,
                                                                      value: updated[idx]
                                                                          .value,
                                                                    );
                                                                motivationsNotifier
                                                                        .state =
                                                                    updated;
                                                              },
                                                            ),
                                                          )
                                                        : Text(
                                                            m.label,
                                                            style: TextStyle(
                                                              fontSize: s(
                                                                12,
                                                              ), // Smaller
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                    Text(
                                                      '${(m.value * 100).round()}%',
                                                      style: TextStyle(
                                                        fontSize: s(
                                                          11,
                                                        ), // Smaller
                                                        color: kBodyTextColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: s(4)),
                                                Container(
                                                  height: s(8),
                                                  decoration: BoxDecoration(
                                                    color: kBackgroundColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          s(4),
                                                        ),
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      FractionallySizedBox(
                                                        widthFactor: m.value,
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            color:
                                                                kPrimaryColor,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  s(4),
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (isEditing)
                                                  Slider(
                                                    value: m.value,
                                                    onChanged: (val) {
                                                      final updated =
                                                          List<MotiveItem>.from(
                                                            motivations,
                                                          );
                                                      updated[idx] = MotiveItem(
                                                        label:
                                                            updated[idx].label,
                                                        value: val,
                                                      );
                                                      motivationsNotifier
                                                              .state =
                                                          updated;
                                                    },
                                                    min: 0,
                                                    max: 1,
                                                  ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: s(12)),
                                  Container(
                                    decoration: _cardDecoration(),
                                    padding: EdgeInsets.all(s(12)),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Frustrations',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: headingViolet,
                                            fontSize: s(14), // Smaller
                                          ),
                                        ),
                                        SizedBox(height: s(8)),
                                        ...frustrations.map((f) {
                                          final idx = frustrations.indexOf(f);
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              bottom: s(6),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    top: s(4),
                                                  ),
                                                  child: Icon(
                                                    Icons.circle,
                                                    size: s(6), // Smaller
                                                    color: kPrimaryColor,
                                                  ),
                                                ),
                                                SizedBox(width: s(6)),
                                                Expanded(
                                                  child: isEditing
                                                      ? Row(
                                                          children: [
                                                            Expanded(
                                                              child: TextField(
                                                                controller:
                                                                    TextEditingController(
                                                                      text: f,
                                                                    ),
                                                                onChanged: (val) {
                                                                  final updated =
                                                                      List<
                                                                        String
                                                                      >.from(
                                                                        frustrations,
                                                                      );
                                                                  updated[idx] =
                                                                      val;
                                                                  frustrationsNotifier
                                                                          .state =
                                                                      updated;
                                                                },
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              width: s(6),
                                                            ),
                                                            IconButton(
                                                              onPressed: () {
                                                                final updated =
                                                                    List<
                                                                      String
                                                                    >.from(
                                                                      frustrations,
                                                                    );
                                                                updated
                                                                    .removeAt(
                                                                      idx,
                                                                    );
                                                                frustrationsNotifier
                                                                        .state =
                                                                    updated;
                                                              },
                                                              icon: Icon(
                                                                Icons.delete,
                                                                size: s(
                                                                  16,
                                                                ), // Smaller
                                                                color: Colors
                                                                    .redAccent,
                                                              ),
                                                            ),
                                                          ],
                                                        )
                                                      : Text(
                                                          f,
                                                          style: TextStyle(
                                                            color:
                                                                kBodyTextColor,
                                                            fontSize: s(
                                                              12,
                                                            ), // Smaller
                                                          ),
                                                        ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                        if (isEditing)
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  controller:
                                                      newFrustrationCtrl,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        'Add new frustration',
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: s(10),
                                                          vertical: s(8),
                                                        ),
                                                  ),
                                                  onSubmitted: (val) {
                                                    final v = val.trim();
                                                    if (v.isEmpty) return;
                                                    final updated =
                                                        List<String>.from(
                                                          frustrations,
                                                        );
                                                    updated.add(v);
                                                    frustrationsNotifier.state =
                                                        updated;
                                                    newFrustrationCtrl.clear();
                                                  },
                                                ),
                                              ),
                                              SizedBox(width: s(6)),
                                              ElevatedButton(
                                                onPressed: () {
                                                  final v = newFrustrationCtrl
                                                      .text
                                                      .trim();
                                                  if (v.isEmpty) return;
                                                  final updated =
                                                      List<String>.from(
                                                        frustrations,
                                                      );
                                                  updated.add(v);
                                                  frustrationsNotifier.state =
                                                      updated;
                                                  newFrustrationCtrl.clear();
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  backgroundColor:
                                                      kPrimaryColor,
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: s(10),
                                                    vertical: s(10),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Add',
                                                  style: TextStyle(
                                                    fontSize: s(12), // Smaller
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Helper Widgets ----------
  Widget _editableTextField(
    bool isEditing,
    TextEditingController ctrl,
    String label,
    double size,
    bool bold, {
    Color? color,
    double scale = 1.0,
  }) {
    return isEditing
        ? TextField(
            controller: ctrl,
            decoration: _inputDecoration(label, scale: scale),
          )
        : Text(
            ctrl.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: size,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color ?? kTitleColor,
            ),
          );
  }

  Widget _infoRow(
    String label,
    TextEditingController ctrl,
    bool isEditing,
    double scale,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 80 * scale, // Smaller
          child: Text(
            '$label:',
            style: TextStyle(fontSize: 12 * scale),
          ), // Smaller
        ),
        Expanded(
          child: isEditing
              ? TextField(
                  controller: ctrl,
                  decoration:
                      _inputDecoration(
                        label,
                        isDense: true,
                        scale: scale,
                      ).copyWith(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10 * scale,
                          vertical: 10 * scale,
                        ),
                      ),
                )
              : Text(
                  ctrl.text,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: kTitleColor,
                    fontSize: 12 * scale, // Smaller
                  ),
                ),
        ),
      ],
    );
  }

  Widget _addTagField(WidgetRef ref, Color color, double scale) {
    final controller = ref.watch(newTagControllerProvider);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: _inputDecoration('Add new interest...', scale: scale),
          ),
        ),
        SizedBox(width: 6 * scale),
        ElevatedButton(
          onPressed: () {
            final newTag = controller.text.trim();
            if (newTag.isNotEmpty) {
              final updated = List<String>.from(
                ref.read(tagsprofilepageProvider),
              );
              updated.add(newTag);
              ref.read(tagsprofilepageProvider.notifier).state = updated;
              controller.clear();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 14 * scale,
              vertical: 10 * scale,
            ),
          ),
          child: Text(
            'Add',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12 * scale,
            ), // Smaller
          ),
        ),
      ],
    );
  }

  Widget _styledInterestChip(
    String label,
    Color color,
    double Function(double) s, {
    VoidCallback? onDeleted,
  }) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(color: Colors.white, fontSize: s(10)), // Smaller
      ),
      backgroundColor: color,
      onDeleted: onDeleted != null ? onDeleted : null,
      deleteIconColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.symmetric(
        horizontal: s(6),
        vertical: s(8),
      ), // Smaller
    );
  }

  

  Widget _buildPersonalityBar(double value) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                color: kPrimaryColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}