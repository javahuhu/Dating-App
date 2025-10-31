// lib/presentation/pages/messages_page.dart
import 'dart:convert';
import 'dart:ui';
import 'package:dating_app/Presentation/View/Desktop/match_page_desktop.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dating_app/Data/API/discovery_api.dart';
import 'package:dating_app/Core/Theme/colors.dart';
import 'package:go_router/go_router.dart';

// Defensive tag parser: accepts null, List, or JSON-encoded String and returns List<dynamic>
List<dynamic> _parseTags(dynamic raw) {
  if (raw == null) return <dynamic>[];
  if (raw is List) return raw;
  if (raw is String) {
    final s = raw.trim();
    if (s.isEmpty) return <dynamic>[];
    try {
      final decoded = jsonDecode(s);
      if (decoded is List) return decoded;
      return <dynamic>[s];
    } catch (_) {
      return <dynamic>[s];
    }
  }
  return <dynamic>[raw.toString()];
}

// provider for DiscoveryApi (replace with your provider name if different)
final discoveryApiProvider = Provider<DiscoveryApi>(
  (ref) => DiscoveryApi(baseUrl: 'http://localhost:3000'),
);

// provider to fetch pending "sent" likes (people you liked)
final sentLikesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final api = ref.read(discoveryApiProvider);
      final raw = await api.getSent();
      return raw;
    });

// NEW: provider to fetch pending "received" likes (people who liked you)
final receivedLikesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final api = ref.read(discoveryApiProvider);
      final raw = await api.getReceived();
      return raw;
    });

// provider to fetch matches (mutual)
final matchesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final api = ref.read(discoveryApiProvider);
  final raw = await api.getMatches();
  return raw;
});

class MessagesPageDesktop extends ConsumerStatefulWidget {
  final void Function(String)? onOpenProfile;
  final void Function(String)? onOpenChat;

  const MessagesPageDesktop({super.key, this.onOpenProfile, this.onOpenChat});

