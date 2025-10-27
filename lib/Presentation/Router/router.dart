import 'package:dating_app/Presentation/View/Desktop/desktop_main.dart';
import 'package:dating_app/Presentation/View/Mobile/mobile_main.dart';
import 'package:dating_app/Presentation/View/Tablet/tablet_main.dart';
import 'package:dating_app/responsive_layout.dart';
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',

  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => ResponsiveLayout(
        mobileBody: MobileMainScreen(),
        tabletBody: TabletMainScreen(),
        desktopBody: DesktopMainScreen(),
      ),
    ),
  ],
);
