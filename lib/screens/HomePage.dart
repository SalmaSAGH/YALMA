import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'JourneyPage.dart';
import 'ProfilePage.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  int _selectedIndex = 0;
  List<Marker> _markers = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentPosition = position;
    });

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    }
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

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  // fonction pour gérer le tap sur la carte
  Future<void> _onMapTapped(LatLng tappedPoint) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${tappedPoint.latitude}&lon=${tappedPoint.longitude}&format=json&addressdetails=1');

    final response = await http.get(url, headers: {
      'User-Agent': 'FlutterTransportApp/1.0'
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final address = data['display_name'];

      // Mettre à jour la barre de recherche avec le nom de l'endroit
      setState(() {
        _searchController.text = address;
        _markers.clear(); // Effacer les anciens marqueurs
        _markers.add(
          Marker(
            markerId: const MarkerId('selected-location'),
            position: tappedPoint,
            infoWindow: InfoWindow(title: address),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      });

      // Déplacer la caméra vers le point cliqué
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(tappedPoint, 14),
      );
    } else {
      throw Exception('Erreur lors de la récupération de l\'adresse');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Choisir la page à afficher selon l'onglet sélectionné
    Widget selectedPage;
    if (_selectedIndex == 1) {
      selectedPage = const ProfilePage(); // Affiche la page Profil
    } else if (_selectedIndex == 2) {
      selectedPage = const JourneyPage(); // Affiche la page Journey
    } else {
      selectedPage = Stack(
        children: [
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: Set<Marker>.of(_markers),
            onTap: _onMapTapped,
          ),
          Positioned(
            top: 50,
            left: 15,
            right: 15,
            child: TypeAheadField<String>(
              textFieldConfiguration: TextFieldConfiguration(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search a place',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 0.0, horizontal: 15.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              suggestionsCallback: (pattern) async {
                if (pattern.length < 3) return [];
                return await getSuggestions(pattern);
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion),
                );
              },
              onSuggestionSelected: (suggestion) async {
                FocusScope.of(context).unfocus();
                _searchController.text = suggestion;

                final LatLng target = await getPlaceLatLng(suggestion);

                setState(() {
                  _markers.clear();
                  _markers.add(
                    Marker(
                      markerId: const MarkerId('selected-location'),
                      position: target,
                      infoWindow: InfoWindow(title: suggestion),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed),
                    ),
                  );
                });

                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(target, 14),
                );
              },
            ),
          ),
        ],
      );
    }

    return Scaffold(
      body: selectedPage,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'You',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: 'Journey',
          ),
        ],
      ),
    );
  }
}