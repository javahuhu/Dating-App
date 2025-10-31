// lib/presentation/pages/match_page_tablet.dart
import 'dart:async';
import 'dart:ui';
import 'package:dating_app/Data/Models/userinformation_model.dart';
import 'package:dating_app/Presentation/View/Desktop/visit_profile.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dating_app/Data/API/discovery_api.dart';
import 'package:dating_app/Core/Theme/colors.dart';

// Provider for tablet version
final discoveryApiProviderTablet = Provider<DiscoveryApi>(
  (ref) => DiscoveryApi(baseUrl: 'http://localhost:3000'),
);

// Matches provider for tablet
final matchesProviderTablet =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final api = ref.read(discoveryApiProviderTablet);
      final raw = await api.getMatches();
      return raw;
    });

// Messages stream provider for tablet
final messagesStreamProviderTablet = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, partnerId) {
      final api = ref.read(discoveryApiProviderTablet);

      return (() async* {
        // first immediate fetch
        try {
          final initial = await api.getMessages(partnerId);
          yield initial;
        } catch (_) {
          yield <Map<String, dynamic>>[];
        }

        // then periodic polling
        await for (final _ in Stream.periodic(const Duration(seconds: 2))) {
          try {
            final next = await api.getMessages(partnerId);
            yield next;
          } catch (_) {
            yield <Map<String, dynamic>>[];
          }
        }
      })();
    });

class MatchPageTablet extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToMatches;
  final void Function(String)? onOpenDiscovery;
  const MatchPageTablet({
    super.key,
    this.onNavigateToMatches,
    this.onOpenDiscovery,
  });

  @override
  ConsumerState<MatchPageTablet> createState() => _MatchPageTabletState();
}

