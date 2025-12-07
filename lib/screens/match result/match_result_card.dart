import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../utilites/colors.dart';
import '../../utilites/responsive.dart';

class MatchResultCard extends StatelessWidget {
  final String name;
  final double matchPercentage;
  final DateTime matchTime;
  final String? profileImageUrl;
  final VoidCallback onViewProfile;

  const MatchResultCard({
    super.key,
    required this.name,
    required this.matchPercentage,
    required this.matchTime,
    required this.profileImageUrl,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);
     Uint8List? decodedImage;

    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      try {
        decodedImage = base64Decode(profileImageUrl!);
      } catch (e) {
        debugPrint("Error decoding Base64 image: $e");
      }
    }
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 3, 51, 122),
                Color.fromARGB(255, 37, 144, 231),
              ],)
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: isDesktop? 70:55,
                backgroundImage: decodedImage != null
                ? MemoryImage(decodedImage)
                : (profileImageUrl != null && profileImageUrl!.startsWith('http'))
                    ? NetworkImage(profileImageUrl!) as ImageProvider
                    : null,
                backgroundColor: Colors.grey.shade200,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 20,
                        color: kWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.green,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              "${matchPercentage.toStringAsFixed(1)}% Match",
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    LinearProgressIndicator(
                      value: matchPercentage / 100,
                      borderRadius: BorderRadius.circular(8),
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade300,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Matched on: ${matchTime.day}/${matchTime.month}/${matchTime.year}",
                      style: TextStyle(color: kMainTextColor, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: onViewProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kMainTextColor.withOpacity(0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text("View Profile", style: TextStyle(color: kWhite),),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
