import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/theme.dart';

class SimpleAdventureMapScreen extends StatefulWidget {
  const SimpleAdventureMapScreen({super.key});

  @override
  State<SimpleAdventureMapScreen> createState() => _SimpleAdventureMapScreenState();
}

class _SimpleAdventureMapScreenState extends State<SimpleAdventureMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Set<Polyline> _polylines = {};
  
  // Mock data
  final LatLng _center = const LatLng(37.7749, -122.4194); // San Francisco
  final List<Map<String, dynamic>> _mockQuests = [
    {
      'id': 'quest_1',
      'title': 'Explore Golden Gate Park',
      'description': 'Visit the famous park and discover hidden treasures',
      'location': const LatLng(37.7694, -122.4862),
      'type': 'exploration',
      'difficulty': 'easy',
      'reward': '50 XP, 25 Gold',
    },
    {
      'id': 'quest_2',
      'title': 'Climb Twin Peaks',
      'description': 'Hike to the top for a breathtaking view of the city',
      'location': const LatLng(37.7516, -122.4476),
      'type': 'fitness',
      'difficulty': 'medium',
      'reward': '100 XP, 50 Gold',
    },
    {
      'id': 'quest_3',
      'title': 'Visit Alcatraz',
      'description': 'Explore the historic island prison',
      'location': const LatLng(37.8270, -122.4230),
      'type': 'exploration',
      'difficulty': 'hard',
      'reward': '150 XP, 75 Gold',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    _createMarkers();
    _createCircles();
  }

  void _createMarkers() {
    _markers = _mockQuests.map((quest) {
      return Marker(
        markerId: MarkerId(quest['id']),
        position: quest['location'],
        infoWindow: InfoWindow(
          title: quest['title'],
          snippet: quest['description'],
          onTap: () => _showQuestDetails(quest),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerColor(quest['type'])),
      );
    }).toSet();
  }

  void _createCircles() {
    _circles = _mockQuests.map((quest) {
      return Circle(
        circleId: CircleId('${quest['id']}_area'),
        center: quest['location'],
        radius: 500, // 500 meters
        fillColor: _getQuestColor(quest['type']).withOpacity(0.2),
        strokeColor: _getQuestColor(quest['type']),
        strokeWidth: 2,
      );
    }).toSet();
  }

  double _getMarkerColor(String type) {
    switch (type) {
      case 'exploration':
        return BitmapDescriptor.hueBlue;
      case 'fitness':
        return BitmapDescriptor.hueGreen;
      case 'battle':
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueYellow;
    }
  }

  Color _getQuestColor(String type) {
    switch (type) {
      case 'exploration':
        return Colors.blue;
      case 'fitness':
        return Colors.green;
      case 'battle':
        return Colors.red;
      default:
        return Colors.yellow;
    }
  }

  void _showQuestDetails(Map<String, dynamic> quest) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQuestDetailsSheet(quest),
    );
  }

  Widget _buildQuestDetailsSheet(Map<String, dynamic> quest) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: RealmOfValorTheme.surfaceDark,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getQuestIcon(quest['type']),
                      color: RealmOfValorTheme.accentGold,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        quest['title'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(quest['difficulty']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        quest['difficulty'].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  quest['description'],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Type', quest['type'].toUpperCase()),
                  _buildInfoRow('Reward', quest['reward']),
                  _buildInfoRow('Distance', '2.3 km'),
                  _buildInfoRow('Duration', '45 minutes'),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _startQuest(quest);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RealmOfValorTheme.accentGold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Start Quest',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showDirections(quest);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: RealmOfValorTheme.accentGold,
                            side: const BorderSide(color: RealmOfValorTheme.accentGold),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Directions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getQuestIcon(String type) {
    switch (type) {
      case 'exploration':
        return Icons.explore;
      case 'fitness':
        return Icons.fitness_center;
      case 'battle':
        return Icons.sports_martial_arts;
      default:
        return Icons.assignment;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _startQuest(Map<String, dynamic> quest) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Started quest: ${quest['title']}'),
        backgroundColor: RealmOfValorTheme.accentGold,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDirections(Map<String, dynamic> quest) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Showing directions to: ${quest['title']}'),
        backgroundColor: RealmOfValorTheme.accentGold,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adventure Map'),
        backgroundColor: RealmOfValorTheme.surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _initializeMap();
              });
            },
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 12,
        ),
        markers: _markers,
        circles: _circles,
        polylines: _polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: true,
        onTap: (LatLng position) {
          // Handle map tap
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'simple_map_location_button',
        onPressed: () {
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(_center),
          );
        },
        backgroundColor: RealmOfValorTheme.accentGold,
        foregroundColor: Colors.black,
        child: const Icon(Icons.my_location),
      ),
    );
  }
} 