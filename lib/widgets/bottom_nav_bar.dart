import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flexibleea/discover/discover_page.dart';
import 'package:flexibleea/freelancer/expertise.dart';
import 'package:flexibleea/freelancer/profie_freelancer.dart';
import 'package:flexibleea/home/home_screen_freelancer.dart';
import 'package:flexibleea/user_state.dart';
import 'package:flutter/material.dart';

class BottomNavigationBarApp extends StatelessWidget {
  int indexNum = 0;
  BottomNavigationBarApp({super.key, required this.indexNum});

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
          Icons.home,
          size: 19,
          color: Colors.white,
        ),
        Icon(
          Icons.search,
          size: 19,
          color: Colors.white,
        ),
        Icon(
          Icons.edit,
          size: 19,
          color: Colors.white,
        ),
        Icon(
          Icons.person,
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
              context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        } else if (index == 1) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => DiscoverPage()));
        } else if (index == 2) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const Expertise()));
        } else if (index == 3) {
          final FirebaseAuth auth = FirebaseAuth.instance;
          final User? user = auth.currentUser;
          final String uid = user!.uid;
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => FreelancerProfile(
                        userID: uid,
                      )));
        } else if (index == 4) {
          _logout(context);
        }
      },
    );
  }
}
