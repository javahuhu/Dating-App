import 'dart:io';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:dating_app/Application/UseCases/login_usecases.dart';
import 'package:dating_app/Application/UseCases/user_register_usecases.dart';
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
import 'package:dating_app/Core/Auth/auth_storage.dart'; // <-- ADDED: token persistence helpers
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

double rClamp(double screenWidth, double min, double base, double max) {
  const designWidth = 2560.0;
  if (screenWidth <= 0) return base;
  final scaled = base * (screenWidth / designWidth);
  return scaled.clamp(min, max);
}

class LoginScreenDesktop extends HookConsumerWidget {
  const LoginScreenDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignUp = ref.watch(isSignUpProvider);
    final screenSize = MediaQuery.of(context).size;
    final w = screenSize.width;

    final titleFontSize = rClamp(w, 120, 220, 320);
    final logoIconSize = rClamp(w, 48, 96, 160);
    final logoPadding = rClamp(w, 16, 36, 64);
    final brandSpacing = rClamp(w, 12, 36, 80);
    final cardWidth = rClamp(w, 320, 700, 1100);
    final cardPadding = rClamp(w, 20, 40, 80);
    final topLeftTitleX = rClamp(w, 20, 180, 560);
    final topLeftTitleY = rClamp(w, 16, 60, 120);
    final socialTop = rClamp(w, 200, 420, 700);
    final socialLeft = rClamp(w, 80, 180, 560);
    final flyHeight = rClamp(w, 300, 810, 1000);
    final flyWidth = rClamp(w, 250, 750, 1000);
    final subtitleFont = rClamp(w, 12, 20, 32);
    final bodyFont = rClamp(w, 16, 28, 44);
    final buttonHeight = rClamp(w, 40, 72, 120);

