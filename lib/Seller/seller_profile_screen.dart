import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart'; // For animations
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
        DocumentSnapshot doc = await _firestore
            .collection('sellers')
            .doc(userId)
            .get();
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue[900]!, Colors.black87],
                    stops: [0.2, 0.8],
                  ),
                ),
              ),
              SafeArea(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                    : sellerData == null
                        ? const Center(
                            child: Text(
                              'No Data Available',
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Profile Header with Photo
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.blue[800]!.withOpacity(0.3), Colors.blue[900]!.withOpacity(0.1)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Stack(
                                        alignment: Alignment.bottomRight,
                                        children: [
                                          CircleAvatar(
                                            radius: 80,
                                            backgroundImage: _profileImageUrl != null
                                                ? NetworkImage(_profileImageUrl!)
                                                : const AssetImage('assets/images/default_profile.png')
                                                    as ImageProvider,
                                            backgroundColor: Colors.grey[800],
                                          ).animate().scale(duration: 600.ms, curve: Curves.easeOut),
                                          Positioned(
                                            bottom: -15,
                                            right: -15,
                                            child: GestureDetector(
                                              onTap: _pickImage,
                                              child: Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Colors.blueAccent, Colors.lightBlueAccent],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.blueAccent.withOpacity(0.5),
                                                      blurRadius: 15,
                                                      offset: const Offset(0, 5),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.camera_alt,
                                                  color: Colors.white,
                                                  size: 28,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 25),
                                      _isEditing
                                          ? Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 20),
                                              child: TextFormField(
                                                controller: _displayNameController,
                                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                                                decoration: InputDecoration(
                                                  labelText: 'Display Name',
                                                  labelStyle: const TextStyle(color: Colors.white70, fontSize: 16),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(15),
                                                    borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.6)),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(15),
                                                    borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.blue[900]!.withOpacity(0.2),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            )
                                          : Text(
                                              sellerData!['displayName'] ?? 'N/A',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                shadows: [
                                                  Shadow(color: Colors.blueAccent, offset: Offset(0, 2), blurRadius: 4),
                                                ],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                      const SizedBox(height: 15),
                                      _isEditing
                                          ? Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 20),
                                              child: TextFormField(
                                                controller: _emailController,
                                                style: const TextStyle(color: Colors.white, fontSize: 18),
                                                decoration: InputDecoration(
                                                  labelText: 'Email',
                                                  labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(15),
                                                    borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.6)),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(15),
                                                    borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.blue[900]!.withOpacity(0.2),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            )
                                          : Text(
                                              sellerData!['email'] ?? 'N/A',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 18,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 40),
                                // Profile Details Section
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 20),
                                  padding: const EdgeInsets.all(25),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.blue[800]!.withOpacity(0.2), Colors.transparent],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Profile Details',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(color: Colors.blueAccent, offset: Offset(0, 2), blurRadius: 4),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 25),
                                      _isEditing
                                          ? Column(
                                              children: [
                                                _buildModernTextField(
                                                  controller: _addressController,
                                                  label: 'Address',
                                                ),
                                                const SizedBox(height: 20),
                                                _buildProfileField('NIC Number', sellerData!['nicNumber'] ?? 'N/A', readOnly: true),
                                                const SizedBox(height: 20),
                                                _buildProfileField('Phone Number', sellerData!['phoneNumber'] ?? 'N/A', readOnly: true),
                                                const SizedBox(height: 20),
                                                _buildModernTextField(
                                                  controller: _usernameController,
                                                  label: 'Username',
                                                ),
                                              ],
                                            )
                                          : Column(
                                              children: [
                                                _buildProfileField('Address', sellerData!['address'] ?? 'N/A'),
                                                const SizedBox(height: 20),
                                                _buildProfileField('NIC Number', sellerData!['nicNumber'] ?? 'N/A', readOnly: true),
                                                const SizedBox(height: 20),
                                                _buildProfileField('Phone Number', sellerData!['phoneNumber'] ?? 'N/A', readOnly: true),
                                                const SizedBox(height: 20),
                                                _buildProfileField('Username', sellerData!['username'] ?? 'N/A'),
                                              ],
                                            ),
                                      const SizedBox(height: 25),
                                      if (_isEditing)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildModernButton(
                                              text: 'Cancel',
                                              color: Colors.grey[700]!,
                                              onPressed: () {
                                                setState(() {
                                                  _isEditing = false;
                                                  _displayNameController.text = sellerData!['displayName'] ?? '';
                                                  _addressController.text = sellerData!['address'] ?? '';
                                                  _emailController.text = sellerData!['email'] ?? '';
                                                  _usernameController.text = sellerData!['username'] ?? '';
                                                });
                                              },
                                            ),
                                            _buildModernButton(
                                              text: 'Save',
                                              color: Colors.blueAccent,
                                              onPressed: _saveProfile,
                                            ),
                                          ],
                                        ),
                                      if (!_isEditing)
                                        Center(
                                          child: _buildModernButton(
                                            text: 'Edit Profile',
                                            color: Colors.blueAccent,
                                            onPressed: () {
                                              setState(() {
                                                _isEditing = true;
                                              });
                                            },
                                          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 50),
                              ],
                            ),
                          ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[900]!, Colors.black87],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
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
              selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              showUnselectedLabels: true,
              selectedIconTheme: const IconThemeData(size: 32, color: Colors.blueAccent),
              unselectedIconTheme: const IconThemeData(size: 28, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        filled: true,
        fillColor: Colors.blue[900]!.withOpacity(0.2),
      ),
    );
  }

  Widget _buildModernButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        elevation: 8,
        shadowColor: Colors.blueAccent.withOpacity(0.5),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildProfileField(String label, String value, {bool readOnly = false}) {
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