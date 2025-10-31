// login_screen_mobile.dart
import 'dart:io';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:dating_app/Application/UseCases/login_usecases.dart';
import 'package:dating_app/Application/UseCases/user_register_usecases.dart';
import 'package:dating_app/Core/AuthStorage/auth_storage.dart';
import 'package:dating_app/Core/Theme/colors.dart';
import 'package:dating_app/Data/API/login_api.dart';
import 'package:dating_app/Data/API/profile_api.dart';
import 'package:dating_app/Data/API/register_api.dart';
import 'package:dating_app/Data/API/social_api.dart';
import 'package:dating_app/Data/Models/userinformation_model.dart';
import 'package:dating_app/Data/Repositories/Implementation/login_implementation.dart';
import 'package:dating_app/Data/Repositories/Implementation/register_implementation.dart';
import 'package:dating_app/Domain/Enteties/user_entities.dart';
import 'package:dating_app/Domain/Enteties/user_register_entities.dart';
import 'package:dating_app/Presentation/Provider/login_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


final isSignUpProvider = StateProvider<bool>((ref) => false);

class LoginScreenMobile extends HookConsumerWidget {
  const LoginScreenMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignUp = ref.watch(isSignUpProvider);


    
    Future<void> handleGoogleSignIn() async {
      final social = SocialAuth();
      final api = ProfileApi();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Starting Google sign-in...')),
        );
      }

      try {
        final token = await social.signInWithProvider('google');

        if (token == null || token.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Google sign-in not completed.')),
            );
          }
          return;
        }

        // Persist token
        await social.saveToken(token);

        // Attempt to fetch profile using your ProfileApi
        UserinformationModel? profile;
        String rawBody = '';
        try {
          // Use ProfileApi.fetchProfile
          profile = await api.fetchProfile(token);

          // If fetchProfile returns null, try fallback GET /api/profile (explicit)
          if (profile == null) {
            final uri = Uri.parse('http://localhost:3000/api/profile');
            final resp = await http.get(
              uri,
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            );
            rawBody = resp.body;
            if (resp.statusCode == 200) {
              final Map<String, dynamic> j =
                  jsonDecode(resp.body) as Map<String, dynamic>;
              profile = UserinformationModel.fromMap(j);
            } else {
              debugPrint('Fallback /api/profile returned ${resp.statusCode}');
              profile = null;
            }
          }
        } catch (e, st) {
          debugPrint('fetchProfile error: $e\n$st');
          profile = null;
        }

        // DEBUG: print raw profile object & model fields
        debugPrint('=== PROFILE FETCH DEBUG ===');
        if (rawBody.isNotEmpty) {
          debugPrint('Raw fallback body: $rawBody');
        }
        if (profile == null) {
          debugPrint('Profile is null after fetch.');
        } else {
          debugPrint(
            'Profile model -> name: "${profile.name}", age: ${profile.age}, bio: "${profile.bio}", profilePicture: "${profile.profilePicture}", profilePictureUrl: "${profile.profilePictureUrl}"',
          );
        }

        // Accept either profilePictureUrl or profilePicture field
        final picture =
            (profile?.profilePictureUrl ?? profile?.profilePicture ?? '')
                .toString()
                .trim();

        // Strict completeness: all required
        final hasName =
            profile?.name != null && profile!.name.trim().isNotEmpty;
        final hasAge = profile?.age != null && profile!.age > 0;
        final hasBio = profile?.bio != null && profile!.bio.trim().isNotEmpty;
        final hasPicture = picture.isNotEmpty;

        debugPrint(
          'Checks -> hasName:$hasName, hasAge:$hasAge, hasBio:$hasBio, hasPicture:$hasPicture',
        );

        final bool isComplete = hasName && hasAge && hasBio && hasPicture;

       

        if (!context.mounted) return;
        if (isComplete) {
          if (context.mounted) {
            context.go('/homepage');
          }
        } else {
          if (context.mounted) {
            context.go('/setup');
          }
        }
      } on SocketException {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Network error — please check your connection.'),
            ),
          );
        }
      } catch (e, st) {
        debugPrint('_handleGoogleSignIn error: $e\n$st');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign-in failed: ${e.toString()}')),
          );
          context.go(
            '/setup',
          ); // fallback to setup so user can finish onboarding
        }
      }
    }



    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
          child: Column(
            children: [
              // small header with animated title (less intrusive)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: -30.0, end: 0.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, dx, child) {
                  final opacity = (dx + 30) / 30;
                  return Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(dx, 0),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  'Kismet',
                  style: TextStyle(
                    fontSize: 48.sp,
                    fontWeight: FontWeight.w700,
                    color: headingViolet,
                  ),
                ),
              ),

              SizedBox(height: 12.h),

              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      kPrimaryColor,
                      kPrimaryColor.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                padding: EdgeInsets.all(16.r),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 44.r,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: 10.h),

              Text(
                'Where hearts align by fate',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontStyle: FontStyle.italic,
                  color: subtextViolet.withValues(alpha: 0.8),
                ),
              ),

              SizedBox(height: 18.h),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                child: isSignUp
                    ? _AuthCardMobile(
                        key: const ValueKey('signup_mobile'),
                        title: "Begin Your Journey",
                        subtitle: "Create your profile and find your match",
                        buttonText: "Create Account",
                        bottomText: "Already on Kismet?",
                        toggleText: " Sign In",
                        accentColor: headingViolet,
                        onToggle: () =>
                            ref.read(isSignUpProvider.notifier).state = false,
                      )
                    : _AuthCardMobile(
                        key: const ValueKey('login_mobile'),
                        title: "Welcome Back",
                        subtitle: "Continue your journey to love",
                        buttonText: "Sign In",
                        bottomText: "New to Kismet?",
                        toggleText: " Create Account",
                        accentColor: headingViolet,
                        onToggle: () =>
                            ref.read(isSignUpProvider.notifier).state = true,
                      ),
              ),

              SizedBox(height: 12.h),

              Text(
                'or continue with',
                style: TextStyle(
                  color: kBodyTextColor.withValues(alpha: 0.7),
                  fontSize: 14.sp,
                ),
              ),

              SizedBox(height: 8.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialIconButtonMobile(
                    image: 'assets/image/googleicon.png',
                    label: 'Google',
                    onTap: handleGoogleSignIn,
                    bgColor: Colors.white,
                    textColor: charcoal,
                    borderColor: kBodyTextColor.withValues(alpha: 0.15),
                  ),
                  SizedBox(width: 10.w),
                
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthCardMobile extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final String bottomText;
  final String toggleText;
  final VoidCallback onToggle;
  final Color accentColor;

  const _AuthCardMobile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.bottomText,
    required this.toggleText,
    required this.onToggle,
    required this.accentColor,
  });

  @override
  ConsumerState<_AuthCardMobile> createState() => _AuthCardMobileState();
}

