import 'dart:io';
import 'dart:convert';
import 'package:dating_app/Core/AuthStorage/auth_storage.dart';
import 'package:dating_app/Presentation/Provider/mainprofileprovider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

// -------------------- Models & Providers --------------------
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
class ProfilePageMobile extends HookConsumerWidget {
  const ProfilePageMobile({super.key});

  BoxDecoration _cardDecoration({Color? color, double radius = 12}) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(radius.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12.r,
          offset: Offset(0, 6.r),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, {bool isDense = false}) {
    return InputDecoration(
      labelText: label,
      isDense: isDense,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.r),
        borderSide: const BorderSide(color: kBodyTextColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.r),
        borderSide: const BorderSide(color: kBodyTextColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.r),
        borderSide: BorderSide(color: kPrimaryColor, width: 2.w),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 14.w,
        vertical: isDense ? 10.h : 12.h,
      ),
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

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, _) {
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
        final newTagCtrl = ref.watch(newTagControllerProvider);
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

        final defaultAvatarProvider = const AssetImage(
          'assets/image/coupl2.jpg',
        );
        final displayedAvatar = avatarImage ?? defaultAvatarProvider;
        final leftCardBg = const Color(0xFFFFF2EE);
        final infoBoxBg = const Color(0xFFF6DCD8);

        // Drawer menu
        final drawer = Drawer(
          backgroundColor: Colors.white,
          child: ListView(
            children: [
              DrawerHeader(
                child: Center(
                  child: Text(
                    "Menu",
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _drawerItem(Icons.person, "Profile", true),
              _drawerItem(Icons.favorite, "Matches", false),
              _drawerItem(Icons.chat, "Messages", false),
              _drawerItem(Icons.explore, "Discover", false),
              _drawerItem(Icons.settings, "Settings", false),
              _drawerItem(Icons.logout, "Logout", false),
            ],
          ),
        );

        return Scaffold(
          backgroundColor: kBackgroundColor,
          drawer: drawer,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            iconTheme: const IconThemeData(color: kPrimaryColor),
            title: Text(
              "Profile",
              style: TextStyle(
                color: kPrimaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar, name, role, bio, info
                Container(
                  width: double.infinity,
                  decoration: _cardDecoration(color: leftCardBg, radius: 16.r),
                  padding: EdgeInsets.symmetric(
                    vertical: 18.h,
                    horizontal: 18.w,
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 116.w,
                            height: 116.w,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: isEditing
                                ? () => _pickAndSetAvatar(ref)
                                : null,
                            child: CircleAvatar(
                              radius: 52.w,
                              backgroundImage: displayedAvatar,
                            ),
                          ),
                          if (isEditing)
                            Positioned(
                              right: 6.w,
                              bottom: 6.h,
                              child: Material(
                                elevation: 2,
                                color: Colors.white,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  onTap: () => _pickAndSetAvatar(ref),
                                  customBorder: const CircleBorder(),
                                  child: Padding(
                                    padding: EdgeInsets.all(6.w),
                                    child: Icon(
                                      Icons.camera_alt,
                                      size: 14.w,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      _editableTextField(
                        isEditing,
                        nameCtrl,
                        'Name',
                        18.sp,
                        true,
                      ),
                      SizedBox(height: 6.h),
                      _editableTextField(
                        isEditing,
                        roleCtrl,
                        'Role',
                        14.sp,
                        false,
                        color: kPrimaryColor,
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        width: 40.w,
                        height: 6.h,
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        bioCtrl.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: kBodyTextColor,
                          height: 1.4,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Container(
                        decoration: _cardDecoration(
                          color: infoBoxBg,
                          radius: 12.r,
                        ),
                        padding: EdgeInsets.all(12.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow('Age', ageCtrl, isEditing),
                            SizedBox(height: 6.h),
                            _infoRow(
                              'Status',
                              TextEditingController()..text = 'Single',
                              false,
                            ),
                            SizedBox(height: 6.h),
                            _infoRow('Location', locCtrl, isEditing),
                            SizedBox(height: 6.h),
                            _infoRow('Archetype', archetypeCtrl, isEditing),
                            SizedBox(height: 12.h),
                            Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
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
                                          (e) => _styledInterestChip(
                                            e,
                                            kPrimaryColor,
                                          ),
                                        )
                                        .toList()
                                  : tags
                                        .map(
                                          (e) => _styledInterestChip(
                                            e,
                                            kPrimaryColor,
                                            onDeleted: isEditing
                                                ? () {
                                                    final updated =
                                                        List<String>.from(tags)
                                                          ..remove(e);
                                                    ref
                                                            .read(
                                                              tagsprofilepageProvider
                                                                  .notifier,
                                                            )
                                                            .state =
                                                        updated;
                                                  }
                                                : null,
                                          ),
                                        )
                                        .toList(),
                            ),
                            if (isEditing) SizedBox(height: 10.h),
                            if (isEditing)
                              _addTagField(ref, kPrimaryColor, newTagCtrl),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      ElevatedButton.icon(
                        icon: Icon(
                          isEditing ? Icons.save : Icons.edit,
                          size: 14.w,
                        ),
                        label: Text(
                          isEditing ? 'Save Changes' : 'Edit Profile',
                          style: TextStyle(fontSize: 13.sp),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          padding: EdgeInsets.symmetric(
                            horizontal: 18.w,
                            vertical: 14.h,
                          ),
                        ),
                        onPressed: () async {
                          if (isEditing) {
                            await _saveProfile(ref, context);
                            ref.read(isEditingprofilepageProvider.notifier).state = false;
                          } else {
                            ref.read(isEditingprofilepageProvider.notifier).state = true;
                          }
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // Motivations
                _motivationsSection(
                  motivations,
                  isEditing,
                  motivationsNotifier,
                ),

                SizedBox(height: 12.h),

                // Frustrations
                _frustrationsSection(
                  isEditing,
                  frustrations,
                  frustrationsNotifier,
                  newFrustrationCtrl,
                ),

                SizedBox(height: 12.h),

                // Personality Column Layout
                _personalitySection(
                  personalityList,
                  personalityNotifier,
                  isEditing,
                  newTraitLeftCtrl,
                  newTraitRightCtrl,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------- Widgets --------------------

  Widget _drawerItem(IconData icon, String title, bool active) {
    return ListTile(
      leading: Icon(icon, color: active ? kPrimaryColor : Colors.black54),
      title: Text(
        title,
        style: TextStyle(
          color: active ? kPrimaryColor : Colors.black87,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _editableTextField(
    bool edit,
    TextEditingController c,
    String l,
    double size,
    bool bold, {
    Color? color,
  }) {
    return edit
        ? TextField(controller: c, decoration: _inputDecoration(l))
        : Text(
            c.text,
            style: TextStyle(
              fontSize: size,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color ?? kTitleColor,
            ),
          );
  }

  Widget _infoRow(String label, TextEditingController c, bool edit) {
    return Row(
      children: [
        SizedBox(
          width: 100.w,
          child: Text('$label:', style: TextStyle(fontSize: 13.sp)),
        ),
        Expanded(
          child: edit
              ? TextField(controller: c, decoration: _inputDecoration(label))
              : Text(
                  c.text,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: kTitleColor,
                    fontSize: 13.sp,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _addTagField(WidgetRef ref, Color color, TextEditingController ctrl) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            decoration: _inputDecoration('Add new interest...'),
          ),
        ),
        SizedBox(width: 8.w),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          ),
          onPressed: () {
            final t = ctrl.text.trim();
            if (t.isNotEmpty) {
              final updated = List<String>.from(
                ref.read(tagsprofilepageProvider),
              )..add(t);
              ref.read(tagsprofilepageProvider.notifier).state = updated;
              ctrl.clear();
            }
          },
          child: Text(
            'Add',
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
          ),
        ),
      ],
    );
  }

  Widget _styledInterestChip(String l, Color c, {VoidCallback? onDeleted}) {
    return Chip(
      label: Text(
        l,
        style: TextStyle(color: Colors.white, fontSize: 12.sp),
      ),
      backgroundColor: c,
      onDeleted: onDeleted,
      deleteIconColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
    );
  }

  Widget _motivationsSection(
    List<MotiveItem> m,
    bool e,
    StateController<List<MotiveItem>> n,
  ) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Motivations',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: headingViolet,
              fontSize: 15.sp,
            ),
          ),
          ...m.map((x) {
            final i = m.indexOf(x);
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      e
                          ? SizedBox(
                              width: 140.w,
                              child: TextField(
                                controller: TextEditingController(
                                  text: x.label,
                                ),
                                decoration: _inputDecoration(
                                  'Label',
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  final u = List<MotiveItem>.from(m);
                                  u[i] = MotiveItem(
                                    label: val,
                                    value: u[i].value,
                                  );
                                  n.state = u;
                                },
                              ),
                            )
                          : Text(
                              x.label,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                      Text(
                        '${(x.value * 100).round()}%',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: kBodyTextColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    height: 10.h,
                    decoration: BoxDecoration(
                      color: kBackgroundColor,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Stack(
                      children: [
                        FractionallySizedBox(
                          widthFactor: x.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (e)
                    Slider(
                      value: x.value,
                      onChanged: (v) {
                        final u = List<MotiveItem>.from(m);
                        u[i] = MotiveItem(label: u[i].label, value: v);
                        n.state = u;
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
    );
  }

  Widget _frustrationsSection(
    bool e,
    List<String> f,
    StateController<List<String>> n,
    TextEditingController ctrl,
  ) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frustrations',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: headingViolet,
              fontSize: 15.sp,
            ),
          ),
          SizedBox(height: 8.h),
          ...f.map((x) {
            final i = f.indexOf(x);
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 6.h),
                    child: Icon(Icons.circle, size: 8.w, color: kPrimaryColor),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: e
                        ? Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: TextEditingController(text: x),
                                  onChanged: (val) {
                                    final u = List<String>.from(f);
                                    u[i] = val;
                                    n.state = u;
                                  },
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  final u = List<String>.from(f)..removeAt(i);
                                  n.state = u;
                                },
                                icon: Icon(
                                  Icons.delete,
                                  size: 18.w,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            x,
                            style: TextStyle(
                              color: kBodyTextColor,
                              fontSize: 13.sp,
                            ),
                          ),
                  ),
                ],
              ),
            );
          }),
          if (e)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    decoration: InputDecoration(
                      hintText: 'Add new frustration',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                    ),
                    onSubmitted: (val) {
                      final v = val.trim();
                      if (v.isEmpty) return;
                      final u = List<String>.from(f)..add(v);
                      n.state = u;
                      ctrl.clear();
                    },
                  ),
                ),
                SizedBox(width: 8.w),
                ElevatedButton(
                  onPressed: () {
                    final v = ctrl.text.trim();
                    if (v.isEmpty) return;
                    final u = List<String>.from(f)..add(v);
                    n.state = u;
                    ctrl.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                  ),
                  child: Text('Add', style: TextStyle(fontSize: 13.sp)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _personalitySection(
    List<PersonalityItem> list,
    StateController<List<PersonalityItem>> notifier,
    bool edit,
    TextEditingController left,
    TextEditingController right,
  ) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personality',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: headingViolet,
              fontSize: 15.sp,
            ),
          ),
          ...list.map((x) {
            final i = list.indexOf(x);
            return Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  edit
                      ? TextField(
                          controller: TextEditingController(text: x.left),
                          decoration: _inputDecoration(
                            'Left Trait',
                            isDense: true,
                          ),
                          onChanged: (v) => x.left = v,
                        )
                      : Text(
                          x.left,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: kTitleColor,
                          ),
                        ),
                  SizedBox(height: 8.h),
                  edit
                      ? Slider(
                          value: x.value,
                          onChanged: (v) {
                            final u = List<PersonalityItem>.from(list);
                            u[i] = PersonalityItem(
                              left: x.left,
                              right: x.right,
                              value: v,
                            );
                            notifier.state = u;
                          },
                          activeColor: kPrimaryColor,
                          min: 0,
                          max: 1,
                        )
                      : _buildPersonalityBar(x.value),
                  SizedBox(height: 8.h),
                  edit
                      ? TextField(
                          controller: TextEditingController(text: x.right),
                          decoration: _inputDecoration(
                            'Right Trait',
                            isDense: true,
                          ),
                          onChanged: (v) => x.right = v,
                        )
                      : Text(
                          x.right,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: kTitleColor,
                          ),
                        ),
                  if (edit)
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.redAccent,
                          size: 18.w,
                        ),
                        onPressed: () {
                          final u = List<PersonalityItem>.from(list)
                            ..removeAt(i);
                          notifier.state = u;
                        },
                      ),
                    ),
                ],
              ),
            );
          }),
          if (edit)
            Container(
              margin: EdgeInsets.only(top: 12.h),
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add New Trait',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: headingViolet,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: left,
                    decoration: _inputDecoration('Left trait', isDense: true),
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: right,
                    decoration: _inputDecoration('Right trait', isDense: true),
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  SizedBox(height: 10.h),
                  ElevatedButton(
                    onPressed: () {
                      if (left.text.trim().isNotEmpty &&
                          right.text.trim().isNotEmpty) {
                        final u = List<PersonalityItem>.from(list)
                          ..add(
                            PersonalityItem(
                              left: left.text,
                              right: right.text,
                              value: 0.5,
                            ),
                          );
                        notifier.state = u;
                        left.clear();
                        right.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      'Add Trait',
                      style: TextStyle(color: Colors.white, fontSize: 13.sp),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalityBar(double value) {
    return Container(
      height: 6.h,
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(3.r),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                color: kPrimaryColor,
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}