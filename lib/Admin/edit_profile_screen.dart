import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:intl/intl.dart';

class AdminEditProfileScreen extends StatefulWidget {
  final String name;
  final String email;

  const AdminEditProfileScreen({
    Key? key,
    required this.name,
    required this.email,
  }) : super(key: key);

  @override
  _AdminEditProfileScreenState createState() => _AdminEditProfileScreenState();
}

class _AdminEditProfileScreenState extends State<AdminEditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  File? _pickedImage;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  String? selectedGender;
  DateTime? selectedBirthDate;
  String profileUrl = "";
  String phoneNumber = '';
  PhoneNumber number = PhoneNumber(isoCode: 'MY'); // Default: Malaysia
  bool isPhoneValid = false;

  @override
  void initState() {
    super.initState();
    emailController.text = widget.email;
    nameController.text = widget.name;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('admins').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        phoneNumber = data['phone'] ?? '';
        PhoneNumber parsedNumber = await PhoneNumber.getRegionInfoFromPhoneNumber(phoneNumber, 'MY');

        setState(() {
          nameController.text = data['name'] ?? '';
          emailController.text = user.email ?? '';
          number = parsedNumber;
          phoneController.text = parsedNumber.phoneNumber ?? '';
          selectedGender = data['gender'] ?? null;
          profileUrl = data['profileUrl'] ?? '';
          if (data['birthDate'] != null) {
            selectedBirthDate = (data['birthDate'] as Timestamp).toDate();
          }
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Image Source"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera),
                title: Text("Camera"),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.image),
                title: Text("Gallery"),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      final picked = await picker.pickImage(source: source);
      if (picked != null) {
        setState(() {
          _pickedImage = File(picked.path);
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (!_formKey.currentState!.validate()) return;

    if (selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select your birth date')),
      );
      return;
    }

    if (!isPhoneValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    String? imageUrl;
    try {
      if (_pickedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('admin_profiles/${user.uid}.jpg');
        await ref.putFile(_pickedImage!);
        imageUrl = await ref.getDownloadURL();
      }

      final docRef = _firestore.collection('admins').doc(user.uid);
      final docSnapshot = await docRef.get();

      final adminData = {
        'name': nameController.text.trim(),
        'phone': phoneNumber,
        'gender': selectedGender,
        'birthDate': selectedBirthDate,
        if (imageUrl != null) 'profileUrl': imageUrl,
      };

      if (docSnapshot.exists) {
        await docRef.update(adminData);
      } else {
        await docRef.set(adminData);
      }

      if (emailController.text.trim() != user.email) {
        await user.updateEmail(emailController.text.trim());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    } on FirebaseException catch (e) {
      print("FirebaseException: ${e.code} - ${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firebase error: ${e.message}')),
      );
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong')),
      );
    }
  }

  void _pickBirthDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedBirthDate = picked;
      });
    }
  }

  void _showCancelConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Cancel Editing?"),
        content: Text("Are you sure you want to discard your changes?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Stay on screen
            child: Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Pop edit screen
            },
            child: Text("Yes"),
          ),
        ],
      ),
    );
  }

  Widget buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InternationalPhoneNumberInput(
          onInputChanged: (PhoneNumber value) {
            setState(() {
              phoneNumber = value.phoneNumber ?? '';
            });
          },
          onInputValidated: (bool isValid) {
            setState(() {
              isPhoneValid = isValid;
            });
          },
          selectorConfig: SelectorConfig(
            selectorType: PhoneInputSelectorType.DROPDOWN,
          ),
          ignoreBlank: false,
          autoValidateMode: AutovalidateMode.onUserInteraction,
          initialValue: number,
          textFieldController: phoneController,
          formatInput: true,
          inputDecoration: InputDecoration(
            labelText: "Phone Number",
            border: OutlineInputBorder(),
          ),
        ),
        if (!isPhoneValid && phoneController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 8.0),
            child: Text(
              'Enter a valid phone number',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _pickedImage != null
                      ? FileImage(_pickedImage!)
                      : (profileUrl.isNotEmpty
                      ? NetworkImage(profileUrl)
                      : AssetImage("assets/images/admin_avatar.png")
                  as ImageProvider),
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt, color: Colors.deepPurple),
                  onPressed: _pickImage,
                ),
              ],
            ),
            SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                    validator: (value) =>
                    value!.isEmpty ? 'Enter your name' : null,
                  ),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Enter email';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$')
                          .hasMatch(value)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  buildPhoneInput(),
                  SizedBox(height: 10),
                  ListTile(
                    title: Text(
                      selectedBirthDate != null
                          ? 'Birth Date: ${DateFormat('yyyy-MM-dd').format(selectedBirthDate!)}'
                          : 'Select Birth Date',
                    ),
                    trailing: Icon(Icons.calendar_today),
                    onTap: _pickBirthDate,
                  ),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Gender'),
                    value: selectedGender,
                    items: [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value;
                      });
                    },
                    validator: (value) =>
                    value == null ? 'Please select gender' : null,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    child: Text("Save Profile"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple[100],
                      foregroundColor: Colors.deepPurple,
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _showCancelConfirmationDialog,
                    child: Text("Cancel"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