class _AuthCardMobileState extends ConsumerState<_AuthCardMobile> {
  final _formKey = GlobalKey<FormState>();

  // Now use provider-backed controllers (do not create new instances here)
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController nameController;
  late final TextEditingController confirmpasswordController;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Obtain controller instances from Riverpod providers.
    // Using ref.read in initState returns the same instance for the scope.
    emailController = ref.read(emailControllerProvider);
    passwordController = ref.read(passwordControllerProvider);
    nameController = ref.read(nameControllerProvider);
    confirmpasswordController = ref.read(confirmPasswordControllerProvider);
  }

  @override
  void dispose() {
    // IMPORTANT: don't dispose controllers here — providers handle disposal (autoDispose).
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Full name is required';
    if (v.trim().length < 2) return 'Enter a valid name';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Confirm your password';
    if (v != passwordController.text) return 'Passwords do not match';
    return null;
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: kBodyTextColor.withValues(alpha: 0.45),
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(
        icon,
        color: subtextViolet.withValues(alpha: 0.6),
        size: 22.r,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: kSecondaryColor.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: kSecondaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: kSecondaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: kPrimaryColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
    );
  }

  /// Show an AwesomeSnackbar via ScaffoldMessenger (survives UI changes)
  void _showAwesomeSnackBar({
    required BuildContext ctx,
    required String title,
    required String message,
    required ContentType contentType,
    Duration duration = const Duration(seconds: 4),
  }) {
    final snack = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      duration: duration,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: contentType,
      ),
    );

    ScaffoldMessenger.of(ctx).showSnackBar(snack);
  }

  Future<void> _submitRegister() async {
    final isSignUp = widget.title.toLowerCase().contains('journey');

    // Validate
    if (!(_formKey.currentState?.validate() ?? false)) {
      if (!mounted) return;
      _showAwesomeSnackBar(
        ctx: context,
        title: 'Validation error',
        message: 'Please check your input fields.',
        contentType: ContentType.failure,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // start loading
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      if (isSignUp) {
        final entity = UserRegisterEntities(
          username: nameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text,
          confirmpassword: confirmpasswordController.text,
        );

        final api = RegisterAuth();
        final repo = RegisterImplementation(api);
        final useCase = RegisterUseCase(repo);

        final result = await useCase.execute(entity);

        if (!mounted) return;
        setState(() => isLoading = false);

        if (result['success'] == true) {
          passwordController.clear();
          confirmpasswordController.clear();

          _showAwesomeSnackBar(
            ctx: context,
            title: 'Success!',
            message: 'You Successfully Registered — please log in to proceed',
            contentType: ContentType.success,
            duration: const Duration(seconds: 4),
          );

          // flip to login view (same screen)
          widget.onToggle();
        } else {
          _showAwesomeSnackBar(
            ctx: context,
            title: 'Registration failed',
            message: result['message']?.toString() ?? 'Please try again',
            contentType: ContentType.failure,
            duration: const Duration(seconds: 4),
          );
        }
      } else {
        final loginModel = UserLoginEntities(
          email: emailController.text.trim(),
          password: passwordController.text,
        );

        final loginApi = LoginApi();
        final repo = LoginImplementation(loginApi);
        final useCase = LoginUsecases(repo);

        final loginResult = await useCase.execute(loginModel);

        if (!mounted) return;
        setState(() => isLoading = false);

        if (loginResult['success'] == true) {
          if (context.mounted) {
            _showAwesomeSnackBar(
              ctx: context,
              title: 'Welcome!',
              message: loginResult['message']?.toString() ?? 'Login successful',
              contentType: ContentType.success,
              duration: const Duration(seconds: 2),
            );
          }

          // optional: persist token if backend returned one
          final token = loginResult['token'] as String?;
          if (token != null && token.isNotEmpty) {
            try {
              await saveToken(
                token,
              ); // remove or replace if your helper name differs
            } catch (e) {
              debugPrint('saveToken failed: $e');
            }
          }

          // Show success snackbar (you already do this above — keep if duplicated)
          // _showAwesomeSnackBar(...)

          try {
            final api = ProfileApi();
            UserinformationModel? existingProfile;

            // Prefer using the token returned from login; fallback to readToken() if necessary
            final effectiveToken = token ?? await readToken();

            if (effectiveToken != null && effectiveToken.isNotEmpty) {
              existingProfile = await api.fetchProfile(effectiveToken);
            } else {
              existingProfile = null;
            }

            final hasProfile =
                existingProfile != null &&
                (existingProfile.name.trim().isNotEmpty == true) &&
                (existingProfile.age > 0) &&
                (existingProfile.bio.trim().isNotEmpty == true) &&
                (existingProfile.profilePicture?.trim().isNotEmpty == true);

            if (!mounted) return;

            if (hasProfile) {
              // user already has a complete profile -> go home
              if (context.mounted) {
                context.go('/homepage');
              }
            } else {
              // no/partial profile -> go to setup
              if (context.mounted) {
                context.go('/setup');
              }
            }
          } catch (e, st) {
            debugPrint('fetchProfile after login failed: $e\n$st');
            // fallback: go to setup if profile check fails
            if (context.mounted) return;
            context.go('/setup');
          }
        } else {
          _showAwesomeSnackBar(
            ctx: context,
            title: 'Login failed',
            message:
                loginResult['message']?.toString() ?? 'Invalid credentials',
            contentType: ContentType.failure,
            duration: const Duration(seconds: 4),
          );
        }
      }
    } on SocketException {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showAwesomeSnackBar(
        ctx: context,
        title: 'Network error',
        message: 'Cannot reach the server. Please check your connection.',
        contentType: ContentType.failure,
      );
    } on FormatException {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showAwesomeSnackBar(
        ctx: context,
        title: 'Bad response',
        message: 'Invalid server response format.',
        contentType: ContentType.failure,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showAwesomeSnackBar(
        ctx: context,
        title: 'Error',
        message: 'Unexpected error occurred: $e',
        contentType: ContentType.failure,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSignUp = widget.title.toLowerCase().contains('journey');

    return Form(
      key: _formKey,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: kSecondaryColor.withValues(alpha: 0.06),
              blurRadius: 12.r,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: widget.accentColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            Text(
              widget.subtitle,
              style: TextStyle(
                fontSize: 12.sp,
                color: kBodyTextColor.withValues(alpha: 0.85),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),

            if (isSignUp)
              Column(
                children: [
                  TextFormField(
                    controller: nameController,
                    validator: _validateName,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration('Full name', Icons.person),
                  ),
                  SizedBox(height: 10.h),
                ],
              ),

            TextFormField(
              controller: emailController,
              validator: _validateEmail,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration('Email address', Icons.email),
            ),
            SizedBox(height: 10.h),

            TextFormField(
              controller: passwordController,
              obscureText: _obscurePassword,
              validator: _validatePassword,
              textInputAction: isSignUp
                  ? TextInputAction.next
                  : TextInputAction.done,
              decoration: _inputDecoration(
                'Password',
                Icons.lock,
                suffix: IconButton(
                  splashRadius: 20.r,
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    size: 20.r,
                    color: kBodyTextColor.withValues(alpha: 0.6),
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            SizedBox(height: 10.h),

            if (isSignUp)
              Column(
                children: [
                  TextFormField(
                    controller: confirmpasswordController,
                    obscureText: _obscureConfirm,
                    validator: _validateConfirm,
                    textInputAction: TextInputAction.done,
                    decoration: _inputDecoration(
                      'Confirm Password',
                      Icons.security,
                      suffix: IconButton(
                        splashRadius: 20.r,
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20.r,
                          color: kBodyTextColor.withValues(alpha: 0.6),
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                ],
              ),

            SizedBox(height: 12.h),

            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _submitRegister(); // triggers register OR login flow
                        } else {
                          // reuse your existing top snack
                          showTopSnackBar(context);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator.adaptive()
                    : Text(
                        widget.buttonText,
                        style: TextStyle(fontSize: 15.sp),
                      ),
              ),
            ),

            SizedBox(height: 10.h),

            GestureDetector(
              onTap: widget.onToggle,
              child: RichText(
                text: TextSpan(
                  text: widget.bottomText,
                  style: TextStyle(
                    color: kBodyTextColor.withValues(alpha: 0.8),
                    fontSize: 13.sp,
                  ),
                  children: [
                    TextSpan(
                      text: widget.toggleText,
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showTopSnackBar(BuildContext context) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      right: 20,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 150,
          padding: EdgeInsets.all(16),
          color: Colors.redAccent,
          child: Text('Error', style: TextStyle(color: Colors.white)),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Future.delayed(Duration(seconds: 3), () => entry.remove());
}

class _SocialIconButtonMobile extends StatelessWidget {
  final String image;
  final String label;
  final VoidCallback onTap;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;

  const _SocialIconButtonMobile({
    required this.image,
    required this.label,
    required this.onTap,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: 120.w,
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(image, height: 22.h, width: 18.w),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
