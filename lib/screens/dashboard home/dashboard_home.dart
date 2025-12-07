import 'dart:convert';
import 'dart:typed_data';
import 'package:bio_metric_system/utilites/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Uint8List? _safeBase64Decode(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  String _getFormattedDate() {
    return DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 24),
            _buildStatCards(context),
            const SizedBox(height: 24),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getGreeting(),
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Here is the summary of your system. (${_getFormattedDate()})",
          style: TextStyle(
            color: Colors.black.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards(BuildContext context) {
    final card1 = StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('citizens').snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length;
        }
        return _buildStatCard(
          "Total Citizens",
          count.toString(),
          Icons.people_outline,
          Colors.blue,
        );
      },
    );

    final card2 = StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('Meta').doc('caseCounter').snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          count =
              (snapshot.data!.data() as Map<String, dynamic>)['lastCase'] ?? 0;
        }
        return _buildStatCard(
          "Total Cases Opened",
          count.toString(),
          Icons.folder_open_outlined,
          Colors.orange,
        );
      },
    );

    final card3 = StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('ConfirmedCases').snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length;
        }
        return _buildStatCard(
          "Confirmed Cases",
          count.toString(),
          Icons.check_circle_outline,
          Colors.green,
        );
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Column(
            children: [
              card1,
              const SizedBox(height: 16),
              card2,
              const SizedBox(height: 16),
              card3,
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(child: card1),
              const SizedBox(width: 20),
              Expanded(child: card2),
              const SizedBox(width: 20),
              Expanded(child: card3),
            ],
          );
        }
      },
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent Activity",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: kWhite.withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('ConfirmedCases')
                .orderBy('confirmedAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    "No confirmed cases yet.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return _buildRecentCaseTile(data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: kWhite.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero, 
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 28, color: color),
        ),
        title: Text(
          value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildRecentCaseTile(Map<String, dynamic> data) {
    final imageBytes = _safeBase64Decode(data['suspectProfileUrl']);

    String formattedDate = "Just now";
    if (data['confirmedAt'] != null) {
      Timestamp t = data['confirmedAt'];
      formattedDate = DateFormat('MMMM d, hh:mm a').format(t.toDate());
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
        child: imageBytes == null ? const Icon(Icons.person) : null,
      ),
      title: Text(
        "${data['caseId']} - ${data['caseType']}".toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        "Confirmed: ${data['suspectName']}",
        style: TextStyle(color: Colors.grey[700]),
      ),
      trailing: Text(
        formattedDate,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }
}