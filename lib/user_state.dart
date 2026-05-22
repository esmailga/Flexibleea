// ignore_for_file: avoid_print
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flexibleea/home/home_screen_freelancer.dart';
import 'package:flexibleea/login/login_screen.dart';
import 'package:flutter/material.dart';

class UserState extends StatelessWidget {
  const UserState({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, userSnapshot) {
        if (userSnapshot.data == null) {
          print('User is not logged in');
          return Login();
        } else if (userSnapshot.hasData) {
          print('User is already logged in');
          return const HomeScreen();
        } else if (userSnapshot.hasError) {
          return const Scaffold(
            body: Center(
                child: Text(
              'Error occured, please try again later',
            )),
          );
        } else if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return const Scaffold(
          body: Center(
              child: Text(
            'Something is not right',
          )),
        );
      },
    );
  }
}
