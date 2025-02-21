import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class BannerProvider with ChangeNotifier {
  List<String> _bannerList = [];

  List<String> get bannerList => _bannerList;

  Future<void> fetchBannerImages() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('banners').get();
      final List<String> banners = [];

      for (var doc in querySnapshot.docs) {
        String gsUrl = doc['url'];
        String httpUrl = await FirebaseStorage.instance.refFromURL(gsUrl).getDownloadURL();
        banners.add(httpUrl);
      }

      _bannerList = banners;
      notifyListeners();
    } catch (e) {
      print('Error fetching banners: $e');
    }
  }
}
