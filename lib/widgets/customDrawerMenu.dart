import 'package:bio_metric_system/utilites/responsive.dart';
import 'package:flutter/material.dart';
import 'package:bio_metric_system/utilites/colors.dart';
import 'package:bio_metric_system/utilites/constant.dart';

class CustomDrawerMenu extends StatelessWidget {
  final Function(int) onItemSelected;
  final int selectedIndex;
  final bool showCitizensData;

  const CustomDrawerMenu({
    super.key,
    required this.onItemSelected,
    required this.selectedIndex,
    required this.showCitizensData,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = Responsive.isDesktop(context);
    
    return Container(
      width: screenWidth / 1.2,
      decoration: BoxDecoration(
        borderRadius: isDesktop
            ? const BorderRadius.only(
                topRight: Radius.zero, 
                bottomRight: Radius.zero,
              )
            : const BorderRadius.only(
                topRight: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 3, 51, 122),
            Color.fromARGB(255, 37, 144, 231),
          ],
        ),
      ),
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: appPadding / 2.5),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: appPadding * 3),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: kMainTextColor,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.fingerprint,
                      size: isDesktop ? 55 : 40,
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
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: cusHeight / 5),
              ],
            ),
          ),
          _buildDrawerItem(
            0,
            Icons.dashboard_customize_outlined,
            "Dashboard",
            context,
          ),
          _buildDrawerItem(
            1,
            Icons.fingerprint_outlined,
            "Fingerprint Upload",
            context,
          ),
          _buildDrawerItem(2, Icons.search_outlined, "Match Result", context),
          _buildDrawerItem(
            3,
            Icons.person_2_outlined,
            "Suspect Profile",
            context,
          ),
          _buildDrawerItem(4, Icons.file_present, "Case Management", context),
          if (showCitizensData)
            _buildDrawerItem(
              5, 
              Icons.file_present, 
              "Citizens data Management", 
              context
            ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    int index,
    IconData icon,
    String text,
    BuildContext context,
  ) {
    bool isSelected = selectedIndex == index;

    return Container(
      decoration: isSelected
          ? BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: ListTile(
        leading: Icon(icon, color: kWhite),
        title: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () {
          onItemSelected(index);
          if (Responsive.isMobile(context) && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}