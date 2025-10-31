import 'dart:io';
import 'dart:convert';
import 'package:dating_app/Data/API/profile_api.dart';
import 'package:dating_app/Data/API/social_api.dart';
import 'package:http/http.dart' as http;
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
import 'package:flutter_screenutil/flutter_screenutil.dart';


class MobileMainScreen extends HookConsumerWidget {
  const MobileMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: kBackgroundColor,
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context),
                SizedBox(height: 32.h),
                _buildMobileHeroSection(context),
                SizedBox(height: 80.h),
                _showFeatures(context, ref),
                SizedBox(height: 60.h),

                /// 💞 HOW IT WORKS SECTION
                _buildHowItWorksSection(),

                SizedBox(height: 60.h),

                /// 💬 TESTIMONIALS SECTION
                _buildTestimonialsSection(),

                SizedBox(height: 60.h),

                /// 🔒 SAFETY SECTION
                _buildSafetySection(),

                SizedBox(height: 60.h),

                /// 🌍 MEET NEARBY SECTION
                _buildMeetNearbySection(),

                SizedBox(height: 60.h),

                SizedBox(height: 60.h),

                /// ❤️ CALL TO ACTION SECTION
                _buildCTABanner(),

                SizedBox(height: 100.h),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Kismet',
                style: GoogleFonts.poppins(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: kTitleColor,
                ),
              ),
              SizedBox(width: 8.w),
              Image.asset(
                'assets/Icons/logostar.png',
                height: 32.h,
                width: 32.w,
                fit: BoxFit.cover,
              ),
            ],
          ),
          Row(
            children: [
              _miniButton('Log In', false, context),
              SizedBox(width: 12.w),
              _miniButton('Sign Up', true, context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniButton(String text, bool filled, BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        context.go('/login');
      },
      style: ElevatedButton.styleFrom(
        side: BorderSide(color: charcoal.withValues(alpha: 0.80), width: 1.w),
        backgroundColor: filled ? kTitleColor : Colors.transparent,
        foregroundColor: filled ? Colors.white : kTitleColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 12.sp,
        ),
      ),
    );
  }

  Widget _buildMobileHeroSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Image.asset(
              'assets/image/twoheart.png',
              height: 280.h,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 32.h),
          FadeInLeft(
            config: BaseAnimationConfig(
              repeat: false,
              duration: 1.seconds,
              child: Text(
                'Here’s to dating with confidence',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: charcoal.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          FadeInLeft(
            config: BaseAnimationConfig(
              delay: 1.5.seconds,
              duration: 1.5.seconds,
              child: Text(
                '— and a spark that’s real.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  color: charcoal.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
          SizedBox(height: 40.h),
          _buildMobileAuthButtons(context),
        ],
      ),
    );
  }

  Widget _buildMobileAuthButtons(BuildContext context) {
    return FadeInLeft(
      config: BaseAnimationConfig(
        repeat: true,
        delay: 2.seconds,
        duration: 2.seconds,
        child: Column(
          children: [
            _authButton('Continue With Google', Colors.red, context),
            
           
          ],
        ),
      ),
    );
  }

  Widget _authButton(String text, Color hoverColor, BuildContext context) {

    
    
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
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: handleGoogleSignIn,
        style: ButtonStyle(
          side: WidgetStateProperty.all(
            BorderSide(color: charcoal.withValues(alpha: 0.80), width: 1.5.w),
          ),
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          ),
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(fontSize: 14.sp, color: kTitleColor),
        ),
      ),
    );
  }

  Widget _showFeatures(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: SnakeBorderWithHeart(
        height: 800.h,
        color: kPrimaryColor,
        strokeWidth: 40.w,
        snakeLength: 300.w,
        speed: 0.2,
        borderRadius: BorderRadius.circular(20.r),
        tailSegments: 2,
        heartSize: 50.w,
        heartColor: Colors.pinkAccent,
        child: GlassmorphicContainer(
          height: 600.h,
          width: double.infinity,
          blur: 15,
          border: 1.w,
          borderRadius: 20.r,
          linearGradient: LinearGradient(
            colors: [
              kSecondaryColor.withValues(alpha: 0.3),
              kSecondaryColor.withValues(alpha: 0.3),
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
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          child: _buildMobileFeatures(),
        ),
      ),
    );
  }

  Widget _buildMobileFeatures() {
    return Column(
      children: [
        SizedBox(height: 30.h),
        Image.asset(
          'assets/image/responsivelaptop.png',
          height: 150.h,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 32.h),

        SlideInDown(
          config: BaseAnimationConfig(
            repeat: false,
            duration: 1.5.seconds,
            child: Text(
              'Find Love That Feels Real.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: headingViolet,
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        FadeInRight(
          config: BaseAnimationConfig(
            repeat: false,
            duration: 3.seconds,
            delay: 5.seconds,
            child: Text(
              'Discover genuine people ready for meaningful connections. '
              'Chat, meet, and fall in love — anytime, anywhere.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14.sp, color: subtextViolet),
            ),
          ),
        ),
        SizedBox(height: 40.h),
        _buildMobileFeatureCards(),
      ],
    );
  }

  Widget _buildMobileFeatureCards() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 25.w),
      child: Column(
        children: features.asMap().entries.map((entry) {
          final feature = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 24.h),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Row(
                children: [
                  FadeInUp(
                    config: BaseAnimationConfig(
                      repeat: false,
                      delay: 0.seconds, // starts immediately
                      duration: 2.seconds,
                      child: Image.asset(
                        feature['img'],
                        height: 60.h,
                        width: 60.w,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      feature['details'],
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.pinkAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 💡 HOW IT WORKS SECTION
  Widget _buildHowItWorksSection() {
    final steps = [
      {
        'title': 'Create Your Profile',
        'desc': 'Add photos, interests, and preferences.',
        'icon': Icons.person_add_alt_1,
      },
      {
        'title': 'Find Matches',
        'desc': 'Discover people who truly click with you.',
        'icon': Icons.favorite_outline,
      },
      {
        'title': 'Start Chatting',
        'desc': 'Connect and let sparks fly!',
        'icon': Icons.chat_bubble_outline,
      },
    ];

    return Column(
      children: [
        Text(
          'How Kismet Works',
          style: GoogleFonts.poppins(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: charcoal.withValues(alpha: 0.95),
          ),
        ),
        SizedBox(height: 20.h),
        Column(
          children: steps
              .map(
                (s) => FadeInUp(
                  config: BaseAnimationConfig(
                    repeat: false,
                    duration: 600.milliseconds,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 10.h,
                        horizontal: 20.w,
                      ),
                      child: GlassmorphicContainer(
                        height: 120.h,
                        width: double.infinity,
                        blur: 10,
                        border: 1,
                        borderRadius: 20.r,
                        linearGradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.2),
                            Colors.white.withValues(alpha: 0.1),
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
                        child: Row(
                          children: [
                            SizedBox(width: 16.w),
                            Icon(
                              s['icon'] as IconData,
                              color: headingViolet,
                              size: 30.sp,
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s['title'].toString(),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16.sp,
                                      color: charcoal.withValues(alpha: 0.95),
                                    ),
                                  ),
                                  Text(
                                    s['desc'].toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.sp,
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
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  // replace your current _buildTestimonialsSection with this
  Widget _buildTestimonialsSection() {
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

    return Column(
      children: [
        Text(
          'Real Stories',
          style: GoogleFonts.poppins(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: charcoal.withValues(alpha: 0.95),
          ),
        ),
        SizedBox(height: 20.h),

        // Smooth ticker (mobile)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 0.w),
          child: MobileTestimonialsTicker(
            items: testimonials,
            speedPxPerSecond: 120.0, // tune: increase for faster scroll
          ),
        ),
      ],
    );
  }

  // 🔒 SAFETY SECTION
  Widget _buildSafetySection() {
    final safeties = [
      {'icon': Icons.verified, 'text': 'Verified Profiles'},
      {'icon': Icons.block, 'text': 'No Spam Accounts'},
      {'icon': Icons.lock, 'text': 'Encrypted Chats'},
    ];

    return Column(
      children: [
        Text(
          'Safety & Trust',
          style: GoogleFonts.poppins(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: charcoal.withValues(alpha: 0.85),
          ),
        ),
        SizedBox(height: 20.h),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16.w,
          runSpacing: 16.h,
          children: safeties
              .map(
                (s) => FadeInUp(
                  config: BaseAnimationConfig(
                    repeat: false,
                    duration: 600.milliseconds,
                    child: Container(
                      width: 160.w,
                      height: 150,
                      padding: EdgeInsets.all(5.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 12),
                          Icon(
                            s['icon'] as IconData,
                            color: headingViolet,
                            size: 32.sp,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            s['text']!.toString(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: charcoal.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  // 🌍 MEET NEARBY SECTION
  Widget _buildMeetNearbySection() {
    return Column(
      children: [
        Text(
          'Meet People Near You 🌍',
          style: GoogleFonts.poppins(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: headingViolet,
          ),
        ),
        SizedBox(height: 20.h),
        FadeInUp(
          config: BaseAnimationConfig(
            repeat: false,
            duration: 500.milliseconds,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.asset(
                'assets/image/gmaps.png',
                height: 200.h,
                width: 330.w,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        FadeInUp(
          config: BaseAnimationConfig(
            repeat: false,
            duration: 500.milliseconds,
            child: Text(
              'Love might be just a few miles away.',
              style: GoogleFonts.poppins(fontSize: 14.sp, color: subtextViolet),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCTABanner() {
    return SlideInRight(
      config: BaseAnimationConfig(
        repeat: false,
        duration: 300.milliseconds,
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pinkAccent.shade100, headingViolet],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            children: [
              Text(
                'Ready to find your spark? ✨',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Join thousands discovering real connections today.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 32.w,
                    vertical: 14.h,
                  ),
                ),
                child: Text(
                  'Get Started Free',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: headingViolet,
                  ),
                ),
              ),
            ],
          ),
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
