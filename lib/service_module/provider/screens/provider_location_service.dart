import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProviderLocationService {

  static StreamSubscription<Position>? _positionStream;
  static bool _firebaseReady = false;

  /// 🔐 Ensure Firebase login BEFORE tracking
  static Future<void> _ensureFirebaseAuth() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    _firebaseReady = true;
  }

  /// 🔥 Start live tracking
  static Future<void> startTracking({
    required String bookingId,
    required String providerId,
  }) async {

    try {

      /// IMPORTANT: wait Firebase login
      if (!_firebaseReady) {
        await _ensureFirebaseAuth();
      }

      /// GPS enabled?
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      /// Permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      /// Start stream
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) async {

        /// SAFETY: skip if auth lost
        if (FirebaseAuth.instance.currentUser == null) return;

        await FirebaseFirestore.instance
            .collection("service_live_locations")
            .doc(bookingId)
            .set({
          "provider_id": providerId,
          "lat": pos.latitude,
          "lng": pos.longitude,
          "updated_at": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

    } catch (e) {
      print("Live tracking error: $e");
    }
  }

  /// 🛑 Stop tracking safely
  static Future<void> stopTracking(String bookingId) async {
    try {
      await _positionStream?.cancel();
      _positionStream = null;

      /// ensure firebase before delete
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      await FirebaseFirestore.instance
          .collection("service_live_locations")
          .doc(bookingId)
          .delete();
    } catch (e) {
      print("Stop tracking error: $e");
    }
  }
}
