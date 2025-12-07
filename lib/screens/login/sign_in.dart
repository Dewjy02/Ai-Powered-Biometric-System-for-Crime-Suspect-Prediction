import 'package:bio_metric_system/screens/dashboard%20home/dashboard.dart';
import 'package:bio_metric_system/utilites/colors.dart';
import 'package:bio_metric_system/utilites/constant.dart';
import 'package:bio_metric_system/utilites/responsive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController nicController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _signIn() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('nic', isEqualTo: int.tryParse(nicController.text))
          .where('password', isEqualTo: passwordController.text)
          .get();

      if (query.docs.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid NIC or Password")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isDesktop = Responsive.isDesktop(context);

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              height: screenHeight,
              width: screenWidth,
              color: kMainColor,
            ),
            Center(
              child: Container(
                width: isDesktop? screenWidth /3.5 : screenWidth/1.5,
                height: isDesktop? screenHeight/1.8 :screenHeight/2,
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: appPadding * 1.5,
                    horizontal: appPadding,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: kBlue,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.fingerprint,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: cusHeight / 2),
                        const Text(
                          "Bio Metric System",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: cusHeight / 5),
                        const Text(
                          "Advanced Fingerprint Matching System",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: cusHeight * 1.5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: const [Text("NIC", style: TextStyle(fontSize: 13))],
                        ),
                        SizedBox(height: cusHeight / 2),
                        TextFormField(
                          controller: nicController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(15),
                            border: OutlineInputBorder(
                              gapPadding: 2,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.confirmation_number, size: 20),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? "Enter NIC" : null,
                        ),
                        SizedBox(height: cusHeight / 1.5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: const [Text("Password", style: TextStyle(fontSize: 13))],
                        ),
                        SizedBox(height: cusHeight / 2),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(15),
                            border: OutlineInputBorder(
                              gapPadding: 2,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.password, size: 20),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? "Enter Password" : null,
                        ),
                        SizedBox(height: cusHeight * 1.5),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _signIn();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 50,
                            ),
                            child: Text(
                              "Sign In",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    );
  }
}
