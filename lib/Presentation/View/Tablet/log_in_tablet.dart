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
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginScreenTablet extends HookConsumerWidget {
 const LoginScreenTablet({super.key});

  double _clampScale(double value, double min, double max) {
    return value.clamp(min, max);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignUp = ref.watch(isSignUpProvider);
    final Size screen = MediaQuery.of(context).size;
    final double screenWidth = screen.width;

    // --- DESIGN BASE ADJUSTED TO 1100px ---
    final double baseWidth = 1100; // <- changed from 768 to 1100
    final double scale = screenWidth / baseWidth;

    // Responsive values using clamp (these multipliers are the values at screenWidth == 1100)
    final double logoSize = _clampScale(48 * scale, 36, 60);
    final double logoPadding = _clampScale(20 * scale, 16, 24);
    final double taglineFontSize = _clampScale(13 * scale, 11, 16);
    final double brandFontSize = _clampScale(80 * scale, 60, 100);
    final double continueFontSize = _clampScale(18 * scale, 14, 22);
    final double cardWidth = _clampScale(400 * scale, 350, 500);
    final double cardPadding = _clampScale(24 * scale, 20, 32);
    final double titleFontSize = _clampScale(24 * scale, 20, 28);
    final double subtitleFontSize = _clampScale(13 * scale, 11, 15);
    final double buttonHeight = _clampScale(50 * scale, 44, 56);
    final double socialButtonWidth = _clampScale(170 * scale, 150, 200);
    final double horizontalPadding = _clampScale(screenWidth * 0.05, 16, 100);

    // Position values for tablet
    final double brandTop = _clampScale(30 * scale, 20, 40);
    final double brandLeft = _clampScale(50 * scale, 30, 80);
    final double continueTop = _clampScale(150 * scale, 120, 180);
    final double continueLeft = _clampScale(50 * scale, 30, 80);
    final double socialTop = _clampScale(200 * scale, 160, 240);
    final double socialLeft = _clampScale(50 * scale, 30, 80);
    final double backgroundHeight = _clampScale(400 * scale, 300, 500);
    final double backgroundWidth = _clampScale(350 * scale, 280, 450);



    
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
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kBackgroundColor,
                  kSecondaryColor.withValues(alpha: 0.08),
                  kAccentColor.withValues(alpha: 0.12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    vertical: _clampScale(32 * scale, 24, 48),
                    horizontal: horizontalPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo & Brand Section
                      Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  kPrimaryColor,
                                  kPrimaryColor.withValues(alpha: 0.85),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimaryColor.withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: kSecondaryColor.withValues(alpha: 0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(logoPadding),
                            child: Icon(
                              Icons.favorite_rounded,
                              size: logoSize,
                              color: Colors.white,
                            ),
                          ),

                          SizedBox(height: _clampScale(20 * scale, 16, 24)),
                          Text(
                            'Where hearts align by fate',
                            style: TextStyle(
                              fontSize: taglineFontSize,
                              fontWeight: FontWeight.w400,
                              color: subtextViolet.withValues(alpha: 0.8),
                              letterSpacing: 0.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: _clampScale(30 * scale, 20, 40)),

                      // Animated card container switcher
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 650),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final offsetAnimation =
                              Tween<Offset>(
                                begin: const Offset(0.0, 0.08),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutBack,
                                ),
                              );
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            ),
                          );
                        },
                        child: isSignUp
                            ? _AuthCardTablet(
                                key: const ValueKey('signup'),
                                title: "Begin Your Journey",
                                subtitle:
                                    "Create your profile and find your match",
                                buttonText: "Create Account",
                                bottomText: "Already on Kismet?",
                                toggleText: " Sign In",
                                accentColor: headingViolet,
                                onToggle: () =>
                                    ref.read(isSignUpProvider.notifier).state =
                                        false,
                                cardWidth: cardWidth,
                                cardPadding: cardPadding,
                                titleFontSize: titleFontSize,
                                subtitleFontSize: subtitleFontSize,
                                buttonHeight: buttonHeight,
                              )
                            : _AuthCardTablet(
                                key: const ValueKey('login'),
                                title: "Welcome Back",
                                subtitle: "Continue your journey to love",
                                buttonText: "Sign In",
                                bottomText: "New to Kismet?",
                                toggleText: " Create Account",
                                accentColor: headingViolet,
                                onToggle: () =>
                                    ref.read(isSignUpProvider.notifier).state =
                                        true,
                                cardWidth: cardWidth,
                                cardPadding: cardPadding,
                                titleFontSize: titleFontSize,
                                subtitleFontSize: subtitleFontSize,
                                buttonHeight: buttonHeight,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Background image for tablet
          Positioned(
            right: -30,
            bottom: 30,
            child: ClipRRect(
              child: Image.asset(
                'assets/image/fly.png',
                fit: BoxFit.cover,
                height: backgroundHeight,
                width: backgroundWidth,
                opacity: const AlwaysStoppedAnimation(0.8),
              ),
            ),
          ),

          // Brand name for tablet
          Positioned(
            top: brandTop,
            left: brandLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: -50.0, end: 0.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, dx, child) {
                final opacity = (dx + 50) / 50;
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
                  fontSize: brandFontSize,
                  fontWeight: FontWeight.w700,
                  color: headingViolet,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: kSecondaryColor.withValues(alpha: 0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // "or continue with" text for tablet
          Positioned(
            top: continueTop,
            left: continueLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or continue with',
                style: TextStyle(
                  color: kBodyTextColor.withValues(alpha: 0.7),
                  fontSize: continueFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Social buttons for tablet
          Positioned(
            top: socialTop,
            left: socialLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialIconButtonTablet(
                  image: 'assets/image/googleicon.png',
                  label: 'Google',
                  onTap: handleGoogleSignIn,
                  bgColor: Colors.white,
                  textColor: charcoal,
                  borderColor: kBodyTextColor.withValues(alpha: 0.15),
                  buttonWidth: socialButtonWidth,
                ),
                SizedBox(width: _clampScale(12 * scale, 8, 16)),
                
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthCardTablet extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final String bottomText;
  final String toggleText;
  final VoidCallback onToggle;
  final Color accentColor;
  final double cardWidth;
  final double cardPadding;
  final double titleFontSize;
  final double subtitleFontSize;
  final double buttonHeight;

  const _AuthCardTablet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.bottomText,
    required this.toggleText,
    required this.onToggle,
    required this.accentColor,
    required this.cardWidth,
    required this.cardPadding,
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.buttonHeight,
  });

  @override
  ConsumerState<_AuthCardTablet> createState() => _AuthCardTabletState();
}

class _AuthCardTabletState extends ConsumerState<_AuthCardTablet> {
  // Use the global providers instead of creating local controllers
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController nameController;
  late final TextEditingController confirmpasswordController;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    // Obtain controllers from the Providers defined on the parent LoginScreenTablet class.
    // ref is available because this is ConsumerState.
    emailController = ref.read(emailControllerProvider);
    passwordController = ref.read(passwordControllerProvider);
    nameController = ref.read(nameControllerProvider);
    confirmpasswordController = ref.read(confirmPasswordControllerProvider);
  }

  @override
  void dispose() {
    // IMPORTANT: Do NOT dispose controllers here because providers manage disposal (autoDispose).
    // Only call super.dispose() so widget lifecycle continues normally.
    super.dispose();
  }

  // --- Validators (same rules as desktop) ---
  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your full name';
    if (v.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your email address';
    final email = v.trim();
    final emailReg = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@"
      r"[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?"
      r"(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
    );
    if (!emailReg.hasMatch(email)) return 'Please enter a valid email address';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Please enter a password';
    final strongReg = RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$&*~\-\_+=\[\]{};:"\\|,.<>\/?]).{8,}$',
    );
    if (!strongReg.hasMatch(v)) {
      return 'Password must be at least 8 characters and include\nan uppercase letter, lowercase letter, number and symbol';
    }
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
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
        size: 22,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: kSecondaryColor.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: kSecondaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: kSecondaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: kPrimaryColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  void showTopSnackBar(
    OverlayState? overlay,
    Widget content, {
    Duration animationDuration = const Duration(milliseconds: 400),
    Duration displayDuration = const Duration(seconds: 3),
  }) {
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Material(color: Colors.transparent, child: content),
        );
      },
    );

    overlay.insert(entry);

    Future.delayed(displayDuration, () {
      try {
        entry.remove();
      } catch (_) {}
    });
  }

  Future<void> _onSubmit(BuildContext context) async {
    final isSignUp = widget.title.toLowerCase().contains('journey');

    // Validate form
    if (!formKey.currentState!.validate()) {
      if (!mounted) return;
      showTopSnackBar(
        Overlay.of(context),
        Material(
          color: Colors.transparent,
          child: AwesomeSnackbarContent(
            title: 'Validation error',
            message: 'Please check your input fields.',
            contentType: ContentType.failure,
          ),
        ),
        animationDuration: const Duration(milliseconds: 800),
        displayDuration: const Duration(seconds: 3),
      );
      return;
    }

    // Start loading
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      if (isSignUp) {
        // --- SIGN UP flow (unchanged) ---
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
          // Clear sensitive fields
          passwordController.clear();
          confirmpasswordController.clear();

          if (context.mounted) {
            showTopSnackBar(
              Overlay.of(context),
              Material(
                color: Colors.transparent,
                child: AwesomeSnackbarContent(
                  title: 'Success!',
                  message:
                      'You Successfully Registered — please log in to proceed',
                  contentType: ContentType.success,
                ),
              ),
              animationDuration: const Duration(milliseconds: 800),
              displayDuration: const Duration(seconds: 6),
            );
          }

          // show login UI (same screen)
          ref.read(isSignUpProvider.notifier).state = false;
        } else {
          if (context.mounted) {
            showTopSnackBar(
              Overlay.of(context),
              Material(
                color: Colors.transparent,
                child: AwesomeSnackbarContent(
                  title: 'Registration failed',
                  message: result['message']?.toString() ?? 'Please try again',
                  contentType: ContentType.failure,
                ),
              ),
              animationDuration: const Duration(milliseconds: 800),
              displayDuration: const Duration(seconds: 4),
            );
          }
        }
      } else {
        // --- LOGIN flow ---
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
            showTopSnackBar(
              Overlay.of(context),
              Material(
                color: Colors.transparent,
                child: AwesomeSnackbarContent(
                  title: 'Welcome!',
                  message:
                      loginResult['message']?.toString() ?? 'Login successful',
                  contentType: ContentType.success,
                ),
              ),
              animationDuration: const Duration(milliseconds: 500),
              displayDuration: const Duration(seconds: 2),
            );
          }

          if (loginResult['success'] == true) {
            // persist token if backend returned one
            final token = loginResult['token'] as String?;
            if (token != null && token.isNotEmpty) {
              try {
                await saveToken(token);
              } catch (e) {
                debugPrint('saveToken failed: $e');
              }
            } else {
              debugPrint('Login succeeded but no token was returned');
            }

            // show success snackbar (your existing code)
            if (context.mounted) {
              showTopSnackBar(
                Overlay.of(context),
                Material(
                  color: Colors.transparent,
                  child: AwesomeSnackbarContent(
                    title: 'Welcome!',
                    message:
                        loginResult['message']?.toString() ??
                        'Login successful',
                    contentType: ContentType.success,
                  ),
                ),
                animationDuration: const Duration(milliseconds: 500),
                displayDuration: const Duration(seconds: 2),
              );
            }

            // --- NEW: check if profile already exists, then route accordingly ---
            try {
              final api = ProfileApi();
              UserinformationModel? existingProfile;

              // Only call fetchProfile if token exists
              if (token != null && token.isNotEmpty) {
                existingProfile = await api.fetchProfile(token);
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
              // If profile check fails for any reason, fall back to setup page:
              if (context.mounted) {
                context.go('/setup');
              }
            }
          }
        } else {
          if (context.mounted) {
            showTopSnackBar(
              Overlay.of(context),
              Material(
                color: Colors.transparent,
                child: AwesomeSnackbarContent(
                  title: 'Login failed',
                  message:
                      loginResult['message']?.toString() ??
                      'Invalid credentials',
                  contentType: ContentType.failure,
                ),
              ),
              animationDuration: const Duration(milliseconds: 800),
              displayDuration: const Duration(seconds: 4),
            );
          }
        }
      }
    } on SocketException {
      if (context.mounted) {
        setState(() => isLoading = false);
        showTopSnackBar(
          Overlay.of(context),
          Material(
            color: Colors.transparent,
            child: AwesomeSnackbarContent(
              title: 'Network error',
              message: 'Cannot reach the server. Please check your connection.',
              contentType: ContentType.failure,
            ),
          ),
          animationDuration: const Duration(milliseconds: 800),
          displayDuration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      if (context.mounted) {
        setState(() => isLoading = false);
        showTopSnackBar(
          Overlay.of(context),
          Material(
            color: Colors.transparent,
            child: AwesomeSnackbarContent(
              title: 'Error',
              message: 'Unexpected error occurred: $e',
              contentType: ContentType.failure,
            ),
          ),
          animationDuration: const Duration(milliseconds: 800),
          displayDuration: const Duration(seconds: 4),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Riverpod-observed obscure flags
    final obscurePassword = ref.watch(obscurePasswordProvider);
    final obscureConfirm = ref.watch(obscureConfirmProvider);

    return Form(
      key: formKey,
      child: Container(
        width: widget.cardWidth,
        padding: EdgeInsets.all(widget.cardPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withValues(alpha: 0.08),
              blurRadius: 25,
              offset: const Offset(0, 12),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: kSecondaryColor.withValues(alpha: 0.06),
              blurRadius: 50,
              offset: const Offset(0, 25),
              spreadRadius: -8,
            ),
          ],
          border: Border.all(
            color: kSecondaryColor.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: widget.titleFontSize,
                fontWeight: FontWeight.w700,
                color: widget.accentColor,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: TextStyle(
                fontSize: widget.subtitleFontSize,
                color: kBodyTextColor.withValues(alpha: 0.85),
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),

            // Name (signup only)
            if (widget.title.toLowerCase().contains('journey'))
              Column(
                children: [
                  TextFormField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      'Full name',
                      Icons.person_outline_rounded,
                    ),
                    validator: _validateName,
                  ),
                  const SizedBox(height: 14),
                ],
              ),

            // Email
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                'Email address',
                Icons.email_outlined,
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 14),

            // Password w/ eye
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              textInputAction: widget.title.toLowerCase().contains('journey')
                  ? TextInputAction.next
                  : TextInputAction.done,
              decoration: _inputDecoration(
                'Password',
                Icons.lock_outline_rounded,
                suffix: IconButton(
                  splashRadius: 20,
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                    color: kBodyTextColor.withValues(alpha: 0.6),
                  ),
                  onPressed: () {
                    ref.read(obscurePasswordProvider.notifier).state =
                        !obscurePassword;
                  },
                ),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 14),

            // Confirm Password (signup only) w/ eye
            if (widget.title.toLowerCase().contains('journey'))
              Column(
                children: [
                  TextFormField(
                    controller: confirmpasswordController,
                    obscureText: obscureConfirm,
                    textInputAction: TextInputAction.done,
                    decoration: _inputDecoration(
                      'Confirm Password',
                      Icons.security,
                      suffix: IconButton(
                        splashRadius: 20,
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20,
                          color: kBodyTextColor.withValues(alpha: 0.6),
                        ),
                        onPressed: () {
                          ref.read(obscureConfirmProvider.notifier).state =
                              !obscureConfirm;
                        },
                      ),
                    ),
                    validator: _validateConfirmPassword,
                  ),
                  const SizedBox(height: 14),
                ],
              ),

            const SizedBox(height: 22),

            // Submit button: set flag to show validation, then validate
            SizedBox(
              width: double.infinity,
              height: widget.buttonHeight,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _onSubmit(context),
                style:
                    ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.all(
                        Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                child: isLoading
                    ? const CircularProgressIndicator.adaptive()
                    : Text(
                        widget.buttonText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: widget.onToggle,
              child: RichText(
                text: TextSpan(
                  text: widget.bottomText,
                  style: TextStyle(
                    color: kBodyTextColor.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  children: [
                    TextSpan(
                      text: widget.toggleText,
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
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

class _SocialIconButtonTablet extends StatelessWidget {
  final String image;
  final String label;
  final VoidCallback onTap;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;
  final double buttonWidth;

  const _SocialIconButtonTablet({
    required this.image,
    required this.label,
    required this.onTap,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
    required this.buttonWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: buttonWidth,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 21),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                child: Image.asset(
                  image,
                  fit: BoxFit.contain,
                  height: 32,
                  width: 25,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
