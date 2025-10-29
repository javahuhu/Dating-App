// main.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';

// 🎨 Color Palette
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

final profilesProvider = Provider<List<ProfileCard>>((ref) => [
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
        bio: 'Foodie | Travel addict ✈️ | Dog lover | Always up for new experiences',
        distance: '3 miles away',
        images: [
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=1200',
        ],
      ),
    ]);

// -------------------- App --------------------
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

// -------------------- Home --------------------
class KismetHomePage extends HookConsumerWidget {
  const KismetHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final currentProfileIndex = ref.watch(currentProfileIndexProvider);
    final profiles = ref.watch(profilesProvider);

    // Responsive clamps for desktop
    final screenWidth = MediaQuery.of(context).size.width;
    final clampedWidth = screenWidth.clamp(1024.0, 2560.0);
    final navWidth = (clampedWidth * 0.18).clamp(220.0, 340.0);
    final contentWidth = clampedWidth - navWidth;
    final horizontalPadding = (contentWidth * 0.08).clamp(40.0, 140.0);

    void onNavTap(int idx) => ref.read(selectedIndexProvider.notifier).state = idx;

    void swipeCard(bool liked) {
      final notifier = ref.read(currentProfileIndexProvider.notifier);
      final next = notifier.state < profiles.length - 1 ? notifier.state + 1 : 0;
      notifier.state = next;
    }

    return Scaffold(
      body: Center(
        // center and constrain whole layout to maxWidth 2560
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 2560),
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
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                            child: const Icon(Icons.favorite_rounded, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Text('Kismet',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: headingViolet)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
                    _navItem(Icons.explore_rounded, 'Discover', 0, selectedIndex, onNavTap),
                    _navItem(Icons.favorite_rounded, 'Matches', 1, selectedIndex, onNavTap),
                    _navItem(Icons.chat_bubble_rounded, 'Messages', 2, selectedIndex, onNavTap),
                    _navItem(Icons.person_rounded, 'Profile', 3, selectedIndex, onNavTap),
                    _navItem(Icons.settings_rounded, 'Settings', 4, selectedIndex, onNavTap),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(
                              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('You',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600, color: kTitleColor)),
                              Text('View Profile',
                                  style: TextStyle(fontSize: 12, color: subtextViolet)),
                            ],
                          ),
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
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 40),
                  child: selectedIndex == 0
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Discover',
                                style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: headingViolet)),
                            const SizedBox(height: 8),
                            Text('Find your perfect match',
                                style: TextStyle(fontSize: 16, color: subtextViolet)),
                            const SizedBox(height: 40),
                            // AnimatedSwitcher for profile card transitions (fade + slide)
                            Expanded(
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 600),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  transitionBuilder: (child, animation) {
                                    // combine fade + slide
                                    final offsetAnimation = Tween<Offset>(
                                      begin: const Offset(0.3, 0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(position: offsetAnimation, child: child),
                                    );
                                  },
                                  child: _ProfileCardWrapper(
                                    key: ValueKey<int>(currentProfileIndex),
                                    profile: profiles[currentProfileIndex],
                                    onLike: () => swipeCard(true),
                                    onDislike: () => swipeCard(false),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Text(
                            _getPageTitle(selectedIndex),
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: headingViolet),
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
  Widget _navItem(IconData icon, String label, int index, int selected, void Function(int) onTap) {
    final isSelected = index == selected;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? kPrimaryColor.withValues(alpha: .3) : Colors.transparent, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? kPrimaryColor : kBodyTextColor, size: 24),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? kPrimaryColor : kBodyTextColor)),
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

  const _ProfileCardWrapper({
    required Key key,
    required this.profile,
    required this.onLike,
    required this.onDislike,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Keep card size clamped so it doesn't grow too large on huge screens
    final maxW = 600.0;
    final maxH = 700.0;

    return SizedBox(
      width: maxW,
      height: maxH + 40, // extra space for action buttons
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Card container
          Container(
            width: maxW,
            height: maxH,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: kPrimaryColor.withValues(alpha: 0.15), blurRadius: 40, offset: const Offset(0, 10))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(profile.images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300)),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: .8)], stops: const [0.5, 1.0]),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(profile.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(width: 8),
                          Text('${profile.age}', style: const TextStyle(fontSize: 28, color: Colors.white)),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [Icon(Icons.location_on, color: kAccentColor, size: 16), const SizedBox(width: 4), Text(profile.distance, style: const TextStyle(color: Colors.white, fontSize: 14))]),
                        const SizedBox(height: 12),
                        Text(profile.bio, style: TextStyle(color: Colors.white.withValues(alpha:   0.9), fontSize: 15, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action buttons (overlap)
          Positioned(
            left: 0,
            right: 0,
            bottom: -30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionButton(Icons.close_rounded, kPrimaryColor, onDislike),
                const SizedBox(width: 24),
                _actionButton(Icons.star_rounded, kAccentColor, () {}, size: 56),
                const SizedBox(width: 24),
                _actionButton(Icons.favorite_rounded, kSecondaryColor, onLike),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap, {double size = 64}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
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