  @override
  ConsumerState<MessagesPageDesktop> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPageDesktop> {
  // local "acknowledged" set for UI (id => matched boolean)
  final Map<String, bool> _acknowledged = {};

  // IDs to hide from "pending" (skipped/unmatched locally)
  final Set<String> _hidden = {};

  final PageController _pendingPageController = PageController(
    viewportFraction: 0.7,
  );
  final PageController _matchesPageController = PageController(
    viewportFraction: 0.8,
  );

  @override
  void dispose() {
    _pendingPageController.dispose();
    _matchesPageController.dispose();
    super.dispose();
  }

  void _markAcknowledged(String id, {bool matched = false}) {
    setState(() {
      _acknowledged[id] = matched;
    });
  }

  Future<void> _openProfileDialog(
    BuildContext context,
    Map<String, dynamic> user,
  ) async {
    final id = (user['_id'] ?? user['id'] ?? '').toString();
    final name = (user['name'] ?? 'No name').toString();
    final bio = (user['bio'] ?? '').toString();
    final profilePicture =
        (user['profilePicture'] ?? user['profilePictureUrl'] ?? '').toString();

    final api = ref.read(discoveryApiProvider);

    final result = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) {
        final imgWidget = profilePicture.isNotEmpty
            ? Image.network(
                profilePicture,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kSecondaryColor.withOpacity(0.3),
                        kAccentColor.withOpacity(0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.person, size: 48, color: kPrimaryColor),
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kSecondaryColor.withOpacity(0.3),
                      kAccentColor.withOpacity(0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.person, size: 48, color: kPrimaryColor),
                ),
              );
        final isAck = _acknowledged[id] ?? false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 420, // Reduced width for better proportions
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withOpacity(0.15),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Square image container (300x300)
                    Container(
                      height: 300,
                      width: 300,
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            Positioned.fill(child: imgWidget),
                            if (!(isAck))
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withOpacity(0.2),
                                        Colors.black.withOpacity(0.5),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 8,
                                      sigmaY: 8,
                                    ),
                                    child: Container(
                                      color: Colors.black.withOpacity(0),
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              left: 12,
                              top: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.95),
                                      Colors.white.withOpacity(0.85),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: headingViolet,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        bio.isNotEmpty ? bio : 'No bio available',
                        style: const TextStyle(
                          height: 1.5,
                          color: kBodyTextColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: kPrimaryColor.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: TextButton(
                                onPressed: () async {
                                  try {
                                    // CHANGE: for received likes we call declineReceivedLike
                                    await api.declineReceivedLike(id);
                                    // hide immediately
                                    setState(() {
                                      _hidden.add(id);
                                    });
                                    ref.invalidate(receivedLikesProvider);
                                    ref.invalidate(sentLikesProvider);
                                  } catch (e) {
                                    // ignore network error for now
                                  }
                                  Navigator.of(ctx).pop('skipped');
                                },
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: const Text(
                                  'Skip',
                                  style: TextStyle(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [kPrimaryColor, Color(0xFFD81B60)],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: kPrimaryColor.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextButton(
                                onPressed: () async {
                                  try {
                                    final res = await api.like(id);
                                    final matched =
                                        (res['matched'] == true ||
                                        res['matched'] == 'true');

                                    // mark acknowledged locally and hide from pending
                                    setState(() {
                                      _acknowledged[id] = matched || true;
                                      _hidden.add(id);
                                    });
                                    _markAcknowledged(id, matched: matched);

                                    // refresh lists
                                    if (matched) {
                                      // ensure matches list refreshes
                                      ref.invalidate(matchesProvider);
                                    }
                                    // always refresh pending lists
                                    ref.invalidate(receivedLikesProvider);
                                    ref.invalidate(sentLikesProvider);

                                    Navigator.of(
                                      ctx,
                                    ).pop(matched ? 'matched' : 'ack');
                                  } catch (e) {
                                    _markAcknowledged(id, matched: false);
                                    Navigator.of(ctx).pop('ack');
                                  }
                                },
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: const Text(
                                  'Like',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == 'skipped') {
      // If user skipped a received-like, refresh received list
      ref.invalidate(receivedLikesProvider);
    } else if (result == 'matched' || result == 'ack') {
      _markAcknowledged(id, matched: result == 'matched');
      ref.invalidate(matchesProvider);
      ref.invalidate(receivedLikesProvider);
      ref.invalidate(sentLikesProvider);
    }
  }

  Future<void> _openChatOrRoute(String partnerId) async {
    if (partnerId.isNotEmpty) {
      // call callback if parent handles navigation; otherwise use push route
      if (widget.onOpenChat != null) {
        widget.onOpenChat!.call(partnerId);
      } else {
        context.push('/chat/$partnerId');
      }
    }
  }

  Future<void> _handleUnmatch(String partnerId) async {
    final api = ref.read(discoveryApiProvider);

    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: kBackgroundColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.heart_broken, size: 48, color: kPrimaryColor),
              const SizedBox(height: 16),
              const Text(
                'Unmatch',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: headingViolet,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to unmatch? This will remove the conversation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kBodyTextColor,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: kDisabledColor, width: 1.5),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: kBodyTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Yes, unmatch',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    try {
      final res = await api.unmatch(partnerId);
      final ok =
          (res['success'] == true) ||
          (res['ok'] == true) ||
          res['removedMatch'] == true;
      if (ok) {
        setState(() {
          _hidden.add(partnerId);
          if (_acknowledged.containsKey(partnerId))
            _acknowledged.remove(partnerId);
        });

        ref.invalidate(matchesProvider);
        ref.invalidate(receivedLikesProvider);
        ref.invalidate(sentLikesProvider);
        // optionally invalidate messages stream if you have it:
        // ref.invalidate(messagesStreamProvider(partnerId));

        if (context.mounted) {
          await showDialog(
            context: context,
            barrierColor: Colors.black.withOpacity(0.6),
            builder: (dctx) => Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 360,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 56,
                      color: kPrimaryColor,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unmatched',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: headingViolet,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'The user has been removed from your matches.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kBodyTextColor, fontSize: 15),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to unmatch'),
            backgroundColor: kPrimaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      ref.invalidate(matchesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unmatch: ${e.toString()}'),
          backgroundColor: kPrimaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // NEW: _buildPendingCarousel now receives matchesAsync so it can filter out matches
  Widget _buildPendingCarousel(
    List<Map<String, dynamic>> pending,
    AsyncValue<List<Map<String, dynamic>>> matchesAsync,
  ) {
    // Build list excluding locally hidden IDs
    final hiddenFiltered = pending.where((p) {
      final id = (p['_id'] ?? p['id'] ?? '').toString();
      if (_hidden.contains(id)) return false;
      return true;
    }).toList();

    // collect known matched ids (if available)
    final List<String> matchedIds = [];
    matchesAsync.maybeWhen(
      data: (items) {
        for (final m in items) {
          final partner = m['partner'] ?? m['user'] ?? m;
          final id = (partner?['_id'] ?? partner?['id'] ?? '').toString();
          if (id.isNotEmpty) matchedIds.add(id);
        }
      },
      orElse: () {},
    );

    // final filtered pending excludes matched ids too
    final filteredPending = hiddenFiltered.where((p) {
      final id = (p['_id'] ?? p['id'] ?? '').toString();
      return !matchedIds.contains(id);
    }).toList();

    if (filteredPending.isEmpty) {
      return Container(
        height: 260,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              kSecondaryColor.withOpacity(0.15),
              kAccentColor.withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: kSecondaryColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border,
                size: 48,
                color: kPrimaryColor.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No pending likes',
                style: TextStyle(
                  color: kBodyTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: PageView.builder(
        controller: _pendingPageController,
        itemCount: filteredPending.length,
        padEnds: false,
        itemBuilder: (ctx, idx) {
          final u = filteredPending[idx];
          final id = (u['_id'] ?? u['id'] ?? '').toString();
          final name = (u['name'] ?? 'No name').toString();
          final age = u['age']?.toString() ?? '';
          final pic = (u['profilePicture'] ?? u['profilePictureUrl'] ?? '')
              .toString();
          final bio = (u['bio'] ?? '').toString();
          final tags = _parseTags(u['tags']);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: GestureDetector(
              onTap: () => _openProfileDialog(context, u),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // background image - now properly constrained
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: pic.isNotEmpty
                            ? Image.network(
                                pic,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        kSecondaryColor.withOpacity(0.4),
                                        kAccentColor.withOpacity(0.4),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      kSecondaryColor.withOpacity(0.4),
                                      kAccentColor.withOpacity(0.4),
                                    ],
                                  ),
                                ),
                              ),
                      ),

                      // gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.3, 1.0],
                            ),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                            child: const SizedBox(),
                          ),
                        ),
                      ),

                      // content
                      Positioned(
                        left: 20,
                        bottom: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '$name${age.isNotEmpty ? ", $age" : ""}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        kAccentColor.withOpacity(0.9),
                                        kAccentColor.withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: kAccentColor.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'Waiting',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: headingViolet,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              bio.isNotEmpty
                                  ? (bio.length > 70
                                        ? '${bio.substring(0, 70)}...'
                                        : bio)
                                  : 'No bio',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.3,
                                shadows: [
                                  Shadow(color: Colors.black26, blurRadius: 6),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: (tags).take(3).map<Widget>((t) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    t.toString(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () async {
                                final api = ref.read(discoveryApiProvider);
                                try {
                                  // CHANGE: decline the received like (remove it from DB)
                                  await api.declineReceivedLike(id);
                                  // hide immediately and refresh the received list
                                  setState(() {
                                    _hidden.add(id);
                                  });
                                  ref.invalidate(receivedLikesProvider);
                                  ref.invalidate(sentLikesProvider);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Removed from pending',
                                      ),
                                      backgroundColor: kPrimaryColor,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Action failed: ${e.toString()}',
                                      ),
                                      backgroundColor: kPrimaryColor,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
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
        },
      ),
    );
  }

  Widget _buildMatchesCarousel(List<Map<String, dynamic>> matches) {
    if (matches.isEmpty) {
      return Container(
        height: 280,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              kPrimaryColor.withOpacity(0.08),
              kSecondaryColor.withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kPrimaryColor.withOpacity(0.2), width: 1.5),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite,
                size: 48,
                color: kPrimaryColor.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No matches yet',
                style: TextStyle(
                  color: kBodyTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      width: 700,
      child: PageView.builder(
        controller: _matchesPageController,
        itemCount: matches.length,
        padEnds: false,
        itemBuilder: (ctx, idx) {
          final m = matches[idx];
          final partner = m['partner'] ?? m['user'] ?? m;
          final id = (partner?['_id'] ?? partner?['id'] ?? '').toString();
          final name = (partner?['name'] ?? 'No name').toString();
          final pic =
              (partner?['profilePicture'] ??
                      partner?['profilePictureUrl'] ??
                      '')
                  .toString();
          final bio = (partner?['bio'] ?? '').toString();
          final age = partner?['age']?.toString() ?? '';
          final tags = _parseTags(partner?['tags']);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: GestureDetector(
              onTap: () async {
                if (id.isNotEmpty) _openChatOrRoute(id);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: headingViolet.withOpacity(0.12),
                      blurRadius: 20,
                      spreadRadius: 3,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: kSecondaryColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Row(
                    children: [
                      // Square image container (200x200)
                      Container(
                        width: 200,
                        height: 200,
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: pic.isNotEmpty
                              ? Image.network(
                                  pic,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          kSecondaryColor.withOpacity(0.3),
                                          kAccentColor.withOpacity(0.3),
                                        ],
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.person,
                                        size: 48,
                                        color: kPrimaryColor,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        kSecondaryColor.withOpacity(0.3),
                                        kAccentColor.withOpacity(0.3),
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.person,
                                      size: 48,
                                      color: kPrimaryColor,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      // right details
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            color: headingViolet,
                                          ),
                                        ),
                                        if (age.isNotEmpty)
                                          Text(
                                            '$age years old',
                                            style: TextStyle(
                                              color: kBodyTextColor.withOpacity(
                                                0.8,
                                              ),
                                              fontSize: 14,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: kPrimaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      onPressed: () => _handleUnmatch(id),
                                      icon: const Icon(
                                        Icons.block_outlined,
                                        color: kPrimaryColor,
                                      ),
                                      tooltip: 'Unmatch',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: Text(
                                  bio.isNotEmpty
                                      ? (bio.length > 100
                                            ? '${bio.substring(0, 100)}...'
                                            : bio)
                                      : 'No bio',
                                  style: const TextStyle(
                                    color: kBodyTextColor,
                                    height: 1.4,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: tags.take(4).map((t) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          kAccentColor.withOpacity(0.3),
                                          kSecondaryColor.withOpacity(0.3),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: kAccentColor.withOpacity(0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      t.toString(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: subtextViolet,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [headingViolet, subtextViolet],
                                      ),
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: headingViolet.withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        widget.onOpenChat?.call(id);
                                      },
                                      icon: const Icon(
                                        Icons.chat_bubble_rounded,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Message',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // NOTE: pending is now the receivedLikesProvider (people who liked you)
    final pendingAsync = ref.watch(receivedLikesProvider);
    final matchesAsync = ref.watch(matchesProvider);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kBackgroundColor, kSecondaryColor.withOpacity(0.05)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kAccentColor.withOpacity(0.2),
                        kSecondaryColor.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: kAccentColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kAccentColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          color: headingViolet,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pending',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: headingViolet,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'People who liked you (waiting for your response)',
                              style: TextStyle(
                                color: kBodyTextColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Pending carousel (pass matchesAsync so we can filter matched ids)
                pendingAsync.when(
                  data: (items) => _buildPendingCarousel(items, matchesAsync),
                  loading: () => Container(
                    height: 260,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: kBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: kSecondaryColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: kPrimaryColor,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  error: (err, st) => Container(
                    height: 260,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: kPrimaryColor.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: kPrimaryColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load pending',
                            style: TextStyle(
                              color: kBodyTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Matches header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kPrimaryColor.withOpacity(0.15),
                        headingViolet.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: kPrimaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              kPrimaryColor.withOpacity(0.3),
                              headingViolet.withOpacity(0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: kPrimaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Matches',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: headingViolet,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'People who liked you back',
                              style: TextStyle(
                                color: kBodyTextColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {
                            ref.invalidate(matchesProvider);
                            ref.invalidate(receivedLikesProvider);
                            ref.invalidate(sentLikesProvider);
                          },
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: headingViolet,
                          ),
                          tooltip: 'Refresh',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Matches carousel
                matchesAsync.when(
                  data: (matches) => _buildMatchesCarousel(matches),
                  loading: () => Container(
                    height: 280,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: kBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: kPrimaryColor.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: headingViolet,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  error: (err, st) => Container(
                    height: 280,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: kPrimaryColor.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: kPrimaryColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load matches',
                            style: TextStyle(
                              color: kBodyTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Quick access horizontal avatars
                matchesAsync.when(
                  data: (matches) {
                    if (matches.isEmpty) return const SizedBox();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            'Quick Access',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: headingViolet.withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: matches.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (ctx, i) {
                              final m = matches[i];
                              final partner = m['partner'] ?? m['user'] ?? m;
                              final name = (partner?['name'] ?? 'No name')
                                  .toString();
                              final pic =
                                  (partner?['profilePicture'] ??
                                          partner?['profilePictureUrl'] ??
                                          '')
                                      .toString();
                              final id =
                                  (partner?['_id'] ?? partner?['id'] ?? '')
                                      .toString();

                              return GestureDetector(
                                onTap: () {
                                  widget.onOpenProfile?.call(id);
                                },
                                child: Container(
                                  width: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: kPrimaryColor.withOpacity(0.1),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: kSecondaryColor.withOpacity(
                                              0.5,
                                            ),
                                            width: 2.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: kPrimaryColor.withOpacity(
                                                0.2,
                                              ),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 32,
                                          backgroundColor: kSecondaryColor
                                              .withOpacity(0.2),
                                          backgroundImage: pic.isNotEmpty
                                              ? NetworkImage(pic)
                                              : null,
                                          child: pic.isEmpty
                                              ? const Icon(
                                                  Icons.person,
                                                  color: kPrimaryColor,
                                                  size: 32,
                                                )
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: headingViolet,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
