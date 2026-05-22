import 'package:flexibleea/freelancer/profie_freelancer.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AllFreelancersWidget extends StatefulWidget {
  final String userID;
  final String userName;
  final String email;
  final String phoneNumber;
  final String userImageUrl;

  const AllFreelancersWidget({
    super.key,
    required this.userID,
    required this.userName,
    required this.email,
    required this.phoneNumber,
    required this.userImageUrl,
  });

  @override
  State<AllFreelancersWidget> createState() => _AllFreelancersWidgetState();
}

class _AllFreelancersWidgetState extends State<AllFreelancersWidget> {
  @override
  void _mailTo() async {
    var mailUrl = 'mailto:${widget.email}';
    print('widget.email ${widget.email}');
    if (await canLaunchUrlString(mailUrl)) {
      await launchUrlString(mailUrl);
    } else {
      print('Error');
      throw 'Error Occurred';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      color: Colors.white12,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        onTap: () {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      FreelancerProfile(userID: widget.userID)));
        },
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.only(right: 12),
          decoration: const BoxDecoration(
            border: Border(
              right: BorderSide(width: 1),
            ),
          ),
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            radius: 20,
            // ignore: prefer_if_null_operators
            child: Image.network(
              // ignore: prefer_if_null_operators, unnecessary_null_comparison
              widget.userImageUrl == null
                  ? 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460__340.png'
                  : widget.userImageUrl,
            ),
          ),
        ),
        title: Text(
          widget.userName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        subtitle: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Visit Profile',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: () {
            _mailTo();
          },
          icon: const Icon(
            Icons.mail_rounded,
            size: 30,
            color: Colors.purple,
          ),
        ),
      ),
    );
  }
}
