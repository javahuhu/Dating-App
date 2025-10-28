import 'package:dating_app/Core/Theme/colors.dart';
import 'package:dating_app/Presentation/Animation/animation_carousel.dart';
import 'package:dating_app/Presentation/View/Desktop/snake_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate_on_scroll/flutter_animate_on_scroll.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class DesktopMainScreen extends HookConsumerWidget {
  const DesktopMainScreen({super.key});

  double _clampScale(double value, double min, double max) {
    return value.clamp(min, max);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Size screen = MediaQuery.of(context).size;
    final double screenWidth = screen.width;

    final double baseWidth = 1440;

    final double scale = screenWidth / baseWidth;
    final double titleFontSize = _clampScale(60 * scale, 28, 72);
    final double subtitleFontSize = _clampScale(30 * scale, 16, 40);
    final double heroWidth = _clampScale(screenWidth * 0.35, 300, 700);
    final double heroImageWidth = _clampScale(screenWidth * 0.45, 280, 700);
    final double horizontalPadding = _clampScale(screenWidth * 0.064, 16, 400);
    final double buttonPaddingH = _clampScale(22 * scale, 12, 32);
    final double buttonPaddingV = _clampScale(20 * scale, 15, 30);
    final double buttonPaddingEV = _clampScale(20 * scale, 15, 20);
    final double borderRadius = _clampScale(28 * scale, 8, 40);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // -------- NAV --------
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 24,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Kismet',
                        style: GoogleFonts.poppins(
                          fontSize: _clampScale(40, 18, 60),
                          fontWeight: FontWeight.bold,
                          color: kTitleColor,
                        ),
                      ),

                      SizedBox(width: 10),

                      ClipRRect(
                        child: Image.asset(
                          'assets/Icons/logostar.png',
                          fit: BoxFit.cover,
                          height: _clampScale(60, 28, 80),
                          width: _clampScale(60, 28, 80),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: EdgeInsets.only(right: _clampScale(120, 20, 20)),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            context.go('/login');
                          },
                          style: ElevatedButton.styleFrom(
                            side: BorderSide(
                              color: charcoal.withValues(alpha: 0.80),
                              width: 2,
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
                              vertical: buttonPaddingEV,
                            ),
                          ),
                          child: Text(
                            'Log In',
                            style: GoogleFonts.poppins(
                              fontSize: _clampScale(18, 12, 20),
                            ),
                          ),
                        ),

                        SizedBox(width: 25),

                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            side: BorderSide(
                              color: charcoal.withValues(alpha: 0.80),
                              width: 2,
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
                              vertical: buttonPaddingEV,
                            ),
                          ),
                          child: Text(
                            'Sign Up',
                            style: GoogleFonts.poppins(
                              fontSize: _clampScale(18, 12, 20),
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: _clampScale(40, 20, 40)),

            // -------- HERO --------
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            FadeInLeft(
                              config: BaseAnimationConfig(
                                repeat: false,
                                duration: 1.seconds,
                                child: SizedBox(
                                  width: heroWidth,
                                  child: Text(
                                    'Here’s to dating with confidence',
                                    style: GoogleFonts.poppins(
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: charcoal.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            FadeInLeft(
                              config: BaseAnimationConfig(
                                repeat: false,
                                delay: 1.5.seconds,
                                duration: 1.5.seconds,
                                child: SizedBox(
                                  width: heroWidth,
                                  child: Text(
                                    '— and a spark that’s real.',
                                    style: GoogleFonts.poppins(
                                      fontSize: subtitleFontSize,
                                      fontWeight: FontWeight.normal,
                                      color: charcoal.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 50),

                            FadeInLeft(
                              config: BaseAnimationConfig(
                                repeat: true,
                                delay: 2.seconds,
                                duration: 2.seconds,
                                child: Column(
                                  children: [
                                    OutlinedButton(
                                      onPressed: () {},
                                      style: ButtonStyle(
                                        side:
                                            WidgetStateProperty.resolveWith<
                                              BorderSide
                                            >((Set<WidgetState> states) {
                                              if (states.contains(
                                                WidgetState.hovered,
                                              )) {
                                                return BorderSide(
                                                  color: Colors.red,
                                                  width: 2,
                                                );
                                              }

                                              return BorderSide(
                                                color: charcoal.withValues(
                                                  alpha: 0.80,
                                                ),
                                                width: 2,
                                              );
                                            }),
                                        backgroundColor:
                                            WidgetStateProperty.resolveWith<
                                              Color?
                                            >((Set<WidgetState> states) {
                                              return Colors.transparent;
                                            }),
                                        shape: WidgetStateProperty.all(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              28,
                                            ),
                                          ),
                                        ),
                                        textStyle: WidgetStateProperty.all(
                                          GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
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
                                        style: GoogleFonts.poppins(
                                          fontSize: _clampScale(15, 12, 20),
                                          color: kTitleColor,
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: _clampScale(20, 12, 30)),

                                    Text(
                                      'Or',
                                      style: GoogleFonts.poppins(
                                        fontSize: _clampScale(22, 14, 28),
                                        color: charcoal,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: _clampScale(20, 12, 30)),

                                    OutlinedButton(
                                      onPressed: () {},
                                      style: ButtonStyle(
                                        side:
                                            WidgetStateProperty.resolveWith<
                                              BorderSide
                                            >((Set<WidgetState> states) {
                                              if (states.contains(
                                                WidgetState.hovered,
                                              )) {
                                                return BorderSide(
                                                  color: Colors.blue,
                                                  width: 2,
                                                );
                                              }

                                              return BorderSide(
                                                color: charcoal.withValues(
                                                  alpha: 0.80,
                                                ),
                                                width: 2,
                                              );
                                            }),
                                        backgroundColor:
                                            WidgetStateProperty.resolveWith<
                                              Color?
                                            >((Set<WidgetState> states) {
                                              return Colors.transparent;
                                            }),
                                        shape: WidgetStateProperty.all(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              28,
                                            ),
                                          ),
                                        ),
                                        textStyle: WidgetStateProperty.all(
                                          GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
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
                                        style: GoogleFonts.poppins(
                                          fontSize: _clampScale(15, 12, 20),
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

                      FadeInRight(
                        config: BaseAnimationConfig(
                          repeat: false,
                          duration: 1.seconds,
                          child: Padding(
                            padding: EdgeInsets.only(left: 50),
                            child: SizedBox(
                              width: heroImageWidth,
                              child: Column(
                                children: [
                                  ClipRRect(
                                    child: Image.asset(
                                      'assets/image/twoheart.png',
                                      fit: BoxFit.cover,
                                      height: _clampScale(
                                        420 * scale,
                                        220,
                                        700,
                                      ),
                                      width: heroImageWidth,
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

            SizedBox(height: 200),

          
            _showFeatures(
              context,
              ref,
              _clampScale,
              horizontalPadding,
              scale,
              screenWidth,
            ),

            
            SizedBox(height: 60),
            _howItWorksSection(context, _clampScale, scale, horizontalPadding),
            SizedBox(height: 40),
            _testimonialsSection(context, _clampScale, scale),
            SizedBox(height: 40),
            _safetyTrustSection(context, _clampScale, scale),
            SizedBox(height: 40),
            _nearbyMapPreview(context, _clampScale, scale),
            SizedBox(height: 40),

            _ctaBanner(context, _clampScale, scale),
            SizedBox(height: 40),
            _footer(context, _clampScale, scale),

            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ------------------------ HELPERS / SECTIONS ------------------------

Widget _howItWorksSection(
  BuildContext context,
  double Function(double, double, double) clampScale,
  double scale,
  double horizontalPadding,
) {
  final double heading = clampScale(28 * scale, 18, 36);
  final double cardW = clampScale(280 * scale, 220, 420);
  final double cardH = clampScale(160 * scale, 140, 220);
  final double iconSize = clampScale(40 * scale, 28, 56);

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
        SizedBox(height: clampScale(18 * scale, 10, 28)),
        Wrap(
          spacing: clampScale(20 * scale, 12, 40),
          runSpacing: clampScale(20 * scale, 12, 30),
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
              subtitle: 'Smart suggestions you\'ll actually like.',
              icon: Icons.favorite_border,
              iconSize: iconSize,
              width: cardW,
              height: cardH,
              clampScale: clampScale,
              scale: scale,
            ),
            _featureStepCard(
              title: 'Start chatting',
              subtitle: 'Meet and connect — safely and easily.',
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
        duration: 600.milliseconds,
        child: Container(
          height: height,
          padding: EdgeInsets.all(clampScale(16 * scale, 10, 24)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(clampScale(16 * scale, 8, 24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: iconSize + 18,
                width: iconSize + 18,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: iconSize, color: headingViolet),
              ),
              SizedBox(width: clampScale(16 * scale, 8, 20)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: clampScale(16 * scale, 12, 20),
                        fontWeight: FontWeight.w600,
                        color: charcoal.withValues(alpha: 0.9),
                      ),
                    ),
                    SizedBox(height: clampScale(6 * scale, 4, 10)),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: clampScale(13 * scale, 12, 16),
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
Widget _testimonialsSection(
  BuildContext context,
  double Function(double, double, double) clampScale,
  double scale,
) {
  return InfiniteTestimonialCarousel(
    testimonials: testimonials,
    scale: scale,
    clampScale: clampScale,
  );
}

Widget _safetyTrustSection(
  BuildContext context,
  double Function(double, double, double) clampScale,
  double scale,
) {
  final double heading = clampScale(22 * scale, 16, 28);
  final double iconSize = clampScale(34 * scale, 22, 44);

  final items = [
    {
      'icon': Icons.verified,
      'title': 'Verified Profiles',
      'subtitle': 'Identity checks for peace of mind.',
    },
    {
      'icon': Icons.block,
      'title': 'No Fake Accounts',
      'subtitle': 'Active moderation and reporting.',
    },
    {
      'icon': Icons.lock,
      'title': 'Encrypted Chats',
      'subtitle': 'Your conversations stay private.',
    },
  ];

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: clampScale(32 * scale, 12, 120)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Safety & Trust',
          style: GoogleFonts.poppins(
            fontSize: clampScale(28 * scale, 18, 36),
            fontWeight: FontWeight.bold,
            color: charcoal.withValues(alpha: 0.95),
          ),
        ),
        SizedBox(height: clampScale(16 * scale, 8, 24)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: items.map((it) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: clampScale(8 * scale, 6, 12),
                ),
                child: FadeInUp(
                  config: BaseAnimationConfig(
                    repeat: false,
                    duration: 600.milliseconds,
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(
                            clampScale(12 * scale, 8, 16),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              clampScale(12 * scale, 8, 16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .03),
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
                        SizedBox(height: clampScale(10 * scale, 6, 14)),
                        Text(
                          it['title'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: heading,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: clampScale(8 * scale, 6, 12)),
                        Text(
                          it['subtitle'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: clampScale(13 * scale, 12, 14),
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
  double scale,
) {
  final double height = clampScale(220 * scale, 140, 420);
  final double heading = clampScale(22 * scale, 16, 28);

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: clampScale(32 * scale, 12, 120)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meet people near you',
          style: GoogleFonts.poppins(
            fontSize: heading,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: clampScale(12 * scale, 8, 16)),
        FadeInUp(
          config: BaseAnimationConfig(
            repeat: false,
            duration: 700.milliseconds,
            child: Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  clampScale(16 * scale, 10, 24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
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
                  // fake pins
                  Positioned(
                    left: clampScale(40 * scale, 20, 80),
                    top: clampScale(40 * scale, 20, 80),
                    child: _mapPin(clampScale(48 * scale, 30, 72)),
                  ),
                  Positioned(
                    right: clampScale(80 * scale, 40, 120),
                    bottom: clampScale(40 * scale, 20, 80),
                    child: _mapPin(clampScale(56 * scale, 34, 84)),
                  ),
                  Positioned(
                    left: clampScale(180 * scale, 80, 260),
                    bottom: clampScale(70 * scale, 40, 120),
                    child: _mapPin(clampScale(44 * scale, 28, 68)),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: clampScale(18 * scale, 12, 28),
                        ),
                        child: Container(
                          width: clampScale(240 * scale, 180, 420),
                          padding: EdgeInsets.all(
                            clampScale(12 * scale, 8, 16),
                          ),
                          decoration: BoxDecoration(
                            color: kBackgroundColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(
                              clampScale(12 * scale, 8, 20),
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
                                  fontSize: clampScale(13 * scale, 12, 14),
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
        BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 8),
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
  final double height = clampScale(120 * scale, 100, 220);
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: clampScale(32 * scale, 12, 120)),
    child: Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pinkAccent.withValues(alpha: .9),
            Colors.purpleAccent.withValues(alpha: .9),
          ],
        ),
        borderRadius: BorderRadius.circular(clampScale(18 * scale, 12, 28)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 16),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite,
              color: Colors.white,
              size: clampScale(36 * scale, 24, 44),
            ),
            SizedBox(width: clampScale(12 * scale, 8, 20)),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ready to find your spark?',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: clampScale(20 * scale, 16, 26),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Join thousands discovering real connections today',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: clampScale(13 * scale, 12, 16),
                  ),
                ),
              ],
            ),
            SizedBox(width: clampScale(24 * scale, 12, 36)),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: kBackgroundColor,
                foregroundColor: kTitleColor,
                padding: EdgeInsets.symmetric(horizontal: 26, vertical: 16),
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
  final double small = clampScale(13 * scale, 11, 16);

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: clampScale(32 * scale, 12, 120)),
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
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: () {},
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: headingViolet,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}



Widget _showFeatures(
  BuildContext context,
  WidgetRef ref,
  double Function(double, double, double) clampScale,
  double horizontalPadding,
  double scale,
  double screenWidth,
) {
  // scaled values
  final double snakeHeight = clampScale(550 * scale, 360, 900);
  final double leftImageHeight = clampScale(
    210 * scale,
    180,
    400,
  ); // Adjusted range
  final double leftImageWidth = clampScale(
    screenWidth * 0.25,
    120,
    610,
  ); // Adjusted range
  final double headlineFont = clampScale(48 * scale, 15, 55);
  final double subtitleFont = clampScale(20 * scale, 14, 28);
  final double gapBetween = clampScale(40 * scale, 12, 120);
  final double laptopLeftPadding = clampScale(
    30 * scale,
    10,
    60,
  ); // Added left padding

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: clampScale(50 * scale, 12, 80)),
    child: SnakeBorderWithHeart(
      height: snakeHeight,
      color: kPrimaryColor,
      strokeWidth: clampScale(60 * scale, 2, 80),
      snakeLength: clampScale(500 * scale, 100, 2000),
      speed: 0.2,
      borderRadius: BorderRadius.circular(clampScale(25 * scale, 8, 40)),
      tailSegments: 2,
      heartSize: clampScale(80 * scale, 16, 125),
      heartColor: Colors.pinkAccent,
      child: GlassmorphicContainer(
        height: snakeHeight,
        width: double.infinity,
        blur: 15,
        border: 2,
        borderRadius: clampScale(25 * scale, 8, 40),
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kSecondaryColor.withValues(alpha: 0.3),
            kSecondaryColor.withValues(alpha: 0.3),
          ],
          stops: [0.1, 1],
        ),

        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.4),
            Colors.white.withValues(alpha: 0.2),
          ],
        ),

        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: clampScale(30 * scale, 12, 80),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1440),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            fit: BoxFit.cover,
                            height: leftImageHeight,
                            width: leftImageWidth,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: gapBetween),

                // RIGHT: content area - make it responsive
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: clampScale(50 * scale, 8, 80)),

                      SlideInDown(
                        config: BaseAnimationConfig(
                          repeat: false,
                          duration: 1.5.seconds,
                          child: Text(
                            'Find Love That Feels Real.',
                            style: GoogleFonts.poppins(
                              fontSize: headlineFont,
                              color: headingViolet,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: clampScale(8 * scale, 6, 24)),

                      SlideInDown(
                        config: BaseAnimationConfig(
                          repeat: false,
                          duration: 3.seconds,
                          delay: 5.seconds,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: Text(
                              'Discover genuine people ready for meaningful connections. '
                              'Chat, meet, and fall in love — anytime, anywhere.',
                              style: GoogleFonts.poppins(
                                fontSize: subtitleFont,
                                fontWeight: FontWeight.w400,
                                color: subtextViolet,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: clampScale(80 * scale, 12, 120)),
                      SizedBox(
                        width: double.infinity,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double available = constraints.maxWidth;
                            final bool isWide = available > 700;

                            // spacing values (keep your clampScale usage)
                            final double spacing = clampScale(
                              50 * scale,
                              8,
                              50,
                            );
                            final double runSpacing = clampScale(
                              30 * scale,
                              20,
                              40,
                            );

                            const int childCount = 3;

                            final double minCardWidth = clampScale(
                              120 * scale,
                              120,
                              160,
                            );
                            final double maxCardWidth = clampScale(
                              240 * scale,
                              160,
                              320,
                            );

                            int perRow =
                                ((available + spacing) ~/
                                        (minCardWidth + spacing))
                                    .toInt();
                            if (perRow < 1) perRow = 1;
                            if (perRow > childCount) perRow = childCount;

                            final double totalSpacing = spacing * (perRow + 1);
                            double cardWidth =
                                (available - totalSpacing) / perRow;

                            cardWidth = cardWidth.clamp(
                              minCardWidth,
                              maxCardWidth,
                            );

                            final double cardHeight = clampScale(
                              170 * scale,
                              120,
                              210,
                            );
                            final double imageAreaHeight = clampScale(
                              80 * scale,
                              60,
                              110,
                            );
                            final double imagePopUp = clampScale(
                              60 * scale,
                              35,
                              70,
                            );

                            return Wrap(
                              alignment: isWide
                                  ? WrapAlignment.start
                                  : WrapAlignment.center,
                              spacing: spacing,
                              runSpacing: runSpacing,
                              children: [
                                // === Chat Card ===
                                Container(
                                  height: cardHeight,
                                  width: cardWidth,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: clampScale(8 * scale, 6, 12),
                                    vertical: clampScale(8 * scale, 6, 12),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      clampScale(12 * scale, 8, 20),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      SizedBox(
                                        height: imageAreaHeight,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Positioned(
                                              top: -imagePopUp,
                                              left: 0,
                                              right: 0,
                                              child: Center(
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        clampScale(
                                                          12 * scale,
                                                          8,
                                                          20,
                                                        ),
                                                      ),
                                                  child: FadeInUp(
                                                    config: BaseAnimationConfig(
                                                      repeat: false,
                                                      delay: 0
                                                          .seconds, // starts immediately
                                                      duration: 2
                                                          .seconds, // lasts 2 seconds
                                                      child: Image.asset(
                                                        'assets/image/message.png',
                                                        fit: BoxFit.cover,
                                                        height: clampScale(
                                                          90 * scale,
                                                          70,
                                                          120,
                                                        ),
                                                        width: clampScale(
                                                          90 * scale,
                                                          70,
                                                          120,
                                                        ),
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
                                        height: clampScale(6 * scale, 4, 10),
                                      ),
                                      Text(
                                        'Chat',
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: clampScale(
                                            16 * scale,
                                            14,
                                            22,
                                          ),
                                          fontWeight: FontWeight.w600,
                                          color: Colors.pinkAccent,
                                          shadows: [
                                            Shadow(
                                              color: Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // === Secure Card ===
                                Container(
                                  height: cardHeight,
                                  width: cardWidth,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: clampScale(8 * scale, 6, 12),
                                    vertical: clampScale(8 * scale, 6, 12),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      clampScale(12 * scale, 8, 20),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      SizedBox(
                                        height: imageAreaHeight,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Positioned(
                                              top: -imagePopUp,
                                              left: 0,
                                              right: 0,
                                              child: Center(
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        clampScale(
                                                          12 * scale,
                                                          8,
                                                          20,
                                                        ),
                                                      ),
                                                  child: FadeInUp(
                                                    config: BaseAnimationConfig(
                                                      repeat: false,
                                                      delay: 2.2
                                                          .seconds, // starts after message finishes + slight gap
                                                      duration: 2
                                                          .seconds, // same duration
                                                      child: Image.asset(
                                                        'assets/image/secure.png',
                                                        fit: BoxFit.cover,
                                                        height: clampScale(
                                                          90 * scale,
                                                          70,
                                                          120,
                                                        ),
                                                        width: clampScale(
                                                          90 * scale,
                                                          70,
                                                          120,
                                                        ),
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
                                        height: clampScale(6 * scale, 4, 10),
                                      ),
                                      Text(
                                        'Secure',
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: clampScale(
                                            16 * scale,
                                            14,
                                            22,
                                          ),
                                          fontWeight: FontWeight.w600,
                                          color: Colors.pinkAccent,
                                          shadows: [
                                            Shadow(
                                              color: Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // === Smart Matches Card ===
                                Container(
                                  height: cardHeight,
                                  width: cardWidth,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: clampScale(8 * scale, 6, 12),
                                    vertical: clampScale(8 * scale, 6, 12),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      clampScale(12 * scale, 8, 20),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      SizedBox(
                                        height: imageAreaHeight,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Positioned(
                                              top: -imagePopUp,
                                              left: 0,
                                              right: 0,
                                              child: Center(
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        clampScale(
                                                          12 * scale,
                                                          8,
                                                          20,
                                                        ),
                                                      ),
                                                  child: FadeInUp(
                                                    config: BaseAnimationConfig(
                                                      repeat: false,
                                                      delay: 4.4.seconds,
                                                      duration: 2.seconds,
                                                      child: Image.asset(
                                                        'assets/image/dart.png',
                                                        fit: BoxFit.cover,
                                                        height: clampScale(
                                                          90 * scale,
                                                          70,
                                                          120,
                                                        ),
                                                        width: clampScale(
                                                          90 * scale,
                                                          70,
                                                          120,
                                                        ),
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
                                        height: clampScale(6 * scale, 4, 10),
                                      ),
                                      Text(
                                        'Smart Matching',
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: clampScale(
                                            16 * scale,
                                            14,
                                            22,
                                          ),
                                          fontWeight: FontWeight.w600,
                                          color: Colors.pinkAccent,
                                          shadows: [
                                            Shadow(
                                              color: Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
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
  );
}
