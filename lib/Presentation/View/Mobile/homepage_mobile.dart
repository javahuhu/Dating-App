// main.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/legacy.dart';

//// Color Palette
const Color kTitleColor = Color(0xFF2D2D2D);
const Color kBodyTextColor = Color(0xFF4F4F4F);
const Color kPrimaryColor = Color(0xFFE91E63);
const Color kSecondaryColor = Color(0xFFCFA7F6);
const Color kAccentColor = Color(0xFFFFDCA8);
const Color kBackgroundColor = Color(0xFFFAF6F9);
const Color subtextViolet = Color(0xFF4B3B9A);
const Color headingViolet = Color(0xFF3D2C8D);

void main() {
  runApp(const ProviderScope(child: KismetApp()));
}

// -------------------- Providers --------------------
final selectedIndexProvider = StateProvider<int>((ref) => 0);
final currentProfileIndexProvider = StateProvider<int>((ref) => 0);

final profilesProvider = Provider<List<ProfileCard>>(
  (ref) => [
    ProfileCard(
      name: 'Sarah',
      age: 28,
      bio: 'Adventure seeker | Coffee enthusiast | Love hiking & photography',
      distance: '2 miles away',
      images: [
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=1200',
      ],
    ),
    ProfileCard(
      name: 'Emily',
      age: 26,
      bio: 'Artist & dreamer | Plant mom 🌿 | Looking for genuine connections',
      distance: '5 miles away',
      images: [
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=1200',
      ],
    ),
    ProfileCard(
      name: 'Jessica',
      age: 30,
      bio:
          'Foodie | Travel addict ✈️ | Dog lover | Always up for new experiences',
      distance: '3 miles away',
      images: [
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=1200',
      ],
    ),
  ],
);

// -------------------- App --------------------
class KismetApp extends HookConsumerWidget {
  const KismetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize ScreenUtil with a typical mobile design size
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Kismet',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: kPrimaryColor,
            scaffoldBackgroundColor: kBackgroundColor,
            fontFamily: 'SF Pro Display',
            textTheme: Typography.blackMountainView,
          ),
          home: const KismetHomePage(),
        );
      },
    );
  }
}

// -------------------- Home --------------------
class KismetHomePage extends HookConsumerWidget {
  const KismetHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final currentProfileIndex = ref.watch(currentProfileIndexProvider);
    final profiles = ref.watch(profilesProvider);

    // Screen width detection
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 720.0;
    final isTablet = screenWidth > 720.0 && screenWidth <= 1100.0;
    final isDesktop = screenWidth > 1100.0;

    // Clamped widths/paddings per breakpoint
    final clampedWidth = isDesktop
        ? screenWidth.clamp(1024.0, 2560.0)
        : isTablet
        ? screenWidth.clamp(720.0, 1100.0)
        : screenWidth.clamp(0.0, 420.0); // mobile max width 420

    final navWidth = isDesktop
        ? (clampedWidth * 0.18).clamp(220.0, 340.0)
        : isTablet
        ? (clampedWidth * 0.18).clamp(160.0, 260.0)
        : 72.0.w; // compact sidebar on mobile, scaled via ScreenUtil

    final contentWidth = clampedWidth - navWidth;
    final horizontalPadding = isDesktop
        ? (contentWidth * 0.08).clamp(40.0, 140.0)
        : isTablet
        ? (contentWidth * 0.06).clamp(20.0, 60.0)
        : 16.0.w; // mobile padding scaled

    void onNavTap(int idx) =>
        ref.read(selectedIndexProvider.notifier).state = idx;

    void swipeCard(bool liked) {
      final notifier = ref.read(currentProfileIndexProvider.notifier);
      final next = notifier.state < profiles.length - 1
          ? notifier.state + 1
          : 0;
      notifier.state = next;
    }

