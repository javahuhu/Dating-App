
import 'package:dating_app/Core/AuthStorage/auth.dart';
import 'package:dating_app/Presentation/View/Desktop/completeprofile_dekstop.dart';
import 'package:dating_app/Presentation/View/Desktop/desktop_main.dart';
import 'package:dating_app/Presentation/View/Desktop/homepage_desktop.dart';
import 'package:dating_app/Presentation/View/Desktop/log_in_desktop.dart';
import 'package:dating_app/Presentation/View/Desktop/profile_desktop.dart';
import 'package:dating_app/Presentation/View/Mobile/completeprofile_mobile.dart';
import 'package:dating_app/Presentation/View/Mobile/homepage_mobile.dart';
import 'package:dating_app/Presentation/View/Mobile/log_in_mobile.dart';
import 'package:dating_app/Presentation/View/Mobile/mobile_main.dart';
import 'package:dating_app/Presentation/View/Mobile/profile_main_mobile.dart';
import 'package:dating_app/Presentation/View/Tablet/completeprofile_tablet.dart';
import 'package:dating_app/Presentation/View/Tablet/homepage_tablet.dart';
import 'package:dating_app/Presentation/View/Tablet/log_in_tablet.dart';
import 'package:dating_app/Presentation/View/Tablet/profile_main_tablet.dart';
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

    GoRoute(
      path: '/login',
      builder: (context, state) => ResponsiveLayout(
        mobileBody: LoginScreenMobile(),
        tabletBody: LoginScreenTablet(),
        desktopBody: LoginScreenDesktop(),
      ),

    ),

    GoRoute(
      path: '/setup',
      builder: (context, state) => ResponsiveLayout(
        mobileBody: ProfileSetupMobile(),
        tabletBody: ProfileSetupTablet(),
        desktopBody: ProfileSetupPageDesktop(),
      ),

      
    ),


     GoRoute(
      path: '/homepage',
      builder: (context, state) => ResponsiveLayout(
        mobileBody: HomepageMobile(),
        tabletBody: TabletHomePage(),
        desktopBody: DesktopHomePage(),
      ),

      routes: [],
    ),


    GoRoute(
      path: '/profile',
      builder: (context, state) => ResponsiveLayout(
        mobileBody: ProfilePageMobile(),
        tabletBody: ProfilePageTablet(),
        desktopBody: ProfileDesktop(),
      ),

      routes: [],
    ),

   

    GoRoute(
      path: '/auth/success',
      builder: (context, state) => const AuthSuccessPage(),
    ),


    
  ],
);
