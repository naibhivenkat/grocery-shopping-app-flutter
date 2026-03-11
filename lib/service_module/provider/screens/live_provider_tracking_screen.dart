import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class LiveProviderTrackingScreen extends StatefulWidget {
  final String bookingId;

  const LiveProviderTrackingScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<LiveProviderTrackingScreen> createState() =>
      _LiveProviderTrackingScreenState();
}

class _LiveProviderTrackingScreenState
    extends State<LiveProviderTrackingScreen> {

  GoogleMapController? _mapController;
  LatLng? _providerLocation;

  bool _mapReady = false;
  bool _firebaseReady = false;
  bool _locationPermissionGranted = false;

  Set<Marker> _markers = {};

  /// 🔐 Firebase login
  Future<void> ensureFirebaseLogin() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    _firebaseReady = true;
  }

  /// 📍 Location permission
  Future<void> checkLocationPermission() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    _locationPermissionGranted = true;
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    await ensureFirebaseLogin();
    await checkLocationPermission();
    setState(() {});
  }

  void _moveCamera(LatLng position) {
    if (_mapController != null && _mapReady) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: position, zoom: 16),
        ),
      );
    }
  }

  void _updateMarker(LatLng position) {
    if (!_mapReady) return;

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId("provider"),
          position: position,
          infoWindow: const InfoWindow(title: "Provider"),
        )
      };
    });
  }

  @override
  Widget build(BuildContext context) {

    if (!_firebaseReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Live Provider Tracking")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("service_live_locations")
            .doc(widget.bookingId)
            .snapshots(),
        builder: (context, snap) {

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.data!.exists) {
            return const Center(
              child: Text("Waiting for provider to start service..."),
            );
          }

          final data = snap.data!.data() as Map<String, dynamic>;

          if (data["lat"] == null || data["lng"] == null) {
            return const Center(
              child: Text("Waiting for provider location..."),
            );
          }

          final newLocation =
              LatLng(data["lat"].toDouble(), data["lng"].toDouble());

          if (_providerLocation == null ||
              _providerLocation != newLocation) {
            _providerLocation = newLocation;
            _moveCamera(newLocation);
            _updateMarker(newLocation);
          }

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _providerLocation!,
              zoom: 15,
            ),
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
              _mapReady = true;
            },
            myLocationEnabled: _locationPermissionGranted,
            zoomControlsEnabled: true,
          );
        },
      ),
    );
  }
}
