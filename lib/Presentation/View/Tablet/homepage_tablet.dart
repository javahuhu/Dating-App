// main.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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

class KismetApp extends HookConsumerWidget {
  const KismetApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Kismet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: kBackgroundColor,
        fontFamily: 'SF Pro Display',
      ),
      home: const KismetHomePage(),
    );
  }
}

class KismetHomePage extends HookConsumerWidget {
  const KismetHomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final currentProfileIndex = ref.watch(currentProfileIndexProvider);
    final profiles = ref.watch(profilesProvider);

    // Responsive breakpoints:
    // - Tablet: screenWidth <= 1100 -> clamp max width to 1100
    // - Desktop: screenWidth > 1100 -> clamp 1024..2560
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth <= 1100.0;

    final clampedWidth = isTablet
        ? screenWidth.clamp(720.0, 1100.0) // tablet range (min comfortable 720)
        : screenWidth.clamp(1024.0, 2560.0); // desktop range

    // Sidebar and paddings adapt for tablet vs desktop
    final navWidth = isTablet
        ? (clampedWidth * 0.18).clamp(
            160.0,
            260.0,
          ) // narrower sidebar on tablet
        : (clampedWidth * 0.18).clamp(220.0, 340.0);

    final contentWidth = clampedWidth - navWidth;
    final horizontalPadding = isTablet
        ? (contentWidth * 0.06).clamp(20.0, 60.0) // smaller paddings on tablet
        : (contentWidth * 0.08).clamp(40.0, 140.0);

    void onNavTap(int idx) =>
        ref.read(selectedIndexProvider.notifier).state = idx;

    void swipeCard(bool liked) {
      final notifier = ref.read(currentProfileIndexProvider.notifier);
      final next = notifier.state < profiles.length - 1
          ? notifier.state + 1
          : 0;
      notifier.state = next;
    }

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 1100.0 : 2560.0),
          child: Row(
            children: [
              // Sidebar
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
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
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
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Kismet',
                              style: TextStyle(
                                fontSize: isTablet ? 22 : 28,
                                fontWeight: FontWeight.bold,
                                color: headingViolet,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isTablet ? 28 : 50),
                    _navItem(
                      Icons.explore_rounded,
                      'Discover',
                      0,
                      selectedIndex,
                      onNavTap,
                      isTablet: isTablet,
                    ),
                    _navItem(
                      Icons.favorite_rounded,
                      'Matches',
                      1,
                      selectedIndex,
                      onNavTap,
                      isTablet: isTablet,
                    ),
                    _navItem(
                      Icons.chat_bubble_rounded,
                      'Messages',
                      2,
                      selectedIndex,
                      onNavTap,
                      isTablet: isTablet,
                    ),
                    _navItem(
                      Icons.person_rounded,
                      'Profile',
                      3,
                      selectedIndex,
                      onNavTap,
                      isTablet: isTablet,
                    ),
                    _navItem(
                      Icons.settings_rounded,
                      'Settings',
                      4,
                      selectedIndex,
                      onNavTap,
                      isTablet: isTablet,
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.all(isTablet ? 16 : 24),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: isTablet ? 18 : 20,
                            backgroundImage: const NetworkImage(
                              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
                            ),
                          ),
                          SizedBox(width: isTablet ? 10 : 12),
                          if (!isTablet)
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
                                    fontSize: 12,
                                    color: subtextViolet,
                                  ),
                                ),
                              ],
                            )
                          else
                            // For tighter tablet bottom row, show only name
                            Flexible(
                              child: Text(
                                'You',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: kTitleColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main content area
              Expanded(
                child: Container(
                  width: contentWidth,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isTablet ? 24 : 40,
                  ),
                  child: selectedIndex == 0
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Discover',
                              style: TextStyle(
                                fontSize: isTablet ? 28 : 36,
                                fontWeight: FontWeight.bold,
                                color: headingViolet,
                              ),
                            ),
                            SizedBox(height: isTablet ? 6 : 8),
                            Text(
                              'Find your perfect match',
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 16,
                                color: subtextViolet,
                              ),
                            ),
                            SizedBox(height: isTablet ? 20 : 40),
                            Expanded(
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 600),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  transitionBuilder: (child, animation) {
                                    final offsetAnimation =
                                        Tween<Offset>(
                                          begin: const Offset(0.3, 0),
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
                                    isTablet: isTablet,
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
                              fontSize: isTablet ? 22 : 32,
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

  Widget _navItem(
    IconData icon,
    String label,
    int index,
    int selected,
    void Function(int) onTap, {
    required bool isTablet,
  }) {
    final isSelected = index == selected;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isTablet ? 6 : 8,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isTablet ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? kPrimaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? kPrimaryColor.withValues(alpha: 0.25)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? kPrimaryColor : kBodyTextColor,
              size: isTablet ? 20 : 24,
            ),
            SizedBox(width: isTablet ? 12 : 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? kPrimaryColor : kBodyTextColor,
                ),
                overflow: TextOverflow.ellipsis,
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

/// ProfileCard wrapper used by AnimatedSwitcher
class _ProfileCardWrapper extends StatelessWidget {
  final ProfileCard profile;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final bool isTablet;

  const _ProfileCardWrapper({
    required Key key,
    required this.profile,
    required this.onLike,
    required this.onDislike,
    this.isTablet = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Smaller card on tablet
    final maxW = isTablet ? 480.0 : 600.0;
    final maxH = isTablet ? 560.0 : 700.0;

    return SizedBox(
      width: maxW,
      height: maxH + 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: maxW,
            height: maxH,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withValues(alpha: 0.14),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
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
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              profile.name,
                              style: TextStyle(
                                fontSize: isTablet ? 26 : 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: isTablet ? 8 : 12),
                            Text(
                              '${profile.age}',
                              style: TextStyle(
                                fontSize: isTablet ? 20 : 28,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isTablet ? 8 : 12),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: kAccentColor,
                              size: isTablet ? 14 : 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              profile.distance,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: isTablet ? 12 : 14,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isTablet ? 10 : 12),
                        Text(
                          profile.bio,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: isTablet ? 13 : 15,
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
          Positioned(
            left: 0,
            right: 0,
            bottom: -28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionButton(
                  Icons.close_rounded,
                  kPrimaryColor,
                  onDislike,
                  size: isTablet ? 56 : 64,
                ),
                SizedBox(width: isTablet ? 18 : 24),
                _actionButton(
                  Icons.star_rounded,
                  kAccentColor,
                  () {},
                  size: isTablet ? 50 : 56,
                ),
                SizedBox(width: isTablet ? 18 : 24),
                _actionButton(
                  Icons.favorite_rounded,
                  kSecondaryColor,
                  onLike,
                  size: isTablet ? 56 : 64,
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

/// Profile model
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
