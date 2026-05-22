import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flexibleea/freelancer/freelancer_details.dart';
import 'package:flexibleea/services/global_methods.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ExpertiseWidget extends StatefulWidget {
  final String expertiseTitle;
  final String expertiseDescription;
  final String freelancerId;
  final String uploadedBy;
  final String userImage;
  final String name;
  final bool recruitment;
  final String email;
  final String phone;
  final String availableDate;
  final String availableTime;

  const ExpertiseWidget({
    super.key,
    required this.expertiseTitle,
    required this.expertiseDescription,
    required this.freelancerId,
    required this.uploadedBy,
    required this.userImage,
    required this.name,
    required this.recruitment,
    required this.email,
    required this.phone,
    required this.availableDate,
    required this.availableTime,
  });

  @override
  State<ExpertiseWidget> createState() => _ExpertiseWidgetState();
}

class _ExpertiseWidgetState extends State<ExpertiseWidget> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  _deleteExpertise() {
    User? user = _auth.currentUser;
    final uid = user!.uid;
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            actions: [
              TextButton(
                onPressed: () async {
                  try {
                    if (widget.uploadedBy == uid) {
                      await FirebaseFirestore.instance
                          .collection('Freelancer Expertise')
                          .doc(widget.freelancerId)
                          .delete();
                      await Fluttertoast.showToast(
                        msg: 'Expertise deleted',
                        toastLength: Toast.LENGTH_LONG,
                        backgroundColor: Colors.grey,
                        fontSize: 18.0,
                      );
                      // ignore: use_build_context_synchronously
                      Navigator.canPop(context) ? Navigator.pop(context) : null;
                    } else {
                      GlobalMethod.showErrorDialog(
                          ctx: ctx, error: 'Cannot perform action');
                    }
                  } catch (error) {
                    GlobalMethod.showErrorDialog(
                        ctx: ctx, error: 'Expertise cannot be deleted');
                  } finally {}
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_rounded,
                      color: Colors.purple,
                    ),
                    Text(
                      'Delete',
                      style: TextStyle(color: Colors.purple),
                    )
                  ],
                ),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(87, 236, 207, 237),
      elevation: 8,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: ListTile(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => FreelancerDetailsScreen(
                uploadedBy: widget.uploadedBy,
                freelancerId: widget.freelancerId,
              ),
            ),
          );
        },
        onLongPress: () {
          _deleteExpertise();
        },
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.only(right: 8),
          decoration: const BoxDecoration(
            border: Border(
              right: BorderSide(width: 1.5),
            ),
          ),
          child: SizedBox(
              height: 60, width: 50, child: Image.network(widget.userImage)),
        ),
        title: Text(
          widget.expertiseTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.deepPurpleAccent,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(
              height: 4,
            ),
            Text(
              widget.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              widget.expertiseDescription,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              widget.availableDate,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(
              height: 2,
            ),
            Text(
              widget.availableTime,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.keyboard_arrow_right,
          size: 30,
          color: Colors.black,
        ),
      ),
    );
  }
}
