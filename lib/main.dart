import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/onboarding_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final seenOnboarding = await OnboardingStore.hasSeen();
  runApp(FlexibleeaApp(showOnboarding: !seenOnboarding));
}
