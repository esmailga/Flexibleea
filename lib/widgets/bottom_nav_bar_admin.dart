import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flexibleea/admin/admin_delete_expertise.dart';
import 'package:flexibleea/admin/admin_home.dart';
import 'package:flexibleea/user_state.dart';
import 'package:flutter/material.dart';

class AdminNavigationBarApp extends StatelessWidget {
  int indexNum = 0;
  AdminNavigationBarApp({super.key, required this.indexNum});

  void _logout(context) {
    final FirebaseAuth auth = FirebaseAuth.instance;

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.black54,
            title: const Row(children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Sign out',
                  style: TextStyle(color: Colors.white, fontSize: 28),
                ),
              ),
            ]),
            content: const Text(
              'Do you want to log out?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.canPop(context) ? Navigator.pop(context) : null;
                },
                child: const Text(
                  'No',
                  style: TextStyle(color: Colors.amber, fontSize: 18),
                ),
              ),
              TextButton(
                onPressed: () {
                  auth.signOut();
                  Navigator.canPop(context) ? Navigator.pop(context) : null;
                  Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (_) => UserState()));
                },
                child: const Text(
                  'Yes',
                  style: TextStyle(color: Colors.amber, fontSize: 18),
                ),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      color: const Color.fromARGB(140, 157, 47, 220),
      buttonBackgroundColor: const Color.fromARGB(223, 163, 47, 220),
      backgroundColor: const Color.fromARGB(156, 211, 141, 247),
      height: 70,
      index: indexNum,
      items: const [
        Icon(
          Icons.person_2,
          size: 19,
          color: Colors.white,
        ),
        Icon(
          Icons.list,
          size: 19,
          color: Colors.white,
        ),
        Icon(
          Icons.exit_to_app_rounded,
          size: 19,
          color: Colors.white,
        )
      ],
      animationDuration: const Duration(
        milliseconds: 350,
      ),
      animationCurve: Curves.easeInCubic,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => AdminHomePage()));
        } else if (index == 1) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const AdminExpertise()));
        } else if (index == 2) {
          _logout(context);
        }
      },
    );
  }
}
