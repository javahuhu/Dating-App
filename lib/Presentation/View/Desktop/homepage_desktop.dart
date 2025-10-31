// lib/presentation/pages/desktop_homepage.dart
import 'dart:convert';
import 'dart:math';
import 'package:dating_app/Data/Models/userinformation_model.dart';
import 'package:dating_app/Presentation/View/Desktop/match_page_desktop.dart';
import 'package:dating_app/Presentation/View/Desktop/message_page.dart';
import 'package:dating_app/Presentation/View/Desktop/visit_profile.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dating_app/Data/API/discovery_api.dart';
import 'package:dating_app/core/theme/colors.dart';
import 'package:hooks_riverpod/legacy.dart';

// ---------------- Providers ----------------
final selectedIndexProvider = StateProvider<int>((ref) => 0);
final currentProfileIndexProvider = StateProvider<int>((ref) => 0);
final seenProfilesProvider = StateProvider<Set<String>>((ref) => <String>{});
final selectedPartnerIdProvider = StateProvider<String>((ref) => '');
final selectedUserProvider = StateProvider<UserinformationModel?>(
  (ref) => null,
);

// filters
final minAgeProvider = StateProvider<int>((ref) => 18);
final maxAgeProvider = StateProvider<int>((ref) => 50);
final maxDistanceProvider = StateProvider<int>((ref) => 50);
final filtersAppliedToggleProvider = StateProvider<int>((ref) => 0);

// Single provider for discovery API (use same provider across app)
final discoveryApiProvider = Provider<DiscoveryApi>((ref) {
  return DiscoveryApi(baseUrl: 'http://localhost:3000');
});

// provider that fetches discovery profiles and maps into local ProfileCard model
final discoveryProfilesProvider = FutureProvider.autoDispose<List<ProfileCard>>((
  ref,
) async {
  final minAge = ref.watch(minAgeProvider);
  final maxAge = ref.watch(maxAgeProvider);
  final maxDistance = ref.watch(maxDistanceProvider);
  ref.watch(filtersAppliedToggleProvider); // to refetch when filters change

  // example default coords (Manila) - replace with user's real coordinates if available
  const double lat = 14.5995;
  const double lon = 120.9842;

  final api = ref.read(discoveryApiProvider);
  final List<Map<String, dynamic>> raw = await api.fetchProfiles(
    lat: lat,
    lon: lon,
    page: 0,
    limit: 100,
    minAge: minAge,
    maxAge: maxAge,
    maxDistanceKm: maxDistance.toDouble(),
  );

  return raw.map<ProfileCard>((m) {
    final Map<String, dynamic> map = <String, dynamic>{}..addAll(m);
    if (map.containsKey('user') && map['user'] is Map) {
      map.addAll(Map<String, dynamic>.from(map['user'] as Map));
    }

    final id = (map['_id'] ?? map['id'] ?? '').toString();
    final name = (map['name'] ?? map['fullName'] ?? map['displayName'] ?? '')
        .toString()
        .trim();
    int age = 0;
    if (map['age'] is int) {
      age = map['age'] as int;
    } else if (map['age'] != null) {
      age = int.tryParse(map['age'].toString()) ?? 0;
    }
    final bio = (map['bio'] ?? map['about'] ?? '').toString().trim();

    String distance = 'Unknown';
    if (map['distanceKm'] != null) {
      final d = map['distanceKm'];
      distance = d is num ? '${d.toString()} km away' : d.toString();
    } else if (map['distance'] != null) {
      distance = map['distance'].toString();
    }

    String interestsDisplay = 'No info';
    final rawTags = map['tags'] ?? map['interests'] ?? map['tagList'];
    if (rawTags != null) {
      if (rawTags is List && rawTags.isNotEmpty) {
        interestsDisplay = rawTags.map((e) => e.toString()).join(', ');
      } else if (rawTags is String && rawTags.trim().isNotEmpty) {
        final s = rawTags.trim();
        try {
          final decoded = jsonDecode(s);
          if (decoded is List) {
            interestsDisplay = decoded.map((e) => e.toString()).join(', ');
          } else {
            interestsDisplay = s;
          }
        } catch (_) {
          interestsDisplay = s;
        }
      }
    }

    String imageUrl = '';
    if (map['profilePicture'] is String &&
        (map['profilePicture'] as String).trim().isNotEmpty) {
      imageUrl = map['profilePicture'] as String;
    } else if (map['profilePictureUrl'] is String &&
        (map['profilePictureUrl'] as String).trim().isNotEmpty) {
      imageUrl = map['profilePictureUrl'] as String;
    } else if (map['images'] is List && (map['images'] as List).isNotEmpty) {
      imageUrl = (map['images'] as List).first.toString();
    } else if (map['photos'] is List && (map['photos'] as List).isNotEmpty) {
      imageUrl = (map['photos'] as List).first.toString();
    }

    if (imageUrl.isEmpty) {
      imageUrl = 'https://via.placeholder.com/800x1000.png?text=No+Image';
    }

    return ProfileCard(
      id: id,
      name: name.isEmpty ? 'No name' : name,
      age: age,
      bio: bio.isEmpty ? 'No bio' : bio,
      distance: distance,
      images: [imageUrl],
      interests: interestsDisplay,
    );
  }).toList();
});

