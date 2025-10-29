import 'package:dating_app/Core/Auth/auth_storage.dart';
import 'package:dating_app/Data/API/profile_api.dart';
import 'package:dating_app/Data/Models/userinformation_model.dart';
import 'package:dating_app/Presentation/Provider/profile_provider.dart';
import 'package:dating_app/Presentation/View/Desktop/completeprofile_dekstop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:path_provider/path_provider.dart';


const Color kTitleColor = Color(0xFF2D2D2D);
const Color kBodyTextColor = Color(0xFF4F4F4F);
const Color kPrimaryColor = Color(0xFFE91E63);
const Color kSecondaryColor = Color(0xFFCFA7F6);
const Color kAccentColor = Color(0xFFFFDCA8);
const Color kBackgroundColor = Color(0xFFFAF6F9);
const Color subtextViolet = Color(0xFF4B3B9A);
const Color headingViolet = Color(0xFF3D2C8D);

/// Mobile Profile Setup with Global Providers
class ProfileSetupMobile extends ConsumerWidget {
  const ProfileSetupMobile({super.key});

  // clampScale tuned for mobile (target width 575)
  double clampScale(double width, double base, double min, double max) {
    const double target = 575.0;
    final raw = width / target;
    final factor = raw.clamp(0.85, 1.18);
    final scaled = base * factor;
    return scaled.clamp(min, max);
  }

  /// simplified file picker - same as desktop and tablet
  Future<void> pickFile(WidgetRef ref, BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        ref.read(selectedFileProvider.notifier).state = result.files.single;
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }


  /// Convert PlatformFile -> File (handles path OR bytes)
  Future<File> _platformFileToFile(PlatformFile pf) async {
    // If the PlatformFile already has a path (mobile/desktop), use it.
    if (pf.path != null && pf.path!.isNotEmpty) {
      return File(pf.path!);
    }

    // Otherwise, create a temporary file and write bytes to it.
    final bytes = pf.bytes;
    if (bytes == null) {
      throw Exception('PlatformFile has no bytes and no path');
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/${pf.name}');
    await tempFile.writeAsBytes(bytes, flush: true);
    return tempFile;
  }

  
Future<void> _submitProfile(
  BuildContext context,
  GlobalKey<FormState> formKey,
  WidgetRef ref,
) async {
  final filePlatform = ref.read(selectedFileProvider);
  final nameCtl = ref.read(nameprofileControllerProvider);
  final ageCtl = ref.read(ageControllerProvider);
  final bioCtl = ref.read(bioControllerProvider);

  if (!formKey.currentState!.validate()) return;

  if (filePlatform == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please upload a profile picture'),
        backgroundColor: kPrimaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
    // get token (works for web + mobile)
    final token = await readToken();

    if (token == null || token.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You must be logged in to create a profile'),
            backgroundColor: kPrimaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    final name = nameCtl.text.trim();
    final age = int.tryParse(ageCtl.text.trim()) ?? 0;
    final bio = bioCtl.text.trim();

    final api = ProfileApi();
    late final UserinformationModel updatedUser;

    // platformFile may be PlatformFile or a wrapper; extract safely
    PlatformFile? platformFile;
    if (filePlatform is PlatformFile) {
      platformFile = filePlatform;
    } else if (filePlatform != null && filePlatform is ValueNotifier) {
      platformFile = (filePlatform as ValueNotifier<PlatformFile?>).value;
    } else {
      // Defensive fallback: try to cast dynamically
      try {
        platformFile = filePlatform as PlatformFile?;
      } catch (_) {
        platformFile = null;
      }
    }

    if (platformFile == null) {
      throw Exception('Selected file is invalid.');
    }

    if (kIsWeb) {
      // on web use bytes + filename
      final bytes = platformFile.bytes;
      final filename = platformFile.name;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Selected file has no bytes (web).');
      }
      updatedUser = await api.uploadProfile(
        token: token,
        name: name,
        age: age,
        bio: bio,
        imageBytes: bytes,
        filename: filename,
      );
    } else {
      // non-web: convert to dart:io File and upload
      final imageFile = await _platformFileToFile(platformFile);
      updatedUser = await api.uploadProfile(
        token: token,
        name: name,
        age: age,
        bio: bio,
        imageFile: imageFile,
      );
    }
  if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✨ Profile created successfully!'),
          backgroundColor: kPrimaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      if (!context.mounted) return;
      context.go('/homepage');

    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ProfileResultScreen(user: updatedUser),
      ),
    );
  } catch (e, st) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    debugPrint('Profile upload failed: $e\n$st');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Upload failed: $e'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}


