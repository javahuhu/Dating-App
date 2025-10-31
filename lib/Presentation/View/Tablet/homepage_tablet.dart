
import 'package:dating_app/Presentation/View/Tablet/match_page_tablet.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dating_app/Data/API/discovery_api.dart';
import 'package:dating_app/core/theme/colors.dart';
import 'package:dating_app/Presentation/View/Desktop/match_page_desktop.dart';
import 'package:dating_app/Presentation/View/Desktop/message_page.dart';
import 'package:hooks_riverpod/legacy.dart';

// ---------------- Providers ----------------
final selectedIndexProvider = StateProvider<int>((ref) => 0);
final currentProfileIndexProvider = StateProvider<int>((ref) => 0);
final seenProfilesProvider = StateProvider<Set<String>>((ref) => <String>{});
final selectedPartnerIdProvider = StateProvider<String>((ref) => '');

// filters
final minAgeProvider = StateProvider<int>((ref) => 18);
final maxAgeProvider = StateProvider<int>((ref) => 50);
final maxDistanceProvider = StateProvider<int>((ref) => 50);
final filtersAppliedToggleProvider = StateProvider<int>((ref) => 0);

// Discovery API Provider
final discoveryApiProvider = Provider<DiscoveryApi>((ref) {
  return DiscoveryApi(baseUrl: 'http://localhost:3000');
});

// provider that fetches discovery profiles
final discoveryProfilesProvider = FutureProvider.autoDispose<List<ProfileCard>>(
  (ref) async {
    final minAge = ref.watch(minAgeProvider);
    final maxAge = ref.watch(maxAgeProvider);
    final maxDistance = ref.watch(maxDistanceProvider);
    ref.watch(filtersAppliedToggleProvider);

    const double lat = 14.5995; // Manila
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
      final map = Map<String, dynamic>.from(m);
      final id = (map['_id'] ?? '').toString();
      final name = (map['name'] ?? 'Unknown').toString();
      final age = (map['age'] is int)
          ? map['age']
          : int.tryParse(map['age'].toString()) ?? 0;
      final bio = (map['bio'] ?? 'No bio').toString();
      final imageUrl =
          (map['profilePicture'] ?? 'https://via.placeholder.com/800x1000.png')
              .toString();

      return ProfileCard(
        id: id,
        name: name,
        age: age,
        bio: bio,
        distance: map['distance']?.toString() ?? 'Unknown',
        images: [imageUrl],
        interests: (map['tags'] ?? []).toString(),
      );
    }).toList();
  },
);

// -------------------- MAIN APP --------------------
void main() {
  runApp(const ProviderScope(child: TabletHomePage()));
}

