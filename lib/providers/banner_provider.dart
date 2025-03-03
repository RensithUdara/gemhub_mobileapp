import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class BannerProvider with ChangeNotifier {
  List<String> _bannerList = [];
  bool _isLoading = false;
  String? _error;

  List<String> get bannerList => _bannerList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchBannerImages() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Fetching banners from Firestore collection
      final querySnapshot = await FirebaseFirestore.instance.collection('banners').get();

      if (querySnapshot.docs.isEmpty) {
        _error = 'No documents found in banners collection';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final List<String> banners = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        print('Document data: $data'); // Debug print

        if (!data.containsKey('imageUrl') || data['imageUrl'].isEmpty) {
          print('Warning: Document ${doc.id} has no or empty imageUrl field');
          continue;
        }

        String gsUrl = data['imageUrl'];

        try {
          print('Fetching URL for: $gsUrl'); // Debug print
          String httpUrl = await FirebaseStorage.instance.refFromURL(gsUrl).getDownloadURL();
          banners.add(httpUrl);
          print('Successfully got URL: $httpUrl'); // Debug print
        } catch (e) {
          print('Error getting download URL for $gsUrl: $e');
          continue; // Skip this banner and continue with others
        }
      }

      if (banners.isEmpty) {
        _error = 'No valid banner URLs found';
      } else {
        _bannerList = banners;
      }

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
