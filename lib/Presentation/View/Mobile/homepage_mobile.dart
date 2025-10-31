
import 'package:dating_app/Presentation/View/Desktop/match_page_desktop.dart';
import 'package:dating_app/Presentation/View/Desktop/message_page.dart';
import 'package:dating_app/Presentation/View/Desktop/visit_profile.dart';
import 'package:dating_app/Presentation/View/Mobile/match_page_mobile.dart';
import 'package:dating_app/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:dating_app/Data/API/discovery_api.dart';


// -------------------- Providers --------------------
final selectedIndexProvider = StateProvider<int>((ref) => 0);
final currentProfileIndexProvider = StateProvider<int>((ref) => 0);
final seenProfilesProvider = StateProvider<Set<String>>((ref) => <String>{});
final selectedPartnerIdProvider = StateProvider<String>((ref) => '');

// filters (kept in case you want to wire them to fetch)
final minAgeProvider = StateProvider<int>((ref) => 18);
final maxAgeProvider = StateProvider<int>((ref) => 50);
final maxDistanceProvider = StateProvider<int>((ref) => 50);
final filtersAppliedToggleProvider = StateProvider<int>((ref) => 0);

// Discovery API provider (used by logic)
final discoveryApiProvider = Provider<DiscoveryApi>((ref) {
  return DiscoveryApi(baseUrl: 'http://localhost:3000');
});

// --- Remote profiles provider (async) ---
final discoveryProfilesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final api = ref.read(discoveryApiProvider);
      // example default coords (Manila)
      const double lat = 14.5995;
      const double lon = 120.9842;

      final minAge = ref.read(minAgeProvider);
      final maxAge = ref.read(maxAgeProvider);
      final maxDistance = ref.read(maxDistanceProvider);

      final List<Map<String, dynamic>> raw = await api.fetchProfiles(
        lat: lat,
        lon: lon,
        page: 0,
        limit: 100,
        minAge: minAge,
        maxAge: maxAge,
        maxDistanceKm: maxDistance.toDouble(),
      );

      return raw;
    });

// --- Synchronous provider used by UI (keeps UI unchanged) ---
// This provider prefers remote data when available, otherwise falls back
// to your original static sample list so UI stays synchronous and unchanged.
final profilesProvider = Provider<List<ProfileCard>>((ref) {
  final async = ref.watch(discoveryProfilesProvider);

  // default static samples (your original data)
  final fallback = <ProfileCard>[
    ProfileCard(
      id: '',
      name: 'Sarah',
      age: 28,
      bio: 'Adventure seeker | Coffee enthusiast | Love hiking & photography',
      distance: '2 miles away',
      images: [
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=1200',
      ],
    ),
    ProfileCard(
      id: '',
      name: 'Emily',
      age: 26,
      bio: 'Artist & dreamer | Plant mom 🌿 | Looking for genuine connections',
      distance: '5 miles away',
      images: [
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=1200',
      ],
    ),
    ProfileCard(
      id: '',
      name: 'Jessica',
      age: 30,
      bio:
          'Foodie | Travel addict ✈️ | Dog lover | Always up for new experiences',
      distance: '3 miles away',
      images: [
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=1200',
      ],
    ),
  ];

  return async.maybeWhen(
    data: (list) {
      // map remote shape to ProfileCard (keep UI fields stable)
      return list.map<ProfileCard>((m) {
        final map = Map<String, dynamic>.from(m);

        // defensive extraction (various possible keys)
        final id = (map['_id'] ?? map['id'] ?? '').toString();
        final name =
            (map['name'] ??
                    map['fullName'] ??
                    map['displayName'] ??
                    map['username'] ??
                    '')
                .toString();
        int age = 0;
        if (map['age'] is int) {
          age = map['age'] as int;
        } else if (map['age'] != null) {
          age = int.tryParse(map['age'].toString()) ?? 0;
        }
        final bio = (map['bio'] ?? map['about'] ?? '').toString();
        String imageUrl = '';
        if (map['profilePicture'] is String &&
            (map['profilePicture'] as String).isNotEmpty) {
          imageUrl = map['profilePicture'] as String;
        } else if (map['profilePictureUrl'] is String &&
            (map['profilePictureUrl'] as String).isNotEmpty) {
          imageUrl = map['profilePictureUrl'] as String;
        } else if (map['images'] is List &&
            (map['images'] as List).isNotEmpty) {
          imageUrl = (map['images'] as List).first.toString();
        }
        if (imageUrl.isEmpty) {
          imageUrl = 'https://via.placeholder.com/800x1000.png?text=No+Image';
        }

        String distance = 'Unknown';
        if (map['distanceKm'] != null) {
          final d = map['distanceKm'];
          distance = d is num ? '${d.toString()} km away' : d.toString();
        } else if (map['distance'] != null) {
          distance = map['distance'].toString();
        }

        return ProfileCard(
          id: id,
          name: name.isEmpty ? 'No name' : name,
          age: age,
          bio: bio.isEmpty ? 'No bio' : bio,
          distance: distance,
          images: [imageUrl],
        );
      }).toList();
    },
    orElse: () => fallback,
  );
});

