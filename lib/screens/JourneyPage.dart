import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:transport_app/screens/transport_step.dart';
import 'RouteDetailsPage.dart';


class JourneyPage extends StatefulWidget {
  const JourneyPage({Key? key}) : super(key: key);

  @override
  _JourneyPageState createState() => _JourneyPageState();
}

class _JourneyPageState extends State<JourneyPage> {
  late GoogleMapController _mapController;
  Position? _currentPosition;
  final TextEditingController _destinationController = TextEditingController();
  String? _selectedRouteType = 'transit';
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _showSearchPanel = true;
  LatLng? _destination;
  List<TransportStep> _routeSteps = [];
  double _totalDistance = 0;
  double _totalDuration = 0;
  String _startAddress = '';
  String _endAddress = '';
  String _departureTime = '';
  String _arrivalTime = '';



  static const String _googleApiKey = 'AIzaSyDBbmmnmr09v4I5tVisCgZlQay6ZydtAoU';
  static const Map<String, LatLng> knownStations = {
    'Gare Casa-Voyageurs': LatLng(33.5955, -7.5499),
    'Gare Casa-Port': LatLng(33.5946, -7.6146),
    'Gare Oasis': LatLng(33.5696, -7.5939),
    'Gare Rabat-Agdal': LatLng(34.0086, -6.8510),
  };

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
          infoWindow: const InfoWindow(title: 'Votre position'),
        ),
      );
    });
  }

  Future<List<String>> getSuggestions(String input) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
            'input=$input'
            '&key=$_googleApiKey'
            '&components=country:ma'
            '&language=fr'
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['predictions'] as List)
          .map((prediction) => prediction['description'] as String)
          .toList();
    }
    return [];
  }

  Future<LatLng> getPlaceLatLng(String description) async {
    final placeId = await _getPlaceId(description);
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?'
            'place_id=$placeId'
            '&key=$_googleApiKey'
            '&fields=geometry'
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final location = data['result']['geometry']['location'];
      return LatLng(location['lat'], location['lng']);
    }
    throw Exception('Lieu introuvable');
  }

  Future<String> _getPlaceId(String description) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?'
            'input=$description'
            '&inputtype=textquery'
            '&fields=place_id'
            '&key=$_googleApiKey'
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['candidates'][0]['place_id'];
    }
    throw Exception('Place ID non trouvé');
  }

  Future<bool> _isDifferentCity(LatLng destination) async {
    try {
      final originResponse = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?'
              'latlng=${_currentPosition!.latitude},${_currentPosition!.longitude}'
              '&key=$_googleApiKey'
              '&language=fr'
              '&region=ma',
        ),
      );

      final destResponse = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?'
              'latlng=${destination.latitude},${destination.longitude}'
              '&key=$_googleApiKey'
              '&language=fr'
              '&region=ma',
        ),
      );

      if (originResponse.statusCode == 200 && destResponse.statusCode == 200) {
        final originData = json.decode(originResponse.body);
        final destData = json.decode(destResponse.body);

        final originCity = _extractCityFromAddress(originData);
        final destCity = _extractCityFromAddress(destData);

        return originCity != destCity;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  String _extractCityFromAddress(Map<String, dynamic> data) {
    if (data['results'] is List && data['results'].isNotEmpty) {
      for (var component in data['results'][0]['address_components']) {
        if (component['types'].contains('locality')) {
          return component['long_name'];
        }
      }
    }
    return '';
  }

  Future<void> _getRouteDirections() async {
    if (_currentPosition == null || _destination == null) return;

    try {
      if (_selectedRouteType == 'transit' && await _isDifferentCity(_destination!)) {
        await _getIntercityRoute();
        return;
      }

      final mode = _selectedRouteType == 'transit' ? 'transit' : 'driving';
      final response = await http.get(
        Uri.parse(
            'https://maps.googleapis.com/maps/api/directions/json?'
                'origin=${_currentPosition!.latitude},${_currentPosition!.longitude}'
                '&destination=${_destination!.latitude},${_destination!.longitude}'
                '&mode=$mode'
                '&key=$_googleApiKey'
                '&language=fr'
                '&region=ma'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'].isNotEmpty) {
          _processRouteData(data);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
  Future<void> _getIntercityRoute() async {
    try {
      // 1. Trouver la gare la plus proche de la position actuelle
      final nearestStationOrigin = await _findNearestTrainStation(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
      );

      // 2. Trouver la gare la plus proche de la destination
      final nearestStationDest = await _findNearestTrainStation(_destination!);

      // 3. Obtenir l'itinéraire en transport public vers la gare de départ
      final toStationRoute = await _getRouteToStation(nearestStationOrigin);

      // 4. Obtenir l'itinéraire en transport public de la gare d'arrivée à la destination
      final fromStationRoute = await _getRouteFromStation(nearestStationDest);

      // 5. Mettre à jour l'état
      if (mounted) {
        setState(() {
          _routeSteps = [
            ...toStationRoute['steps'],
            TransportStep(
              type: 'train',
              instruction: 'Prendre le train de ${nearestStationOrigin['name']} à ${nearestStationDest['name']}',
              distance: 0, // Nous ne traçons pas cette distance
              duration: 0, // Durée estimée non disponible
              icon: Icons.train,
              color: Colors.red,
              lineNumber: 'Train',
              departureStop: nearestStationOrigin['name'],
              arrivalStop: nearestStationDest['name'],
              departureTime: 'Consulter horaires ONCF',
            ),
            ...fromStationRoute['steps'],
          ];

          _totalDistance = toStationRoute['distance'] + fromStationRoute['distance'];
          _totalDuration = toStationRoute['duration'] + fromStationRoute['duration'];
          _startAddress = toStationRoute['startAddress'];
          _endAddress = fromStationRoute['endAddress'];
          _departureTime = _formatTime(DateTime.now());
          _arrivalTime = _formatTime(DateTime.now().add(Duration(seconds: _totalDuration.toInt())));

          // Afficher uniquement les parties que nous pouvons tracer précisément
          _showPartialIntercityRoute(
            toStationRoute['polyline'],
            fromStationRoute['polyline'],
            nearestStationOrigin,
            nearestStationDest,
          );

          _showSearchPanel = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de planification: $e')),
        );
      }
    }
  }

  void _showPartialIntercityRoute(
      List<LatLng> toStationPolyline,
      List<LatLng> fromStationPolyline,
      Map<String, dynamic> originStation,
      Map<String, dynamic> destStation,
      ) {
    setState(() {
      _polylines.clear();
      _markers.clear();

      // Marqueurs importants
      _markers.addAll([
        Marker(
          markerId: const MarkerId('current-location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(title: 'Votre position'),
        ),
        Marker(
          markerId: const MarkerId('origin-station'),
          position: originStation['location'],
          infoWindow: InfoWindow(title: 'Gare de départ: ${originStation['name']}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
        Marker(
          markerId: const MarkerId('dest-station'),
          position: destStation['location'],
          infoWindow: InfoWindow(title: 'Gare d\'arrivée: ${destStation['name']}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: _destination!,
          infoWindow: InfoWindow(title: _destinationController.text),
        ),
      ]);

      // Tracer uniquement les parties connues
      _polylines.add(Polyline(
        polylineId: const PolylineId('to-station-route'),
        points: toStationPolyline,
        color: Colors.blue,
        width: 5,
      ));

      _polylines.add(Polyline(
        polylineId: const PolylineId('from-station-route'),
        points: fromStationPolyline,
        color: Colors.blue,
        width: 5,
      ));

      // Ajouter des marqueurs spéciaux pour les gares
      _markers.add(Marker(
        markerId: const MarkerId('train-connection'),
        position: originStation['location'],
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Prendre le train ici'),
      ));

      _markers.add(Marker(
        markerId: const MarkerId('train-destination'),
        position: destStation['location'],
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Descendre du train ici'),
      ));
    });

    // Ajuster la vue pour montrer les parties utiles
    final bounds = _boundsFromLatLngList([
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      _destination!,
      originStation['location'],
      destStation['location'],
    ]);

    _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  Future<Map<String, dynamic>> _findNearestTrainStation(LatLng location) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
                'location=${location.latitude},${location.longitude}'
                '&radius=10000'  // Augmentez le rayon à 10km
                '&type=train_station'
                '&key=$_googleApiKey'
                '&language=fr'
                '&region=ma'  // Important pour le Maroc
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['results'].isEmpty) {
          // Second essai sans filtre strict si aucun résultat
          return await _fallbackFindStation(location);
        }

        // Trouve la première vraie gare (pas un arrêt de tram)
        final station = data['results'].firstWhere(
              (s) => _isValidTrainStation(s),
          orElse: () => data['results'][0],
        );

        return {
          'name': station['name'],
          'location': LatLng(
            station['geometry']['location']['lat'],
            station['geometry']['location']['lng'],
          ),
        };
      }
    } catch (e) {
      debugPrint('Erreur recherche gare: $e');
      final nearest = _findNearestKnownStation(location);
      if (nearest != null) return nearest;
    }

    throw Exception('Aucune gare ferroviaire ONCF trouvée');
  }

  Map<String, dynamic>? _findNearestKnownStation(LatLng location) {
    if (knownStations.isEmpty) return null;

    var nearestDist = double.maxFinite;
    MapEntry<String, LatLng>? nearestStation;

    knownStations.forEach((name, pos) {
      final dist = Geolocator.distanceBetween(
        location.latitude, location.longitude,
        pos.latitude, pos.longitude,
      );

      if (dist < nearestDist) {
        nearestDist = dist;
        nearestStation = MapEntry(name, pos);
      }
    });

    return nearestStation != null
        ? {'name': nearestStation!.key, 'location': nearestStation!.value}
        : null;
  }

  bool _isValidTrainStation(Map<String, dynamic> station) {
    final name = station['name'].toString().toLowerCase();
    // Liste des mots-clés identifiant les vraies gares
    final validKeywords = ['gare', 'oncf', 'casa-voyageurs', 'casa-port', 'train'];
    // Exclure les tramways
    final invalidKeywords = ['tram', 'bus', 'station', 'ligne'];

    return validKeywords.any((word) => name.contains(word)) &&
        !invalidKeywords.any((word) => name.contains(word));
  }

  Future<Map<String, dynamic>> _fallbackFindStation(LatLng location) async {
    // Recherche élargie avec texte pour Casablanca
    final response = await http.get(
      Uri.parse(
          'https://maps.googleapis.com/maps/api/place/textsearch/json?'
              'query=gare+ONCF+Casablanca'
              '&location=${location.latitude},${location.longitude}'
              '&radius=50000'
              '&key=$_googleApiKey'
              '&language=fr'
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'].isNotEmpty) {
        final station = data['results'].firstWhere(
              (s) => _isValidTrainStation(s),
          orElse: () => data['results'][0],
        );

        return {
          'name': station['name'],
          'location': LatLng(
            station['geometry']['location']['lat'],
            station['geometry']['location']['lng'],
          ),
        };
      }
    }
    throw Exception('Aucune gare trouvée même avec recherche élargie');
  }

  Future<Map<String, dynamic>> _getRouteToStation(Map<String, dynamic> station) async {
    final response = await http.get(
      Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?'
              'origin=${_currentPosition!.latitude},${_currentPosition!.longitude}'
              '&destination=${station['location'].latitude},${station['location'].longitude}'
              '&mode=transit'
              '&key=$_googleApiKey'
              '&language=fr'
              '&region=ma'
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final legs = route['legs'][0];
        return {
          'steps': _parseSteps(legs['steps']),
          'distance': legs['distance']['value'].toDouble(),
          'duration': legs['duration']['value'].toDouble(),
          'startAddress': legs['start_address'],
          'endAddress': legs['end_address'],
          'polyline': _decodePolyline(route['overview_polyline']['points']),
        };
      }
    }
    throw Exception('Impossible de trouver un itinéraire vers la gare');
  }

  Future<Map<String, dynamic>> _getRouteFromStation(Map<String, dynamic> station) async {
    final response = await http.get(
      Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?'
              'origin=${station['location'].latitude},${station['location'].longitude}'
              '&destination=${_destination!.latitude},${_destination!.longitude}'
              '&mode=transit'
              '&key=$_googleApiKey'
              '&language=fr'
              '&region=ma'
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final legs = route['legs'][0];
        return {
          'steps': _parseSteps(legs['steps']),
          'distance': legs['distance']['value'].toDouble(),
          'duration': legs['duration']['value'].toDouble(),
          'startAddress': legs['start_address'],
          'endAddress': legs['end_address'],
          'polyline': _decodePolyline(route['overview_polyline']['points']),
        };
      }
    }
    throw Exception('Impossible de trouver un itinéraire depuis la gare');
  }

  Future<void> _getRouteBetweenPoints(LatLng origin, LatLng destination, String mode) async {
    final response = await http.get(
      Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?'
              'origin=${origin.latitude},${origin.longitude}'
              '&destination=${destination.latitude},${destination.longitude}'
              '&mode=$mode'
              '&key=$_googleApiKey'
              '&language=fr'
              '&region=ma'
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final legs = route['legs'][0];

        setState(() {
          _routeSteps = _parseSteps(legs['steps']);
          _totalDistance = legs['distance']['value'].toDouble();
          _totalDuration = legs['duration']['value'].toDouble();
          _startAddress = legs['start_address'];
          _endAddress = legs['end_address'];
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('partial-route'),
              color: Colors.blue,
              width: 5,
              points: _decodePolyline(route['overview_polyline']['points']),
            ),
          );
        });
      }
    }
  }

  void _showIntercityRoute(
      List<LatLng> toStationPolyline,
      List<LatLng> fromStationPolyline,
      Map<String, dynamic> originStation,
      Map<String, dynamic> destStation,
      ) {
    setState(() {
      _polylines.clear();
      _markers.clear();

      // Ajouter les marqueurs
      _markers.addAll([
        Marker(
          markerId: const MarkerId('current-location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(title: 'Votre position'),
        ),
        Marker(
          markerId: const MarkerId('origin-station'),
          position: originStation['location'],
          infoWindow: InfoWindow(title: 'Gare de départ: ${originStation['name']}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
        Marker(
          markerId: const MarkerId('dest-station'),
          position: destStation['location'],
          infoWindow: InfoWindow(title: 'Gare d\'arrivée: ${destStation['name']}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: _destination!,
          infoWindow: InfoWindow(title: _destinationController.text),
        ),
      ]);

      // Ajouter les polylignes
      _polylines.add(Polyline(
        polylineId: const PolylineId('to-station'),
        points: toStationPolyline,
        color: Colors.blue,
        width: 5,
      ));

      _polylines.add(Polyline(
        polylineId: const PolylineId('from-station'),
        points: fromStationPolyline,
        color: Colors.blue,
        width: 5,
      ));

      // Ajouter une ligne droite entre les gares (représentant le train)
      _polylines.add(Polyline(
        polylineId: const PolylineId('train-route'),
        points: [originStation['location'], destStation['location']],
        color: Colors.red,
        width: 3,
        geodesic: true,
      ));
    });

    // Ajuster la caméra pour afficher tout le trajet
    _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        _boundsFromLatLngList([
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          _destination!,
        ]),
        100,
      ),
    );
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
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
  void _processRouteData(Map<String, dynamic> data) {
    final route = data['routes'][0];
    final legs = route['legs'][0];
    final points = route['overview_polyline']['points'];
    final routePoints = _decodePolyline(points);

    setState(() {
      _routeSteps = _parseSteps(legs['steps']);
      _totalDistance = legs['distance']['value'].toDouble();
      _totalDuration = legs['duration']['value'].toDouble();
      _startAddress = legs['start_address'];
      _endAddress = legs['end_address'];
      _departureTime = _formatTime(DateTime.now());
      _arrivalTime = _formatTime(
          DateTime.now().add(Duration(seconds: legs['duration']['value'].toInt()))
      );
      _showRouteOnMap(routePoints);
      _showSearchPanel = false;
    });
  }

  List<TransportStep> _parseSteps(List<dynamic> steps) {
    return steps.map((step) {
      if (step['travel_mode'] == 'WALKING') {
        return TransportStep(
          type: 'walk',
          instruction: 'Marcher jusqu\'à ${step['end_address'] ??
              'la station'}',
          distance: step['distance']['value'].toDouble(),
          duration: step['duration']['value'].toDouble(),
          icon: Icons.directions_walk,
          color: Colors.green,
        );
      } else if (step['travel_mode'] == 'TRANSIT') {
        final transit = step['transit_details'];
        return TransportStep(
          type: 'transport',
          instruction: 'Prendre ${transit['line']['vehicle']['name']}',
          distance: step['distance']['value'].toDouble(),
          duration: step['duration']['value'].toDouble(),
          icon: _getTransportIcon(transit['line']['vehicle']['type']),
          color: Colors.blue,
          lineNumber: transit['line']['short_name'] ?? transit['line']['name'],
          departureStop: transit['departure_stop']['name'],
          arrivalStop: transit['arrival_stop']['name'],
          departureTime: transit['departure_time']['text'],
        );
      } else {
        return TransportStep(
          type: 'drive',
          instruction: 'Conduire vers ${step['end_address']}',
          distance: step['distance']['value'].toDouble(),
          duration: step['duration']['value'].toDouble(),
          icon: Icons.directions_car,
          color: Colors.purple,
        );
      }
    }).toList();
  }

  IconData _getTransportIcon(String vehicleType) {
    switch (vehicleType) {
      case 'BUS':
        return Icons.directions_bus;
      case 'TRAM':
        return Icons.tram;
      case 'SUBWAY':
        return Icons.subway;
      case 'TRAIN':
        return Icons.train;
      default:
        return Icons.directions_transit;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0,
        len = encoded.length;
    int lat = 0,
        lng = 0;

    while (index < len) {
      int b,
          shift = 0,
          result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  String _formatTime(DateTime time) {
    return DateFormat.Hm().format(time); // Format 24h (14:30)
  }

  void _showRouteOnMap(List<LatLng> routePoints) {
    setState(() {
      _polylines.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destination!,
          infoWindow: InfoWindow(title: _destinationController.text),
        ),
      );
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: _selectedRouteType == 'transit' ? Colors.blue : Colors.purple,
          width: 5,
          points: routePoints,
        ),
      );
    });
  }

  void _resetSearch() {
    setState(() {
      _showSearchPanel = true;
      _polylines.clear();
      _markers.removeWhere((m) => m.markerId.value == 'destination');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Carte Google Maps ou indicateur de chargement
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(
                  _currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(33.5731, -7.5898),
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
          ),

          // Panneau de recherche
          if (_showSearchPanel)
            Align(
              alignment: Alignment.center,
              child: Container(
                width: MediaQuery
                    .of(context)
                    .size
                    .width * 0.9,
                margin: const EdgeInsets.all(20),
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
                      'Planifier votre trajet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TypeAheadField<String>(
                      textFieldConfiguration: TextFieldConfiguration(
                        controller: _destinationController,
                        decoration: InputDecoration(
                          hintText: 'Destination',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      suggestionsCallback: (pattern) => getSuggestions(pattern),
                      itemBuilder: (context, suggestion) =>
                          ListTile(
                            title: Text(suggestion),
                          ),
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
                            onPressed: () {
                              setState(() {
                                _selectedRouteType =
                                _selectedRouteType == 'transit'
                                    ? 'driving'
                                    : 'transit';
                              });
                            },
                            child: Text(
                              _selectedRouteType == 'transit'
                                  ? 'Cheaper'
                                  : 'Faster',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _getRouteDirections,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Rechercher'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Boutons de navigation (quand le panneau de recherche n'est pas visible)
          if (!_showSearchPanel) ...[
            Positioned(
              top: MediaQuery
                  .of(context)
                  .padding
                  .top + 20,
              left: 20,
              child: FloatingActionButton(
                mini: true,
                onPressed: _resetSearch,
                child: const Icon(Icons.arrow_back),
                backgroundColor: Colors.white,
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RouteDetailsPage(
                            steps: _routeSteps,
                            totalDistance: _totalDistance,
                            totalDuration: _totalDuration,
                            startAddress: _startAddress,
                            endAddress: _endAddress,
                            departureTime: _departureTime,
                            arrivalTime: _arrivalTime,
                          ),
                    ),
                  );
                },
                icon: const Icon(Icons.list),
                label: const Text('Details'),
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ],
      ),
    );
  }
}