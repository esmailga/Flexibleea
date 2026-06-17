# Flexibleea

Flexibleea is a professional Flutter-based freelancer marketplace application designed to support flexible pay, customizable schedules, and profile-driven talent discovery. This repository demonstrates a cross-platform Flutter implementation with Firebase backend services for authentication, storage, and realtime data.

---

## Project Overview
Flexibleea provides a modern mobile-first experience for freelancers and recruiters.

Key capabilities include:
- Freelancer registration with profile image upload
- Secure authentication via Firebase Auth
- Recruiter workflows for discovering talent and sending requests
- Admin management for users and expertise listings
- Realtime Firestore feeds for live expertise display
- Search, filtering, and request workflows for matched expertise

---

## Core Features
- Onboarding experience using `introduction_screen`
- Email login and admin login flows
- Forgot password recovery
- Freelancer expertise browsing with category filters
- Search by freelancer name or skill
- Detailed freelancer profiles with contact and availability information
- Admin dashboard for user and expertise moderation
- Image upload, cropping, and Firebase Storage integration

---

## Technology Stack
- Flutter
- Dart
- Firebase Authentication
- curved_navigation_bar
- fluttertoast
- smooth_page_indicator


---

## Project Structure
- `lib/main.dart` — App entry point and Firebase initialization
- `lib/Persistent/` — Onboarding flow and user state routing
- `lib/login/` — Login screen, admin login, and password recovery
- `lib/signup/` — User registration and profile image upload
- `lib/home/` — Freelancer explorer and expertise feed
- `lib/discover/` — Search and discovery screens
- `lib/freelancer/` — Freelancer expertise, details, and profile pages
- `lib/admin/` — Admin user and expertise management
- `lib/widgets/` — Shared UI components and navigation bars
- `lib/services/` — Global utilities and reusable methods

---

## Screenshots & Showcase
The repository contains preview assets for onboarding and authentication screens.

- `assets/images/intro.jpg` — Onboarding presentation
- `assets/images/login.jpg` — Login screen layout
- `assets/images/signup.jpg` — Signup screen layout
- `assets/images/search_bg.png` — Search page background

Open these assets in the project to review the visual presentation.

---


## Useful Links
- Flutter: https://flutter.dev
- Firebase: https://firebase.google.com
- GetX: https://pub.dev/packages/get
- Packages in this project: `cached_network_image`, `image_picker`, `image_cropper`, `url_launcher`, `curved_navigation_bar`, `fluttertoast`, `smooth_page_indicator`, `introduction_screen`

---

## Notes
- Supports multiple target platforms: Android, iOS, macOS, Windows, Linux, and web.
- Modular architecture makes it easy to extend with payment, messaging, or team collaboration features.
- Firebase services power authentication, file storage, and realtime data streaming.
