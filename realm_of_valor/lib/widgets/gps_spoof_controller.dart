import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/theme.dart';

class GpsSpoofController extends StatefulWidget {
  final Function(LatLng) onLocationChanged;
  final LatLng currentLocation;

  const GpsSpoofController({
    super.key,
    required this.onLocationChanged,
    required this.currentLocation,
  });

  @override
  State<GpsSpoofController> createState() => _GpsSpoofControllerState();
}

class _GpsSpoofControllerState extends State<GpsSpoofController> {
  bool _isVisible = false;
  double _latitude = 52.2405;
  double _longitude = -0.9027;
  double _movementSpeed = 0.001; // Degrees per step

  @override
  void initState() {
    super.initState();
    _latitude = widget.currentLocation.latitude;
    _longitude = widget.currentLocation.longitude;
  }

  void _moveNorth() {
    setState(() {
      _latitude += _movementSpeed;
    });
    _updateLocation();
  }

  void _moveSouth() {
    setState(() {
      _latitude -= _movementSpeed;
    });
    _updateLocation();
  }

  void _moveEast() {
    setState(() {
      _longitude += _movementSpeed;
    });
    _updateLocation();
  }

  void _moveWest() {
    setState(() {
      _longitude -= _movementSpeed;
    });
    _updateLocation();
  }

  void _updateLocation() {
    final newLocation = LatLng(_latitude, _longitude);
    widget.onLocationChanged(newLocation);
  }

  void _setSpeed(double speed) {
    setState(() {
      _movementSpeed = speed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      right: 16,
      child: GestureDetector(
        onScaleUpdate: (_) {}, // Prevent map zooming when touching this widget
        child: Column(
          children: [
            // Toggle Button
            FloatingActionButton(
              heroTag: 'gps_spoof_toggle',
              onPressed: () {
                setState(() {
                  _isVisible = !_isVisible;
                });
              },
              backgroundColor: _isVisible ? Colors.red : RealmOfValorTheme.accentGold,
              child: Icon(
                _isVisible ? Icons.gps_off : Icons.gps_fixed,
                color: Colors.white,
              ),
            ),
            
            if (_isVisible) ...[
              const SizedBox(height: 8),
              
              // Movement Controls
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RealmOfValorTheme.surfaceDark.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: RealmOfValorTheme.accentGold),
                ),
                child: Column(
                  children: [
                    // North Button
                    IconButton(
                      onPressed: _moveNorth,
                      icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: RealmOfValorTheme.accentGold,
                      ),
                    ),
                    
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // West Button
                        IconButton(
                          onPressed: _moveWest,
                          icon: const Icon(Icons.keyboard_arrow_left, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: RealmOfValorTheme.accentGold,
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // East Button
                        IconButton(
                          onPressed: _moveEast,
                          icon: const Icon(Icons.keyboard_arrow_right, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: RealmOfValorTheme.accentGold,
                          ),
                        ),
                      ],
                    ),
                    
                    // South Button
                    IconButton(
                      onPressed: _moveSouth,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: RealmOfValorTheme.accentGold,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Speed Control
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Speed:',
                          style: TextStyle(
                            color: RealmOfValorTheme.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<double>(
                          value: _movementSpeed,
                          dropdownColor: RealmOfValorTheme.surfaceDark,
                          style: TextStyle(color: RealmOfValorTheme.textPrimary),
                          items: const [
                            DropdownMenuItem(value: 0.0001, child: Text('Slow')),
                            DropdownMenuItem(value: 0.001, child: Text('Normal')),
                            DropdownMenuItem(value: 0.01, child: Text('Fast')),
                          ],
                          onChanged: (value) {
                            if (value != null) _setSpeed(value);
                          },
                        ),
                      ],
                    ),
                    
                    // Current Coordinates
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: RealmOfValorTheme.surfaceMedium,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          color: RealmOfValorTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 