class _MatchPageTabletState extends ConsumerState<MatchPageTablet> {
  String _selectedId = '';
  String _query = '';
  final Map<String, int> _unread = {};
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _composerCtrl = TextEditingController();
  final ScrollController _messagesScrollCtrl = ScrollController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _composerCtrl.dispose();
    _messagesScrollCtrl.dispose();
    super.dispose();
  }

  void _openChat(String partnerId) {
    if (partnerId.isNotEmpty) {
      setState(() {
        _selectedId = partnerId;
        _unread[partnerId] = 0;
      });
      ref.invalidate(messagesStreamProviderTablet(partnerId));
    }
  }

  Future<void> _checkMatchAndOpenChat(
    String partnerId, [
    Map<String, dynamic>? partner,
  ]) async {
    final api = ref.read(discoveryApiProviderTablet);
    try {
      final matched = await api.isMatched(partnerId);
      if (matched) {
        _openChat(partnerId);
        return;
      }

      final res = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Not matched yet'),
          content: Text(
            partner != null && (partner['name'] ?? '').toString().isNotEmpty
                ? '${partner['name']} hasn\'t liked you back yet. You can send a like or view their profile.'
                : 'This person hasn\'t liked you back yet. Messaging is available only after a mutual match.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('close'),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('view'),
              child: const Text('View Profile'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('like'),
              child: const Text('Send Like'),
            ),
          ],
        ),
      );

      if (res == 'view') {
        if (partner != null) _openProfilePreview(context, partner);
      } else if (res == 'like') {
        try {
          final likeRes = await api.like(partnerId);
          final newlyMatched =
              (likeRes['matched'] == true || likeRes['matched'] == 'true');
          ref.invalidate(matchesProviderTablet);

          if (newlyMatched) {
            _openChat(partnerId);
            return;
          }

          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Like sent')));
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to send like: ${e.toString()}')),
            );
          }
        }
      }
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not check match: ${err.toString()}')),
        );
      }
    }
  }

  Future<void> _sendMessage(String partnerId, String text) async {
    if (text.trim().isEmpty) return;
    final api = ref.read(discoveryApiProviderTablet);

    try {
      await api.sendMessage(partnerId, text.trim());
      _composerCtrl.clear();
      ref.invalidate(messagesStreamProviderTablet(partnerId));
      await Future.delayed(const Duration(milliseconds: 250));
      if (_messagesScrollCtrl.hasClients) {
        _messagesScrollCtrl.animateTo(
          _messagesScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to send message')));
      }
    }
  }

  Future<void> _confirmAndUnmatch(String partnerId) async {
    final api = ref.read(discoveryApiProviderTablet);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Unmatch'),
        content: const Text(
          'Are you sure you want to unmatch? This will remove the conversation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Yes, unmatch',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await api.unmatch(partnerId);
      if (res != null &&
          (res['success'] == true ||
              res['ok'] == true ||
              res['removedMatch'] == true)) {
        setState(() {
          _selectedId = '';
        });
        ref.invalidate(matchesProviderTablet);
        ref.invalidate(messagesStreamProviderTablet(partnerId));

        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (dctx) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Unmatched'),
              content: const Text(
                'Unmatch successful. The conversation has been removed.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Failed to unmatch')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to unmatch')));
      }
    }
  }

  Widget _buildEmptyState(double width) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 68, color: kSecondaryColor),
            const SizedBox(height: 14),
            Text(
              'No matches yet',
              style: TextStyle(
                fontSize: 20,
                color: kTitleColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When someone likes you back they\'ll appear here. Keep swiping — love might be just a tap away.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kBodyTextColor),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: width * 0.50,
              child: ElevatedButton(
                onPressed: () {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Open Discover panel')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                ),
                child: const Text(
                  'Discover people',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterMatches(List<Map<String, dynamic>> raw) {
    if (_query.trim().isEmpty) return raw;
    final q = _query.toLowerCase();
    return raw.where((m) {
      final partner = m['partner'] ?? m['user'] ?? m;
      final name = (partner?['name'] ?? '').toString().toLowerCase();
      final bio = (partner?['bio'] ?? '').toString().toLowerCase();
      return name.contains(q) || bio.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(matchesProviderTablet);
    final screenWidth = MediaQuery.of(context).size.width;

    // Tablet responsive clamping - 1100px max with proper scaling
    final clampedWidth = screenWidth.clamp(768.0, 1100.0);
    final scaleFactor = clampedWidth / 1100.0;

    // Responsive dimensions based on screen size
    final leftPanelWidth = clampedWidth * 0.45; // 45% for matches list
    final rightPanelWidth = clampedWidth * 0.55; // 55% for chat
    final isVeryNarrow = clampedWidth < 900;
    final showSinglePanel = clampedWidth < 800;

    double responsiveSize(double size) => size * scaleFactor;
    double responsivePadding(double padding) => padding * scaleFactor;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kBackgroundColor,
            kBackgroundColor.withOpacity(0.95),
            Colors.white.withOpacity(0.9),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(responsiveSize(20)),
              color: Colors.white.withOpacity(0.7),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: responsiveSize(20),
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            margin: EdgeInsets.all(responsiveSize(16)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(responsiveSize(20)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(responsiveSize(20)),
                  ),
                  child: Row(
                    children: [
                      // LEFT: Matches list
                      if (!showSinglePanel || _selectedId.isEmpty)
                        Container(
                          width: showSinglePanel
                              ? clampedWidth
                              : leftPanelWidth,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            border: Border(
                              right: BorderSide(
                                color: Colors.grey.shade100.withOpacity(0.5),
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Search area - tablet optimized
                              Container(
                                padding: EdgeInsets.all(responsivePadding(16)),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade100.withOpacity(
                                        0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: responsiveSize(44),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: responsivePadding(12),
                                        ),
                                        decoration: BoxDecoration(
                                          color: kBackgroundColor.withOpacity(
                                            0.7,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            responsiveSize(15),
                                          ),
                                          border: Border.all(
                                            color: kSecondaryColor.withOpacity(
                                              0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.search,
                                              size: responsiveSize(20),
                                              color: kBodyTextColor.withOpacity(
                                                0.7,
                                              ),
                                            ),
                                            SizedBox(
                                              width: responsivePadding(8),
                                            ),
                                            Expanded(
                                              child: TextField(
                                                controller: _searchCtrl,
                                                decoration: InputDecoration(
                                                  hintText: 'Search matches...',
                                                  border: InputBorder.none,
                                                  isDense: true,
                                                  hintStyle: TextStyle(
                                                    color: kBodyTextColor
                                                        .withOpacity(0.6),
                                                    fontSize: responsiveSize(
                                                      14,
                                                    ),
                                                  ),
                                                ),
                                                style: TextStyle(
                                                  fontSize: responsiveSize(14),
                                                ),
                                                onChanged: (v) {
                                                  setState(() {
                                                    _query = v;
                                                  });
                                                },
                                              ),
                                            ),
                                            if (_query.isNotEmpty)
                                              GestureDetector(
                                                onTap: () {
                                                  _searchCtrl.clear();
                                                  setState(() => _query = '');
                                                },
                                                child: Icon(
                                                  Icons.close,
                                                  size: responsiveSize(18),
                                                  color: kBodyTextColor
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (!isVeryNarrow) ...[
                                      SizedBox(width: responsivePadding(12)),
                                      Container(
                                        height: responsiveSize(44),
                                        width: responsiveSize(44),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            responsiveSize(12),
                                          ),
                                          border: Border.all(
                                            color: kSecondaryColor.withOpacity(
                                              0.3,
                                            ),
                                          ),
                                        ),
                                        child: IconButton(
                                          onPressed: () {
                                            showModalBottomSheet(
                                              context: context,
                                              backgroundColor:
                                                  Colors.transparent,
                                              builder: (ctx) => Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(20),
                                                        topRight:
                                                            Radius.circular(20),
                                                      ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      blurRadius: 20,
                                                      offset: const Offset(
                                                        0,
                                                        -5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    20.0,
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'Sort & Filters',
                                                        style: TextStyle(
                                                          color: kTitleColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize:
                                                              responsiveSize(
                                                                18,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      Text(
                                                        'Add your filter options here',
                                                        style: TextStyle(
                                                          color: kBodyTextColor,
                                                          fontSize:
                                                              responsiveSize(
                                                                14,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                              ctx,
                                                            ).pop(),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              kPrimaryColor,
                                                          foregroundColor:
                                                              Colors.white,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 24,
                                                                vertical: 12,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          'Close',
                                                          style: TextStyle(
                                                            fontSize:
                                                                responsiveSize(
                                                                  14,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          icon: Icon(
                                            Icons.tune_rounded,
                                            size: responsiveSize(20),
                                            color: kBodyTextColor.withOpacity(
                                              0.7,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Matches list
                              Expanded(
                                child: matchesAsync.when(
                                  data: (items) {
                                    final filtered = _filterMatches(items);
                                    if (filtered.isEmpty)
                                      return _buildEmptyState(leftPanelWidth);

                                    return ListView.separated(
                                      padding: EdgeInsets.symmetric(
                                        vertical: responsivePadding(8),
                                        horizontal: responsivePadding(12),
                                      ),
                                      itemBuilder: (ctx, idx) {
                                        final m = filtered[idx];
                                        final partner =
                                            m['partner'] ?? m['user'] ?? m;
                                        final id =
                                            (partner?['_id'] ??
                                                    partner?['id'] ??
                                                    '')
                                                .toString();
                                        final name =
                                            (partner?['name'] ?? 'No name')
                                                .toString();
                                        final age =
                                            partner?['age']?.toString() ?? '';
                                        final pic =
                                            (partner?['profilePicture'] ??
                                                    partner?['profilePictureUrl'] ??
                                                    '')
                                                .toString();
                                        final lastMessage =
                                            (m['lastMessage'] ??
                                                    m['last_msg'] ??
                                                    'Say hi!')
                                                .toString();
                                        final time =
                                            (m['lastMessageAt'] ??
                                                    m['lastAt'] ??
                                                    '')
                                                .toString();
                                        final unreadCount =
                                            _unread[id] ??
                                            (m['unread'] is int
                                                ? m['unread']
                                                : 0);

                                        return Container(
                                          margin: EdgeInsets.symmetric(
                                            vertical: responsivePadding(4),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    responsiveSize(16),
                                                  ),
                                              onTap: () =>
                                                  _checkMatchAndOpenChat(
                                                    id,
                                                    partner,
                                                  ),
                                              onLongPress: () {
                                                if (partner != null &&
                                                    partner
                                                        is Map<
                                                          String,
                                                          dynamic
                                                        >) {
                                                  try {
                                                    final userModel =
                                                        UserinformationModel.fromMap(
                                                          partner,
                                                        );
                                                    Navigator.of(ctx).push(
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            ProfilePageVisitDesktop(
                                                              user: userModel,
                                                            ),
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    _openProfilePreview(
                                                      ctx,
                                                      partner,
                                                    );
                                                  }
                                                } else {
                                                  _openProfilePreview(
                                                    ctx,
                                                    partner,
                                                  );
                                                }
                                              },
                                              child: Container(
                                                padding: EdgeInsets.all(
                                                  responsivePadding(12),
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _selectedId == id
                                                      ? kSecondaryColor
                                                            .withOpacity(0.1)
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        responsiveSize(16),
                                                      ),
                                                  border: _selectedId == id
                                                      ? Border.all(
                                                          color: kSecondaryColor
                                                              .withOpacity(0.3),
                                                        )
                                                      : null,
                                                ),
                                                child: Row(
                                                  children: [
                                                    // Profile image - responsive size
                                                    Container(
                                                      width: responsiveSize(64),
                                                      height: responsiveSize(
                                                        64,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              responsiveSize(
                                                                16,
                                                              ),
                                                            ),
                                                        color: Colors
                                                            .grey
                                                            .shade200,
                                                        image: pic.isNotEmpty
                                                            ? DecorationImage(
                                                                image:
                                                                    NetworkImage(
                                                                      pic,
                                                                    ),
                                                                fit: BoxFit
                                                                    .cover,
                                                              )
                                                            : null,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                            blurRadius:
                                                                responsiveSize(
                                                                  8,
                                                                ),
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  2,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: responsivePadding(
                                                        12,
                                                      ),
                                                    ),

                                                    // Text content
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  '$name${age.isNotEmpty ? ", $age" : ""}',
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    color:
                                                                        kTitleColor,
                                                                    fontSize:
                                                                        responsiveSize(
                                                                          16,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Text(
                                                                time.isNotEmpty
                                                                    ? time
                                                                    : '',
                                                                style: TextStyle(
                                                                  fontSize:
                                                                      responsiveSize(
                                                                        12,
                                                                      ),
                                                                  color: kBodyTextColor
                                                                      .withOpacity(
                                                                        0.7,
                                                                      ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(
                                                            height:
                                                                responsivePadding(
                                                                  6,
                                                                ),
                                                          ),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  lastMessage,
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: TextStyle(
                                                                    color: kBodyTextColor
                                                                        .withOpacity(
                                                                          0.8,
                                                                        ),
                                                                    fontSize:
                                                                        responsiveSize(
                                                                          14,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width:
                                                                    responsivePadding(
                                                                      6,
                                                                    ),
                                                              ),
                                                              if (unreadCount >
                                                                  0)
                                                                Container(
                                                                  padding: EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        responsivePadding(
                                                                          8,
                                                                        ),
                                                                    vertical:
                                                                        responsivePadding(
                                                                          4,
                                                                        ),
                                                                  ),
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        kPrimaryColor,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          responsiveSize(
                                                                            12,
                                                                          ),
                                                                        ),
                                                                  ),
                                                                  child: Text(
                                                                    unreadCount
                                                                        .toString(),
                                                                    style: TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          responsiveSize(
                                                                            12,
                                                                          ),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
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
                                            ),
                                          ),
                                        );
                                      },
                                      separatorBuilder: (_, __) => SizedBox(
                                        height: responsivePadding(4),
                                      ),
                                      itemCount: filtered.length,
                                    );
                                  },
                                  loading: () => Center(
                                    child: CircularProgressIndicator(
                                      color: kPrimaryColor,
                                    ),
                                  ),
                                  error: (err, st) => Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(
                                        responsivePadding(16),
                                      ),
                                      child: Text(
                                        'Could not load matches: ${err.toString()}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: kBodyTextColor,
                                          fontSize: responsiveSize(14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // RIGHT: Chat area
                      if (!showSinglePanel || _selectedId.isNotEmpty)
                        Expanded(
                          child: Container(
                            width: showSinglePanel
                                ? clampedWidth
                                : rightPanelWidth,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0.95),
                                  kBackgroundColor.withOpacity(0.8),
                                ],
                              ),
                            ),
                            child: _selectedId.isEmpty
                                ? _buildPlaceholderRight(responsiveSize)
                                : _buildChatArea(
                                    context,
                                    _selectedId,
                                    responsiveSize,
                                    responsivePadding,
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

  Widget _buildPlaceholderRight(double Function(double) responsiveSize) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: responsiveSize(120),
            height: responsiveSize(120),
            decoration: BoxDecoration(
              color: kSecondaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: responsiveSize(60),
              color: subtextViolet.withOpacity(0.7),
            ),
          ),
          SizedBox(height: responsiveSize(20)),
          Text(
            'Pick a match to start a conversation',
            style: TextStyle(
              color: kTitleColor,
              fontWeight: FontWeight.w700,
              fontSize: responsiveSize(18),
            ),
          ),
          SizedBox(height: responsiveSize(12)),
          Text(
            'Matches will appear here once you select one from the left.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kBodyTextColor,
              fontSize: responsiveSize(14),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _findPartner(String partnerId) {
    final asyncMatches = ref.read(matchesProviderTablet);
    Map<String, dynamic>? partner;
    asyncMatches.maybeWhen(
      data: (items) {
        for (final m in items) {
          final p = m['partner'] ?? m['user'] ?? m;
          final id = (p?['_id'] ?? p?['id'] ?? '').toString();
          if (id == partnerId) {
            partner = p as Map<String, dynamic>?;
            break;
          }
        }
      },
      orElse: () {},
    );
    return partner;
  }

  Widget _buildChatArea(
    BuildContext context,
    String partnerId,
    double Function(double) responsiveSize,
    double Function(double) responsivePadding,
  ) {
    final partner = _findPartner(partnerId);
    final name = (partner?['name'] ?? 'No name').toString();
    final pic =
        (partner?['profilePicture'] ?? partner?['profilePictureUrl'] ?? '')
            .toString();
    final bio = (partner?['bio'] ?? '').toString();

    final messagesAsync = ref.watch(messagesStreamProviderTablet(partnerId));

    return Column(
      children: [
        // Header - tablet optimized
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: responsivePadding(20),
            vertical: responsivePadding(16),
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: responsiveSize(8),
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Back button for single panel mode
              if (MediaQuery.of(context).size.width < 800)
                IconButton(
                  onPressed: () => setState(() => _selectedId = ''),
                  icon: Icon(Icons.arrow_back, size: responsiveSize(20)),
                ),

              Container(
                width: responsiveSize(50),
                height: responsiveSize(50),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(responsiveSize(15)),
                  color: Colors.grey.shade300,
                  image: pic.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(pic),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: responsiveSize(6),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              SizedBox(width: responsivePadding(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: kTitleColor,
                        fontSize: responsiveSize(16),
                      ),
                    ),
                    SizedBox(height: responsivePadding(2)),
                    Text(
                      bio.isNotEmpty
                          ? (bio.length > 60
                                ? '${bio.substring(0, 60)}...'
                                : bio)
                          : 'No bio',
                      style: TextStyle(
                        color: kBodyTextColor,
                        fontSize: responsiveSize(13),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  if (partner != null) _openProfilePreview(context, partner);
                },
                icon: Icon(
                  Icons.person_outline_rounded,
                  size: responsiveSize(20),
                  color: kBodyTextColor.withOpacity(0.8),
                ),
              ),
              SizedBox(width: responsivePadding(6)),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(responsiveSize(10)),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: TextButton.icon(
                  onPressed: () => _confirmAndUnmatch(partnerId),
                  icon: Icon(
                    Icons.block_outlined,
                    size: responsiveSize(16),
                    color: Colors.red,
                  ),
                  label: Text(
                    'Unmatch',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: responsiveSize(12),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsivePadding(12),
                      vertical: responsivePadding(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Messages list
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.3),
                  kBackgroundColor.withOpacity(0.2),
                ],
              ),
            ),
            child: messagesAsync.when(
              data: (messages) {
                messages.sort((a, b) {
                  final ta =
                      DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
                      DateTime.now();
                  final tb =
                      DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
                      DateTime.now();
                  return ta.compareTo(tb);
                });

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_messagesScrollCtrl.hasClients) {
                    _messagesScrollCtrl.jumpTo(
                      _messagesScrollCtrl.position.maxScrollExtent,
                    );
                  }
                });

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: responsiveSize(80),
                          height: responsiveSize(80),
                          decoration: BoxDecoration(
                            color: kSecondaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.favorite,
                            size: responsiveSize(40),
                            color: kSecondaryColor,
                          ),
                        ),
                        SizedBox(height: responsiveSize(16)),
                        Text(
                          'Say hello to $name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: responsiveSize(18),
                            color: kTitleColor,
                          ),
                        ),
                        SizedBox(height: responsiveSize(8)),
                        Text(
                          'Break the ice — ask a question or mention something from their profile.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: kBodyTextColor,
                            fontSize: responsiveSize(14),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _messagesScrollCtrl,
                  padding: EdgeInsets.symmetric(
                    horizontal: responsivePadding(20),
                    vertical: responsivePadding(16),
                  ),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = messages[i];
                    final fromId = (msg['fromId'] ?? msg['senderId'] ?? '')
                        .toString();
                    final text = (msg['text'] ?? '').toString();
                    final createdAtStr =
                        (msg['createdAt'] ?? msg['created'] ?? '').toString();
                    final createdAt =
                        DateTime.tryParse(createdAtStr) ?? DateTime.now();
                    final isMe = fromId.isNotEmpty
                        ? (fromId != partnerId)
                        : false;

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: responsivePadding(6),
                      ),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isMe) SizedBox(width: responsiveSize(44)),
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: responsivePadding(16),
                                vertical: responsivePadding(12),
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? kPrimaryColor : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: Radius.circular(isMe ? 18 : 6),
                                  bottomRight: Radius.circular(isMe ? 6 : 18),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: responsiveSize(4),
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    text,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : kTitleColor,
                                      fontSize: responsiveSize(15),
                                    ),
                                  ),
                                  SizedBox(height: responsivePadding(6)),
                                  Text(
                                    '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: responsiveSize(11),
                                      color: isMe
                                          ? Colors.white70
                                          : kBodyTextColor.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isMe) SizedBox(width: responsiveSize(44)),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(color: kPrimaryColor),
              ),
              error: (err, st) => Center(
                child: Padding(
                  padding: EdgeInsets.all(responsivePadding(16)),
                  child: Text(
                    'Messages error: ${err.toString()}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kBodyTextColor,
                      fontSize: responsiveSize(14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Message composer
        Container(
          padding: EdgeInsets.all(responsivePadding(16)),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            border: Border(top: BorderSide(color: Colors.grey.shade100)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: responsiveSize(8),
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: kBackgroundColor.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(responsiveSize(20)),
                    border: Border.all(color: kSecondaryColor.withOpacity(0.2)),
                  ),
                  child: TextField(
                    controller: _composerCtrl,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: responsivePadding(16),
                        vertical: responsivePadding(14),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(responsiveSize(20)),
                        borderSide: BorderSide.none,
                      ),
                      hintStyle: TextStyle(
                        color: kBodyTextColor.withOpacity(0.6),
                        fontSize: responsiveSize(14),
                      ),
                    ),
                    style: TextStyle(fontSize: responsiveSize(14)),
                    onSubmitted: (v) => _sendMessage(partnerId, v),
                  ),
                ),
              ),
              SizedBox(width: responsivePadding(12)),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(responsiveSize(15)),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withOpacity(0.3),
                      blurRadius: responsiveSize(8),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => _sendMessage(partnerId, _composerCtrl.text),
                  icon: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: responsiveSize(20),
                  ),
                  padding: EdgeInsets.all(responsivePadding(14)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openProfilePreview(
    BuildContext ctx,
    Map<String, dynamic> partner,
  ) async {
    final id = (partner['_id'] ?? partner['id'] ?? '').toString();
    final name = (partner['name'] ?? 'No name').toString();
    final bio = (partner['bio'] ?? '').toString();
    final profilePicture =
        (partner['profilePicture'] ?? partner['profilePictureUrl'] ?? '')
            .toString();

    final result = await showDialog<String>(
      context: ctx,
      builder: (ctx2) {
        final screenWidth = MediaQuery.of(ctx2).size.width;
        final dialogWidth = screenWidth.clamp(300.0, 400.0);

        final imgWidget = profilePicture.isNotEmpty
            ? ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Image.network(
                  profilePicture,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey.shade300),
                ),
              )
            : Container(
                color: Colors.grey.shade300,
                child: const Center(child: Icon(Icons.person, size: 48)),
              );
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: dialogWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 300, width: dialogWidth, child: imgWidget),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kTitleColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        bio.isNotEmpty ? bio : 'No bio available',
                        style: TextStyle(color: kBodyTextColor, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () async {
                          try {
                            await ref.read(discoveryApiProviderTablet).skip(id);
                          } catch (_) {}
                          Navigator.of(ctx2).pop('skipped');
                        },
                        child: const Text(
                          'Skip',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.of(ctx2).pop('close'),
                        child: Text(
                          'Close',
                          style: TextStyle(color: kBodyTextColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx2).pop('message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Message'),
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

    if (result == 'message') {
      _checkMatchAndOpenChat(id, partner);
    } else if (result == 'skipped') {
      ref.invalidate(matchesProviderTablet);
    } else if (result == 'view_profile') {
      try {
        final userModel = UserinformationModel.fromMap(partner);
        if (context.mounted) {
          Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) => ProfilePageVisitDesktop(user: userModel),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open profile: ${e.toString()}')),
          );
        }
      }
    }
  }
}
