import 'dart:async' as async; 
import 'package:flutter/material.dart';
import 'package:flutter_animate_on_scroll/flutter_animate_on_scroll.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dating_app/Core/Theme/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InfiniteTestimonialCarousel extends StatefulWidget {
  final List<Map<String, String>> testimonials;
  final double scale;
  final double Function(double, double, double) clampScale;

  const InfiniteTestimonialCarousel({
    super.key,
    required this.testimonials,
    required this.scale,
    required this.clampScale,
  });

  @override
  State<InfiniteTestimonialCarousel> createState() =>
      _InfiniteTestimonialCarouselState();
}

class _InfiniteTestimonialCarouselState
    extends State<InfiniteTestimonialCarousel> {
  late final ScrollController _controller;
  async.Timer? _resumeTimer;
  bool _userInteracting = false;

  // tuning knobs
  static const double _speedPxPerSecondDefault = 500.0; // increase => faster
  static const int _repeatFactor =
      100; // how many times to repeat the list visually

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // optionally start near middle to reduce visible jump
      if (_controller.hasClients) {
        final double initialOffset = 0;
        _controller.jumpTo(initialOffset);
      }
      _startInfiniteScroll();
    });
  }

  @override
  void dispose() {
    _resumeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _pauseThenResumeAfterInteraction() {
    _resumeTimer?.cancel();
    _resumeTimer = async.Timer(const Duration(milliseconds: 800), () {
      _userInteracting = false;
    });
  }

  Future<void> _startInfiniteScroll() async {
    final double speedPxPerSecond = _speedPxPerSecondDefault;
    final double step = 3.0; // pixels per small animateTo
    final Duration stepDuration = Duration(
      milliseconds: (1000 * step / speedPxPerSecond).round(),
    );

    // Loop forever while mounted
    while (mounted) {
      if (!_userInteracting && _controller.hasClients) {
        final double nextOffset = _controller.offset + step;

        // If we're near the end, jump back to start (no await because jumpTo is void)
        if (_controller.position.maxScrollExtent > 0 &&
            nextOffset >= _controller.position.maxScrollExtent - step) {
          _controller.jumpTo(0);
        } else {
          try {
            await _controller.animateTo(
              nextOffset,
              duration: stepDuration,
              curve: Curves.linear,
            );
          } catch (_) {
            // ignore if controller disposed mid-animation
          }
        }
      } else {
        // if user interacting or controller not ready, wait a bit
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // tiny throttle to avoid super tight loop
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double cardW = widget.clampScale(360 * widget.scale, 260, 560);
    final double cardH = widget.clampScale(180 * widget.scale, 140, 260);
    final double heading = widget.clampScale(28 * widget.scale, 18, 36);
    final double separator = widget.clampScale(18 * widget.scale, 12, 28);

    // Build a repeated list for the infinite feel
    final loopItems = List.generate(
      _repeatFactor,
      (_) => widget.testimonials,
    ).expand((x) => x).toList();

    // placeholder asset path (optional) - ensure exists if you use it
    const String placeholder = 'assets/image/avatar_placeholder.png';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.clampScale(32 * widget.scale, 12, 120),
            ),
            child: Text(
              'Real Stories',
              style: GoogleFonts.poppins(
                fontSize: heading,
                fontWeight: FontWeight.bold,
                color: charcoal.withValues(alpha: 0.95),
              ),
            ),
          ),
          SizedBox(height: widget.clampScale(16 * widget.scale, 8, 24)),
          GestureDetector(
            onHorizontalDragStart: (_) {
              _userInteracting = true;
              _pauseThenResumeAfterInteraction();
            },
            onHorizontalDragUpdate: (_) {
              _userInteracting = true;
            },
            onHorizontalDragEnd: (_) {
              _pauseThenResumeAfterInteraction();
            },
            child: SizedBox(
              height: cardH,
              child: ListView.separated(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                itemCount: loopItems.length,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.clampScale(8 * widget.scale, 8, 16),
                ),
                separatorBuilder: (_, __) => SizedBox(width: separator),
                itemBuilder: (context, index) {
                  final t = loopItems[index];
                  final avatarPath = (t['avatar']?.isNotEmpty == true)
                      ? t['avatar']!
                      : placeholder;

                  return FadeInUp(
                    config: BaseAnimationConfig(
                      repeat: false,
                      delay: (index * 0.05).seconds,
                      child: Container(
                        width: cardW,
                        padding: EdgeInsets.all(
                          widget.clampScale(16 * widget.scale, 12, 20),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            widget.clampScale(16 * widget.scale, 8, 24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Image.asset(
                                avatarPath,
                                fit: BoxFit.cover,
                                height: widget.clampScale(
                                  80 * widget.scale,
                                  48,
                                  80,
                                ),
                                width: widget.clampScale(
                                  80 * widget.scale,
                                  48,
                                  80,
                                ),
                                errorBuilder: (c, e, s) {
                                  // fallback to placeholder if image decode fails
                                  return Image.asset(
                                    placeholder,
                                    fit: BoxFit.cover,
                                    height: widget.clampScale(
                                      80 * widget.scale,
                                      48,
                                      80,
                                    ),
                                    width: widget.clampScale(
                                      80 * widget.scale,
                                      48,
                                      80,
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(
                              width: widget.clampScale(
                                14 * widget.scale,
                                8,
                                18,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '"${t['quote'] ?? ''}"',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: widget.clampScale(
                                        14 * widget.scale,
                                        12,
                                        16,
                                      ),
                                      color: charcoal,
                                    ),
                                  ),
                                  SizedBox(
                                    height: widget.clampScale(
                                      8 * widget.scale,
                                      6,
                                      12,
                                    ),
                                  ),
                                  Text(
                                    t['name'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: widget.clampScale(
                                        13 * widget.scale,
                                        12,
                                        14,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      color: headingViolet,
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
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}









class TabletTestimonialsCarousel extends StatefulWidget {
  final List<Map<String, String>> items;
  final double Function(double, double, double) clampScale;
  final double scale;

  const TabletTestimonialsCarousel({
    super.key,
    required this.items,
    required this.clampScale,
    required this.scale,
  });

  @override
  State<TabletTestimonialsCarousel> createState() =>
      _TabletTestimonialsCarouselState();
}

class _TabletTestimonialsCarouselState extends State<TabletTestimonialsCarousel> {
  late final ScrollController _controller;
  async.Timer? _resumeTimer;
  bool _userInteracting = false;

  // tuning
  final double _speedPxPerSecond = 500; // increase to make it faster
  final double _stepPx = 4; // pixels moved per animateTo call
  final int _repeatTimes = 100; // repeat list times to create long scroll

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // optionally position near start (0)
      if (_controller.hasClients) _controller.jumpTo(0);
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _resumeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _pauseThenResumeAfterInteraction() {
    _resumeTimer?.cancel();
    _resumeTimer = async.Timer(const Duration(milliseconds: 700), () {
      _userInteracting = false;
    });
  }

  Future<void> _startAutoScroll() async {
    final Duration stepDuration =
        Duration(milliseconds: (1000 * (_stepPx / _speedPxPerSecond)).round());

    while (mounted) {
      if (!_userInteracting && _controller.hasClients) {
        final double next = _controller.offset + _stepPx;
        final max = _controller.position.maxScrollExtent;

        try {
          if (max > 0 && next >= max - _stepPx) {
            // jump to 0 (no await)
            _controller.jumpTo(0);
          } else {
            await _controller.animateTo(
              next,
              duration: stepDuration,
              curve: Curves.linear,
            );
          }
        } catch (_) {
          // ignore if controller disposed mid-animation
        }
      }
      // small wait to avoid busy loop
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }

  @override
  Widget build(BuildContext context) {
    // tablet-friendly sizes using clampScale + scale passed in
    final double cardW = widget.clampScale(320 * widget.scale, 220, 420);
    final double cardH = widget.clampScale(160 * widget.scale, 120, 220);
    final double avatarSize = widget.clampScale(72 * widget.scale, 48, 96);
    final double gap = widget.clampScale(12 * widget.scale, 8, 18);

    final loopList = List.generate(_repeatTimes, (_) => widget.items)
        .expand((e) => e)
        .toList();

    const String placeholder = 'assets/image/avatar_placeholder.png';

    return SizedBox(
      height: cardH,
      child: GestureDetector(
        onHorizontalDragStart: (_) {
          _userInteracting = true;
          _pauseThenResumeAfterInteraction();
        },
        onHorizontalDragUpdate: (_) => _userInteracting = true,
        onHorizontalDragEnd: (_) => _pauseThenResumeAfterInteraction(),
        child: ListView.separated(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          itemCount: loopList.length,
          padding:
              EdgeInsets.symmetric(horizontal: widget.clampScale(8 * widget.scale, 8, 16)),
          separatorBuilder: (_, __) => SizedBox(width: gap),
          itemBuilder: (context, idx) {
            final item = loopList[idx];
            final avatar = (item['avatar']?.isNotEmpty == true) ? item['avatar']! : placeholder;

            return FadeInUp(
              config: BaseAnimationConfig(
                repeat: false,
                delay: (idx * 40).milliseconds,
                child: Container(
                  width: cardW,
                  padding: EdgeInsets.all(widget.clampScale(12 * widget.scale, 8, 16)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      widget.clampScale(12 * widget.scale, 8, 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(avatarSize),
                        child: Image.asset(
                          avatar,
                          fit: BoxFit.cover,
                          height: avatarSize,
                          width: avatarSize,
                          errorBuilder: (c, e, s) {
                            return Image.asset(
                              placeholder,
                              fit: BoxFit.cover,
                              height: avatarSize,
                              width: avatarSize,
                            );
                          },
                        ),
                      ),
                      SizedBox(width: gap),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '"${item['quote'] ?? ''}"',
                              style: GoogleFonts.poppins(
                                fontSize: widget.clampScale(13 * widget.scale, 12, 16),
                                color: charcoal,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: widget.clampScale(8 * widget.scale, 6, 12)),
                            Text(
                              item['name'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: widget.clampScale(12 * widget.scale, 11, 14),
                                fontWeight: FontWeight.w600,
                                color: headingViolet,
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
          },
        ),
      ),
    );
  }
}



// ---- Fixed MobileTestimonialsTicker ----
class MobileTestimonialsTicker extends StatefulWidget {
  final List<Map<String, String>> items;
  /// speed in pixels/second (bigger = faster)
  final double speedPxPerSecond;

  const MobileTestimonialsTicker({
    super.key,
    required this.items,
    this.speedPxPerSecond = 120.0,
  });

  @override
  MobileTestimonialsTickerState createState() =>
      MobileTestimonialsTickerState();
}

class MobileTestimonialsTickerState extends State<MobileTestimonialsTicker>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late double _cardW;
  late double _cardH;
  late double _gap;
  late double _avatarSize;
  late double _totalWidth; // width of single sequence (not duplicated)
  final String _placeholder = 'assets/image/avatar_placeholder.png';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // initialize after first frame so ScreenUtil values are available
    WidgetsBinding.instance.addPostFrameCallback((_) => _initController());
  }

  void _initController() {
    if (!mounted) return;

    // sizes tuned for mobile using ScreenUtil
    _cardW = 250.w; // same width you used for card
    _cardH = 218.h; // container height
    _avatarSize = 80.h;
    _gap = 16.w;

    final int n = widget.items.isNotEmpty ? widget.items.length : 1;
    _totalWidth = (_cardW + _gap) * n;

    // duration to travel the single sequence width at given speed
    final double seconds =
        (_totalWidth / (widget.speedPxPerSecond <= 0 ? 120.0 : widget.speedPxPerSecond))
            .clamp(0.1, 9999.0);
    final int ms = (seconds * 1000).round();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: ms),
    );

    // loop forever
    _controller!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller!.repeat();
      }
    });

    // start animation
    if (mounted) {
      _controller!.repeat();
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _pause() {
    if (_controller?.isAnimating == true) _controller!.stop(canceled: false);
  }

  void _resume() {
    if (_controller != null && !_controller!.isAnimating) {
      _controller!.repeat(min: _controller!.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    // if controller not yet initialized, render a placeholder-sized box
    if (!_initialized || _controller == null || _controller!.duration == null) {
      return SizedBox(
        height: 218.h,
        child: Center(child: CircularProgressIndicator(strokeWidth: 1.6.w)),
      );
    }

    // build a single row of cards (immutable list)
    final rowChildren = widget.items.map((item) {
      final avatar = (item['avatar']?.isNotEmpty == true) ? item['avatar']! : _placeholder;

      return Container(
        width: _cardW,
        margin: EdgeInsets.only(right: _gap),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8.r, offset: Offset(0, 2.h))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Image.asset(
                avatar,
                fit: BoxFit.cover,
                height: _avatarSize,
                width: _avatarSize,
                errorBuilder: (c, e, s) => Image.asset(
                  _placeholder,
                  height: _avatarSize,
                  width: _avatarSize,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              item['quote'] ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14.sp),
            ),
            SizedBox(height: 10.h),
            Text(
              item['name'] ?? '',
              style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.pinkAccent),
            ),
          ],
        ),
      );
    }).toList(growable: false);

    // duplicate to make seamless loop
    final duplicated = [...rowChildren, ...rowChildren];

    // Bound the moving content using a SizedBox so Row doesn't go infinite
    final double movingWidth = _totalWidth * 2;

    return ClipRect(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: (_) => _pause(),
        onPanCancel: () => _resume(),
        onPanEnd: (_) => _resume(),
        child: SizedBox(
          height: _cardH,
          child: AnimatedBuilder(
            animation: _controller!,
            builder: (context, child) {
              // controller.value ranges 0..1; compute translation across single sequence width
              final double translateX = -(_controller!.value * _totalWidth);

              return Transform.translate(
                offset: Offset(translateX, 0),
                child: SizedBox(
                  width: movingWidth,
                  // Now Row has a concrete width and cannot overflow layout.
                  child: Row(children: duplicated),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
