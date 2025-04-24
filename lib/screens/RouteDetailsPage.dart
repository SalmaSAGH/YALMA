import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'transport_step.dart';

class RouteDetailsPage extends StatelessWidget {
  final List<TransportStep> steps;
  final double totalDistance;
  final double totalDuration;
  final String startAddress;
  final String endAddress;
  final String departureTime;
  final String arrivalTime;

  const RouteDetailsPage({
    Key? key,
    required this.steps,
    required this.totalDistance,
    required this.totalDuration,
    required this.startAddress,
    required this.endAddress,
    required this.departureTime,
    required this.arrivalTime,
  }) : super(key: key);

  bool get isIntercityTrip => steps.any((step) => step.type == 'train');

  @override
  Widget build(BuildContext context) {
    final isCarTrip = steps.isNotEmpty && steps.first.type == 'drive';
    final durationInMinutes = (totalDuration / 60).round();
    final distanceInKm = (totalDistance / 1000).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du trajet'),
        backgroundColor: isCarTrip ? Colors.purple :
                         isIntercityTrip ? Colors.red : Colors.blue,
      ),
      body: Column(
        children: [
          // En-tête avec durée et distance
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCarTrip ? Colors.purple[50] :
                     isIntercityTrip ? Colors.red[50] : Colors.blue[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  Icons.timer,
                  '$durationInMinutes min',
                  isCarTrip ? Colors.purple :
                  isIntercityTrip ? Colors.red : Colors.blue,
                ),
                _buildInfoItem(
                  isCarTrip ? Icons.directions_car :
                  isIntercityTrip ? Icons.train : Icons.linear_scale,
                  '$distanceInKm km',
                  isCarTrip ? Colors.purple :isIntercityTrip ? Colors.red : Colors.blue,
                ),
                if (!isCarTrip)
                  _buildInfoItem(
                    isIntercityTrip ? Icons.train : Icons.directions_bus,
                    isIntercityTrip ? 'Train inter-villes' : '${_countTransports()} transport(s)',
                    isIntercityTrip ? Colors.red : Colors.blue,
                  ),
              ],
            ),
          ),

          // Corps principal
          Expanded(
            child: isCarTrip ? _buildCarView() : _buildPublicTransportView(),
          ),
        ],
      ),
    );
  }

  Widget _buildCarView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLocationCard(
            Icons.location_on,
            'Départ',
            startAddress,
            departureTime,
            Colors.purple,
          ),
          const SizedBox(height: 24),
          const Icon(Icons.arrow_downward, size: 36, color: Colors.purple),
          const SizedBox(height: 24),
          _buildLocationCard(
            Icons.flag,
            'Arrivée',
            endAddress,
            arrivalTime,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildPublicTransportView() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: steps.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildTransportStep(steps[index]),
    );
  }

  Widget _buildLocationCard(
      IconData icon,
      String title,
      String address,
      String time,
      Color color,
      ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    address,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportStep(TransportStep step) {
    final isTransport = step.type == 'transport';
    final isWalking = step.type == 'walk';
    final isTrain = step.type == 'train';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: step.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isTrain ? Icons.train : step.icon,
                    color: isTrain ? Colors.red : step.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isTrain ? 'Train inter-villes' : _getStepTitle(step),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '${(step.duration / 60).round()} min',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (isTransport) _buildTransportDetails(step),
            if (isWalking) _buildWalkingDetails(step),
            if (isTrain) _buildTrainDetails(step),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: step.distance > 0 ? step.distance / totalDistance : 0.1,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                  isTrain ? Colors.red : step.color),
            ),
            const SizedBox(height: 4),
            Text(
              step.distance > 0
                  ? '${(step.distance / 1000).toStringAsFixed(1)} km'
                  : 'Distance non spécifiée',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildTrainDetails(TransportStep step) {
    return Padding(
      padding: const EdgeInsets.only(left: 42, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(Icons.train, 'Gare de départ:', step.departureStop ?? ''),
          _buildDetailRow(Icons.train, 'Gare d\'arrivée:', step.arrivalStop ?? ''),
          _buildDetailRow(Icons.info, 'Instructions:',
              '1. Rendez-vous à la gare ${step.departureStop}\n'
                  '2. Prendre un train ONCF en direction de ${step.arrivalStop?.replaceAll('Gare ', '')}\n'
                  '3. Consultez les horaires sur https://www.oncf.ma'),
          _buildDetailRow(Icons.warning, 'Attention:',
              'Ne pas confondre avec le tramway ou bus'),
        ],
      ),
    );
  }

  Widget _buildTransportDetails(TransportStep step) {
    return Padding(
      padding: const EdgeInsets.only(left: 42, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(Icons.location_on, 'Départ:', step.departureStop ?? ''),
          const SizedBox(height: 4),
          _buildDetailRow(Icons.flag, 'Arrivée:', step.arrivalStop ?? ''),
          if (step.departureTime != null) ...[
            const SizedBox(height: 4),
            _buildDetailRow(Icons.access_time, 'Horaire:', step.departureTime!),
          ],
        ],
      ),
    );
  }

  Widget _buildWalkingDetails(TransportStep step) {
    return Padding(
      padding: const EdgeInsets.only(left: 42, top: 8),
      child: _buildDetailRow(
        Icons.directions_walk,
        'Destination:',
        step.instruction.replaceFirst('Marcher jusqu\'à ', ''),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Flexible(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              children: [
                TextSpan(
                  text: '$label ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  int _countTransports() {
    return steps.where((step) => step.type == 'transport').length;
  }

  String _getStepTitle(TransportStep step) {
    switch (step.type) {
      case 'walk':
        return 'Marche à pied';
      case 'transport':
        return '${step.lineNumber != null ? 'Ligne ${step.lineNumber}' : 'Transport en commun'}';
      case 'drive':
        return 'Trajet en voiture';
      case 'train':
        return 'Train ${step.lineNumber ?? 'inter-villes'}';
      default:
        return step.instruction;
    }
  }
}