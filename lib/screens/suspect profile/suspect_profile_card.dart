import 'dart:convert';

import 'package:bio_metric_system/model/citizen_model.dart';
import 'package:bio_metric_system/utilites/colors.dart';
import 'package:bio_metric_system/utilites/constant.dart';
import 'package:flutter/material.dart';

class SuspectProfileCard extends StatelessWidget {
  final Citizen citizen;
  const SuspectProfileCard({super.key, required this.citizen});

  ImageProvider _getImage() {
    try {
      return MemoryImage(base64Decode(citizen.profileUrl));
    } catch (e) {
      return const AssetImage("assets/images/transparent.png");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      clipBehavior: Clip.antiAlias, 
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 3, 51, 122),
                  Color.fromARGB(255, 37, 144, 231),
                ],
              ),
            ), 
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: _getImage(),
                  backgroundColor: Colors.grey.shade300,
                  child: citizen.profileUrl.isEmpty
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                SizedBox(width: appPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        citizen.name,
                        style: TextStyle(
                          fontSize: 20,
                          color: kMainTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        "NIC: ${citizen.nic}",
                        style: TextStyle(
                          fontSize: 16,
                          color: kMainTextColor.withOpacity(0.7),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 2, color: Colors.white),
          Container(
            color: Colors.black.withOpacity(0.8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  Icons.credit_card,
                  citizen.passportId.toString(),
                ),
                _buildDetailRow(Icons.date_range, citizen.dateOfBirth),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 15),
                  child: Row(
                    children: [
                      Icon(Icons.phone_android, color: Colors.white, size: 22),
                      SizedBox(width: appPadding),
                      Expanded(
                        child: Text(
                          "(+94) - ${citizen.mobileNumber}".toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDetailRow(
                  Icons.location_on,
                  citizen.address, 
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Icon(icon, color: Colors.white, size: 22),
          SizedBox(width: appPadding),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
