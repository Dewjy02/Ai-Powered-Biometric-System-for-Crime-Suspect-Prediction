import 'package:bio_metric_system/screens/match%20result/match_result.dart';
import 'package:bio_metric_system/utilites/colors.dart';
import 'package:bio_metric_system/utilites/constant.dart';
import 'package:bio_metric_system/utilites/responsive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

import 'package:lottie/lottie.dart';

class FingerprintUpload extends StatefulWidget {
  final VoidCallback onMatchFound;
  const FingerprintUpload({super.key, required this.onMatchFound});

  @override
  State<FingerprintUpload> createState() => _FingerprintUploadState();
}

class _FingerprintUploadState extends State<FingerprintUpload> {
  bool isUploading = false;
  Future<void> pickAndUploadFingerprint() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.first.bytes != null) {
      Uint8List fileBytes = result.files.first.bytes!;
      String base64Fingerprint = base64Encode(fileBytes);

      setState(() => isUploading = true);

      try {
        await Future.delayed(const Duration(seconds: 10));
        final url = Uri.parse("http://192.168.1.2:5001/match");
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"fingerPrintBase64": base64Fingerprint}),
        );
        if (!mounted) return;

        if (response.statusCode == 200) {
          final matchData = jsonDecode(response.body);
          widget.onMatchFound();
          if (matchData["matches"] != null && matchData["matches"].isNotEmpty) {
            final FirebaseFirestore _firestore = FirebaseFirestore.instance;
            final counterRef = _firestore.collection("Meta").doc("caseCounter");
            final newCaseNumber = await _firestore.runTransaction((
              transaction,
            ) async {
              final snapshot = await transaction.get(counterRef);
              int lastCase = 0;
              if (snapshot.exists) {
                lastCase = snapshot.data()?["lastCase"] ?? 0;
              }
              final updatedCase = lastCase + 1;
              transaction.set(counterRef, {"lastCase": updatedCase});
              return updatedCase;
            });

            final caseId = "case ${newCaseNumber.toString().padLeft(2, '0')}";
            final suspectsRef = _firestore
                .collection("Cases")
                .doc(caseId)
                .collection("suspects");

            int suspectIndex = 1;
            for (var match in matchData["matches"]) {
              await suspectsRef.doc("suspect$suspectIndex").set({
                "nic": match["nic"],
                "name": match["name"],
                "passportId": match["passportId"],
                "profileUrl": match["profileUrl"],
                "uploaded_fp_base64": match["uploaded_fp_base64"],
                "score": (match["score"] as num).toDouble(),
                "created_at": FieldValue.serverTimestamp(),
              });
              suspectIndex++;
            }
          }

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MatchResult()),
          );
        } else {
          throw Exception("Backend error: ${response.body}");
        }
      } catch (e) {
        print(e);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      } finally {
        if (!mounted) return;
        setState(() => isUploading = false);
      }
    }
  }

  @override
Widget build(BuildContext context) {
  final isDesktop = Responsive.isDesktop(context);
  return Container(
    height: double.infinity,
    width: double.infinity,
    color: kMainColor.withOpacity(0.6),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800), 
            child: isUploading
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/animation/fingerprint_biometric_scan.json',
                        width: isDesktop ? 700 : 400,
                        repeat: true,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Scanning fingerprint...",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Upload and process fingerprint images for matching...",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: kMainTextColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: isDesktop ? 400 : 300,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 228, 234, 247),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: InkWell(
                            onTap: () {
                              isUploading ? null : pickAndUploadFingerprint();
                            },
                            child: Padding(
                              padding: EdgeInsets.all(isDesktop ? 40.0 : 20.0),
                              child: DottedBorder(
                                  options: RectDottedBorderOptions(
                                    dashPattern: [10, 5],
                                    strokeWidth: 2,
                                    padding: EdgeInsets.all(16),
                                  ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.upload,
                                        size: 70,
                                        color: kGrey,
                                      ),
                                      SizedBox(height: appPadding / 2),
                                      Text(
                                        isDesktop
                                            ? 'Drag and Drop a fingerprint image \n click to browse files'
                                            : 'Click to browse files',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: appPadding),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 228, 234, 247),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Upload Guidelines",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: kMainTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: appPadding / 2),
                              _buildGuidelineRow("Ensure fingerprint image is clear and high-resolution"),
                              _buildGuidelineRow("Supported formats: JPG, PNG, TIFF"),
                              _buildGuidelineRow("Maximum file size: 10MB"),
                              _buildGuidelineRow("For best results, ensure the fingerprint is centered in the image"),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildGuidelineRow(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.fingerprint, color: kBlue),
        SizedBox(width: appPadding / 2),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    ),
  );
}
}