    final socialButtonWidth = rClamp(w, 130, 240, 420);
    final socialBtnVerticalPadding = rClamp(w, 10, 20, 36);

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
                    vertical: rClamp(w, 20, 80, 200),
                    horizontal: rClamp(w, 12, 80, 260),
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
                                  blurRadius: rClamp(w, 12, 36, 120),
                                  offset: Offset(0, rClamp(w, 6, 18, 60)),
                                  spreadRadius: rClamp(w, 1, 4, 12),
                                ),
                                BoxShadow(
                                  color: kSecondaryColor.withValues(alpha: 0.2),
                                  blurRadius: rClamp(w, 20, 60, 160),
                                  offset: Offset(0, rClamp(w, 10, 30, 80)),
                                  spreadRadius: rClamp(w, 2, 6, 20),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(logoPadding),
                            child: Icon(
                              Icons.favorite_rounded,
                              size: logoIconSize,
                              color: Colors.white,
                            ),
                          ),

                          SizedBox(height: brandSpacing),
                          Text(
                            'Where hearts align by fate',
                            style: TextStyle(
                              fontSize: subtitleFont,
                              fontWeight: FontWeight.w400,
                              color: subtextViolet.withValues(alpha: 0.8),
                              letterSpacing: 0.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: rClamp(w, 20, 60, 140)),

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
                            ? _AuthCard(
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
                                bodyFontSize: bodyFont,
                                buttonHeight: buttonHeight,
                              )
                            : _AuthCard(
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
                                bodyFontSize: bodyFont,
                                buttonHeight: buttonHeight,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // floating illustration — sizes responsive
          Positioned(
            right: 0,
            bottom: rClamp(w, 20, 80, 300),
            child: ClipRRect(
              child: Image.asset(
                'assets/image/fly.png',
                fit: BoxFit.cover,
                height: flyHeight,
                width: flyWidth,
              ),
            ),
          ),

          // Big title on top-left — responsive size and offset
          Positioned(
            top: topLeftTitleY,
            left: topLeftTitleX,
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
                  fontSize: titleFontSize,
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

          // "or continue with" — positioned relative and responsive
          Positioned(
            top: rClamp(w, 160, 320, 420),
            left: rClamp(w, 28, 180, 560),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or continue with',
                style: TextStyle(
                  color: kBodyTextColor.withValues(alpha: 0.7),
                  fontSize: bodyFont * 0.9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Social buttons — positioned responsively
          Positioned(
            top: socialTop,
            left: socialLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialIconButton(
                  image: 'assets/image/googleicon.png',
                  label: 'Google',
                  onTap: () async {
                    final social = SocialAuth();
                    try {
                      final token = await social.signInWithProvider('google');
                      if (token != null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Signed in with Google'),
                            ),
                          );
                          context.go('/setup');
                        }
                      } else {
                        // popup opened (or fallback nav). show a message telling user to complete sign-in.
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Opening Google sign-in... complete the flow in the popup',
                              ),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sign-in error: $e')),
                        );
                      }
                    }
                  },

                  bgColor: Colors.white,
                  textColor: charcoal,
                  borderColor: kBodyTextColor.withValues(alpha: 0.15),
                  width: socialButtonWidth,
                  verticalPadding: socialBtnVerticalPadding,
                ),
                SizedBox(width: rClamp(w, 8, 24, 48)),
                _SocialIconButton(
                  image: 'assets/image/facebookicon.png',
                  label: 'Facebook',
                  onTap: () {},

                  bgColor: Colors.white,
                  textColor: charcoal,
                  borderColor: kBodyTextColor.withValues(alpha: 0.15),
                  width: socialButtonWidth,
                  verticalPadding: socialBtnVerticalPadding,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthCard extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final String bottomText;
  final String toggleText;
  final VoidCallback onToggle;
  final Color accentColor;

  // responsive props injected
  final double cardWidth;
  final double cardPadding;
  final double bodyFontSize;
  final double buttonHeight;

  const _AuthCard({
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
    required this.bodyFontSize,
    required this.buttonHeight,
  });

  @override
  ConsumerState<_AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends ConsumerState<_AuthCard> {
  // now we use the global providers instead of local controllers
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController nameController;
  late final TextEditingController confirmpasswordController;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    // Fetch controllers from Riverpod providers. Using ref.read to get the same instance.
    // These controllers are created by the providers defined above.
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

  // --- Validators' helpers (unchanged) ---
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
          // <-- NEW: persist token if backend returned one
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
                  (existingProfile.profilePictureUrl?.trim().isNotEmpty ==
                      true);

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
    final screenW = MediaQuery.of(context).size.width;

    // Riverpod state for obscure toggles
    final obscurePassword = ref.watch(obscurePasswordProvider);
    final obscureConfirm = ref.watch(obscureConfirmProvider);

    return Form(
      key: formKey,
      child: Container(
        width: widget.cardWidth,
        padding: EdgeInsets.all(widget.cardPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: kSecondaryColor.withValues(alpha: 0.06),
              blurRadius: 60,
              offset: const Offset(0, 30),
              spreadRadius: -10,
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
                fontSize: widget.bodyFontSize + 12,
                fontWeight: FontWeight.w700,
                color: widget.accentColor,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: rClamp(screenW, 8, 16, 40)),
            Text(
              widget.subtitle,
              style: TextStyle(
                fontSize: widget.bodyFontSize - 8,
                color: kBodyTextColor.withValues(alpha: 0.85),
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: rClamp(screenW, 16, 36, 80)),

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
                  SizedBox(height: rClamp(screenW, 8, 20, 40)),
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
            SizedBox(height: rClamp(screenW, 8, 20, 40)),

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
            SizedBox(height: rClamp(screenW, 8, 20, 40)),

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
                  SizedBox(height: rClamp(screenW, 8, 20, 40)),
                ],
              ),

            SizedBox(height: rClamp(screenW, 14, 32, 60)),

            // Submit
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
                        style: TextStyle(
                          fontSize: (widget.bodyFontSize - 4).clamp(12.0, 36.0),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
            SizedBox(height: rClamp(screenW, 10, 24, 48)),

            GestureDetector(
              onTap: widget.onToggle,
              child: RichText(
                text: TextSpan(
                  text: widget.bottomText,
                  style: TextStyle(
                    color: kBodyTextColor.withValues(alpha: 0.8),
                    fontSize: (widget.bodyFontSize - 8).clamp(12.0, 28.0),
                    fontWeight: FontWeight.w400,
                  ),
                  children: [
                    TextSpan(
                      text: widget.toggleText,
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                        fontSize: (widget.bodyFontSize - 8).clamp(12.0, 28.0),
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

class _SocialIconButton extends StatelessWidget {
  final String image;
  final String label;
  final VoidCallback onTap;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;

  // responsive
  final double width;
  final double verticalPadding;

  const _SocialIconButton({
    required this.image,
    required this.label,
    required this.onTap,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
    this.width = 150,
    this.verticalPadding = 14,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: width,
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: 21,
          ),
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
                  height: rClamp(screenW, 20, 48, 96),
                  width: rClamp(screenW, 16, 36, 72),
                ),
              ),
              SizedBox(width: rClamp(screenW, 8, 18, 32)),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  fontSize: rClamp(screenW, 12, 20, 28),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
