import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReservationPage extends StatelessWidget {
  final String stopName;
  final String lineNumber;
  final DateTime departureTime;
  final double price;

  const ReservationPage({
    Key? key,
    required this.stopName,
    required this.lineNumber,
    required this.departureTime,
    required this.price,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de Réservation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailCard(
              Icons.directions_bus,
              'Arrêt',
              stopName,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              Icons.confirmation_number,
              'Ligne',
              lineNumber,
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              Icons.access_time,
              'Départ',
              DateFormat('dd MMMM yyyy, HH:mm').format(departureTime),
              Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              Icons.attach_money,
              'Prix',
              '${price.toStringAsFixed(2)} DH',
              Colors.purple,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Logique de confirmation de réservation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Réservation confirmée!')),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Confirmer la Réservation'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String title, String value, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}