import 'package:dating_app/Presentation/Auth/auth.dart';
import 'package:dating_app/Presentation/View/Desktop/completeprofile_dekstop.dart';
import 'package:dating_app/Presentation/View/Desktop/desktop_main.dart';
import 'package:dating_app/Presentation/View/Desktop/log_in_desktop.dart';
import 'package:dating_app/Presentation/View/Mobile/log_in_mobile.dart';
import 'package:dating_app/Presentation/View/Mobile/mobile_main.dart';
import 'package:dating_app/Presentation/View/Tablet/log_in_tablet.dart';
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

      routes: [],
    ),

    GoRoute(
      path: '/login',
      builder: (context, state) => ResponsiveLayout(
        mobileBody: LoginScreenMobile(),
        tabletBody: LoginScreenTablet(),
        desktopBody: LoginScreenDesktop(),
      ),

      routes: [],
    ),

    GoRoute(
      path: '/setup',
      builder: (context, state) => ResponsiveLayout(
        mobileBody: LoginScreenMobile(),
        tabletBody: LoginScreenTablet(),
        desktopBody: ProfileSetupPage(),
      ),

      routes: [],
    ),

    GoRoute(
      path: '/auth/success',
      builder: (context, state) => const AuthSuccessPage(),
    ),
  ],
);
