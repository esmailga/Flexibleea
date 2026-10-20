// Screenshot demo: runs the real UI against in-memory demo data, so README
// screenshots can be captured without a device or Firebase project.
//
// Build & capture with tool/screenshots/capture.sh. Pick a screen with
// ?screen=onboarding|login|explore|people|details|profile|form|admin and
// optionally &theme=dark.
import 'package:flexibleea/app.dart';
import 'package:flexibleea/features/admin/admin_shell.dart';
import 'package:flexibleea/features/auth/login_screen.dart';
import 'package:flexibleea/features/home/home_shell.dart';
import 'package:flexibleea/features/listing/listing_details_screen.dart';
import 'package:flexibleea/features/listing/listing_form_screen.dart';
import 'package:flexibleea/features/onboarding/onboarding_screen.dart';
import 'package:flexibleea/features/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'demo_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lay out with the real font from the first frame.
  await GoogleFonts.pendingFonts([GoogleFonts.plusJakartaSans()])
      .timeout(const Duration(seconds: 10), onTimeout: () => const <void>[]);
  final params = Uri.base.queryParameters;
  final screen = params['screen'] ?? 'explore';
  final data = DemoData('${Uri.base.origin}/demo_avatars');
  final featured = data.listings.firstWhere((l) => l.ownerId == 'demo-abdullah-alqahtani');

  final Widget home = switch (screen) {
    'onboarding' => OnboardingScreen(onFinished: () {}),
    'login' => const LoginScreen(),
    'people' => const HomeShell(initialIndex: 1),
    'details' => ListingDetailsScreen(listingId: featured.id, initial: featured),
    'profile' => const ProfileScreen(userId: 'demo-noura-alotaibi'),
    'form' => ListingFormScreen(existing: featured),
    'admin' => const AdminShell(),
    _ => const HomeShell(),
  };

  runApp(FlexibleeaApp(
    showOnboarding: false,
    auth: DemoAuth(signedIn: screen != 'login' && screen != 'onboarding', admin: screen == 'admin'),
    users: DemoUsers(data),
    listings: DemoListings(data),
    themeMode: params['theme'] == 'dark' ? ThemeMode.dark : ThemeMode.light,
    home: home,
  ));
}
