// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flexibleea/login/login_screen.dart';
import 'package:flexibleea/services/global_methods.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController _nameTextController =
      TextEditingController(text: '');
  final TextEditingController _phoneTextController =
      TextEditingController(text: '');
  final TextEditingController _emailTextController =
      TextEditingController(text: '');
  final TextEditingController _passTextController =
      TextEditingController(text: '');
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passFocusNode = FocusNode();
  final _signUpFormKey = GlobalKey<FormState>();
  File? imageFile;
  bool _isLoading = false;
  String? imageUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _nameTextController.dispose();
    _emailTextController.dispose();
    _passTextController.dispose();
    _phoneTextController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _submitFormSignUP() async {
    final isValid = _signUpFormKey.currentState!.validate();
    if (isValid) {
      if (imageFile == null) {
        GlobalMethod.showErrorDialog(
          ctx: context,
          error: 'Please pick an image',
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        await _auth.createUserWithEmailAndPassword(
          email: _emailTextController.text.trim().toLowerCase(),
          password: _passTextController.text.trim(),
        );
        final User? user = _auth.currentUser;
        final uid = user!.uid;
        // ignore: prefer_interpolation_to_compose_strings
        final ref =
            FirebaseStorage.instance.ref('userImages').child('$uid.jpg');
        await ref.putFile(imageFile!);
        imageUrl = await ref.getDownloadURL();
        FirebaseFirestore.instance.collection('Users').doc(uid).set({
          'id': uid,
          'name': _nameTextController.text,
          'email': _emailTextController.text,
          'phoneNumber': _phoneTextController.text,
          'userImage': imageUrl,
          'createdAt': Timestamp.now(),
        });

        Navigator.canPop(context) ? Navigator.pop(context) : null;
      } catch (error) {
        setState(() {
          _isLoading = false;
        });
        GlobalMethod.showErrorDialog(ctx: context, error: error.toString());
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Widget buildName() {
    return Form(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
          const Text(
            'Full Name',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2))
                  ]),
              height: 40,
              child: TextFormField(
                textInputAction: TextInputAction.next,
                onEditingComplete: () =>
                    FocusScope.of(context).requestFocus(_nameFocusNode),
                keyboardType: TextInputType.emailAddress,
                controller: _nameTextController,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'enter your name';
                  } else {
                    return null;
                  }
                },
                style: const TextStyle(color: Colors.black87),
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(top: 7),
                    prefixIcon: Icon(Icons.person,
                        color: Color.fromARGB(255, 15, 126, 126)),
                    hintText: 'Full Name',
                    hintStyle: TextStyle(color: Colors.black38)),
              )),
        ]));
  }

  Widget buildPhone() {
    return Form(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
          const Text(
            'Phone Number',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2))
                  ]),
              height: 40,
              child: TextFormField(
                textInputAction: TextInputAction.next,
                onEditingComplete: () =>
                    FocusScope.of(context).requestFocus(_phoneFocusNode),
                keyboardType: TextInputType.emailAddress,
                controller: _phoneTextController,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Enter phone number';
                  } else {
                    return null;
                  }
                },
                style: const TextStyle(color: Colors.black87),
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(top: 7),
                    prefixIcon: Icon(Icons.phone,
                        color: Color.fromARGB(255, 15, 126, 126)),
                    hintText: 'Phone Number',
                    hintStyle: TextStyle(color: Colors.black38)),
              )),
        ]));
  }

  Widget buildEmail() {
    return Form(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
          const Text(
            'Email',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Container(
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2))
                  ]),
              height: 40,
              child: TextFormField(
                textInputAction: TextInputAction.next,
                onEditingComplete: () =>
                    FocusScope.of(context).requestFocus(_emailFocusNode),
                keyboardType: TextInputType.emailAddress,
                controller: _emailTextController,
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
                    contentPadding: EdgeInsets.only(top: 7),
                    prefixIcon: Icon(Icons.email,
                        color: Color.fromARGB(255, 15, 126, 126)),
                    hintText: 'Email',
                    hintStyle: TextStyle(color: Colors.black38)),
              )),
        ]));
  }

  Widget buildPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Password',
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
          height: 40,
          child: TextFormField(
            textInputAction: TextInputAction.next,
            onEditingComplete: () =>
                FocusScope.of(context).requestFocus(_passFocusNode),
            keyboardType: TextInputType.visiblePassword,
            controller: _passTextController,
            obscureText: true,
            validator: (value) {
              if (value!.isEmpty || value.length < 8) {
                return 'password must be at least 8 characters';
              } else {
                return null;
              }
            },
            style: const TextStyle(color: Colors.black87),
            decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(top: 7),
                prefixIcon:
                    Icon(Icons.lock, color: Color.fromARGB(255, 15, 126, 126)),
                hintText: 'Password',
                hintStyle: TextStyle(color: Colors.black38)),
          ),
        )
      ],
    );
  }

  Widget buildLoginBtn() {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => Login())),
      child: RichText(
          text: const TextSpan(children: [
        TextSpan(
            text: 'Already have an account? ',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500)),
        TextSpan(
            text: 'Login',
            style: TextStyle(
                color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold))
      ])),
    );
  }

  void _showImageDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Choose option'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    _getFromCamera();
                  },
                  child: const Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.camera_alt,
                          color: Color.fromARGB(255, 117, 48, 134),
                        ),
                      ),
                      Text(
                        'Camera',
                        style:
                            TextStyle(color: Color.fromARGB(255, 117, 48, 134)),
                      )
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    _getFromPhotos();
                  },
                  child: const Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.photo,
                          color: Color.fromARGB(255, 117, 48, 134),
                        ),
                      ),
                      Text(
                        'Photos',
                        style:
                            TextStyle(color: Color.fromARGB(255, 117, 48, 134)),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  void _getFromCamera() async {
    XFile? pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    _cropImage(pickedFile!.path);
    // ignore: use_build_context_synchronously
    Navigator.pop(context);
  }

  void _getFromPhotos() async {
    XFile? pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    _cropImage(pickedFile!.path);
    Navigator.pop(context);
  }

  void _cropImage(filePath) async {
    CroppedFile? croppedImage = await ImageCropper()
        .cropImage(sourcePath: filePath, maxHeight: 1080, maxWidth: 1080);
    if (croppedImage != null) {
      setState(() {
        imageFile = File(croppedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

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
                    const SizedBox(height: 110),
                    buildName(),
                    const SizedBox(height: 20),
                    buildPhone(),
                    const SizedBox(height: 20),
                    buildEmail(),
                    const SizedBox(height: 20),
                    buildPassword(),
                    const SizedBox(height: 40),
                    _isLoading
                        ? Center(
                            child: SizedBox(
                              width: 70,
                              height: 70,
                              child: const CircularProgressIndicator(),
                            ),
                          )
                        : MaterialButton(
                            onPressed: () {
                              _submitFormSignUP();
                            },
                            color: Colors.amber,
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                    const SizedBox(height: 20),
                    buildLoginBtn(),
                  ],
                ),
              ),
            ),
            Form(
              key: _signUpFormKey,
              child: Column(children: [
                GestureDetector(
                  onTap: () {
                    _showImageDialog();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 175, horizontal: 150),
                    child: Container(
                      width: size.width * 0.24,
                      height: size.width * 0.24,
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 3,
                          color: const Color.fromARGB(255, 117, 48, 134),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: imageFile == null
                              ? const Icon(
                                  Icons.camera_enhance_sharp,
                                  color: Color.fromARGB(255, 117, 48, 134),
                                  size: 30,
                                )
                              : Image.file(
                                  imageFile!,
                                  fit: BoxFit.fill,
                                )),
                    ),
                  ),
                )
              ]),
            )
          ],
        )),
      ),
    );
  }
}
