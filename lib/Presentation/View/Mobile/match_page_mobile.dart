// lib/presentation/pages/match_page_mobile.dart
import 'dart:async';
import 'dart:ui';
import 'package:dating_app/Data/Models/userinformation_model.dart';
import 'package:dating_app/Presentation/View/Desktop/visit_profile.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dating_app/Data/API/discovery_api.dart';
import 'package:dating_app/Core/Theme/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Provider for mobile version
final discoveryApiProviderMobile = Provider<DiscoveryApi>(
  (ref) => DiscoveryApi(baseUrl: 'http://localhost:3000'),
);

// Matches provider for mobile
final matchesProviderMobile = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final api = ref.read(discoveryApiProviderMobile);
  final raw = await api.getMatches();
  return raw;
});

// Messages stream provider for mobile
final messagesStreamProviderMobile = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, partnerId) {
      final api = ref.read(discoveryApiProviderMobile);

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

class MatchPageMobile extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToMatches;
  final void Function(String)? onOpenDiscovery;
  const MatchPageMobile({super.key, this.onNavigateToMatches, this.onOpenDiscovery});

  @override
  ConsumerState<MatchPageMobile> createState() => _MatchPageMobileState();
}

class _MatchPageMobileState extends ConsumerState<MatchPageMobile> {
  String _selectedId = '';
  String _query = '';
  final Map<String, int> _unread = {};
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _composerCtrl = TextEditingController();
  final ScrollController _messagesScrollCtrl = ScrollController();
  final ScrollController _matchesScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize ScreenUtil for responsive design
    ScreenUtil.init(
      context,
      designSize: const Size(375, 812), // iPhone 13 mini as base design
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _composerCtrl.dispose();
    _messagesScrollCtrl.dispose();
    _matchesScrollCtrl.dispose();
    super.dispose();
  }

  void _openChat(String partnerId) {
    if (partnerId.isNotEmpty) {
      setState(() {
        _selectedId = partnerId;
        _unread[partnerId] = 0;
      });
      ref.invalidate(messagesStreamProviderMobile(partnerId));
    }
  }

