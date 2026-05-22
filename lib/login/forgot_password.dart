// ignore_for_file: use_build_context_synchronously
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'login_screen.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _forgetPassTextConteroller =
      TextEditingController(text: '');

  Widget buildForget() {
    return Form(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Password Reset',
          style: TextStyle(
              color: Color.fromARGB(255, 31, 28, 28),
              fontSize: 28,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        const Text(
          'Email',
          style: TextStyle(
              color: Color.fromARGB(255, 31, 28, 28),
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
              ]),
          height: 60,
          child: TextFormField(
            controller: _forgetPassTextConteroller,
            validator: (value) {
              if (value!.isEmpty || !value.contains('@')) {
                return 'enter valid email address';
              } else {
                return null;
              }
            },
            style: const TextStyle(color: Colors.black87),
            decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(top: 14),
                prefixIcon:
                    Icon(Icons.email, color: Color.fromARGB(255, 15, 126, 126)),
                hintText: 'Email',
                hintStyle: TextStyle(color: Colors.black38)),
          ),
        )
      ],
    ));
  }

  Widget buildForgetBtn() {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 25),
        width: double.infinity,
        child: ButtonTheme(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(15),
                backgroundColor: const Color.fromARGB(255, 255, 206, 28),
              ),
              // ignore: avoid_print
              onPressed: _forgetPassSubmitForm,
              child: const Text(
                'Reset Password',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            )));
  }

  void _forgetPassSubmitForm() async {
    try {
      await _auth.sendPasswordResetEmail(
        email: _forgetPassTextConteroller.text,
      );
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => Login()));
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: GestureDetector(
            child: Stack(
          children: <Widget>[
            Container(
              height: double.infinity,
              width: double.infinity,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                    Color.fromARGB(102, 29, 226, 226),
                    Color.fromARGB(153, 102, 199, 199),
                    Color.fromARGB(204, 64, 145, 145),
                    Color.fromARGB(255, 22, 110, 110),
                  ])),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: 80, right: 80),
                      child: Image.asset('assets/icons/logo.png'),
                    ),
                    const SizedBox(height: 50),
                    buildForget(),
                    buildForgetBtn(),
                  ],
                ),
              ),
            )
          ],
        )),
      ),
    );
  }
}