// -------------------- App --------------------
class HomepageMobile extends HookConsumerWidget {
  const HomepageMobile({super.key});

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

    final contentWidth = clampedWidth;
    final horizontalPadding = isDesktop
        ? (contentWidth * 0.08).clamp(40.0, 140.0)
        : isTablet
        ? (contentWidth * 0.06).clamp(20.0, 60.0)
        : 16.0.w; // mobile padding scaled

    void onNavTap(int idx) =>
        ref.read(selectedIndexProvider.notifier).state = idx;

    // compute safe index to avoid RangeError
    final int safeIndex = (() {
      if (profiles.isEmpty) return 0;
      if (currentProfileIndex < 0) return 0;
      if (currentProfileIndex >= profiles.length) return profiles.length - 1;
      return currentProfileIndex;
    })();

    // NEW: swipeCard runs API calls (like/skip) in background while advancing UI
    void swipeCard(bool liked) {
      final notifier = ref.read(currentProfileIndexProvider.notifier);
      final profilesList = ref.read(profilesProvider);
      final idx = notifier.state;

      // compute next index safely
      final next = profilesList.isEmpty
          ? 0
          : (notifier.state < profilesList.length - 1 ? notifier.state + 1 : 0);
      notifier.state = next;

      // mark seen locally immediately (best-effort)
      if (profilesList.isNotEmpty) {
        final profile = profilesList[safeIndex];
        final seenNotifier = ref.read(seenProfilesProvider.notifier);
        if (profile.id.isNotEmpty) {
          seenNotifier.state = {...seenNotifier.state, profile.id};
        }

        // fire-and-forget api call
        final api = ref.read(discoveryApiProvider);
        if (liked) {
          api
              .like(profile.id)
              .then((res) {
                final matched =
                    res != null &&
                    (res['matched'] == true || res['matched'] == 'true');
                if (matched) {
                  // navigate to Matches tab
                  ref.read(selectedIndexProvider.notifier).state = 1;
                }
              })
              .catchError((_) {
                // ignore for now - UI already updated
              });
        } else {
          api.skip(profile.id).catchError((_) {
            // ignore
          });
        }
      } else {
        // nothing to do if list empty
      }
    }

    void swipeCardLikePress() => swipeCard(true);
    void swipeCardDislikePress() => swipeCard(false);

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

