import 'package:flutter/material.dart';

class RoleAssignmentScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Assign Roles")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "User Email"),
            ),
            DropdownButtonFormField<String>(
              items: ['Student', 'Mentor'].map((role) {
                return DropdownMenuItem(value: role, child: Text(role));
              }).toList(),
              onChanged: (value) {
                selectedRole = value;
              },
              decoration: InputDecoration(labelText: "Select Role"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Update Firestore user role
              },
              child: Text("Assign Role"),
            ),
          ],
        ),
      ),
    );
  }
}
