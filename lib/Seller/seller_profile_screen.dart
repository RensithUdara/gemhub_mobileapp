import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Added for animations
import 'package:image_picker/image_picker.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? _profileImageUrl;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Seller data and form controllers
  Map<String, dynamic>? sellerData;
  bool _isLoading = true;
  bool _isEditing = false;

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSellerData();
    _loadProfileImage();
  }

  Future<void> _fetchSellerData() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        DocumentSnapshot doc =
            await _firestore.collection('sellers').doc(userId).get();
        if (doc.exists) {
          setState(() {
            sellerData = doc.data() as Map<String, dynamic>;
            _displayNameController.text = sellerData!['displayName'] ?? '';
            _addressController.text = sellerData!['address'] ?? '';
            _emailController.text = sellerData!['email'] ?? '';
            _usernameController.text = sellerData!['username'] ?? '';
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seller data not found')),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
    }
  }

  Future<void> _loadProfileImage() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        final ref = _storage.ref().child('profile_images/$userId.jpg');
        final url = await ref.getDownloadURL();
        setState(() {
          _profileImageUrl = url;
        });
      } catch (e) {
        setState(() {
          _profileImageUrl = null;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage != null) {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        try {
          final ref = _storage.ref().child('profile_images/$userId.jpg');
          await ref.putFile(_selectedImage!);
          final url = await ref.getDownloadURL();
          setState(() {
            _profileImageUrl = url;
            _selectedImage = null;
          });
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        await _firestore.collection('sellers').doc(userId).update({
          'displayName': _displayNameController.text,
          'address': _addressController.text,
          'email': _emailController.text,
          'username': _usernameController.text,
        });
        setState(() {
          _isEditing = false;
          sellerData = {
            ...sellerData!,
            'displayName': _displayNameController.text,
            'address': _addressController.text,
            'email': _emailController.text,
            'username': _usernameController.text,
          };
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.black87, Colors.black54],
                    stops: [0.2, 0.8],
                  ),
                ),
              ),
              SafeArea(
                child: _isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Colors.blueAccent))
                    : sellerData == null
                        ? const Center(
                            child: Text(
                              'No Data Available',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Profile Header with Photo
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 20),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900],
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.2),
                                        blurRadius: 15,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Stack(
                                        alignment: Alignment.bottomRight,
                                        children: [
                                          CircleAvatar(
                                            radius: 70,
                                            backgroundImage: _profileImageUrl !=
                                                    null
                                                ? NetworkImage(
                                                    _profileImageUrl!)
                                                : const AssetImage(
                                                        'assets/images/default_profile.png')
                                                    as ImageProvider,
                                            backgroundColor: Colors.grey[800],
                                          ).animate().scale(duration: 500.ms),
                                          Positioned(
                                            bottom: -10,
                                            right: -10,
                                            child: GestureDetector(
                                              onTap: _pickImage,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                decoration: const BoxDecoration(
                                                  color: Colors.blueAccent,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.blueAccent,
                                                      blurRadius: 10,
                                                      offset: Offset(0, 5),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.camera_alt,
                                                  color: Colors.white,
                                                  size: 26,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      _isEditing
                                          ? TextFormField(
                                              controller:
                                                  _displayNameController,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 22),
                                              decoration: InputDecoration(
                                                labelText: 'Display Name',
                                                labelStyle: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 16),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                      color: Colors.blueAccent),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: const BorderSide(
                                                      color: Colors.blueAccent,
                                                      width: 2),
                                                ),
                                              ),
                                              textAlign: TextAlign.center,
                                            )
                                          : Text(
                                              sellerData!['displayName'] ??
                                                  'N/A',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 26,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                      const SizedBox(height: 10),
                                      _isEditing
                                          ? TextFormField(
                                              controller: _emailController,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16),
                                              decoration: InputDecoration(
                                                labelText: 'Email',
                                                labelStyle: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 14),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                      color: Colors.blueAccent),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: const BorderSide(
                                                      color: Colors.blueAccent,
                                                      width: 2),
                                                ),
                                              ),
                                              textAlign: TextAlign.center,
                                            )
                                          : Text(
                                              sellerData!['email'] ?? 'N/A',
                                              style: TextStyle(
                                                color: Colors.grey[300],
                                                fontSize: 16,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 30),
                                // Profile Details Section
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey[850]!,
                                        Colors.grey[900]!
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.2),
                                        blurRadius: 15,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Profile Details',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              color: Colors.blueAccent,
                                              offset: Offset(0, 2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      _isEditing
                                          ? Column(
                                              children: [
                                                TextFormField(
                                                  controller:
                                                      _addressController,
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16),
                                                  decoration: InputDecoration(
                                                    labelText: 'Address',
                                                    labelStyle: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 14),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      borderSide: BorderSide(
                                                          color: Colors
                                                              .blueAccent),
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      borderSide:
                                                          const BorderSide(
                                                              color: Colors
                                                                  .blueAccent,
                                                              width: 2),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 15),
                                                _buildProfileField(
                                                    'NIC Number',
                                                    sellerData!['nicNumber'] ??
                                                        'N/A',
                                                    readOnly: true),
                                                const SizedBox(height: 15),
                                                _buildProfileField(
                                                    'Phone Number',
                                                    sellerData![
                                                            'phoneNumber'] ??
                                                        'N/A',
                                                    readOnly: true),
                                                const SizedBox(height: 15),
                                                TextFormField(
                                                  controller:
                                                      _usernameController,
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16),
                                                  decoration: InputDecoration(
                                                    labelText: 'Username',
                                                    labelStyle: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 14),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      borderSide: BorderSide(
                                                          color: Colors
                                                              .blueAccent),
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      borderSide:
                                                          const BorderSide(
                                                              color: Colors
                                                                  .blueAccent,
                                                              width: 2),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Column(
                                              children: [
                                                _buildProfileField(
                                                    'Address',
                                                    sellerData!['address'] ??
                                                        'N/A'),
                                                const SizedBox(height: 15),
                                                _buildProfileField(
                                                    'NIC Number',
                                                    sellerData!['nicNumber'] ??
                                                        'N/A',
                                                    readOnly: true),
                                                const SizedBox(height: 15),
                                                _buildProfileField(
                                                    'Phone Number',
                                                    sellerData![
                                                            'phoneNumber'] ??
                                                        'N/A',
                                                    readOnly: true),
                                                const SizedBox(height: 15),
                                                _buildProfileField(
                                                    'Username',
                                                    sellerData!['username'] ??
                                                        'N/A'),
                                              ],
                                            ),
                                      const SizedBox(height: 20),
                                      if (_isEditing)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  _isEditing = false;
                                                  _displayNameController.text =
                                                      sellerData![
                                                              'displayName'] ??
                                                          '';
                                                  _addressController.text =
                                                      sellerData!['address'] ??
                                                          '';
                                                  _emailController.text =
                                                      sellerData!['email'] ??
                                                          '';
                                                  _usernameController.text =
                                                      sellerData!['username'] ??
                                                          '';
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color.fromARGB(
                                                        255, 255, 255, 255),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 12),
                                              ),
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black),
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: _saveProfile,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.blueAccent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 12),
                                              ),
                                              child: const Text(
                                                'Save',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (!_isEditing)
                                        Center(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                _isEditing = true;
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.blueAccent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 30,
                                                      vertical: 12),
                                            ),
                                            child: const Text(
                                              'Edit Profile',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white),
                                            ),
                                          ).animate().scale(
                                              duration: 300.ms,
                                              curve: Curves.easeInOut),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[900]!, Colors.black87],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              selectedItemColor: Colors.blueAccent,
              unselectedItemColor: Colors.grey[400],
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              currentIndex: 2,
              onTap: (index) {
                if (index == 2) return;
                Navigator.pop(context);
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications),
                  label: 'Notifications',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.logout),
                  label: 'Logout',
                ),
              ],
              selectedLabelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              showUnselectedLabels: true,
              selectedIconTheme:
                  const IconThemeData(size: 32, color: Colors.blueAccent),
              unselectedIconTheme:
                  const IconThemeData(size: 28, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value,
      {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