// -------------------- Home Widget --------------------
class DesktopHomePage extends HookConsumerWidget {
  const DesktopHomePage({super.key});

  void _showProfileDialog(BuildContext context, ProfileCard profile) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (context) => WillPopScope(
        onWillPop: () async {
          // Prevent back button from closing the dialog
          return false;
        },
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.4,
            height: MediaQuery.of(context).size.height * 0.95,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header with close button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, size: 20),
                        ),
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),

                // Profile content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Profile Header with Image
                        _buildDialogProfileHeader(profile),

                        // Bio Section
                        _buildBioSection(profile),

                        // Basic Info Section
                        _buildBasicInfoSection(profile),

                        // Personality Section
                        _buildPersonalitySection(),

                        // Motivations Section
                        _buildMotivationsSection(),

                        // Frustrations Section
                        _buildFrustrationsSection(),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Dialog Profile Header
  Widget _buildDialogProfileHeader(ProfileCard profile) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        image: DecorationImage(
          image: NetworkImage(profile.images.first),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
          ),
        ),
        child: Stack(
          children: [
            // Profile info at bottom
            Positioned(
              left: 30,
              right: 30,
              bottom: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.white.withOpacity(0.8),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        profile.distance,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
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

  // Bio Section
  Widget _buildBioSection(ProfileCard profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio Title
          const Text(
            'Bio',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile.bio,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),

        
     
       
        ],
      ),
    );
  }

  // Basic Info Section
  Widget _buildBasicInfoSection(ProfileCard profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // Info Table
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.5),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  children: [
                    _buildTableHeader('Age:'),
                    _buildTableCell('${profile.age}'),
                    _buildTableHeader('Status:'),
                    _buildTableCell('Single'),
                  ],
                ),
                TableRow(
                  children: [
                    _buildTableHeader('Location:'),
                    _buildTableCell('No information'),
                    _buildTableHeader('Archetype:'),
                    _buildTableCell('No information'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Time and Date Section
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '**Time:**',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildTag('Office'),
                        _buildTag('News'),
                        _buildTag('Phone'),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '**Date:**',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: [_buildTag('Country')]),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Container(height: 1, color: Colors.grey.shade300),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: kPrimaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Personality Section
  Widget _buildPersonalitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personality',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hemebody',
            style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 12),

          const Text(
            'Answer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),

          // Personality Traits Table
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  children: [
                    _buildPersonalityTrait('Planner'),
                    const SizedBox(),
                    _buildPersonalityTrait('Spontaneous'),
                  ],
                ),
                TableRow(
                  children: [
                    _buildPersonalityTrait('Reserved'),
                    const SizedBox(),
                    _buildPersonalityTrait('Ongoing'),
                  ],
                ),
                TableRow(
                  children: [
                    _buildPersonalityTrait('Serious'),
                    const SizedBox(),
                    _buildPersonalityTrait('Playful'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Container(height: 1, color: Colors.grey.shade300),
        ],
      ),
    );
  }

  Widget _buildPersonalityTrait(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  // Motivations Section
  Widget _buildMotivationsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '# Motivations',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildMotivationTag('Adventure'),
              _buildMotivationTag('Romance'),
              _buildMotivationTag('Connection'),
              _buildMotivationTag('Fun'),
              _buildMotivationTag('Long-term'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: kSecondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kSecondaryColor.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: kSecondaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Frustrations Section
  Widget _buildFrustrationsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '**Frustrations**',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFrustrationItem('- Looking for genuine connections'),
              _buildFrustrationItem('- Tired of superficial conversations'),
              _buildFrustrationItem('- Want someone who shares my values'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrustrationItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade700,
          height: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final currentProfileIndex = ref.watch(currentProfileIndexProvider);
    final profilesAsync = ref.watch(discoveryProfilesProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final clampedWidth = screenWidth.clamp(1024.0, 2560.0);
    final navWidth = (clampedWidth * 0.18).clamp(220.0, 340.0);
    final contentWidth = clampedWidth - navWidth;
    final horizontalPadding = (contentWidth * 0.08).clamp(40.0, 140.0);

    // when nav tapped, just set index (no route navigation)
    void onNavTap(int idx) {
      ref.read(selectedIndexProvider.notifier).state = idx;
    }

    Future<bool> handleLike(
      BuildContext ctx,
      WidgetRef r,
      ProfileCard card,
    ) async {
      final api = r.read(discoveryApiProvider);
      try {
        final res = await api.like(card.id);
        final matched =
            res != null && (res['matched'] == true || res['matched'] == 'true');
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(matched ? 'It\'s a match!' : 'Liked')),
          );
        }
        if (matched) {
          // navigate to messages view inside the layout
          r.read(selectedIndexProvider.notifier).state = 2;
        }
        return matched;
      } catch (e) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(
            ctx,
          ).showSnackBar(SnackBar(content: Text('Like failed: $e')));
        }
        return false;
      }
    }

    Future<bool> handleSkip(
      BuildContext ctx,
      WidgetRef r,
      ProfileCard card,
    ) async {
      final api = r.read(discoveryApiProvider);
      try {
        await api.skip(card.id);
        if (ctx.mounted)
          ScaffoldMessenger.of(
            ctx,
          ).showSnackBar(const SnackBar(content: Text('Skipped')));
        return true;
      } catch (e) {
        if (ctx.mounted)
          ScaffoldMessenger.of(
            ctx,
          ).showSnackBar(SnackBar(content: Text('Skip failed: $e')));
        return false;
      }
    }

    // advance index safely (avoid out-of-range and clamp)
    void swipeAdvance(int visibleCount) {
      final notifier = ref.read(currentProfileIndexProvider.notifier);
      final current = notifier.state;
      final next = (current + 1) < visibleCount ? (current + 1) : 0;
      notifier.state = next;
    }

    final seen = ref.watch(seenProfilesProvider);

    return WillPopScope(
      onWillPop: () async {
        // Check if any dialog is open
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          // If dialog is open, don't allow going back
          return false;
        }
        // If no dialog is open, allow normal back navigation
        return true;
      },
      child: Scaffold(
        body: Center(
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
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Kismet',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: headingViolet,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),
                      _navItem(
                        Icons.explore_rounded,
                        'Discover',
                        0,
                        selectedIndex,
                        onNavTap,
                      ),
                      _navItem(
                        Icons.favorite_rounded,
                        'Matches',
                        1,
                        selectedIndex,
                        onNavTap,
                      ),
                      _navItem(
                        Icons.chat_bubble_rounded,
                        'Messages',
                        2,
                        selectedIndex,
                        onNavTap,
                      ),
                      
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
                                Text(
                                  'You',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: kTitleColor,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.push('/profile'),
                                  child: Text(
                                    'View Profile',
                                    style: TextStyle(
                                      fontSize: 12,
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

                // ---------- Main Content ----------
                Expanded(
                  child: Container(
                    width: contentWidth,
                    padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    child: Builder(
                      builder: (context) {
                        switch (ref.watch(selectedIndexProvider)) {
                          case 0:
                            // Discover
                            return Padding(
                              padding: EdgeInsets.all(50),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        'Discover',
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: headingViolet,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Find your perfect match',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: subtextViolet,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),
                                  const _SimpleFiltersCard(),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: Center(
                                      child: profilesAsync.when(
                                        data: (profiles) {
                                          // filter out locally seen profiles
                                          final unseen = profiles
                                              .where(
                                                (p) => !seen.contains(p.id),
                                              )
                                              .toList();
                                          if (unseen.isEmpty) {
                                            return Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  'No more profiles matching your filters.',
                                                  style: TextStyle(
                                                    fontSize: 25,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                              ],
                                            );
                                          }

                                          final len = unseen.length;
                                          // safe index computation
                                          final idx = (currentProfileIndex < 0)
                                              ? 0
                                              : (currentProfileIndex >= len
                                                    ? len - 1
                                                    : currentProfileIndex);

                                          return SizedBox(
                                            width: 640,
                                            height: 820,
                                            child: Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                for (
                                                  int i = min(idx + 3, len - 1);
                                                  i >= idx;
                                                  i--
                                                )
                                                  Positioned.fill(
                                                    child: Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: i == idx
                                                          ? DraggableProfileCard(
                                                              profile:
                                                                  unseen[i],
                                                              onSwipeLeft: () async {
                                                                final profile =
                                                                    unseen[i];
                                                                final id =
                                                                    profile.id;
                                                                // mark seen locally immediately
                                                                final seenNotifier =
                                                                    ref.read(
                                                                      seenProfilesProvider
                                                                          .notifier,
                                                                    );
                                                                seenNotifier
                                                                    .state = {
                                                                  ...seenNotifier
                                                                      .state,
                                                                  id,
                                                                };
                                                                // advance UI right away
                                                                swipeAdvance(
                                                                  len,
                                                                );
                                                                // background API call
                                                                handleSkip(
                                                                  context,
                                                                  ref,
                                                                  profile,
                                                                ).then((ok) {
                                                                  // optionally handle failure (e.g., show snackbar) - already handled inside handleSkip
                                                                });
                                                              },
                                                              onSwipeRight: () async {
                                                                final profile =
                                                                    unseen[i];
                                                                final id =
                                                                    profile.id;
                                                                final seenNotifier =
                                                                    ref.read(
                                                                      seenProfilesProvider
                                                                          .notifier,
                                                                    );
                                                                seenNotifier
                                                                    .state = {
                                                                  ...seenNotifier
                                                                      .state,
                                                                  id,
                                                                };
                                                                swipeAdvance(
                                                                  len,
                                                                );
                                                                // call like; handle navigation inside handleLike when match happens
                                                                handleLike(
                                                                  context,
                                                                  ref,
                                                                  profile,
                                                                ).then((
                                                                  matched,
                                                                ) {
                                                                  // nothing else needed here
                                                                });
                                                              },
                                                              onShowProfile: () {
                                                                _showProfileDialog(
                                                                  context,
                                                                  unseen[i],
                                                                );
                                                              },
                                                            )
                                                          : Transform.scale(
                                                              scale:
                                                                  1 -
                                                                  ((i - idx) *
                                                                      0.03),
                                                              child: Opacity(
                                                                opacity:
                                                                    1 -
                                                                    ((i - idx) *
                                                                        0.12),
                                                                child: _ProfileStaticCard(
                                                                  profile:
                                                                      unseen[i],
                                                                ),
                                                              ),
                                                            ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                        loading: () =>
                                            const CircularProgressIndicator(),
                                        error: (err, st) => Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.error_outline,
                                              size: 48,
                                              color: Colors.red,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Failed to load profiles: ${err.toString()}',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );

                          case 1:
                            return MessagesPageDesktop(
                              onOpenProfile: (String partnerId) {
                                // store selected partner id then go to Profile page (3)
                                ref
                                        .read(
                                          selectedPartnerIdProvider.notifier,
                                        )
                                        .state =
                                    partnerId;
                                ref.read(selectedIndexProvider.notifier).state =
                                    3;
                              },
                              onOpenChat: (String partnerId) {
                                // store selected partner id then go to Chat/Match page (2)
                                ref
                                        .read(
                                          selectedPartnerIdProvider.notifier,
                                        )
                                        .state =
                                    partnerId;
                                ref.read(selectedIndexProvider.notifier).state =
                                    2;
                              },
                            );

                          case 2:
                            // Messages — render inside main content (sidebar stays)
                            return MatchPageDesktop(
                              onNavigateToMatches: () {
                                ref.read(selectedIndexProvider.notifier).state =
                                    2;
                              },

                              onOpenDsicovery: (String partnerId) {
                                // store selected partner id then go to Profile page (3)
                                ref
                                        .read(
                                          selectedPartnerIdProvider.notifier,
                                        )
                                        .state =
                                    partnerId;
                                ref.read(selectedIndexProvider.notifier).state =
                                    0;
                              },
                            );

                          case 3:
                            final selectedUser = ref.watch(
                              selectedUserProvider,
                            );
                            return ProfilePageVisitDesktop(
                              user: selectedUser,
                              onNavigateToMatches: () {
                                ref.read(selectedIndexProvider.notifier).state =
                                    2;
                              },
                            );

                          case 4:
                            return Center(
                              child: Text(
                                _getPageTitle(selectedIndex),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: headingViolet,
                                ),
                              ),
                            );

                          default:
                            return Center(
                              child: Text(
                                _getPageTitle(selectedIndex),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: headingViolet,
                                ),
                              ),
                            );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
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
    void Function(int) onTap,
  ) {
    final isSelected = index == selected;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? kPrimaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? kPrimaryColor.withValues(alpha: .3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? kPrimaryColor : kBodyTextColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
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

// -------------------- Simple Filters Card --------------------
class _SimpleFiltersCard extends HookConsumerWidget {
  const _SimpleFiltersCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minAge = ref.watch(minAgeProvider);
    final maxAge = ref.watch(maxAgeProvider);
    final maxDistance = ref.watch(maxDistanceProvider);

    final tempMin = useState(minAge);
    final tempMax = useState(maxAge);
    final tempDist = useState(maxDistance);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Age',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${tempMin.value}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      const Text('—'),
                      const SizedBox(width: 8),
                      Text(
                        '${tempMax.value}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Slider(
                    min: 18,
                    max: 80,
                    divisions: 62,
                    value: (tempMin.value + tempMax.value) / 2,
                    onChanged: (v) {
                      final center = v.round();
                      tempMin.value = max(18, center - 8);
                      tempMax.value = min(80, center + 8);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Distance (km)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${tempDist.value} km',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    min: 1,
                    max: 200,
                    divisions: 199,
                    value: tempDist.value.toDouble(),
                    onChanged: (v) => tempDist.value = v.round(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    ref.read(minAgeProvider.notifier).state = tempMin.value;
                    ref.read(maxAgeProvider.notifier).state = tempMax.value;
                    ref.read(maxDistanceProvider.notifier).state =
                        tempDist.value;
                    ref.read(filtersAppliedToggleProvider.notifier).state++;
                  },
                  child: const Text('Apply'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    tempMin.value = 18;
                    tempMax.value = 50;
                    tempDist.value = 50;
                    ref.read(minAgeProvider.notifier).state = 18;
                    ref.read(maxAgeProvider.notifier).state = 50;
                    ref.read(maxDistanceProvider.notifier).state = 50;
                    ref.read(filtersAppliedToggleProvider.notifier).state++;
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- Draggable Profile Card --------------------
class DraggableProfileCard extends StatefulWidget {
  final ProfileCard profile;
  final Future<void> Function()? onSwipeLeft;
  final Future<void> Function()? onSwipeRight;
  final VoidCallback? onShowProfile;

  const DraggableProfileCard({
    required this.profile,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onShowProfile,
    super.key,
  });

  @override
  State<DraggableProfileCard> createState() => _DraggableProfileCardState();
}

class _DraggableProfileCardState extends State<DraggableProfileCard>
    with SingleTickerProviderStateMixin {
  Offset _pos = Offset.zero;
  double _rotation = 0.0;
  late final AnimationController _anim;
  Animation<Offset>? _animOffset;
  Animation<double>? _animRot;
  bool _isDragging = false;
  bool _actionLocked = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails d) {
    if (_actionLocked) return;
    setState(() => _isDragging = true);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_actionLocked) return;
    setState(() {
      _pos += d.delta;
      _rotation = (_pos.dx / 300) * 0.12;
    });
  }

  Future<void> _onPanEnd(DragEndDetails d) async {
    if (_actionLocked) return;
    final vx = d.velocity.pixelsPerSecond.dx;
    final threshold = 150;
    final shouldLike = _pos.dx > threshold || vx > 800;
    final shouldSkip = _pos.dx < -threshold || vx < -800;

    setState(() => _isDragging = false);

    if (shouldLike) {
      setState(() => _actionLocked = true);
      final target = Offset(1000, _pos.dy + (vx / 3));
      _startAnimation(target, 1.0);
      await Future.delayed(const Duration(milliseconds: 180));
      if (widget.onSwipeRight != null) await widget.onSwipeRight!();
      setState(() => _actionLocked = false);
    } else if (shouldSkip) {
      setState(() => _actionLocked = true);
      final target = Offset(-1000, _pos.dy + (vx / 3));
      _startAnimation(target, -1.0);
      await Future.delayed(const Duration(milliseconds: 180));
      if (widget.onSwipeLeft != null) await widget.onSwipeLeft!();
      setState(() => _actionLocked = false);
    } else {
      _startAnimation(const Offset(0, 0), 0.0);
    }
  }

  void _startAnimation(Offset targetOffset, double targetRotSign) {
    _anim.reset();
    final beginOffset = _pos;
    final endOffset = targetOffset;
    final beginRot = _rotation;
    final endRot = targetRotSign * 0.6;

    _animOffset = Tween<Offset>(
      begin: beginOffset,
      end: endOffset,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _animRot = Tween<double>(
      begin: beginRot,
      end: endRot,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));

    _anim.addListener(() {
      setState(() {
        _pos = _animOffset?.value ?? _pos;
        _rotation = _animRot?.value ?? _rotation;
      });
    });
    _anim.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        if (_pos.dx.abs() <= 800) {
          setState(() {
            _pos = Offset.zero;
            _rotation = 0.0;
          });
        }
      }
    });
    _anim.forward();
  }

  @override
  Widget build(BuildContext context) {
    final width = 600.0;
    final height = 700.0;
    final likeOpacity = (_pos.dx > 0) ? (min(_pos.dx / 150, 1.0)) : 0.0;
    final nopeOpacity = (_pos.dx < 0) ? (min(-_pos.dx / 150, 1.0)) : 0.0;

    return Transform.translate(
      offset: _pos,
      child: Transform.rotate(
        angle: _rotation,
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: SizedBox(
            width: width,
            height: height + 60,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryColor.withValues(alpha: 0.15),
                        blurRadius: 40,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.profile.images.first,
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
                                Colors.black.withValues(alpha: .8),
                              ],
                              stops: const [0.5, 1.0],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 24,
                          right: 24,
                          bottom: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.profile.name,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${widget.profile.age}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: kAccentColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.profile.distance,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.profile.bio,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Interests: ${widget.profile.interests}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Like badge (left)
                Positioned(
                  top: 24,
                  left: 24,
                  child: Opacity(
                    opacity: likeOpacity,
                    child: Transform.rotate(
                      angle: -0.2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green, width: 3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'LIKE',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Skip badge (right)
                Positioned(
                  top: 24,
                  right: 24,
                  child: Opacity(
                    opacity: nopeOpacity,
                    child: Transform.rotate(
                      angle: 0.2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.redAccent, width: 3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SKIP',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Action buttons row (bottom)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -30,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _actionButton(
                        Icons.close_rounded,
                        kPrimaryColor,
                        () async {
                          if (_actionLocked) return;
                          setState(() => _actionLocked = true);
                          _startAnimation(const Offset(-1000, 0), -1.0);
                          await Future.delayed(
                            const Duration(milliseconds: 220),
                          );
                          if (widget.onSwipeLeft != null)
                            await widget.onSwipeLeft!();
                          setState(() => _actionLocked = false);
                        },
                      ),
                      const SizedBox(width: 24),
                      _actionButton(Icons.person_rounded, kAccentColor, () {
                        if (widget.onShowProfile != null) {
                          widget.onShowProfile!();
                        }
                      }),
                      const SizedBox(width: 24),
                      _actionButton(
                        Icons.favorite_rounded,
                        kSecondaryColor,
                        () async {
                          if (_actionLocked) return;
                          setState(() => _actionLocked = true);
                          _startAnimation(const Offset(1000, 0), 1.0);
                          await Future.delayed(
                            const Duration(milliseconds: 220),
                          );
                          if (widget.onSwipeRight != null)
                            await widget.onSwipeRight!();
                          setState(() => _actionLocked = false);
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
              color: color.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}

// -------------------- Static preview card --------------------
class _ProfileStaticCard extends StatelessWidget {
  final ProfileCard profile;
  const _ProfileStaticCard({required this.profile, super.key});
  @override
  Widget build(BuildContext context) {
    final maxW = 600.0;
    final maxH = 700.0;
    return SizedBox(
      width: maxW,
      height: maxH,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
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
                      Colors.black.withValues(alpha: .7),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          profile.name,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${profile.age}',
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: kAccentColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          profile.distance,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.bio,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Interests: ${profile.interests}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- Model --------------------
class ProfileCard {
  final String id;
  final String name;
  final int age;
  final String bio;
  final String distance;
  final List<String> images;
  final String interests;

  ProfileCard({
    required this.id,
    required this.name,
    required this.age,
    required this.bio,
    required this.distance,
    required this.images,
    required this.interests,
  });
}
