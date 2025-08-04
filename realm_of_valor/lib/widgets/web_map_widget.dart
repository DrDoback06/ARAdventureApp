import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/theme.dart';
import '../models/adventure_map_model.dart';

class WebMapWidget extends StatefulWidget {
  final List<MapLocation> locations;
  final UserLocation? userLocation;
  final Function(LatLng) onLocationSelected;
  final Function(CameraPosition) onCameraMove;
  final Function() onCameraIdle;
  final Set<Polyline> polylines; // Added for path visualization

  const WebMapWidget({
    super.key,
    required this.locations,
    this.userLocation,
    required this.onLocationSelected,
    required this.onCameraMove,
    required this.onCameraIdle,
    this.polylines = const {}, // Initialize with empty set
  });

  @override
  State<WebMapWidget> createState() => _WebMapWidgetState();
}

class _WebMapWidgetState extends State<WebMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(51.5074, -0.1278), // London default
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    if (widget.userLocation != null) {
      _initialCameraPosition = CameraPosition(
        target: LatLng(
          widget.userLocation!.latitude,
          widget.userLocation!.longitude,
        ),
        zoom: 14.0,
      );
    }
    _createMarkers();
  }

  void _createMarkers() {
    _markers.clear();
    
    // Add user location marker
    if (widget.userLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(
            widget.userLocation!.latitude,
            widget.userLocation!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'You are here',
          ),
        ),
      );
    }

    // Add location markers
    for (var location in widget.locations) {
      _markers.add(
        Marker(
          markerId: MarkerId(location.id),
          position: LatLng(location.latitude, location.longitude),
          icon: _getMarkerIcon(location.type),
          infoWindow: InfoWindow(
            title: location.name,
            snippet: location.description,
          ),
          onTap: () => widget.onLocationSelected(
            LatLng(location.latitude, location.longitude),
          ),
        ),
      );
    }

    // Add search radius circle
    if (widget.userLocation != null) {
      _circles.add(
        Circle(
          circleId: const CircleId('search_radius'),
          center: LatLng(
            widget.userLocation!.latitude,
            widget.userLocation!.longitude,
          ),
          radius: 5000, // 5km radius
          fillColor: RealmOfValorTheme.accentGold.withOpacity(0.1),
          strokeColor: RealmOfValorTheme.accentGold.withOpacity(0.3),
          strokeWidth: 2,
        ),
      );
    }
  }

  BitmapDescriptor _getMarkerIcon(LocationType type) {
    switch (type) {
      case LocationType.restaurant:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case LocationType.pub:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case LocationType.park:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case LocationType.gym:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case LocationType.trail:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case LocationType.landmark:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      case LocationType.culturalSite:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      default: // Added default case for exhaustive switch
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: _initialCameraPosition,
      markers: _markers,
      circles: _circles,
      polylines: widget.polylines, // Pass polylines to the map
      onCameraMove: widget.onCameraMove,
      onCameraIdle: widget.onCameraIdle,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      mapType: MapType.normal,
      onTap: (LatLng position) {
        // Handle map tap
        debugPrint('Map tapped at: $position');
      },
    );
  }

  @override
  void didUpdateWidget(WebMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locations != widget.locations || 
        oldWidget.userLocation != widget.userLocation) {
      _createMarkers();
    }
  }
} 