  Widget _textField({
    required double width,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    double cs(double base, double min, double max) =>
        clampScale(width, base, min, max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: cs(14, 12, 16),
            fontWeight: FontWeight.w600,
            color: headingViolet,
          ),
        ),
        SizedBox(height: cs(8, 6, 12)),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(fontSize: cs(15, 13, 18), color: kTitleColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: kBodyTextColor.withValues(alpha: 0.6),
              fontSize: cs(14, 12, 16),
            ),
            prefixIcon: Icon(icon, color: subtextViolet, size: cs(20, 18, 24)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: kSecondaryColor.withValues(alpha: 0.28),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: kPrimaryColor, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: maxLines > 1 ? 14 : 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(double maxWidth, WidgetRef ref, BuildContext context) {
    // Using GLOBAL providers that are shared across all screen sizes - SAME AS TABLET
    final nameController = ref.watch(nameprofileControllerProvider);
    final ageController = ref.watch(ageControllerProvider);
    final bioController = ref.watch(bioControllerProvider);
    final selectedFile = ref.watch(selectedFileProvider);
    final isHovering = ref.watch(hoverProvider);

    final formKey = GlobalKey<FormState>();

    double cs(double base, double min, double max) =>
        clampScale(maxWidth, base, min, max);
    final avatarSize = cs(110, 80, 140);

    return Padding(
      padding: EdgeInsets.all(cs(18, 12, 28)),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // header row - SAME UI AS BEFORE
            Row(
              children: [
                Container(
                  width: cs(50, 40, 70),
                  height: cs(50, 40, 70),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kPrimaryColor, kSecondaryColor],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryColor.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: cs(22, 18, 30),
                  ),
                ),
                SizedBox(width: cs(12, 8, 16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Your Profile',
                        style: TextStyle(
                          fontSize: cs(18, 16, 22),
                          fontWeight: FontWeight.bold,
                          color: headingViolet,
                        ),
                      ),
                      SizedBox(height: cs(4, 2, 8)),
                      Text(
                        'Tell us about yourself and find your perfect match',
                        style: TextStyle(
                          fontSize: cs(12, 10, 14),
                          color: subtextViolet,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: cs(18, 12, 28)),

            // avatar - SAME LOGIC AS TABLET
            Center(
              child: MouseRegion(
                onEnter: (_) => ref.read(hoverProvider.notifier).state = true,
                onExit: (_) => ref.read(hoverProvider.notifier).state = false,
                child: GestureDetector(
                  onTap: () => pickFile(ref, context),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: selectedFile == null
                          ? LinearGradient(
                              colors: [
                                kSecondaryColor.withValues(alpha: 0.25),
                                kAccentColor.withValues(alpha: 0.18),
                              ],
                            )
                          : null,
                      border: Border.all(
                        color: isHovering ? kPrimaryColor : kSecondaryColor,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kSecondaryColor.withValues(alpha: .12),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: selectedFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_rounded,
                                size: cs(28, 22, 36),
                                color: subtextViolet,
                              ),
                              SizedBox(height: cs(6, 4, 10)),
                              Text(
                                'Add Photo',
                                style: TextStyle(
                                  color: subtextViolet,
                                  fontSize: cs(12, 10, 14),
                                ),
                              ),
                            ],
                          )
                        : ClipOval(
                            child: SizedBox(
                              width: avatarSize,
                              height: avatarSize,
                              child: Image.memory(
                                selectedFile.bytes!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.error_outline,
                                      color: kPrimaryColor,
                                      size: cs(28, 22, 36),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
            SizedBox(height: cs(18, 14, 26)),

            // fields - SAME LOGIC AS TABLET
            _textField(
              width: maxWidth,
              controller: nameController,
              label: 'Name',
              hint: 'Enter your name',
              icon: Icons.person_rounded,
              validator: (v) => v == null || v.isEmpty
                  ? 'Please enter your name'
                  : null,
            ),
            SizedBox(height: cs(12, 10, 18)),
            _textField(
              width: maxWidth,
              controller: ageController,
              label: 'Age',
              hint: 'Enter your age',
              icon: Icons.cake_rounded,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your age';
                final a = int.tryParse(v);
                if (a == null || a < 18 || a > 100) {
                  return 'Please enter a valid age (18-100)';
                }
                return null;
              },
            ),
            SizedBox(height: cs(12, 10, 18)),
            _textField(
              width: maxWidth,
              controller: bioController,
              label: 'About You',
              hint: 'Tell us something interesting...',
              icon: Icons.edit_note_rounded,
              maxLines: 4,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please write a short bio';
                if (v.length < 20) {
                  return 'Bio should be at least 20 characters';
                }
                return null;
              },
            ),
            SizedBox(height: cs(18, 12, 24)),

            // Submit Button - SAME LOGIC AS TABLET
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [kPrimaryColor, kSecondaryColor],
                ),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryColor.withValues(alpha:0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => _submitProfile(context, formKey, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(
                    vertical: clampScale(maxWidth, 17, 20, 25),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Create Profile',
                  style: TextStyle(
                    fontSize: clampScale(maxWidth, 16, 14, 18),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) {
        final mediaWidth = MediaQuery.of(context).size.width;
        return Scaffold(
          backgroundColor: kBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 575),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: _buildForm(mediaWidth.clamp(0.0, 575.0), ref, context),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}