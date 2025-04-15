import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;

class JourneyPage extends StatefulWidget {
  const JourneyPage({Key? key}) : super(key: key);

  @override
  _JourneyPageState createState() => _JourneyPageState();
}

class _JourneyPageState extends State<JourneyPage> {
  late GoogleMapController _mapController;
  Position? _currentPosition;
  final TextEditingController _destinationController = TextEditingController();
  String? _selectedRouteType;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _showSearchPanel = true;
  LatLng? _destination;

  LatLngBounds boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  void _showRouteOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Route Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Cheaper'),
                leading: Radio<String>(
                  value: 'cheaper',
                  groupValue: _selectedRouteType,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedRouteType = value;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Faster'),
                leading: Radio<String>(
                  value: 'faster',
                  groupValue: _selectedRouteType,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedRouteType = value;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Comfortable'),
                leading: Radio<String>(
                  value: 'comfortable',
                  groupValue: _selectedRouteType,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedRouteType = value;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
      _markers.add(
        Marker(
          markerId: const MarkerId('current-location'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(title: 'Current Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });
  }

  Future<List<String>> getSuggestions(String input) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$input&format=json&addressdetails=1');

    final response = await http.get(url, headers: {
      'User-Agent': 'FlutterTransportApp/1.0'
    });

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((place) => place['display_name'] as String).toList();
    } else {
      return [];
    }
  }

  Future<LatLng> getPlaceLatLng(String place) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$place&format=json&limit=1');

    final response = await http.get(url, headers: {
      'User-Agent': 'FlutterTransportApp/1.0'
    });

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        return LatLng(lat, lon);
      }
    }
    throw Exception('Lieu introuvable');
  }

  Future<void> _getRouteDirections() async {
    if (_currentPosition == null || _destination == null) return;

    String? travelMode;
    switch (_selectedRouteType) {
      case 'faster':
        travelMode = 'driving';
        break;
      case 'cheaper':
        travelMode = 'walking';
        break;
      case 'comfortable':
        travelMode = 'driving';
        break;
      default:
        travelMode = 'driving';
    }

    final response = await http.get(Uri.parse(
      'http://router.project-osrm.org/route/v1/$travelMode/'
          '${_currentPosition!.longitude},${_currentPosition!.latitude};'
          '${_destination!.longitude},${_destination!.latitude}'
          '?overview=full&geometries=geojson',
    ));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> coordinates = data['routes'][0]['geometry']['coordinates'];

      List<LatLng> polylineCoordinates = coordinates
          .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
          .toList();

      setState(() {
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: _destination!,
            infoWindow: InfoWindow(title: _destinationController.text),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );

        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: polylineCoordinates,
            color: Colors.blue,
            width: 5,
          ),
        );

        _showSearchPanel = false;
        LatLngBounds bounds = boundsFromLatLngList(polylineCoordinates);
        _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors du calcul du trajet')),
      );
    }
  }

  void _resetSearch() {
    setState(() {
      _showSearchPanel = true;
      _polylines.clear();
      _markers.removeWhere((marker) => marker.markerId.value == 'destination');
      _destinationController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
          ),

          if (_showSearchPanel)
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Choose starting point',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TypeAheadField<String>(
                      textFieldConfiguration: TextFieldConfiguration(
                        controller: TextEditingController(text: "Current Location"),
                        decoration: InputDecoration(
                          hintText: 'Enter starting point',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                      ),
                      suggestionsCallback: (pattern) async {
                        if (pattern.length < 2) return [];
                        return await getSuggestions(pattern);
                      },
                      itemBuilder: (context, suggestion) {
                        return ListTile(
                          title: Text(suggestion),
                        );
                      },
                      onSuggestionSelected: (suggestion) async {
                        final newStart = await getPlaceLatLng(suggestion);
                        setState(() {
                          _markers.removeWhere((m) => m.markerId.value == 'current-location');
                          _markers.add(
                            Marker(
                              markerId: const MarkerId('current-location'),
                              position: newStart,
                              infoWindow: InfoWindow(title: suggestion),
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                            ),
                          );
                          _currentPosition = Position(
                            latitude: newStart.latitude,
                            longitude: newStart.longitude,
                            timestamp: DateTime.now(),
                            accuracy: 0,
                            altitude: 0,
                            heading: 0,
                            speed: 0,
                            speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Choose destination',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TypeAheadField<String>(
                      textFieldConfiguration: TextFieldConfiguration(
                        controller: _destinationController,
                        decoration: InputDecoration(
                          hintText: 'Search destination',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                      suggestionsCallback: (pattern) async {
                        if (pattern.length < 2) return [];
                        return await getSuggestions(pattern);
                      },
                      itemBuilder: (context, suggestion) {
                        return ListTile(
                          title: Text(suggestion),
                        );
                      },
                      onSuggestionSelected: (suggestion) async {
                        _destinationController.text = suggestion;
                        _destination = await getPlaceLatLng(suggestion);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _showRouteOptions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_selectedRouteType ?? 'Select'),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _getRouteDirections,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Search'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          if (!_showSearchPanel)
            Positioned(
              top: 40,
              left: 15,
              child: FloatingActionButton(
                mini: true,
                onPressed: _resetSearch,
                child: const Icon(Icons.arrow_back),
              ),
            ),
        ],
      ),
    );
  }
}