class TabletHomePage extends HookConsumerWidget {
  const TabletHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final currentProfileIndex = ref.watch(currentProfileIndexProvider);
    final profilesAsync = ref.watch(discoveryProfilesProvider);
    final seen = ref.watch(seenProfilesProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final clampedWidth = screenWidth.clamp(720.0, 1100.0);
    final navWidth = (clampedWidth * 0.18).clamp(180.0, 240.0);
    final contentWidth = clampedWidth - navWidth;

    // ----------- LIKE -------------
    Future<void> handleLike(
      BuildContext ctx,
      WidgetRef r,
      ProfileCard card,
    ) async {
      final api = r.read(discoveryApiProvider);
      try {
        final res = await api.like(card.id);
        final matched =
            res != null && (res['matched'] == true || res['matched'] == 'true');
        if (matched) {
          ScaffoldMessenger.of(
            ctx,
          ).showSnackBar(const SnackBar(content: Text("🎉 It's a Match!")));
          r.read(selectedIndexProvider.notifier).state = 1; // Go to matches
        } else {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text("❤️ You liked this profile")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }

    // ----------- SKIP -------------
    Future<void> handleSkip(
      BuildContext ctx,
      WidgetRef r,
      ProfileCard card,
    ) async {
      final api = r.read(discoveryApiProvider);
      try {
        await api.skip(card.id);
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(const SnackBar(content: Text("⏭️ Skipped")));
      } catch (e) {
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(SnackBar(content: Text("Skip failed: $e")));
      }
    }

    // ----------- SWIPE NAVIGATION -------------
    void swipeAdvance(int visibleCount) {
      final notifier = ref.read(currentProfileIndexProvider.notifier);
      notifier.state = (notifier.state + 1) % visibleCount;
    }

    // -------------------- UI --------------------
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: navWidth,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.favorite, color: Colors.pink, size: 40),
                const SizedBox(height: 20),
                _navItem(
                  Icons.explore_rounded,
                  "Discover",
                  0,
                  selectedIndex,
                  ref,
                ),
                _navItem(
                  Icons.favorite_rounded,
                  "Matches",
                  1,
                  selectedIndex,
                  ref,
                ),
                _navItem(
                  Icons.chat_bubble_rounded,
                  "Messages",
                  2,
                  selectedIndex,
                  ref,
                ),
                
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Builder(
                builder: (context) {
                  switch (selectedIndex) {
                    case 0:
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Discover",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const _SimpleFiltersCard(),
                          const SizedBox(height: 20),
                          Expanded(
                            child: profilesAsync.when(
                              data: (profiles) {
                                final unseen = profiles
                                    .where((p) => !seen.contains(p.id))
                                    .toList();
                                if (unseen.isEmpty) {
                                  return const Center(
                                    child: Text("No profiles found"),
                                  );
                                }

                                final idx = currentProfileIndex.clamp(
                                  0,
                                  unseen.length - 1,
                                );
                                final card = unseen[idx];

                                return Center(
                                  child: _DraggableProfileCard(
                                    profile: card,
                                    onSwipeLeft: () async {
                                      final seenNotifier = ref.read(
                                        seenProfilesProvider.notifier,
                                      );
                                      seenNotifier.state = {
                                        ...seenNotifier.state,
                                        card.id,
                                      };
                                      swipeAdvance(unseen.length);
                                      await handleSkip(context, ref, card);
                                    },
                                    onSwipeRight: () async {
                                      final seenNotifier = ref.read(
                                        seenProfilesProvider.notifier,
                                      );
                                      seenNotifier.state = {
                                        ...seenNotifier.state,
                                        card.id,
                                      };
                                      swipeAdvance(unseen.length);
                                      await handleLike(context, ref, card);
                                    },
                                  ),
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (err, st) =>
                                  Center(child: Text("Error: $err")),
                            ),
                          ),
                        ],
                      );

                    case 1:
                      return MessagesPageDesktop(
                        onOpenProfile: (id) {
                          ref.read(selectedPartnerIdProvider.notifier).state =
                              id;
                          ref.read(selectedIndexProvider.notifier).state = 3;
                        },
                        onOpenChat: (id) {
                          ref.read(selectedPartnerIdProvider.notifier).state =
                              id;
                          ref.read(selectedIndexProvider.notifier).state = 2;
                        },
                      );

                    case 2:
                      return MatchPageTablet(
                        onNavigateToMatches: () {
                          ref.read(selectedIndexProvider.notifier).state = 1;
                        },
                      );

                    

                    default:
                      return const Center(child: Text("Settings"));
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    int index,
    int selected,
    WidgetRef ref,
  ) {
    final isSelected = index == selected;
    return GestureDetector(
      onTap: () => ref.read(selectedIndexProvider.notifier).state = index,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? kPrimaryColor.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? kPrimaryColor : Colors.grey),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? kPrimaryColor : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- Filter Card --------------------
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Age"),
                  RangeSlider(
                    values: RangeValues(
                      tempMin.value.toDouble(),
                      tempMax.value.toDouble(),
                    ),
                    min: 18,
                    max: 80,
                    divisions: 62,
                    onChanged: (v) {
                      tempMin.value = v.start.round();
                      tempMax.value = v.end.round();
                    },
                  ),
                  Text("${tempMin.value} - ${tempMax.value}"),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Distance (km)"),
                  Slider(
                    value: tempDist.value.toDouble(),
                    min: 1,
                    max: 200,
                    onChanged: (v) => tempDist.value = v.round(),
                  ),
                  Text("${tempDist.value} km"),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(minAgeProvider.notifier).state = tempMin.value;
                ref.read(maxAgeProvider.notifier).state = tempMax.value;
                ref.read(maxDistanceProvider.notifier).state = tempDist.value;
                ref.read(filtersAppliedToggleProvider.notifier).state++;
              },
              child: const Text("Apply"),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- Draggable Card --------------------
class _DraggableProfileCard extends StatefulWidget {
  final ProfileCard profile;
  final Future<void> Function()? onSwipeLeft;
  final Future<void> Function()? onSwipeRight;

  const _DraggableProfileCard({
    required this.profile,
    this.onSwipeLeft,
    this.onSwipeRight,
    super.key,
  });

  @override
  State<_DraggableProfileCard> createState() => _DraggableProfileCardState();
}

class _DraggableProfileCardState extends State<_DraggableProfileCard>
    with SingleTickerProviderStateMixin {
  Offset _pos = Offset.zero;
  double _rotation = 0;
  bool _actionLocked = false;

  void _onPanUpdate(DragUpdateDetails details) {
    if (_actionLocked) return;
    setState(() {
      _pos += details.delta;
      _rotation = (_pos.dx / 300) * 0.1;
    });
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    final vx = details.velocity.pixelsPerSecond.dx;
    if (vx > 700 || _pos.dx > 120) {
      setState(() => _actionLocked = true);
      widget.onSwipeRight?.call();
    } else if (vx < -700 || _pos.dx < -120) {
      setState(() => _actionLocked = true);
      widget.onSwipeLeft?.call();
    }
    setState(() {
      _pos = Offset.zero;
      _rotation = 0;
      _actionLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: _pos,
      child: Transform.rotate(
        angle: _rotation,
        child: Container(
          width: 480,
          height: 640,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
            image: DecorationImage(
              image: NetworkImage(widget.profile.images.first),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.profile.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                      Text(
                        "${widget.profile.age}, ${widget.profile.distance}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.profile.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
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
