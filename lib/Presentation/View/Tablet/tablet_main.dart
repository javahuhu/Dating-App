import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dating_app/Data/API/profile_api.dart';
import 'package:dating_app/Data/API/social_api.dart';
import 'package:dating_app/Data/Models/userinformation_model.dart';
import 'package:dating_app/Presentation/Animation/animation_carousel.dart';
import 'package:dating_app/Presentation/View/Desktop/snake_border.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dating_app/Core/Theme/colors.dart';
import 'package:flutter_animate_on_scroll/flutter_animate_on_scroll.dart';
import 'package:google_fonts/google_fonts.dart';

class TabletMainScreen extends HookConsumerWidget {
  const TabletMainScreen({super.key});

  double _clampScale(double value, double min, double max) {
    return value.clamp(min, max);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Size screen = MediaQuery.of(context).size;
    final double screenWidth = screen.width;

    // Tablet base width (smaller than desktop) to get tablet-friendly scaling
    final double baseWidth = 1024;
    final double scale = screenWidth / baseWidth;

    // general sizes (tablet optimized)
    final double titleFontSize = _clampScale(46 * scale, 20, 56);
    final double subtitleFontSize = _clampScale(22 * scale, 14, 34);
    final double heroWidth = _clampScale(screenWidth * 0.6, 260, 640);
    final double heroImageWidth = _clampScale(screenWidth * 0.35, 200, 420);
    final double horizontalPadding = _clampScale(screenWidth * 0.06, 12, 80);
    final double buttonPaddingH = _clampScale(18 * scale, 10, 28);
    final double buttonPaddingV = _clampScale(14 * scale, 10, 20);
    final double borderRadius = _clampScale(20 * scale, 8, 28);

    // treat very narrow tablets / phones differently
    final bool toMobile = screenWidth < 771;
    final bool portrait = screen.height > screen.width;

    
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
          child: Column(
            children: [
              // NAV
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: _clampScale(18 * scale, 12, 28),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Kismet',
                          style: GoogleFonts.poppins(
                            fontSize: _clampScale(36 * scale, 16, 48),
                            fontWeight: FontWeight.bold,
                            color: kTitleColor,
                          ),
                        ),
                        SizedBox(width: _clampScale(8 * scale, 6, 12)),
                        ClipRRect(
                          child: Image.asset(
                            'assets/Icons/logostar.png',
                            fit: BoxFit.cover,
                            height: _clampScale(44 * scale, 20, 64),
                            width: _clampScale(44 * scale, 20, 64),
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            context.go('/login');
                          },
                          style: ElevatedButton.styleFrom(
                            side: BorderSide(
                              color: charcoal.withValues(alpha: 0.80),
                              width: 1.6,
                            ),
                            overlayColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                            ),
                            textStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: buttonPaddingH,
                              vertical: buttonPaddingV,
                            ),
                          ),

                          child: Text(
                            'Log In',
                            style: GoogleFonts.poppins(
                              fontSize: _clampScale(14 * scale, 11, 18),
                            ),
                          ),
                        ),
                        SizedBox(width: _clampScale(12 * scale, 8, 18)),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            side: BorderSide(
                              color: charcoal.withValues(alpha: 0.80),
                              width: 1.6,
                            ),
                            overlayColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: kBackgroundColor,
                            backgroundColor: kTitleColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                            ),
                            textStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: buttonPaddingH,
                              vertical: buttonPaddingV,
                            ),
                          ),
                          child: Text(
                            'Sign Up',
                            style: GoogleFonts.poppins(
                              fontSize: _clampScale(14 * scale, 11, 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: _clampScale(28 * scale, 12, 40)),

              // HERO: condensed for narrow tablets, row for wide tablets
              toMobile
                  ? toSmallScreenHeader(
                      context,
                      ref,
                      titleFontSize,
                      subtitleFontSize,
                      buttonPaddingH,
                      buttonPaddingV,
                      _clampScale,
                      screenWidth,
                    )
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1024),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: Flex(
                            direction: portrait
                                ? Axis.vertical
                                : Axis.horizontal,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: portrait ? 0 : 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FadeInLeft(
                                      config: BaseAnimationConfig(
                                        repeat: false,
                                        duration: 700.milliseconds,
                                        child: SizedBox(
                                          width: heroWidth,
                                          child: Text(
                                            'Here’s to dating with confidence',
                                            style: GoogleFonts.poppins(
                                              fontSize: titleFontSize,
                                              fontWeight: FontWeight.bold,
                                              color: charcoal.withValues(
                                                alpha: 0.9,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    FadeInLeft(
                                      config: BaseAnimationConfig(
                                        repeat: false,
                                        delay: 0.6.seconds,
                                        duration: 600.milliseconds,
                                        child: SizedBox(
                                          width: heroWidth,
                                          child: Text(
                                            '— and a spark that’s real.',
                                            style: GoogleFonts.poppins(
                                              fontSize: subtitleFontSize,
                                              fontWeight: FontWeight.w400,
                                              color: charcoal.withValues(
                                                alpha: 0.85,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: _clampScale(18 * scale, 12, 32),
                                    ),
                                    FadeInLeft(
                                      config: BaseAnimationConfig(
                                        repeat: true,
                                        delay: 1.seconds,
                                        duration: 900.milliseconds,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            OutlinedButton(
                                              onPressed: handleGoogleSignIn,
                                              style: ButtonStyle(
                                                side:
                                                    WidgetStateProperty.resolveWith<
                                                      BorderSide
                                                    >((states) {
                                                      if (states.contains(
                                                        WidgetState.hovered,
                                                      )) {
                                                        return BorderSide(
                                                          color: Colors.red,
                                                          width: 1.6,
                                                        );
                                                      }
                                                      return BorderSide(
                                                        color: charcoal
                                                            .withValues(
                                                              alpha: 0.80,
                                                            ),
                                                        width: 1.6,
                                                      );
                                                    }),
                                                backgroundColor:
                                                    WidgetStateProperty.all(
                                                      Colors.transparent,
                                                    ),
                                                shape: WidgetStateProperty.all(
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          24,
                                                        ),
                                                  ),
                                                ),
                                                padding:
                                                    WidgetStateProperty.all(
                                                      EdgeInsets.symmetric(
                                                        horizontal:
                                                            buttonPaddingH,
                                                        vertical:
                                                            buttonPaddingV,
                                                      ),
                                                    ),
                                              ),
                                              child: Text(
                                                'Continue With Google',
                                                style: GoogleFonts.poppins(
                                                  fontSize: _clampScale(
                                                    14 * scale,
                                                    11,
                                                    18,
                                                  ),
                                                  color: kTitleColor,
                                                ),
                                              ),
                                            ),
                                           
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (!portrait)
                                SizedBox(width: _clampScale(18 * scale, 8, 28)),

                              // hero image (right)
                              SizedBox(
                                width: portrait
                                    ? double.infinity
                                    : heroImageWidth,
                                child: FadeInRight(
                                  config: BaseAnimationConfig(
                                    repeat: false,
                                    duration: 700.milliseconds,

                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        top: portrait ? 18 : 0,
                                      ),
                                      child: Image.asset(
                                        'assets/image/twoheart.png',
                                        fit: BoxFit.contain,
                                        height: _clampScale(
                                          portrait ? 260 * scale : 340 * scale,
                                          160,
                                          520,
                                        ),
                                        width: heroImageWidth,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

              SizedBox(height: _clampScale(40 * scale, 16, 80)),

              // FEATURES (snake) - reuse and tune for tablet
              _showFeaturesTablet(
                context,
                ref,
                _clampScale,
                horizontalPadding,
                scale,
                screenWidth,
              ),

              // BELOW-FOLD SECTIONS (How it works, testimonials, safety, map, app preview, CTA, footer)
              SizedBox(height: _clampScale(28 * scale, 12, 40)),
              _howItWorksSection(
                context,
                _clampScale,
                scale,
                horizontalPadding,
                isTablet: true,
              ),
              SizedBox(height: _clampScale(20 * scale, 10, 32)),
              _testimonialsSection(context, _clampScale, scale, isTablet: true),
              SizedBox(height: _clampScale(20 * scale, 10, 32)),
              _safetyTrustSection(context, _clampScale, scale, isTablet: true),
              SizedBox(height: _clampScale(20 * scale, 10, 32)),
              _nearbyMapPreview(context, _clampScale, scale, isTablet: true),
              SizedBox(height: _clampScale(20 * scale, 10, 32)),
              _ctaBanner(context, _clampScale, scale),
              SizedBox(height: _clampScale(20 * scale, 12, 36)),
              _footer(context, _clampScale, scale),
              SizedBox(height: _clampScale(36 * scale, 24, 60)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- FEATURES (tablet tuned) ----------
Widget _showFeaturesTablet(
  BuildContext context,
  WidgetRef ref,
  clampScale,
  double horizontalPadding,
  double scale,
  double screenWidth,
) {
  // tuned tablet sizes
  final double snakeHeight = clampScale(460 * scale, 380, 680);
  final double leftImageHeight = clampScale(200 * scale, 140, 360);
  final double leftImageWidth = clampScale(screenWidth * 0.30, 120, 360);
  final double laptopLeftPadding = clampScale(18 * scale, 8, 36);
  final double headlineFont = clampScale(32 * scale, 18, 44);
  final double subtitleFont = clampScale(16 * scale, 12, 20);
  final double gapBetween = clampScale(28 * scale, 10, 60);

  // features list (same as desktop)
  final List<Map<String, dynamic>> features = [
    {"img": 'assets/image/message.png', "details": 'Chat'},
    {"img": 'assets/image/secure.png', "details": 'Secure'},
    {"img": 'assets/image/dart.png', "details": 'Smart Matching'},
  ];

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: clampScale(28 * scale, 12, 56)),
    child: SnakeBorderWithHeart(
      height: snakeHeight,
      color: kPrimaryColor,
      strokeWidth: clampScale(48 * scale, 2, 60),
      snakeLength: clampScale(420 * scale, 80, 1500),
      speed: 0.22,
      borderRadius: BorderRadius.circular(clampScale(18 * scale, 8, 40)),
      tailSegments: 2,
      heartSize: clampScale(64 * scale, 12, 100),
      heartColor: Colors.pinkAccent,
      child: GlassmorphicContainer(
        height: snakeHeight,
        width: double.infinity,
        blur: 12,
        border: 1.8,
        borderRadius: clampScale(18 * scale, 8, 40),
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kSecondaryColor.withValues(alpha: 0.28),
            kSecondaryColor.withValues(alpha: 0.22),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.35),
            Colors.white.withValues(alpha: 0.18),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: clampScale(18 * scale, 12, 36),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Row(
            children: [
              // left image
              SizedBox(
                width: leftImageWidth + laptopLeftPadding,
                child: Stack(
                  children: [
                    SizedBox(width: laptopLeftPadding),
                    Align(
                      alignment: Alignment.center,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          clampScale(12 * scale, 6, 20),
                        ),
                        child: Image.asset(
                          'assets/image/responsivelaptop.png',
                          fit: BoxFit.contain,
                          height: leftImageHeight,
                          width: leftImageWidth,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: gapBetween),

              // right content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: clampScale(8 * scale, 8, 20)),
                    SlideInDown(
                      config: BaseAnimationConfig(
                        repeat: false,
                        duration: 500.milliseconds,

                        child: Text(
                          'Find Love That Feels Real.',
                          style: GoogleFonts.poppins(
                            fontSize: headlineFont,
                            color: headingViolet,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: clampScale(8 * scale, 6, 16)),
                    SlideInDown(
                      config: BaseAnimationConfig(
                        repeat: false,
                        duration: 700.milliseconds,
                        delay: 300.milliseconds,

                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Text(
                            'Discover genuine people ready for meaningful connections. Chat, meet, and fall in love — anytime, anywhere.',
                            style: GoogleFonts.poppins(
                              fontSize: subtitleFont,
                              color: subtextViolet,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: clampScale(28 * scale, 12, 48)),
                    // features row/wrap
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double available = constraints.maxWidth;
                        final double spacing = clampScale(20 * scale, 8, 34);
                        final double minCard = clampScale(
                          120 * scale,
                          110,
                          160,
                        );
                        final int childCount = features.length;
                        int perRow =
                            ((available + spacing) ~/ (minCard + spacing))
                                .toInt();
                        if (perRow < 1) perRow = 1;
                        if (perRow > childCount) perRow = childCount;
                        final double totalSpacing = spacing * (perRow + 1);
                        double cardWidth = (available - totalSpacing) / perRow;
                        cardWidth =
                            cardWidth.clamp(
                                  minCard,
                                  clampScale(240 * scale, 140, 320),
                                )
                                as double;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: clampScale(18 * scale, 12, 28),
                          alignment: WrapAlignment.start,
                          children: features.asMap().entries.map((entry) {
                            final i = entry.key;
                            final item = entry.value;
                            return Container(
                              width: cardWidth,
                              height: clampScale(150 * scale, 120, 180),
                              padding: EdgeInsets.all(
                                clampScale(10 * scale, 8, 12),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  clampScale(12 * scale, 8, 18),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  SizedBox(
                                    height: clampScale(70 * scale, 50, 100),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Positioned(
                                          top: -clampScale(40 * scale, 24, 60),
                                          left: 0,
                                          right: 0,
                                          child: Center(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    clampScale(
                                                      12 * scale,
                                                      8,
                                                      18,
                                                    ),
                                                  ),
                                              child: FadeInUp(
                                                config: BaseAnimationConfig(
                                                  repeat: false,
                                                  delay: (i * 260).milliseconds,
                                                  duration: 600.milliseconds,

                                                  child: Image.asset(
                                                    item['img'],
                                                    height: clampScale(
                                                      72 * scale,
                                                      56,
                                                      120,
                                                    ),
                                                    width: clampScale(
                                                      72 * scale,
                                                      56,
                                                      120,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: clampScale(14 * scale, 10, 18),
                                  ),
                                  Text(
                                    item['details'],
                                    style: GoogleFonts.poppins(
                                      fontSize: clampScale(14 * scale, 12, 18),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.pinkAccent,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ---------------------- Below fold shared sections (tablet tuned) ----------------------

Widget _howItWorksSection(
  BuildContext context,
  double Function(double, double, double) clampScale,
  double scale,
  double horizontalPadding, {
  bool isTablet = false,
}) {
  final double heading = clampScale(22 * scale, 16, 28);
  final double cardW = clampScale(
    isTablet ? 260 * scale : 280 * scale,
    220,
    420,
  );
  final double cardH = clampScale(140 * scale, 120, 200);
  final double iconSize = clampScale(36 * scale, 24, 48);

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How Kismet Works',
          style: GoogleFonts.poppins(
            fontSize: heading,
            fontWeight: FontWeight.bold,
            color: charcoal.withValues(alpha: 0.95),
          ),
        ),
        SizedBox(height: clampScale(12 * scale, 8, 20)),
        Wrap(
          spacing: clampScale(16 * scale, 8, 28),
          runSpacing: clampScale(12 * scale, 8, 20),
          children: [
            _featureStepCard(
              title: 'Create your profile',
              subtitle: 'Add photos, interests & preferences.',
              icon: Icons.person_outline,
              iconSize: iconSize,
              width: cardW,
              height: cardH,
              clampScale: clampScale,
              scale: scale,
            ),
            _featureStepCard(
              title: 'Find matches',
              subtitle: 'Smart suggestions you\'ll like.',
              icon: Icons.favorite_border,
              iconSize: iconSize,
              width: cardW,
              height: cardH,
              clampScale: clampScale,
              scale: scale,
            ),
            _featureStepCard(
              title: 'Start chatting',
              subtitle: 'Meet and connect safely.',
              icon: Icons.chat_bubble_outline,
              iconSize: iconSize,
              width: cardW,
              height: cardH,
              clampScale: clampScale,
              scale: scale,
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _featureStepCard({
  required String title,
  required String subtitle,
  required IconData icon,
  required double iconSize,
  required double width,
  required double height,
  required double Function(double, double, double) clampScale,
  required double scale,
}) {
  return SizedBox(
    width: width,
    child: FadeInUp(
      config: BaseAnimationConfig(
        repeat: false,
        duration: 400.milliseconds,
        child: Container(
          height: height,
          padding: EdgeInsets.all(clampScale(12 * scale, 8, 18)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(clampScale(12 * scale, 8, 18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: iconSize + 12,
                width: iconSize + 12,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: iconSize, color: headingViolet),
              ),
              SizedBox(width: clampScale(12 * scale, 8, 18)),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: clampScale(14 * scale, 12, 18),
                        fontWeight: FontWeight.w600,
                        color: charcoal.withValues(alpha: 0.9),
                      ),
                    ),
                    SizedBox(height: clampScale(6 * scale, 4, 10)),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: clampScale(12 * scale, 11, 14),
                        color: subtextViolet,
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
  );
}

/// Updated _testimonialsSection for tablet: returns the tablet carousel widget
Widget _testimonialsSection(
  BuildContext context,
  double Function(double, double, double) clampScale,
  double scale, {
  bool isTablet = true,
}) {
  final testimonials = [
    {
      'quote': 'We met on Kismet and got engaged after 6 months!',
      'name': 'Maria & Paolo',
      'avatar': 'assets/image/couple1.jpg',
    },
    {
      'quote': 'Finally an app that feels genuine.',
      'name': 'Rina, 27',
      'avatar': 'assets/image/couple3.jpg',
    },
    {
      'quote': 'Smooth, safe, and real connections.',
      'name': 'Jon, 31',
      'avatar': 'assets/image/coupl2.jpg',
    },

    {
      'quote': 'Finally an app that feels genuine.',
      'name': 'Rina, 27',
      'avatar': 'assets/image/couple3.jpg',
    },
    {
      'quote': 'Smooth, safe, and real connections.',
      'name': 'Jon, 31',
      'avatar': 'assets/image/coupl2.jpg',
    },

    {
      'quote': 'Smooth, safe, and real connections.',
      'name': 'Jon, 31',
      'avatar': 'assets/image/coupl2.jpg',
    },
  ];
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: clampScale(22 * scale, 12, 60),
          ),
          child: Text(
            'Real Stories',
            style: GoogleFonts.poppins(
              fontSize: clampScale(22 * scale, 16, 28),
              fontWeight: FontWeight.bold,
              color: charcoal.withValues(alpha: 0.95),
            ),
          ),
        ),
        SizedBox(height: clampScale(12 * scale, 8, 20)),
        // Insert tablet carousel
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: clampScale(8 * scale, 8, 16),
          ),
          child: RepaintBoundary(
            child: TabletTestimonialsCarousel(
              items: testimonials,
              clampScale: clampScale,
              scale: scale,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _safetyTrustSection(
  BuildContext context,
  double Function(double, double, double) clampScale,
  double scale, {
  bool isTablet = false,
}) {
  final double iconSize = clampScale(32 * scale, 22, 44);

  final items = [
    {
      'icon': Icons.verified,
      'title': 'Verified Profiles',
      'subtitle': 'Identity checks for peace of mind.',
    },
    {
      'icon': Icons.block,
      'title': 'No Fake Accounts',
      'subtitle': 'Active moderation & reporting.',
    },
    {
      'icon': Icons.lock,
      'title': 'Encrypted Chats',
      'subtitle': 'Your conversations stay private.',
    },
  ];

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: clampScale(22 * scale, 12, 60)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Safety & Trust',
          style: GoogleFonts.poppins(
            fontSize: clampScale(22 * scale, 16, 28),
            fontWeight: FontWeight.bold,
            color: charcoal.withValues(alpha: 0.95),
          ),
        ),
        SizedBox(height: clampScale(12 * scale, 8, 20)),
        Row(
          children: items.map((it) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: clampScale(6 * scale, 6, 10),
                ),
                child: FadeInUp(
                  config: BaseAnimationConfig(
                    repeat: false,
                    duration: 400.milliseconds,

                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(
                            clampScale(10 * scale, 8, 14),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              clampScale(12 * scale, 8, 16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .02),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            it['icon'] as IconData,
                            size: iconSize,
                            color: headingViolet,
                          ),
                        ),
                        SizedBox(height: clampScale(10 * scale, 6, 12)),
                        Text(
                          it['title'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: clampScale(14 * scale, 12, 16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: clampScale(8 * scale, 6, 10)),
                        Text(
                          it['subtitle'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: clampScale(12 * scale, 11, 14),
                            color: subtextViolet,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

Widget _nearbyMapPreview(
  BuildContext context,
  double Function(double, double, double) clampScale,
  double scale, {
  bool isTablet = false,
}) {
  final double height = clampScale(180 * scale, 120, 300);

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: clampScale(22 * scale, 12, 60)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meet people near you',
          style: GoogleFonts.poppins(
            fontSize: clampScale(18 * scale, 14, 24),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: clampScale(10 * scale, 6, 16)),
        FadeInUp(
          config: BaseAnimationConfig(
            repeat: false,
            duration: 400.milliseconds,

            child: Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  clampScale(12 * scale, 8, 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                  ),
                ],
                image: DecorationImage(
                  image: AssetImage('assets/image/gmaps.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.06),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: clampScale(28 * scale, 12, 48),
                    top: clampScale(24 * scale, 12, 44),
                    child: _mapPin(clampScale(40 * scale, 26, 64)),
                  ),
                  Positioned(
                    right: clampScale(36 * scale, 18, 72),
                    bottom: clampScale(18 * scale, 10, 48),
                    child: _mapPin(clampScale(48 * scale, 30, 72)),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: clampScale(12 * scale, 8, 18),
                        ),
                        child: Container(
                          width: clampScale(200 * scale, 140, 300),
                          padding: EdgeInsets.all(
                            clampScale(10 * scale, 8, 12),
                          ),
                          decoration: BoxDecoration(
                            color: kBackgroundColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(
                              clampScale(10 * scale, 8, 14),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'See who’s around you',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: clampScale(6 * scale, 4, 10)),
                              Text(
                                'Love might be only a few miles away.',
                                style: GoogleFonts.poppins(
                                  fontSize: clampScale(12 * scale, 11, 14),
                                  color: subtextViolet,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _mapPin(double size) {
  return Container(
    height: size,
    width: size,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 6),
      ],
    ),
    child: Center(
      child: Icon(
        Icons.location_on,
        color: Colors.pinkAccent,
        size: size * 0.5,
      ),
    ),
  );
}

Widget _ctaBanner(
  BuildContext context,
  double Function(double, double, double) clampScale,
  double scale,
) {
  final double height = clampScale(100 * scale, 80, 160);
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: clampScale(22 * scale, 12, 60)),
    child: Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pinkAccent.withValues(alpha: .95),
            Colors.purpleAccent.withValues(alpha: .95),
          ],
        ),
        borderRadius: BorderRadius.circular(clampScale(14 * scale, 10, 24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 12),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite,
              color: Colors.white,
              size: clampScale(32 * scale, 20, 44),
            ),
            SizedBox(width: clampScale(10 * scale, 8, 16)),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ready to find your spark?',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: clampScale(18 * scale, 14, 22),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Join thousands discovering real connections today',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: clampScale(12 * scale, 11, 14),
                  ),
                ),
              ],
            ),
            SizedBox(width: clampScale(14 * scale, 10, 20)),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: kBackgroundColor,
                foregroundColor: kTitleColor,
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Get Started Free',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _footer(
  BuildContext context,
  double Function(double, double, double) clampScale,
  double scale,
) {
  final double small = clampScale(12 * scale, 10, 14);

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: clampScale(22 * scale, 12, 60)),
    child: Column(
      children: [
        Divider(color: Colors.black12),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '© ${DateTime.now().year} Kismet',
              style: GoogleFonts.poppins(fontSize: small, color: subtextViolet),
            ),
            Row(
              children: [
                _footerLink('About'),
                SizedBox(width: 12),
                _footerLink('Privacy'),
                SizedBox(width: 12),
                _footerLink('Support'),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _footerLink(String title) {
  return InkWell(
    onTap: () {},
    child: Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: headingViolet,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

// helper condensed header (for very small tablets / large phones)
Widget toSmallScreenHeader(
  BuildContext context,
  WidgetRef ref,
  double titleFontSize,
  double subtitleFontSize,
  double buttonPaddingH,
  double buttonPaddingV,
  double Function(double, double, double) clampScale,
  double screenWidth,
) {
  final double heroWidth = clampScale(screenWidth * 0.9, 260, 640);
  return Center(
    child: Column(
      children: [
        FadeInLeft(
          config: BaseAnimationConfig(
            repeat: false,
            duration: 700.milliseconds,
            child: SizedBox(
              width: heroWidth,
              child: Text(
                'Here’s to dating with confidence',
                style: GoogleFonts.poppins(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: charcoal.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        FadeInLeft(
          config: BaseAnimationConfig(
            repeat: false,
            delay: 0.6.seconds,
            duration: 600.milliseconds,

            child: SizedBox(
              width: heroWidth,
              child: Text(
                '— and a spark that’s real.',
                style: GoogleFonts.poppins(
                  fontSize: subtitleFontSize,
                  color: charcoal.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 18),
        FadeInLeft(
          config: BaseAnimationConfig(
            repeat: true,
            delay: 1.seconds,
            duration: 800.milliseconds,

            child: Column(
              children: [
                OutlinedButton(
                  onPressed: () {},
                  style: ButtonStyle(
                    side: WidgetStateProperty.all(
                      BorderSide(color: charcoal.withValues(alpha: 0.8)),
                    ),
                    padding: WidgetStateProperty.all(
                      EdgeInsets.symmetric(
                        horizontal: buttonPaddingH,
                        vertical: buttonPaddingV,
                      ),
                    ),
                  ),
                  child: Text(
                    'Continue With Google',
                    style: GoogleFonts.poppins(),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Or',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {},
                  style: ButtonStyle(
                    side: WidgetStateProperty.all(
                      BorderSide(color: charcoal.withValues(alpha: 0.8)),
                    ),
                    padding: WidgetStateProperty.all(
                      EdgeInsets.symmetric(
                        horizontal: buttonPaddingH,
                        vertical: buttonPaddingV,
                      ),
                    ),
                  ),
                  child: Text(
                    'Continue With Facebook',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
