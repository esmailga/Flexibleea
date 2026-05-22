import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flexibleea/Persistent/persistant.dart';
import 'package:flexibleea/home/home_screen_freelancer.dart';
import 'package:flexibleea/services/global_methods.dart';
import 'package:flexibleea/services/global_variables.dart';
import 'package:flexibleea/widgets/reviews_widget.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:uuid/uuid.dart';

class FreelancerDetailsScreen extends StatefulWidget {
  final String uploadedBy;
  final String freelancerId;

  const FreelancerDetailsScreen({
    super.key,
    required this.uploadedBy,
    required this.freelancerId,
  });
  @override
  State<FreelancerDetailsScreen> createState() =>
      _FreelancerDetailsScreenState();
}

class _FreelancerDetailsScreenState extends State<FreelancerDetailsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _reviewController = TextEditingController();
  bool _isReviewing = false;
  String? authorName;
  String? userImageUrl;
  String? expertiseCategory;
  String? expertiseDescription;
  String? hourlyPayRate;
  String? expertiseTitle;
  bool? recruitment;
  Timestamp? postedDateTimeStamp;
  Timestamp? dateRange;
  String? requestDate;
  String? availableDate;
  String? availableTime;
  String? email = '';
  String? phoneNumber = '';
  int requests = 0;
  bool isDateAvailable = false;
  bool isTimeAvailable = false;
  final bool _isLoading = false;
  bool showReview = false;

  requestExpertise() {
    final Uri param = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Requesting expertise in $expertise&body=Greetings,',
    );
    final url = param.toString();
    launchUrlString(url);
    addRequests();
  }

  void addRequests() async {
    var docRef = FirebaseFirestore.instance
        .collection('Freelancer Expertise')
        .doc(widget.freelancerId);

    docRef.update({
      'numberRequests': requests + 1,
    });

    Navigator.pop(context);
  }

  viewQualifications() {}

  void getFreelancerDatab() async {
    final DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.uploadedBy)
        .get();

    setState(() {
      authorName = userDoc.get('name');
      userImageUrl = userDoc.get('userImage');
    });
    final DocumentSnapshot expertiseDatabase = await FirebaseFirestore.instance
        .collection('Freelancer Expertise')
        .doc(widget.freelancerId)
        .get();
    setState(() {
      expertiseTitle = expertiseDatabase.get('expertise');
      expertiseDescription = expertiseDatabase.get('description');
      recruitment = expertiseDatabase.get('recruitment');
      email = expertiseDatabase.get('email');
      phoneNumber = expertiseDatabase.get('phoneNumber');
      requests = expertiseDatabase.get('numberRequests');
      postedDateTimeStamp = expertiseDatabase.get('createdAt');
      availableDate = expertiseDatabase.get('availableDate');
      availableTime = expertiseDatabase.get('availableTime');
      hourlyPayRate = expertiseDatabase.get('hourlyPayRate');
    });
  }

  Widget dividerWidget() {
    return const Column(
      children: [
        SizedBox(
          height: 8,
        ),
        Divider(
          thickness: 2,
          color: Colors.grey,
        ),
        SizedBox(
          height: 8,
        ),
      ],
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getFreelancerDatab();
    Persistant persistantObject = Persistant();
    persistantObject.getFreeLancerData();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(223, 163, 47, 220),
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              size: 35,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()));
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Card(
                  color: Colors.white70,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            expertiseTitle == null ? '' : expertiseTitle!,
                            maxLines: 3,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 3,
                                  color:
                                      const Color.fromARGB(255, 109, 19, 199),
                                ),
                                shape: BoxShape.rectangle,
                                image: DecorationImage(
                                  image: NetworkImage(
                                    userImageUrl == null
                                        ? 'https://uxwing.com/wp-content/themes/uxwing/download/peoples-avatars/no-profile-picture-icon.png'
                                        : userImageUrl!,
                                  ),
                                  fit: BoxFit.fitHeight,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    authorName == null ? '' : authorName!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                    phoneNumber!,
                                    style: const TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        dividerWidget(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              requests.toString(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            const Text(
                              'Requests',
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(
                              width: 15,
                            ),
                            const Icon(
                              Icons.how_to_reg,
                              color: Colors.black,
                            ),
                          ],
                        ),
                        FirebaseAuth.instance.currentUser!.uid !=
                                widget.uploadedBy
                            ? Container()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  dividerWidget(),
                                  const Text(
                                    'Availability',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          User? user = _auth.currentUser;
                                          final uid = user!.uid;
                                          if (uid == widget.uploadedBy) {
                                            try {
                                              FirebaseFirestore.instance
                                                  .collection(
                                                      'Freelancer Expertise')
                                                  .doc(widget.freelancerId)
                                                  .update(
                                                      {'recruitment': true});
                                            } catch (error) {
                                              GlobalMethod.showErrorDialog(
                                                  ctx: context,
                                                  error:
                                                      'action is not completed');
                                            }
                                          } else {
                                            GlobalMethod.showErrorDialog(
                                                ctx: context,
                                                error: 'action prohibited');
                                          }
                                          getFreelancerDatab();
                                        },
                                        child: const Text(
                                          'ON',
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Color.fromARGB(185, 0, 0, 0),
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Opacity(
                                        opacity: recruitment == true ? 1 : 0,
                                        child: const Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 40,
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          User? user = _auth.currentUser;
                                          final uid = user!.uid;
                                          if (uid == widget.uploadedBy) {
                                            try {
                                              FirebaseFirestore.instance
                                                  .collection(
                                                      'Freelancer Expertise')
                                                  .doc(widget.freelancerId)
                                                  .update(
                                                      {'recruitment': false});
                                            } catch (error) {
                                              GlobalMethod.showErrorDialog(
                                                  ctx: context,
                                                  error:
                                                      'action is not completed');
                                            }
                                          } else {
                                            GlobalMethod.showErrorDialog(
                                                ctx: context,
                                                error: 'action prohibited');
                                          }
                                          getFreelancerDatab();
                                        },
                                        child: const Text(
                                          'OFF',
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Color.fromARGB(185, 0, 0, 0),
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Opacity(
                                        opacity: recruitment == false ? 1 : 0,
                                        child: const Icon(
                                          Icons.error_rounded,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  dividerWidget(),
                                ],
                              ),
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        Text(
                          expertiseDescription == null
                              ? ''
                              : expertiseDescription!,
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                        dividerWidget(),
                        const Text(
                          'Available Dates',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          availableDate == null ? '' : availableDate!,
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        const Text(
                          'Available Time',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          availableTime == null ? '' : availableTime!,
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                        dividerWidget(),
                        const Text(
                          'Hourly Payrate',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        Text(
                          hourlyPayRate == null ? '' : hourlyPayRate!,
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(
                          height: 25,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FirebaseAuth.instance.currentUser!.uid != widget.uploadedBy
                      ? Center(
                          child: MaterialButton(
                            onPressed: () {
                              requestExpertise();
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
                                    'Request Freelancer',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 25,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Container(),
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Card(
                  color: Colors.white70,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(
                            milliseconds: 500,
                          ),
                          child: _isReviewing
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      flex: 3,
                                      child: TextField(
                                        controller: _reviewController,
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                        maxLength: 200,
                                        keyboardType: TextInputType.text,
                                        maxLines: 6,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Theme.of(context)
                                              .scaffoldBackgroundColor,
                                          enabledBorder:
                                              const UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.white,
                                            ),
                                          ),
                                          focusedBorder:
                                              const OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.purpleAccent),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Flexible(
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            child: MaterialButton(
                                              onPressed: () async {
                                                if (_reviewController
                                                        .text.length <
                                                    7) {
                                                  GlobalMethod.showErrorDialog(
                                                      ctx: context,
                                                      error:
                                                          'Review cannot be less than 7 characters');
                                                } else {
                                                  final generatedId =
                                                      const Uuid().v4();
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection(
                                                          'Freelancer Expertise')
                                                      .doc(widget.freelancerId)
                                                      .update({
                                                    'reviews':
                                                        FieldValue.arrayUnion([
                                                      {
                                                        'Id': FirebaseAuth
                                                            .instance
                                                            .currentUser!
                                                            .uid,
                                                        'reviewId': generatedId,
                                                        'name': name,
                                                        'userImageUrl':
                                                            userImage,
                                                        'reviewBody':
                                                            _reviewController
                                                                .text,
                                                        'time': Timestamp.now(),
                                                      }
                                                    ]),
                                                  });
                                                  await Fluttertoast.showToast(
                                                    msg:
                                                        'Your review has been added',
                                                    toastLength:
                                                        Toast.LENGTH_LONG,
                                                    backgroundColor:
                                                        Colors.grey,
                                                    fontSize: 18.0,
                                                  );
                                                  _reviewController.clear();
                                                }
                                                setState(() {
                                                  showReview = true;
                                                });
                                              },
                                              color: const Color.fromARGB(
                                                  223, 122, 47, 220),
                                              elevation: 4,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'Post',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _isReviewing = !_isReviewing;
                                                showReview = false;
                                              });
                                            },
                                            child: const Text('Cancel'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FirebaseAuth.instance.currentUser!.uid !=
                                            widget.uploadedBy
                                        ? IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _isReviewing = !_isReviewing;
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.add_comment_rounded,
                                              color: Color.fromARGB(
                                                  223, 122, 47, 220),
                                              size: 40,
                                            ),
                                          )
                                        : Container(),
                                    const SizedBox(width: 230),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          showReview = true;
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.arrow_drop_down_circle_sharp,
                                        color:
                                            Color.fromARGB(223, 122, 47, 220),
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        showReview == false
                            ? Container()
                            : Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('Freelancer Expertise')
                                      .doc(widget.freelancerId)
                                      .get(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    } else {
                                      if (snapshot.data == null) {
                                        const Center(
                                          child: Text('No reviews posted'),
                                        );
                                      }
                                    }
                                    return ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        return ReviewsWidget(
                                          reviewId: snapshot.data!['reviews']
                                              [index]['reviewId'],
                                          reviewerId: snapshot.data!['reviews']
                                              [index]['Id'],
                                          reviewerName: snapshot
                                              .data!['reviews'][index]['name'],
                                          reviewbody: snapshot.data!['reviews']
                                              [index]['reviewBody'],
                                          reviewerImageUrl:
                                              snapshot.data!['reviews'][index]
                                                  ['userImageUrl'],
                                        );
                                      },
                                      separatorBuilder: (context, index) {
                                        return const Divider(
                                          thickness: 1,
                                          color: Colors.grey,
                                        );
                                      },
                                      itemCount:
                                          snapshot.data!['reviews'].length,
                                    );
                                  },
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
