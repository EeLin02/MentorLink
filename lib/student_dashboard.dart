// Updated StudentDashboard UI to match MentorDashboard style while preserving logic and content
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'settings_screen.dart';
import 'Student/student_subject_class_details_screen.dart';
import 'Student/edit_student_profile_screen.dart';
import 'Student/student_card.dart';
import 'Student/student_notice_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String studentName = '';
  String studentId = '';
  List<Map<String, dynamic>> enrolledClasses = [];
  bool isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('students').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          studentName = data['name'] ?? 'Student';
          studentId = user.uid;
        });
        await _fetchEnrolledClasses(user.uid);
      }
    }
  }

  Future<void> _fetchEnrolledClasses(String studentId) async {
    try {
      final enrollmentSnap = await _firestore
          .collection('subjectEnrollments')
          .where('studentId', isEqualTo: studentId)
          .get();

      List<Map<String, dynamic>> tempList = [];

      for (var doc in enrollmentSnap.docs) {
        final data = doc.data();

        final departmentId = data['departmentId'];
        final subjectId = data['subjectId'];
        final classId = data['classId'];

        final subjectDoc = await _firestore
            .collection('departments')
            .doc(departmentId)
            .collection('subjects')
            .doc(subjectId)
            .get();

        final classDoc = await _firestore
            .collection('departments')
            .doc(departmentId)
            .collection('subjects')
            .doc(subjectId)
            .collection('classes')
            .doc(classId)
            .get();

        String mentorId = '';
        final subjectMentorsSnap = await _firestore
            .collection('subjectMentors')
            .where('departmentId', isEqualTo: departmentId)
            .where('subjectId', isEqualTo: subjectId)
            .where('classIds', arrayContains: classId)
            .get();

        if (subjectMentorsSnap.docs.isNotEmpty) {
          mentorId = subjectMentorsSnap.docs.first.data()['mentorId'] ?? '';
        }

        Color cardColor = Colors.blue;

        if (mentorId.isNotEmpty) {
          final customizationDoc = await _firestore
              .collection('mentorCustomizations')
              .doc('${mentorId}_$classId')
              .get();

          if (customizationDoc.exists) {
            final colorData = customizationDoc.data()?['color'];
            cardColor = _parseColor(colorData);
          }
        }

        if (subjectDoc.exists && classDoc.exists) {
          tempList.add({
            'subjectName': subjectDoc.data()?['name'] ?? 'Unknown Subject',
            'className': classDoc.data()?['name'] ?? 'Unknown Class',
            'subjectId': subjectId,
            'classId': classId,
            'departmentId': departmentId,
            'color': cardColor,
          });
        }
      }

      setState(() {
        enrolledClasses = tempList;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading enrolled classes: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _logout() async {
    await _auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Color _parseColor(dynamic value) {
    try {
      if (value is int) return Color(value);
      if (value is String) return Color(int.parse(value));
    } catch (_) {}
    return Colors.blue; // fallback if parsing fails
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      _buildDashboardBody(),
      NoticeScreen(),
    ];

    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Welcome, $studentName',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.blue),
              title: Text('Profile'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StudentProfileScreen()),
              ),
            ),
            ListTile(
              leading: Icon(Icons.credit_card, color: Colors.blue),
              title: Text('Student Card'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StudentCardScreen()),
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.blue),
              title: Text('Settings'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen()),
              ),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text('Student Dashboard'),
        backgroundColor: Colors.blue,
        elevation: 4,
      ),
      body: isLoading ? Center(child: CircularProgressIndicator()) : _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Event Notices'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildDashboardBody() {
    return enrolledClasses.isEmpty
        ? Center(child: Text("No enrolled classes found."))
        : ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: enrolledClasses.length,
      itemBuilder: (context, index) {
        final item = enrolledClasses[index];
        final cardColor = item['color'] ?? Colors.blue;

        final textColor = cardColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
        final subtitleColor = cardColor.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70;

        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cardColor.withOpacity(0.4),
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            title: Text(
              item['subjectName'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
            subtitle: Text(
              item['className'],
              style: TextStyle(
                color: subtitleColor,
                fontSize: 14,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentSubjectClassDetailsScreen(
                    subjectId: item['subjectId'],
                    classId: item['classId'],
                    color: cardColor,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
