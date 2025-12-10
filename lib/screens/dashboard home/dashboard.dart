import 'package:bio_metric_system/screens/dashboard%20home/user_profile_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bio_metric_system/screens/case%20management/case_management.dart';
import 'package:bio_metric_system/screens/dashboard%20home/dashboard_home.dart';
import 'package:bio_metric_system/screens/fingerprint%20upload/fingerprint_upload.dart';
import 'package:bio_metric_system/screens/match%20result/match_result.dart';
import 'package:bio_metric_system/screens/suspect%20profile/suspect_profile.dart';
import 'package:bio_metric_system/screens/user%20data%20management/citizens_data_managemet.dart';
import 'package:bio_metric_system/utilites/colors.dart';
import 'package:bio_metric_system/utilites/constant.dart';
import 'package:bio_metric_system/utilites/responsive.dart';
import 'package:bio_metric_system/widgets/customDrawerMenu.dart';

class Dashboard extends StatefulWidget {
  final String? loggedInUserId; 
  
  const Dashboard({super.key, this.loggedInUserId});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int currentIndex = 0;

  final List<String> titles = [
    "Dashboard",
    "Fingerprint Upload",
    "Match Result",
    "Suspect Profile",
    "Case Management",
    "Citizens Data Management",
  ];

  Future<void> _handleProfileClick(BuildContext context) async {
    if (widget.loggedInUserId == null) {
      showDialog(
        context: context,
        builder: (context) => const UserProfileDialog(
          uid: "admin_id",
          userEmail: "admin@system.local",
          currentUserData: {
            "name": "System Administrator",
            "nic": "ADMIN-ACCESS",
            "profile_image": "" 
          },
        ),
      );
      return;
    }
    String uid = widget.loggedInUserId!; 
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      
      if (context.mounted) Navigator.pop(context); 

      if (doc.exists && context.mounted) {
        final userData = doc.data() as Map<String, dynamic>;
        
        showDialog(
          context: context,
          builder: (context) => UserProfileDialog(
            uid: uid,
            userEmail: userData['email'] ?? "No Email", 
            currentUserData: userData,
          ),
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("User document not found for ID: $uid")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      debugPrint("Error fetching profile: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    void _goToMatchResult() {
      setState(() {
        currentIndex = 2;
      });
    }

    final List<Widget> pages = [
      const DashboardHome(),
      FingerprintUpload(onMatchFound: _goToMatchResult),
      const MatchResult(),
      const SuspectProfile(),
      const CaseManagement(),
      const UserDataManagemet(),
    ];

    final bool isDesktop = Responsive.isDesktop(context);

    if (isDesktop) {
      return SafeArea(
        child: Scaffold(
          body: Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomDrawerMenu(
                  selectedIndex: currentIndex,
                  showCitizensData: true,
                  onItemSelected: (index) {
                    setState(() => currentIndex = index);
                  },
                ),
              ),
              Expanded(
                flex: 8,
                child: Column(
                  children: [
                    Container(
                      height: 70,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color.fromARGB(255, 38, 116, 233),
                            Color.fromARGB(255, 37, 144, 231),
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: appPadding,
                            ),
                            child: Text(
                              titles[currentIndex],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: GestureDetector(
                              onTap: () => _handleProfileClick(context),
                              child: Icon(
                                Icons.account_circle_rounded,
                                size: 40,
                                color: kWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: pages[currentIndex]),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 70,
            iconTheme: const IconThemeData(size: 30),
            centerTitle: true,
            actionsPadding: EdgeInsets.symmetric(horizontal: appPadding / 2),
            title: Text(
              titles[currentIndex],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => _handleProfileClick(context),
                  child: Icon(
                    Icons.account_circle_rounded,
                    size: 40,
                    color: kWhite,
                  ),
                ),
              ),
            ],
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color.fromARGB(255, 38, 116, 233),
                    Color.fromARGB(255, 37, 144, 231),
                  ],
                ),
              ),
            ),
          ),
          drawer: CustomDrawerMenu(
            selectedIndex: currentIndex,
            showCitizensData: false,
            onItemSelected: (index) {
              setState(() => currentIndex = index);
            },
          ),
          body: pages[currentIndex],
        ),
      );
    }
  }
}