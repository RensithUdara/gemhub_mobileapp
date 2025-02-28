import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class BannerProvider with ChangeNotifier {
  List<String> _bannerList = [];
  bool _isLoading = true;
  String? _error;

  List<String> get bannerList => _bannerList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchBannerImages() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final querySnapshot = await FirebaseFirestore.instance
          .collection('banners')
          .get();
      final List<String> banners = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('imageUrl')) {  // Changed from 'imageUrl' to 'imageUrl1' to match Firestore
          String gsUrl = data['imageUrl'];
          try {
            String httpUrl = await FirebaseStorage.instance
                .refFromURL(gsUrl)
                .getDownloadURL();
            banners.add(httpUrl);
          } catch (e) {
            print('Error getting download URL for $gsUrl: $e');
          }
        }
      }

      _bannerList = banners;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load banners: $e';
      _isLoading = false;
      notifyListeners();
      print('Error fetching banners: $e');
    }
  }
}