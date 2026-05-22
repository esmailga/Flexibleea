import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flexibleea/widgets/all_freelancers_widget.dart';
import 'package:flutter/material.dart';

import '../widgets/bottom_nav_bar.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final TextEditingController _searchQueryController = TextEditingController();
  String searchQuery = 'Search query';

  Widget _buldSearchField() {
    return TextField(
      controller: _searchQueryController,
      autocorrect: true,
      decoration: const InputDecoration(
        hintText: 'Search freelancer...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Color.fromARGB(214, 255, 255, 255)),
      ),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
      onChanged: (query) => updateSearchQuery(query),
    );
  }

  List<Widget> _buildActions() {
    return <Widget>[
      IconButton(
        onPressed: () {
          _clearSearchQuery();
        },
        icon: const Icon(Icons.clear_rounded),
      ),
    ];
  }

  void _clearSearchQuery() {
    setState(() {
      _searchQueryController.clear();
      updateSearchQuery('');
    });
  }

  void updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
      print(searchQuery);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Scaffold(
        bottomNavigationBar: BottomNavigationBarApp(indexNum: 1),
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(223, 163, 47, 220),
            ),
          ),
          automaticallyImplyLeading: false,
          title: _buldSearchField(),
          actions: _buildActions(),
        ),
        body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Users')
                .where('name', isGreaterThanOrEqualTo: searchQuery)
                .snapshots(),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.connectionState == ConnectionState.active) {
                if (snapshot.data!.docs.isNotEmpty) {
                  return ListView.builder(
                      itemCount: snapshot.data?.docs.length,
                      itemBuilder: (BuildContext context, int index) {
                        return AllFreelancersWidget(
                            userID: snapshot.data?.docs[index]['id'],
                            userName: snapshot.data?.docs[index]['name'],
                            email: snapshot.data?.docs[index]['email'],
                            phoneNumber: snapshot.data?.docs[index]
                                ['phoneNumber'],
                            userImageUrl: snapshot.data?.docs[index]
                                ['userImage']);
                      });
                } else {
                  return const Center(
                    child: Text('There is no users on database'),
                  );
                }
              }
              return const Center(
                child: Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                ),
              );
            }),
      ),
    );
  }
}
