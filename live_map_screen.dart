import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:finsightai/url.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({Key? key}) : super(key: key);

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {

  // App Colors
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1F2937);
  static const Color hintColor = Color(0xFF9CA3AF);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // API Base URL
  String baseUrl = '${Url.Urls}';

  GoogleMapController? _mapController;
  Location location = Location();
  LocationData? _currentLocation;
  bool _isNearbyAlertsOn = true;
  bool _showSpendingHeatmap = true;
  bool _isLocationServiceEnabled = false;
  bool _isPermissionGranted = false;
  bool _isLoading = true;
  bool _isLoadingSpendingData = true;

  String _currentUserEmail = '';

  // Default center (Mumbai)
  static const LatLng _defaultCenter = LatLng(19.0760, 72.8777);
  LatLng _mapCenter = _defaultCenter;

  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};

  // Dynamic spending locations from API
  List<Map<String, dynamic>> _spendingLocations = [];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _fetchCurrentUser();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/last_active_user'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          _currentUserEmail = userData['user_details']['email'];
        });
        await _fetchTopSpendingLocations();
      } else {
        _showError('Failed to fetch user data');
      }
    } catch (e) {
      print('Error fetching user: ${e.toString()}');
      _showError('Network error: ${e.toString()}');
    }
  }

  Future<void> _fetchTopSpendingLocations() async {
    if (_currentUserEmail.isEmpty) {
      print('Error: Email is empty');
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isLoadingSpendingData = true;
        });
      }

      print('Fetching top spending locations for: $_currentUserEmail');

      final response = await http.get(
        Uri.parse('$baseUrl/top_spending_locations/$_currentUserEmail'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (!mounted) return; // Check if widget is still mounted

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          final topLocations = responseData['top_locations'] as List;
          print('Found ${topLocations.length} locations');

          if (topLocations.isEmpty) {
            if (mounted) {
              _showError('No spending data found. Add some transactions first!');
              setState(() {
                _isLoadingSpendingData = false;
              });
            }
            return;
          }

          if (mounted) {
            setState(() {
              _spendingLocations = topLocations.map((location) {
                print('Processing location: ${location['name']} - ₹${location['total_amount']}');
                return {
                  'name': location['name'],
                  'position': LatLng(location['latitude'], location['longitude']),
                  'amount': location['total_amount'],
                  'transactions': location['transaction_count'],
                  'category': location['category'],
                  'color': _parseColor(location['color']),
                  'lastVisit': DateTime.now().subtract(Duration(days: math.Random().nextInt(7))),
                };
              }).toList();
              _isLoadingSpendingData = false;
            });

            // Create markers and circles
            _createSpendingMarkersAndCircles();

            _showSuccess('Loaded ${_spendingLocations.length} top spending locations!');
          }
        } else {
          if (mounted) {
            _showError(responseData['message'] ?? 'Failed to load locations');
            setState(() {
              _isLoadingSpendingData = false;
            });
          }
        }
      } else {
        if (mounted) {
          _showError('Failed to fetch spending locations: ${response.statusCode}');
          setState(() {
            _isLoadingSpendingData = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching spending locations: ${e.toString()}');
      if (mounted) {
        _showError('Network error: ${e.toString()}');
        setState(() {
          _isLoadingSpendingData = false;
        });
      }
    }
  }

  Color _parseColor(String colorString) {
    try {
      String hex = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return hintColor;
    }
  }

  Future<void> _initializeLocation() async {
    try {
      _isLocationServiceEnabled = await location.serviceEnabled();
      if (!_isLocationServiceEnabled) {
        _isLocationServiceEnabled = await location.requestService();
        if (!_isLocationServiceEnabled) {
          setState(() {
            _isLoading = false;
          });
          _showLocationServiceDialog();
          return;
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() {
            _isLoading = false;
          });
          _showPermissionDialog();
          return;
        }
      }

      _isPermissionGranted = true;
      await _getCurrentLocation();

      if (_isNearbyAlertsOn) {
        location.onLocationChanged.listen((LocationData currentLocation) {
          _updateCurrentLocation(currentLocation);
          _checkNearbyLocations(currentLocation);
        });
      }

    } catch (e) {
      debugPrint('Error initializing location: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final LocationData locationData = await location.getLocation();
      _updateCurrentLocation(locationData);
    } catch (e) {
      debugPrint('Error getting current location: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateCurrentLocation(LocationData locationData) {
    setState(() {
      _currentLocation = locationData;
      _mapCenter = LatLng(locationData.latitude!, locationData.longitude!);
      _isLoading = false;
    });

    _addCurrentLocationMarker();

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_mapCenter, 14.0),
    );
  }

  void _addCurrentLocationMarker() {
    if (_currentLocation != null) {
      _markers.removeWhere((marker) => marker.markerId.value == 'current_location');
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Current position',
          ),
        ),
      );
    }
  }

  void _createSpendingMarkersAndCircles() {
    if (!mounted) return;

    // Clear existing markers and circles (except current location)
    _markers.removeWhere((marker) => marker.markerId.value != 'current_location');
    _circles.clear();

    print('Creating markers for ${_spendingLocations.length} locations');

    for (var location in _spendingLocations) {
      print('Adding marker for: ${location['name']} at ${location['position']}');

      // Create marker
      _markers.add(
        Marker(
          markerId: MarkerId(location['name']),
          position: location['position'],
          infoWindow: InfoWindow(
            title: location['name'],
            snippet: '₹${location['amount'].toInt()} • ${location['transactions']} transactions',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getMarkerHue(location['color']),
          ),
          onTap: () => _showLocationDetails(location),
        ),
      );

      // Create spending intensity circle
      if (_showSpendingHeatmap) {
        _circles.add(
          Circle(
            circleId: CircleId('${location['name']}_circle'),
            center: location['position'],
            radius: (location['amount'] as double) * 0.5,
            fillColor: location['color'].withOpacity(0.2),
            strokeColor: location['color'],
            strokeWidth: 2,
          ),
        );
      }
    }

    print('Added ${_markers.length} markers and ${_circles.length} circles');

    if (mounted) {
      setState(() {
        // Trigger rebuild to show markers
      });
    }
  }

  void _checkNearbyLocations(LocationData currentLocation) {
    const double alertRadius = 500;

    for (var spendingLocation in _spendingLocations) {
      final double distance = _calculateDistance(
        currentLocation.latitude!,
        currentLocation.longitude!,
        spendingLocation['position'].latitude,
        spendingLocation['position'].longitude,
      );

      if (distance <= alertRadius) {
        _showNearbyAlert(spendingLocation);
      }
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double lat1Rad = _degreesToRadians(lat1);
    final double lat2Rad = _degreesToRadians(lat2);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
            math.sin(dLon / 2) * math.sin(dLon / 2);

    final double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  Future<void> _showNearbyAlert(Map<String, dynamic> location) async {
    if (!_isNearbyAlertsOn) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'nearby_alerts',
      'Nearby Spending Alerts',
      channelDescription: 'Notifications for nearby spending locations',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await FlutterLocalNotificationsPlugin().show(
      location['name'].hashCode,
      'FinSightAI Alert',
      'You\'re near ${location['name']} where you spent ₹${location['amount'].toInt()}. Budget wisely! 💰',
      platformChannelSpecifics,
    );
  }

  double _getMarkerHue(Color color) {
    if (color.value == const Color(0xFFEF4444).value) return BitmapDescriptor.hueRed;
    if (color.value == const Color(0xFF06B6D4).value) return BitmapDescriptor.hueBlue;
    if (color.value == const Color(0xFF8B5CF6).value) return BitmapDescriptor.hueViolet;
    if (color.value == const Color(0xFFEC4899).value) return BitmapDescriptor.hueMagenta;
    if (color.value == successColor.value) return BitmapDescriptor.hueGreen;
    return BitmapDescriptor.hueOrange;
  }

  void _showLocationDetails(Map<String, dynamic> location) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                  margin: const EdgeInsets.only(bottom: 20),
                  alignment: Alignment.center,
                ),
                Row(
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: location['color'].withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(location['category']),
                        color: location['color'],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location['name'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            location['category'],
                            style: TextStyle(
                              fontSize: 14,
                              color: location['color'],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Total Spent',
                              style: TextStyle(
                                fontSize: 14,
                                color: hintColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${location['amount'].toInt()}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Transactions',
                              style: TextStyle(
                                fontSize: 14,
                                color: hintColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${location['transactions']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToLocation(location['position']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.directions, color: Colors.white),
                    label: const Text(
                      'View on Map',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToLocation(LatLng destination) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(destination, 16.0),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Food & Dining':
        return Icons.restaurant;
      case 'Entertainment':
        return Icons.movie;
      case 'Transportation':
        return Icons.directions_car;
      case 'Bills & Utilities':
        return Icons.receipt_long;
      case 'Healthcare':
        return Icons.health_and_safety;
      case 'Investment':
        return Icons.trending_up;
      case 'Travel':
        return Icons.flight;
      default:
        return Icons.location_on;
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Location Services Disabled',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        content: const Text(
          'Please enable location services to use map features and nearby alerts.',
          style: TextStyle(color: hintColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: hintColor)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                _initializeLocation();
              },
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Location Permission Required',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        content: const Text(
          'FinSightAI needs location permission to show nearby spending locations and provide relevant alerts.',
          style: TextStyle(color: hintColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: hintColor)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                ph.openAppSettings();
              },
              child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_isLoadingSpendingData)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Loading your top spending locations...',
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nearby Alerts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Switch(
                value: _isNearbyAlertsOn,
                onChanged: (value) {
                  setState(() {
                    _isNearbyAlertsOn = value;
                  });
                },
                activeColor: successColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Spending Heatmap',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Switch(
                value: _showSpendingHeatmap,
                onChanged: (value) {
                  setState(() {
                    _showSpendingHeatmap = value;
                    _circles.clear();
                    if (value) {
                      _createSpendingMarkersAndCircles();
                    }
                  });
                },
                activeColor: primaryColor,
              ),
            ],
          ),

          if (_spendingLocations.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: successColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: successColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing ${_spendingLocations.length} top spending locations',
                      style: const TextStyle(
                        fontSize: 12,
                        color: successColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton.icon(
              onPressed: _isLoadingSpendingData ? null : _fetchTopSpendingLocations,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: Icon(
                Icons.refresh,
                color: Colors.white,
                size: 16,
              ),
              label: Text(
                'Refresh Locations',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationButton() {
    return Positioned(
      bottom: 200,
      right: 16,
      child: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          color: surfaceColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _currentLocation != null
              ? () {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
                16.0,
              ),
            );
          }
              : _getCurrentLocation,
          backgroundColor: primaryColor,
          elevation: 0,
          child: Icon(
            _currentLocation != null ? Icons.my_location : Icons.location_searching,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: surfaceColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Live Map',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  SizedBox(height: 16),
                  Text(
                    'Getting your location...',
                    style: TextStyle(
                      fontSize: 16,
                      color: hintColor,
                    ),
                  ),
                ],
              ),
            )
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _mapCenter,
                zoom: 12.0,
              ),
              markers: _markers,
              circles: _showSpendingHeatmap ? _circles : {},
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                if (_currentLocation != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(_mapCenter, 14.0),
                  );
                }
              },
              myLocationEnabled: _isPermissionGranted,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              compassEnabled: true,
              zoomControlsEnabled: false,
            ),

          if (!_isLoading) _buildLocationButton(),

          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: _buildControlPanel(),
          ),
        ],
      ),
    );
  }
}
