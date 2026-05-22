import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flexibleea/services/global_methods.dart';
import 'package:flexibleea/widgets/bottom_nav_bar_admin.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String updatedName = '';

  updatedData(id, value) async {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(id)
        .update({'name': value});
  }

  deletedata(id) async {
    await FirebaseFirestore.instance.collection('Users').doc(id).delete();
  }

  getdata() async {
    var result = await FirebaseFirestore.instance.collection('Users').get();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Page'),
        ),
        bottomNavigationBar: AdminNavigationBarApp(indexNum: 0),
        backgroundColor: Colors.transparent,
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('Users').snapshots(),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else {
                if (snapshot.hasData) {
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data?.docs.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: GestureDetector(
                            onTap: () {
                              Get.defaultDialog(
                                content: TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      updatedName = value;
                                    });
                                  },
                                ),
                                actions: [
                                  ElevatedButton(
                                      onPressed: () {
                                        updatedData(
                                            snapshot.data.docs[index].id,
                                            updatedName);
                                        setState(() {});
                                      },
                                      child: const Text('Update User Name')),
                                ],
                              );
                            },
                            child: const Icon(Icons.person),
                          ),
                          title: Text("${snapshot.data.docs[index]['name']}"),
                          subtitle:
                              Text("${snapshot.data.docs[index]['email']}"),
                          trailing: GestureDetector(
                            onTap: () {
                              deletedata(snapshot.data.docs[index].id);
                              setState(() {});
                            },
                            child: const Icon(
                              Icons.delete,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  GlobalMethod.showErrorDialog(
                      ctx: context, error: 'Error occurred retrieving data');
                }
              }
              return Scaffold(
                body: Container(
                  alignment: Alignment.bottomRight,
                ),
              );
            }),
      ),
    );
  }
}
