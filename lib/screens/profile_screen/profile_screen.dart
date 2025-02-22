import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gemhub/screens/auth_screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required String phone, required String email, required String name});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool isLoading = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  File? _profileImage;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _fetchUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _nameController.text = data?['name'] ?? '';
          _emailController.text = data?['email'] ?? '';
          _phoneController.text = data?['phone'] ?? '';
          imageUrl = data?['imageUrl'];
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await showModalBottomSheet<File?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Profile Picture',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildBottomSheetTile(Icons.camera_alt, 'Take a Photo', Colors.blueAccent, () async {
                Navigator.of(context).pop(await picker.pickImage(source: ImageSource.camera));
              }),
              _buildBottomSheetTile(Icons.photo_library, 'Choose from Gallery', Colors.green, () async {
                Navigator.of(context).pop(await picker.pickImage(source: ImageSource.gallery));
              }),
              _buildBottomSheetTile(Icons.cancel, 'Cancel', Colors.redAccent, () {
                Navigator.of(context).pop();
              }),
            ],
          ),
        );
      },
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Widget _buildBottomSheetTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }

  Future<String?> _uploadProfileImage(File? imageFile) async {
    if (imageFile == null) return null;
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return null;
      final ref = FirebaseStorage.instance.ref().child('profile_images').child('$userId.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveUserDetails(String name, String email, String phone, String? imageUrl) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'name': name,
        'email': email,
        'phone': phone,
        'imageUrl': imageUrl,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      print('Error saving user details: $e');
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text('Are you sure you want to logout?', style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.blueAccent),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        shadowColor: Colors.black26,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _isEditing ? _pickImage : null,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blueAccent, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 70,
                            backgroundImage: imageUrl != null
                                ? NetworkImage(imageUrl!)
                                : (_profileImage != null
                                    ? FileImage(_profileImage!)
                                    : null) as ImageProvider?,
                            backgroundColor: Colors.grey[200],
                            child: imageUrl == null && _profileImage == null
                                ? const Icon(
                                    Icons.camera_alt,
                                    color: Colors.blueAccent,
                                    size: 40,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildProfileField(
                                label: 'Full Name',
                                controller: _nameController,
                                enabled: _isEditing,
                              ),
                              _buildProfileField(
                                label: 'Mobile Number',
                                controller: _phoneController,
                                enabled: _isEditing,
                              ),
                              _buildProfileField(
                                label: 'Email Address',
                                controller: _emailController,
                                enabled: _isEditing,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          backgroundColor: Colors.blueAccent,
                          elevation: 5,
                          shadowColor: Colors.black26,
                        ),
                        onPressed: _isEditing
                            ? () async {
                                setState(() => isLoading = true);
                                final imageUrl = await _uploadProfileImage(_profileImage);
                                await _saveUserDetails(
                                  _nameController.text,
                                  _emailController.text,
                                  _phoneController.text,
                                  imageUrl,
                                );
                                setState(() {
                                  _isEditing = false;
                                  isLoading = false;
                                });
                              }
                            : () => setState(() => _isEditing = true),
                        child: Text(
                          _isEditing ? 'Save' : 'Edit Profile',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          backgroundColor: Colors.redAccent,
                          elevation: 5,
                          shadowColor: Colors.black26,
                        ),
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}