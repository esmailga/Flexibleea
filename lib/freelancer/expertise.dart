// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flexibleea/Persistent/persistant.dart';
import 'package:flexibleea/services/global_methods.dart';
import 'package:flexibleea/services/global_variables.dart';
import 'package:flexibleea/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:time_range_picker/time_range_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_document_picker/flutter_document_picker.dart';

class Expertise extends StatefulWidget {
  const Expertise({super.key});
  static const String title = 'Date (Range) & Time';
  @override
  State<Expertise> createState() => _ExpertiseState();
}

class _ExpertiseState extends State<Expertise> {
  int index = 0;
  final TextEditingController _expertiseController =
      TextEditingController(text: 'Select Expertise');
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _jobDescriptionController =
      TextEditingController();
  final TextEditingController _datePickerController =
      TextEditingController(text: 'Select available date');
  final TextEditingController _timePickerController =
      TextEditingController(text: 'Select available time');
  final TextEditingController _payRateController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  DateTimeRange? picked;

  TimeRange? result;

  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
    _expertiseController.dispose();
    _jobTitleController.dispose();
    _jobDescriptionController.dispose();
    _datePickerController.dispose();
    _timePickerController.dispose();
    _payRateController.dispose();
  }

  Widget _textTitles({required String label}) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _textFormField({
    required String valueKey,
    required TextEditingController controller,
    required bool enabled,
    required Function fct,
    required int maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: InkWell(
        onTap: () {
          fct();
        },
        child: TextFormField(
          validator: (value) {
            if (value!.isEmpty) {
              return 'Value is missing';
            }
            return null;
          },
          controller: controller,
          enabled: enabled,
          key: ValueKey(valueKey),
          style: const TextStyle(
            color: Color.fromARGB(255, 26, 25, 25),
          ),
          maxLines: valueKey == 'JobDescription' ? 2 : 1,
          maxLength: maxLength,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
              filled: true,
              fillColor: Color.fromARGB(39, 45, 45, 45),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
              errorBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              )),
        ),
      ),
    );
  }

  _showExpertiseDialog({required Size size}) {
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: Colors.black54,
            title: const Text(
              'Expertise',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            content: SizedBox(
              width: size.width * 0.9,
              child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: Persistant.expertiseList.length,
                  itemBuilder: (ctx, index) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _expertiseController.text =
                              Persistant.expertiseList[index];
                        });
                        Navigator.pop(context);
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_right_alt_outlined,
                            color: Colors.grey,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              Persistant.expertiseList[index],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  }),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.canPop(context) ? Navigator.pop(context) : null;
                },
                child: const Text(
                  'back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          );
        });
  }

  void _pickDateDialog() async {
    picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030, 12, 31),
      currentDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _datePickerController.text =
            '${picked!.start.year}/${picked!.start.month}/${picked!.start.day}  To  ${picked!.end.year}/${picked!.end.month}/${picked!.end.day}';
      });
    }
  }

  void _showTimePicker() async {
    result = await showTimeRangePicker(
      context: context,
      paintingStyle: PaintingStyle.fill,
      strokeColor: const Color.fromARGB(195, 162, 47, 220),
      handlerColor: const Color.fromARGB(195, 162, 47, 220),
    );
    if (result != null) {
      setState(() {
        _timePickerController.text =
            '${result!.startTime} - ${result!.endTime}';
      });
    }
  }

  void _uploadExpertise() async {
    final freelancerId = const Uuid().v4();
    User? user = FirebaseAuth.instance.currentUser;
    final _uid = user!.uid;
    final isValid = _formKey.currentState!.validate();

    if (isValid) {
      if (_datePickerController.text == 'Date' ||
          _expertiseController.text == 'Select Expertise') {
        GlobalMethod.showErrorDialog(
            ctx: context, error: 'Please Enter everything');
        return;
      }
      setState(() {
        _isLoading = true;
      });
      try {
        await FirebaseFirestore.instance
            .collection('Freelancer Expertise')
            .doc(freelancerId)
            .set({
          'freelancerId': freelancerId,
          'uploadedBy': _uid,
          'email': user.email,
          'category': _expertiseController.text,
          'expertise': _jobTitleController.text,
          'description': _jobDescriptionController.text,
          'availableDate': _datePickerController.text,
          'availableTime': _timePickerController.text,
          'hourlyPayRate': _payRateController.text,
          'reviews': [],
          'recruitment': true,
          'createdAt': Timestamp.now(),
          'name': name,
          'userImage': userImage,
          'phoneNumber': phone,
          'numberRequests': 0,
        });
        await Fluttertoast.showToast(
          msg: 'Uploaded Successfully',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.grey,
          fontSize: 18.0,
        );

        _jobTitleController.clear();
        _jobDescriptionController.clear();
        _payRateController.clear();
        setState(() {
          _expertiseController.text = 'Choose category';
          _datePickerController.text = 'Choose Available date';
          _timePickerController.text = 'Choose Available time';
        });
      } catch (error) {
        {
          setState(() {
            _isLoading = false;
          });
          GlobalMethod.showErrorDialog(ctx: context, error: error.toString());
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      print('Not Valid');
    }
  }

  Future<firebase_storage.UploadTask> uploadFile(File file) async {
    firebase_storage.UploadTask uploadTask;
    firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
        .ref()
        .child('pdfs')
        .child('/some-file.pdf');

    final metadata = firebase_storage.SettableMetadata(
        contentType: 'file/pdf',
        customMetadata: {'picked-file-path': file.path});
    print("Uploading..!");

    uploadTask = ref.putData(await file.readAsBytes(), metadata);

    print("done..!");
    return Future.value(uploadTask);
  }

  void _uploadQualification() async {
    final path = await FlutterDocumentPicker.openDocument();
    print(path);
    File file = File(path!);
    firebase_storage.UploadTask task = await uploadFile(file);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Scaffold(
        bottomNavigationBar: BottomNavigationBarApp(indexNum: 2),
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Add/Modify'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(223, 163, 47, 220),
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(7.0),
            child: Card(
              color: Colors.white,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Availability',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const Divider(
                      thickness: 1,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _textTitles(label: 'Category: '),
                            _textFormField(
                              valueKey: 'Expertise',
                              controller: _expertiseController,
                              enabled: false,
                              fct: () {
                                _showExpertiseDialog(size: size);
                              },
                              maxLength: 100,
                            ),
                            _textTitles(label: 'Expertise'),
                            _textFormField(
                              valueKey: 'Jobtitle',
                              controller: _jobTitleController,
                              enabled: true,
                              fct: () {},
                              maxLength: 100,
                            ),
                            _textTitles(label: 'Description'),
                            _textFormField(
                              valueKey: 'JobDescription',
                              controller: _jobDescriptionController,
                              enabled: true,
                              fct: () {},
                              maxLength: 200,
                            ),
                            _textTitles(label: 'Date: '),
                            _textFormField(
                              valueKey: 'Deadline',
                              controller: _datePickerController,
                              enabled: false,
                              fct: () {
                                _pickDateDialog();
                              },
                              maxLength: 100,
                            ),
                            _textTitles(label: 'Time: '),
                            _textFormField(
                              valueKey: 'Deadline',
                              controller: _timePickerController,
                              enabled: false,
                              fct: () {
                                _showTimePicker();
                              },
                              maxLength: 100,
                            ),
                            _textTitles(label: 'Hourly Rate: '),
                            _textFormField(
                              valueKey: 'Jobtitle',
                              controller: _payRateController,
                              enabled: true,
                              fct: () {},
                              maxLength: 30,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : MaterialButton(
                                onPressed: () {
                                  _uploadQualification();
                                },
                                color: const Color.fromARGB(223, 122, 47, 220),
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Upload',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 25,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Icon(
                                        Icons.upload_file_rounded,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : MaterialButton(
                                onPressed: () {
                                  _uploadExpertise();
                                },
                                color: const Color.fromARGB(223, 163, 47, 220),
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Confirm',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 25,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
