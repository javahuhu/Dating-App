import 'package:dating_app/Presentation/View/Desktop/snake_border.dart';
import 'package:dating_app/Presentation/View/Desktop/staggeredanimation.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
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
    final toMobile = MediaQuery.of(context).size.width < 771;
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                          onPressed: () {},
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
                                            color: charcoal.withValues(
                                              alpha: 0.85,
                                            ),
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
                                            color: charcoal.withValues(
                                              alpha: 0.85,
                                            ),
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
                                                      color: charcoal
                                                          .withValues(
                                                            alpha: 0.80,
                                                          ),
                                                      width: 2,
                                                    );
                                                  }),

                                              backgroundColor:
                                                  WidgetStateProperty.resolveWith<
                                                    Color?
                                                  >((Set<WidgetState> states) {
                                                    if (states.contains(
                                                      WidgetState.hovered,
                                                    )) {
                                                      return Colors.transparent;
                                                    }

                                                    return Colors.transparent;
                                                  }),
                                              shape: WidgetStateProperty.all(
                                                RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(28),
                                                ),
                                              ),
                                              textStyle:
                                                  WidgetStateProperty.all(
                                                    GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                                fontSize: _clampScale(
                                                  15,
                                                  12,
                                                  20,
                                                ),
                                                color: kTitleColor,
                                              ),
                                            ),
                                          ),

                                          SizedBox(
                                            height: _clampScale(20, 12, 30),
                                          ),

                                          Text(
                                            'Or',
                                            style: GoogleFonts.poppins(
                                              fontSize: _clampScale(22, 14, 28),
                                              color: charcoal,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(
                                            height: _clampScale(20, 12, 30),
                                          ),

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
                                                      color: charcoal
                                                          .withValues(
                                                            alpha: 0.80,
                                                          ),
                                                      width: 2,
                                                    );
                                                  }),
                                              backgroundColor:
                                                  WidgetStateProperty.resolveWith<
                                                    Color?
                                                  >((Set<WidgetState> states) {
                                                    if (states.contains(
                                                      WidgetState.hovered,
                                                    )) {
                                                      return Colors.transparent;
                                                    }

                                                    return Colors.transparent;
                                                  }),
                                              shape: WidgetStateProperty.all(
                                                RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(28),
                                                ),
                                              ),

                                              textStyle:
                                                  WidgetStateProperty.all(
                                                    GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                                fontSize: _clampScale(
                                                  15,
                                                  12,
                                                  20,
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

                            toMobile
                                ? SizedBox.shrink()
                                : FadeInRight(
                                    config: BaseAnimationConfig(
                                      repeat: false,
                                      duration: 1.seconds,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 50),
                                        child: Expanded(
                                          child: Column(
                                            children: [
                                              ClipRRect(
                                                child: Image.asset(
                                                  'assets/image/twoheart.png',
                                                  fit: BoxFit.cover,
                                                  height: 600,
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

            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> features = [
  {"img": 'assets/image/message.png', "details": 'Chat', "duration": 4},
  {"img": 'assets/image/secure.png', "details": 'Secure', "duration": 5},
  {"img": 'assets/image/dart.png', "details": 'Smart Matching', "duration": 6},
];

Widget _showFeatures(
  BuildContext context,
  WidgetRef ref,
  clampScale,
  double horizontalPadding,
  double scale,
  double screenWidth,
) {
  // scaled values
  final double snakeHeight = clampScale(550 * scale, 360, 900);
  final double leftImageHeight = clampScale(460 * scale, 220, 700);
  final double leftImageWidth = clampScale(screenWidth * 0.4, 150, 600);
  final double laptopsizeHeight = clampScale(220 * scale, 120, 400);
  final double laptopsizeWidth = clampScale(screenWidth * 0.5, 150, 465);
  final double headlineFont = clampScale(48 * scale, 15, 55);
  final double subtitleFont = clampScale(20 * scale, 14, 28);
  final double gapBetween = clampScale(40 * scale, 12, 120);

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
                // LEFT: macbook + positioned laptopsize (kept exactly)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        clampScale(12 * scale, 6, 20),
                      ),
                      child: Image.asset(
                        'assets/image/macbook.png',
                        fit: BoxFit.cover,
                        height: leftImageHeight,
                        width: leftImageWidth,
                      ),
                    ),

                    // <-- laptopsize kept and scaled (same relative position)
                    Positioned(
                      top: clampScale(115 * scale, 40, 180),
                      left: clampScale(50 * scale, 12, 160),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          clampScale(5 * scale, 2, 12),
                        ),
                        child: Image.asset(
                          'assets/image/laptopsize.png',
                          fit: BoxFit.cover,
                          height: laptopsizeHeight,
                          width: laptopsizeWidth,
                        ),
                      ),
                    ),
                  ],
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
                      // FEATURES: horizontal list converted to Wrap (overlapping circular image + label)
                      // If you want the image completely inside the container:
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: clampScale(24 * scale, 8, 50),
                          runSpacing: clampScale(30 * scale, 20, 40),
                          children: features.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final imgPath = item['img'] as String;
                            final details = (item['details'] ?? '') as String;
                            final duration =
                                (item['duration'] as double?) ?? 1.5;

                            final cardWidth = clampScale(160 * scale, 120, 240);
                            final imageSize = clampScale(70 * scale, 50, 90);

                            return StaggeredAnimationContainer(
                              delay: Duration(milliseconds: index * 250),
                              duration: Duration(
                                milliseconds: (duration * 1000).round(),
                              ),
                              child: Container(
                                width: cardWidth,
                                padding: EdgeInsets.only(
                                  top: clampScale(20 * scale, 16, 24),
                                  bottom: clampScale(16 * scale, 12, 20),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    clampScale(12 * scale, 8, 20),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Image inside container
                                    Container(
                                      width: imageSize,
                                      height: imageSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          imgPath,
                                          fit: BoxFit.cover,
                                          width: imageSize,
                                          height: imageSize,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: clampScale(12 * scale, 8, 16),
                                    ),
                                    // Text
                                    Text(
                                      details,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: clampScale(
                                          16 * scale,
                                          14,
                                          20,
                                        ),
                                        color: Colors.pinkAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
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
  final double heroWidth = clampScale(screenWidth * 0.8, 300, 700);
  return Center(
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
                    side: WidgetStateProperty.resolveWith<BorderSide>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.hovered)) {
                        return BorderSide(color: Colors.red, width: 2);
                      }

                      return BorderSide(
                        color: charcoal.withValues(alpha: 0.80),
                        width: 2,
                      );
                    }),

                    backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.transparent;
                      }

                      return Colors.transparent;
                    }),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    textStyle: WidgetStateProperty.all(
                      GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
                      fontSize: clampScale(15, 12, 20),
                      color: kTitleColor,
                    ),
                  ),
                ),

                SizedBox(height: clampScale(20, 12, 30)),

                Text(
                  'Or',
                  style: GoogleFonts.poppins(
                    fontSize: clampScale(22, 14, 28),
                    color: charcoal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: clampScale(20, 12, 30)),

                OutlinedButton(
                  onPressed: () {},
                  style: ButtonStyle(
                    side: WidgetStateProperty.resolveWith<BorderSide>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.hovered)) {
                        return BorderSide(color: Colors.blue, width: 2);
                      }

                      return BorderSide(
                        color: charcoal.withValues(alpha: 0.80),
                        width: 2,
                      );
                    }),
                    backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.transparent;
                      }

                      return Colors.transparent;
                    }),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),

                    textStyle: WidgetStateProperty.all(
                      GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
                      fontSize: clampScale(15, 12, 20),
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
  );
}