    // Card sizes per breakpoint
    final cardMaxWidth = isDesktop
        ? 600.0
        : isTablet
        ? 480.0
        : 320.0.w; // mobile scaled
    final cardMaxHeight = isDesktop
        ? 700.0
        : isTablet
        ? 560.0
        : 420.0.h; // mobile scaled

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 2560.0 : (isTablet ? 1100.0 : 420.0),
          ),
          child: Row(
            children: [
              // ---------- Sidebar ----------
              Container(
                width: navWidth,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(height: isMobile ? 16.h : 40),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8.w : 24,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: isMobile ? 36.w : 42,
                            height: isMobile ? 36.w : 42,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [kPrimaryColor, kSecondaryColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: isMobile ? 8.w : 12),
                          if (!isMobile)
                            Text(
                              'Kismet',
                              style: TextStyle(
                                fontSize: isTablet ? 22.sp : 28.sp,
                                fontWeight: FontWeight.bold,
                                color: headingViolet,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: isMobile ? 10.h : (isTablet ? 28 : 50)),
                    _navItem(
                      Icons.explore_rounded,
                      'Discover',
                      0,
                      selectedIndex,
                      onNavTap,
                      isMobile: isMobile,
                    ),
                    _navItem(
                      Icons.favorite_rounded,
                      'Matches',
                      1,
                      selectedIndex,
                      onNavTap,
                      isMobile: isMobile,
                    ),
                    _navItem(
                      Icons.chat_bubble_rounded,
                      'Messages',
                      2,
                      selectedIndex,
                      onNavTap,
                      isMobile: isMobile,
                    ),
                    _navItem(
                      Icons.person_rounded,
                      'Profile',
                      3,
                      selectedIndex,
                      onNavTap,
                      isMobile: isMobile,
                    ),
                    _navItem(
                      Icons.settings_rounded,
                      'Settings',
                      4,
                      selectedIndex,
                      onNavTap,
                      isMobile: isMobile,
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.all(isMobile ? 12.w : 24),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: isMobile ? 16.r : 20,
                            backgroundImage: const NetworkImage(
                              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
                            ),
                          ),
                          if (!isMobile) ...[
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: kTitleColor,
                                  ),
                                ),
                                Text(
                                  'View Profile',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: subtextViolet,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ---------- Main Content ----------
              Expanded(
                child: Container(
                  width: contentWidth,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isMobile ? 18.h : 40,
                  ),
                  child: selectedIndex == 0
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Discover',
                              style: TextStyle(
                                fontSize: isMobile
                                    ? 22.sp
                                    : (isTablet ? 28.sp : 36.sp),
                                fontWeight: FontWeight.bold,
                                color: headingViolet,
                              ),
                            ),
                            SizedBox(height: isMobile ? 6.h : 8),
                            Text(
                              'Find your perfect match',
                              style: TextStyle(
                                fontSize: isMobile ? 12.sp : 16.sp,
                                color: subtextViolet,
                              ),
                            ),
                            SizedBox(height: isMobile ? 16.h : 40),
                            Expanded(
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 520),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  transitionBuilder: (child, animation) {
                                    final offsetAnimation =
                                        Tween<Offset>(
                                          begin: const Offset(0.25, 0),
                                          end: Offset.zero,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
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
                                  child: _ProfileCardWrapper(
                                    key: ValueKey<int>(currentProfileIndex),
                                    profile: profiles[currentProfileIndex],
                                    onLike: () => swipeCard(true),
                                    onDislike: () => swipeCard(false),
                                    isMobile: isMobile,
                                    maxW: cardMaxWidth,
                                    maxH: cardMaxHeight,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Text(
                            _getPageTitle(selectedIndex),
                            style: TextStyle(
                              fontSize: isMobile
                                  ? 18.sp
                                  : (isTablet ? 22.sp : 32.sp),
                              fontWeight: FontWeight.bold,
                              color: headingViolet,
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

  // nav item helper
  Widget _navItem(
    IconData icon,
    String label,
    int index,
    int selected,
    void Function(int) onTap, {
    required bool isMobile,
  }) {
    final isSelected = index == selected;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(
          horizontal: isMobile ? 8.w : 16,
          vertical: isMobile ? 6.h : 8,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8.w : 20,
          vertical: isMobile ? 10.h : 14,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? kPrimaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
          border: Border.all(
            color: isSelected
                ? kPrimaryColor.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? kPrimaryColor : kBodyTextColor,
              size: isMobile ? 20.sp : 24,
            ),
            SizedBox(width: isMobile ? 8.w : 16),
            if (!isMobile)
              Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 12.sp : 16.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? kPrimaryColor : kBodyTextColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 1:
        return 'Matches';
      case 2:
        return 'Messages';
      case 3:
        return 'Profile';
      case 4:
        return 'Settings';
      default:
        return 'Discover';
    }
  }
}

// -------------------- ProfileCard Wrapper for AnimatedSwitcher --------------------
class _ProfileCardWrapper extends StatelessWidget {
  final ProfileCard profile;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final bool isMobile;
  final double maxW;
  final double maxH;

  const _ProfileCardWrapper({
    required Key key,
    required this.profile,
    required this.onLike,
    required this.onDislike,
    this.isMobile = false,
    required this.maxW,
    required this.maxH,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Card sizes are passed in via maxW / maxH (desktop/tablet/mobile)
    final double cardW = maxW;
    final double cardH = maxH;

    final actionSize = isMobile ? 48.w : 64.0;

    return SizedBox(
      width: cardW,
      height: cardH + (actionSize * 0.8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: cardW,
            height: cardH,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isMobile ? 16.r : 20),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withValues(alpha: 0.14),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isMobile ? 16.r : 20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    profile.images.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey.shade300),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.82),
                        ],
                        stops: const [0.52, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: isMobile ? 12.w : 18,
                    right: isMobile ? 12.w : 18,
                    bottom: isMobile ? 12.h : 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              profile.name,
                              style: TextStyle(
                                fontSize: isMobile ? 20.sp : 32.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: isMobile ? 8.w : 12),
                            Text(
                              '${profile.age}',
                              style: TextStyle(
                                fontSize: isMobile ? 16.sp : 28.sp,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 8.h : 12),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: kAccentColor,
                              size: isMobile ? 14.sp : 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              profile.distance,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: isMobile ? 12.sp : 14.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 8.h : 12),
                        Text(
                          profile.bio,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: isMobile ? 12.sp : 15.sp,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: -(actionSize * 0.6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionButton(
                  Icons.close_rounded,
                  kPrimaryColor,
                  onDislike,
                  size: actionSize,
                ),
                SizedBox(width: isMobile ? 12.w : 24),
                _actionButton(
                  Icons.star_rounded,
                  kAccentColor,
                  () {},
                  size: isMobile ? (actionSize * 0.9) : 56,
                ),
                SizedBox(width: isMobile ? 12.w : 24),
                _actionButton(
                  Icons.favorite_rounded,
                  kSecondaryColor,
                  onLike,
                  size: actionSize,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    Color color,
    VoidCallback onTap, {
    double size = 64,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}

// -------------------- Profile model --------------------
class ProfileCard {
  final String name;
  final int age;
  final String bio;
  final String distance;
  final List<String> images;

  ProfileCard({
    required this.name,
    required this.age,
    required this.bio,
    required this.distance,
    required this.images,
  });
}