  Future<void> _checkMatchAndOpenChat(
    String partnerId, [
    Map<String, dynamic>? partner,
  ]) async {
    final api = ref.read(discoveryApiProviderMobile);
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
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            'Not matched yet',
            style: TextStyle(fontSize: 18.sp),
          ),
          content: Text(
            partner != null && (partner['name'] ?? '').toString().isNotEmpty
                ? '${partner['name']} hasn\'t liked you back yet. You can send a like or view their profile.'
                : 'This person hasn\'t liked you back yet. Messaging is available only after a mutual match.',
            style: TextStyle(fontSize: 14.sp),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('close'),
              child: Text('Close', style: TextStyle(fontSize: 14.sp)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('view'),
              child: Text('View Profile', style: TextStyle(fontSize: 14.sp)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('like'),
              child: Text('Send Like', style: TextStyle(fontSize: 14.sp)),
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
          ref.invalidate(matchesProviderMobile);

          if (newlyMatched) {
            _openChat(partnerId);
            return;
          }

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Like sent', style: TextStyle(fontSize: 14.sp)),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to send like: ${e.toString()}', style: TextStyle(fontSize: 14.sp)),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not check match: ${err.toString()}', style: TextStyle(fontSize: 14.sp)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage(String partnerId, String text) async {
    if (text.trim().isEmpty) return;
    final api = ref.read(discoveryApiProviderMobile);

    try {
      await api.sendMessage(partnerId, text.trim());
      _composerCtrl.clear();
      ref.invalidate(messagesStreamProviderMobile(partnerId));
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message', style: TextStyle(fontSize: 14.sp)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmAndUnmatch(String partnerId) async {
    final api = ref.read(discoveryApiProviderMobile);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('Unmatch', style: TextStyle(fontSize: 18.sp)),
        content: Text(
          'Are you sure you want to unmatch? This will remove the conversation.',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Yes, unmatch',
              style: TextStyle(color: Colors.red, fontSize: 14.sp),
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
        ref.invalidate(matchesProviderMobile);
        ref.invalidate(messagesStreamProviderMobile(partnerId));

        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (dctx) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              title: Text('Unmatched', style: TextStyle(fontSize: 18.sp)),
              content: Text(
                'Unmatch successful. The conversation has been removed.',
                style: TextStyle(fontSize: 14.sp),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dctx).pop(),
                  child: Text('OK', style: TextStyle(fontSize: 14.sp)),
                ),
              ],
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to unmatch', style: TextStyle(fontSize: 14.sp)),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unmatch', style: TextStyle(fontSize: 14.sp)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 68.w, color: kSecondaryColor),
            SizedBox(height: 14.h),
            Text(
              'No matches yet',
              style: TextStyle(
                fontSize: 20.sp,
                color: kTitleColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'When someone likes you back they\'ll appear here. Keep swiping — love might be just a tap away.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kBodyTextColor, fontSize: 14.sp),
            ),
            SizedBox(height: 18.h),
            SizedBox(
              width: 250.w,
              child: ElevatedButton(
                onPressed: () {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Open Discover panel', style: TextStyle(fontSize: 14.sp)),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                ),
                child: Text(
                  'Discover people',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
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
    final matchesAsync = ref.watch(matchesProviderMobile);
    
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _selectedId.isEmpty ? _buildMatchesList(matchesAsync) : _buildChatView(),
      ),
    );
  }

  Widget _buildMatchesList(AsyncValue<List<Map<String, dynamic>>> matchesAsync) {
    return CustomScrollView(
      controller: _matchesScrollCtrl,
      slivers: [
        // App bar with search
        SliverAppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          pinned: true,
          floating: true,
          title: Text(
            'Matches',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: kTitleColor,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(70.h),
            child: _buildSearchSection(),
          ),
        ),

        // Matches list
        matchesAsync.when(
          data: (items) {
            final filtered = _filterMatches(items);
            if (filtered.isEmpty) {
              return SliverFillRemaining(
                child: _buildEmptyState(),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final m = filtered[index];
                  final partner = m['partner'] ?? m['user'] ?? m;
                  final id = (partner?['_id'] ?? partner?['id'] ?? '').toString();
                  final name = (partner?['name'] ?? 'No name').toString();
                  final age = partner?['age']?.toString() ?? '';
                  final pic = (partner?['profilePicture'] ?? partner?['profilePictureUrl'] ?? '').toString();
                  final lastMessage = (m['lastMessage'] ?? m['last_msg'] ?? 'Say hi!').toString();
                  final time = (m['lastMessageAt'] ?? m['lastAt'] ?? '').toString();
                  final unreadCount = _unread[id] ?? (m['unread'] is int ? m['unread'] : 0);

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 12.w),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16.r),
                        onTap: () => _checkMatchAndOpenChat(id, partner),
                        onLongPress: () {
                          if (partner != null && partner is Map<String, dynamic>) {
                            try {
                              final userModel = UserinformationModel.fromMap(partner);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProfilePageVisitDesktop(user: userModel),
                                ),
                              );
                            } catch (e) {
                              _openProfilePreview(context, partner);
                            }
                          } else {
                            _openProfilePreview(context, partner);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: _selectedId == id
                                ? kSecondaryColor.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16.r),
                            border: _selectedId == id
                                ? Border.all(color: kSecondaryColor.withOpacity(0.3))
                                : null,
                          ),
                          child: Row(
                            children: [
                              // Profile image
                              Container(
                                width: 60.w,
                                height: 60.w,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.r),
                                  color: Colors.grey.shade200,
                                  image: pic.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(pic),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8.w,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 12.w),

                              // Text content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '$name${age.isNotEmpty ? ", $age" : ""}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: kTitleColor,
                                              fontSize: 16.sp,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatTime(time),
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: kBodyTextColor.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6.h),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            lastMessage,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: kBodyTextColor.withOpacity(0.8),
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 6.w),
                                        if (unreadCount > 0)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.w,
                                              vertical: 4.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: kPrimaryColor,
                                              borderRadius: BorderRadius.circular(12.r),
                                            ),
                                            child: Text(
                                              unreadCount.toString(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.bold,
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
                childCount: filtered.length,
              ),
            );
          },
          loading: () => SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            ),
          ),
          error: (err, st) => SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  'Could not load matches: ${err.toString()}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kBodyTextColor, fontSize: 14.sp),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Container(
        height: 44.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: kBackgroundColor.withOpacity(0.7),
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: kSecondaryColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: 20.w,
              color: kBodyTextColor.withOpacity(0.7),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search matches...',
                  border: InputBorder.none,
                  isDense: true,
                  hintStyle: TextStyle(
                    color: kBodyTextColor.withOpacity(0.6),
                    fontSize: 14.sp,
                  ),
                ),
                style: TextStyle(fontSize: 14.sp),
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
                  size: 18.w,
                  color: kBodyTextColor.withOpacity(0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatView() {
    final partner = _findPartner(_selectedId);
    final name = (partner?['name'] ?? 'No name').toString();
    final pic = (partner?['profilePicture'] ?? partner?['profilePictureUrl'] ?? '').toString();
    final bio = (partner?['bio'] ?? '').toString();

    final messagesAsync = ref.watch(messagesStreamProviderMobile(_selectedId));

    return Column(
      children: [
        // Chat header
        Container(
          height: 100.h,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 16.w, right: 16.w, bottom: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8.w,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Back button
              IconButton(
                onPressed: () => setState(() => _selectedId = ''),
                icon: Icon(Icons.arrow_back, size: 24.w),
              ),
              SizedBox(width: 8.w),
              
              // Profile image
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  color: Colors.grey.shade300,
                  image: pic.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(pic),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
              SizedBox(width: 12.w),

              // Name and bio
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: kTitleColor,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      bio.isNotEmpty
                          ? (bio.length > 40 ? '${bio.substring(0, 40)}...' : bio)
                          : 'No bio',
                      style: TextStyle(
                        color: kBodyTextColor,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 24.w),
                onSelected: (value) {
                  if (value == 'profile') {
                    if (partner != null) _openProfilePreview(context, partner);
                  } else if (value == 'unmatch') {
                    _confirmAndUnmatch(_selectedId);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 20.w),
                        SizedBox(width: 8.w),
                        Text('View Profile', style: TextStyle(fontSize: 14.sp)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'unmatch',
                    child: Row(
                      children: [
                        Icon(Icons.block, size: 20.w, color: Colors.red),
                        SizedBox(width: 8.w),
                        Text('Unmatch', style: TextStyle(color: Colors.red, fontSize: 14.sp)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Messages area
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
                  final ta = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.now();
                  final tb = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.now();
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
                          width: 80.w,
                          height: 80.w,
                          decoration: BoxDecoration(
                            color: kSecondaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.favorite,
                            size: 40.w,
                            color: kSecondaryColor,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Say hello to $name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                            color: kTitleColor,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40.w),
                          child: Text(
                            'Break the ice — ask a question or mention something from their profile.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: kBodyTextColor, fontSize: 14.sp),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _messagesScrollCtrl,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = messages[i];
                    final fromId = (msg['fromId'] ?? msg['senderId'] ?? '').toString();
                    final text = (msg['text'] ?? '').toString();
                    final createdAtStr = (msg['createdAt'] ?? msg['created'] ?? '').toString();
                    final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();
                    final isMe = fromId.isNotEmpty ? (fromId != _selectedId) : false;

                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isMe) SizedBox(width: 50.w),
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? kPrimaryColor : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(18.r),
                                  topRight: Radius.circular(18.r),
                                  bottomLeft: Radius.circular(isMe ? 18.r : 6.r),
                                  bottomRight: Radius.circular(isMe ? 6.r : 18.r),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4.w,
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
                                      fontSize: 15.sp,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: isMe ? Colors.white70 : kBodyTextColor.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isMe) SizedBox(width: 50.w),
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
                  padding: EdgeInsets.all(16.w),
                  child: Text(
                    'Messages error: ${err.toString()}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kBodyTextColor, fontSize: 14.sp),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Message input
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8.w,
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
                    borderRadius: BorderRadius.circular(25.r),
                    border: Border.all(color: kSecondaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 16.w),
                      Expanded(
                        child: TextField(
                          controller: _composerCtrl,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            filled: true,
                            fillColor: Colors.transparent,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.r),
                              borderSide: BorderSide.none,
                            ),
                            hintStyle: TextStyle(
                              color: kBodyTextColor.withOpacity(0.6),
                              fontSize: 14.sp,
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                          style: TextStyle(fontSize: 14.sp),
                          onSubmitted: (v) => _sendMessage(_selectedId, v),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withOpacity(0.3),
                      blurRadius: 8.w,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => _sendMessage(_selectedId, _composerCtrl.text),
                  icon: Icon(Icons.send, color: Colors.white, size: 20.w),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, dynamic>? _findPartner(String partnerId) {
    final asyncMatches = ref.read(matchesProviderMobile);
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

  String _formatTime(String time) {
    if (time.isEmpty) return '';
    final date = DateTime.tryParse(time);
    if (date == null) return time;
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  Future<void> _openProfilePreview(
    BuildContext ctx,
    Map<String, dynamic> partner,
  ) async {
    final id = (partner['_id'] ?? partner['id'] ?? '').toString();
    final name = (partner['name'] ?? 'No name').toString();
    final bio = (partner['bio'] ?? '').toString();
    final profilePicture = (partner['profilePicture'] ?? partner['profilePictureUrl'] ?? '').toString();

    final result = await showModalBottomSheet<String>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx2) {
        return Container(
          height: MediaQuery.of(ctx2).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: EdgeInsets.only(top: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profile image
                      Container(
                        height: 300.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20.r),
                            topRight: Radius.circular(20.r),
                          ),
                          image: profilePicture.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(profilePicture),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: profilePicture.isEmpty ? Colors.grey.shade300 : null,
                        ),
                        child: profilePicture.isEmpty
                            ? Center(
                                child: Icon(Icons.person, size: 80.w, color: Colors.grey.shade600),
                              )
                            : null,
                      ),
                      Padding(
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: kTitleColor,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              bio.isNotEmpty ? bio : 'No bio available',
                              style: TextStyle(color: kBodyTextColor, fontSize: 16.sp, height: 1.4),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Action buttons
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade100),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx2).pop('close'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text('Close', style: TextStyle(fontSize: 16.sp)),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx2).pop('message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text('Message', style: TextStyle(fontSize: 16.sp)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result == 'message') {
      _checkMatchAndOpenChat(id, partner);
    }
  }
}