import 'package:bio_metric_system/model/user_model.dart';
import 'package:bio_metric_system/screens/login/sign_in.dart';
import 'package:bio_metric_system/utilites/colors.dart';
import 'package:bio_metric_system/utilites/constant.dart';
import 'package:bio_metric_system/utilites/responsive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nicController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  Future<void> saveUser() async {
  try {
    final user = User(
      nic: int.parse(nicController.text),
      name: nameController.text,
      email: emailController.text,
      password: passwordController.text,
    );

    await FirebaseFirestore.instance.collection('users').add(user.toMap());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("User registered successfully!")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to register: $e")),
    );
  }
}
  @override
  void dispose() {
    nicController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isDesktop = Responsive.isDesktop(context);
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Stack(
            children: [
              Container(
                height: screenHeight,
                width: screenWidth,
                color: kMainColor,
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Container(
                    width: isDesktop? screenWidth / 3: screenWidth /1.2 ,
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: appPadding * 1.5,
                        horizontal: appPadding,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: kBlue,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.fingerprint,
                                size: 40,
                                color: kWhite,
                              ),
                            ),
                          ),
                          SizedBox(height: cusHeight / 2),
                          Text(
                            "Bio Metric System",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: cusHeight / 5),
                          Text(
                            "Advanced Fingerprint Matching System",
                            style: TextStyle(
                              fontSize: 13,
                              color: kGrey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: cusHeight * 1.5),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("NIC", style: TextStyle(fontSize: 13)),
                                SizedBox(height: cusHeight / 2),
                                TextFormField(
                                  controller: nicController,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(15),
                                    border: OutlineInputBorder(
                                      gapPadding: 2,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.confirmation_number,
                                      size: 20,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "NIC is required";
                                    }
                                    if (value.length != 12) {
                                      return "NIC must be 12 digits";
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: cusHeight / 1.5),
                                Text("Name", style: TextStyle(fontSize: 13)),
                                SizedBox(height: cusHeight / 2),
                                TextFormField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(15),
                                    border: OutlineInputBorder(
                                      gapPadding: 2,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: Icon(Icons.person_2, size: 20),
                                  ),
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                      ? "Name is required"
                                      : null,
                                ),
                                SizedBox(height: cusHeight / 1.5),
                                Text("Email", style: TextStyle(fontSize: 13)),
                                SizedBox(height: cusHeight / 2),
                                TextFormField(
                                  controller: emailController,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(15),
                                    border: OutlineInputBorder(
                                      gapPadding: 2,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: Icon(Icons.email, size: 20),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Email is required";
                                    }
                                    if (!RegExp(
                                      r'^[^@]+@[^@]+\.[^@]+',
                                    ).hasMatch(value)) {
                                      return "Enter a valid email";
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: cusHeight / 1.5),
                                Text("Password:", style: TextStyle(fontSize: 13)),
                                SizedBox(height: cusHeight / 2),
                                TextFormField(
                                  controller: passwordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(15),
                                    border: OutlineInputBorder(
                                      gapPadding: 2,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: Icon(Icons.password, size: 20),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Password is required";
                                    }
                                    if (value.length < 6) {
                                      return "Password must be at least 6 characters";
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: cusHeight / 1.5),
                                Text(
                                  "Confirm Password:",
                                  style: TextStyle(fontSize: 13),
                                ),
                                SizedBox(height: cusHeight / 2),
                                TextFormField(
                                  controller: confirmPasswordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(15),
                                    border: OutlineInputBorder(
                                      gapPadding: 2,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: Icon(Icons.password, size: 20),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Confirm your password";
                                    }
                                    if (value != passwordController.text) {
                                      return "Passwords do not match";
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: cusHeight * 1.5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Column(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () async {
                                            if (_formKey.currentState!.validate()) {
                                              await saveUser();
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => SignIn(),
                                                ),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: kBlue,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 15,
                                              horizontal: 40,
                                            ),
                                            child: Text(
                                              "Create an account",
                                              style: TextStyle(
                                                color: kWhite,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: appPadding/2.5,),
                                        InkWell(
                                          onTap: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SignIn()));
                                          },
                                          child: Text("Have an exsisting account?",style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold
                                          ),),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                                
                              ],
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
      ),
    );
  }
}