    // Drawer widget (reused)
    Widget buildAppDrawer() {
      return Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
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
                    SizedBox(width: 12.w),
                    Text(
                      'Kismet',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: headingViolet,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              _drawerNavItem(
                icon: Icons.explore_rounded,
                label: 'Discover',
                index: 0,
                selected: selectedIndex,
                onTap: (i) {
                  onNavTap(i);
                  Navigator.of(context).maybePop();
                },
              ),
              _drawerNavItem(
                icon: Icons.favorite_rounded,
                label: 'Matches',
                index: 1,
                selected: selectedIndex,
                onTap: (i) {
                  onNavTap(i);
                  Navigator.of(context).maybePop();
                },
              ),
              _drawerNavItem(
                icon: Icons.chat_bubble_rounded,
                label: 'Messages',
                index: 2,
                selected: selectedIndex,
                onTap: (i) {
                  onNavTap(i);
                  Navigator.of(context).maybePop();
                },
              ),
             
              
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: const NetworkImage(
                        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
                      ),
                    ),
                    SizedBox(width: 12.w),
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
                        GestureDetector(
                          onTap: () {
                            context.go('/profile');
                          },
                          child: Text(
                            'View Profile',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: subtextViolet,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      // AppBar with menu icon to open drawer
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kBackgroundColor,
        title: Text(
          _getPageTitle(selectedIndex),
          style: TextStyle(
            color: headingViolet,
            fontSize: isMobile ? 18.sp : (isTablet ? 22.sp : 28.sp),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Builder(
          builder: (ctx) {
            return IconButton(
              icon: Icon(
                Icons.menu_rounded,
                color: kBodyTextColor,
                size: isMobile ? 22.sp : 26,
              ),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            );
          },
        ),
        actions: [
          if (!isMobile)
            Padding(
              padding: EdgeInsets.only(right: 18.0),
              child: Center(
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: const NetworkImage(
                    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
                  ),
                ),
              ),
            ),
        ],
      ),
      drawer: buildAppDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 2560.0 : (isTablet ? 1100.0 : 420.0),
          ),
          child: Container(
            width: contentWidth,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: isMobile ? 18.h : 24,
            ),
            child: selectedIndex == 0
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title area kept (you may remove duplicate title if prefer)
                      if (!isDesktop) ...[
                        Text(
                          'Find your perfect match',
                          style: TextStyle(
                            fontSize: isMobile ? 12.sp : 16.sp,
                            color: subtextViolet,
                          ),
                        ),
                        SizedBox(height: 12.h),
                      ],
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
                            // Use safeIndex for key and profile selection
                            child: profiles.isEmpty
                                ? _NoProfilesPlaceholder(
                                    key: const ValueKey('no_profiles'),
                                  )
                                : _ProfileCardWrapper(
                                    key: ValueKey<int>(safeIndex),
                                    profile: profiles[safeIndex],
                                    onLike: () {
                                      swipeCardLikePress();
                                    },
                                    onDislike: () {
                                      swipeCardDislikePress();
                                    },
                                    isMobile: isMobile,
                                    maxW: cardMaxWidth,
                                    maxH: cardMaxHeight,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  )
                : _nonDiscoverBody(selectedIndex, ref),
          ),
        ),
      ),
    );
  }

  Widget _nonDiscoverBody(int selectedIndex, WidgetRef ref) {
    switch (selectedIndex) {
      case 1:
        return MatchPageMobile(
          onNavigateToMatches: () {
            ref.read(selectedIndexProvider.notifier).state = 1;
          },
        );
      case 2:
        return MessagesPageDesktop(
          onOpenProfile: (String partnerId) {
            ref.read(selectedPartnerIdProvider.notifier).state = partnerId;
            ref.read(selectedIndexProvider.notifier).state = 3;
          },
          onOpenChat: (String partnerId) {
            ref.read(selectedPartnerIdProvider.notifier).state = partnerId;
            ref.read(selectedIndexProvider.notifier).state = 2;
          },
        );
      
      default:
        return Center(child: Text('Unknown page'));
    }
  }

  Widget _drawerNavItem({
    required IconData icon,
    required String label,
    required int index,
    required int selected,
    required void Function(int) onTap,
  }) {
    final bool isSelected = index == selected;
    return ListTile(
      leading: Icon(icon, color: isSelected ? kPrimaryColor : kBodyTextColor),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? kPrimaryColor : kBodyTextColor,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onTap: () => onTap(index),
    );
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 1:
        return 'Matches';
      case 2:
        return 'Messages';
      default:
        return 'Discover';
    }
  }
}

// simple placeholder when profiles is empty (keeps UI layout)
class _NoProfilesPlaceholder extends StatelessWidget {
  const _NoProfilesPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 420,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: kPrimaryColor.withOpacity(0.04),
          border: Border.all(color: kPrimaryColor.withOpacity(0.08)),
        ),
        child: Center(
          child: Text(
            'No profiles available',
            style: TextStyle(color: kBodyTextColor, fontSize: 16),
          ),
        ),
      ),
    );
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
// NOTE: added `id` (optional) so API logic can use it; default to empty string
// UI code is unchanged (fields used by UI remain the same).
class ProfileCard {
  final String id;
  final String name;
  final int age;
  final String bio;
  final String distance;
  final List<String> images;

  ProfileCard({
    this.id = '',
    required this.name,
    required this.age,
    required this.bio,
    required this.distance,
    required this.images,
  });
}
