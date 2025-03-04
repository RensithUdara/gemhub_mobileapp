import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BannerProvider extends ChangeNotifier {
  List<String> _bannerList = [];
  bool _isLoading = false;
  String? _error;

  List<String> get bannerList => _bannerList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchBannerImages() async {
    _isLoading = true;
    notifyListeners();
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('banners').get();
      _bannerList = snapshot.docs.map((doc) => doc['imageUrl'] as String).toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to load banners';
    }
    _isLoading = false;
    notifyListeners();
  }
}
