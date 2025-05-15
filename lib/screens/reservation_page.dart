import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'ticket.dart';
import '../providers/ticket_provider.dart';

class ReservationPage extends StatefulWidget {
  final String stopName;
  final String lineNumber;
  final DateTime departureTime;
  final double price;
  final bool isTaxi;

  const ReservationPage({
    Key? key,
    required this.stopName,
    required this.lineNumber,
    required this.departureTime,
    required this.price,
    this.isTaxi = false,
  }) : super(key: key);

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  int _ticketCount = 1;
  bool _hasAirConditioning = true;
  bool _cardPayment = false;

  @override
  Widget build(BuildContext context) {
    double totalPrice = widget.price * (widget.isTaxi ? 1 : _ticketCount);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTaxi ? 'Réservation de taxi' : 'Détails de Réservation'),
      ),
      body: SingleChildScrollView(  // Added SingleChildScrollView to handle overflow
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailCard(
              widget.isTaxi ? Icons.local_taxi : Icons.directions_bus,
              widget.isTaxi ? 'Taxi' : 'Ligne',
              widget.isTaxi ? 'Service de taxi' : widget.lineNumber,
              widget.isTaxi ? Colors.purple : Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              Icons.location_on,
              'Point de départ',
              widget.stopName,
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              Icons.access_time,
              'Départ',
              DateFormat('dd MMMM yyyy, HH:mm').format(widget.departureTime),
              Colors.orange,
            ),

            if (!widget.isTaxi) ...[
              const SizedBox(height: 16),
              _buildTicketSelector(),
            ],

            if (widget.isTaxi) ...[
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Options supplémentaires:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Climatisation'),
                value: _hasAirConditioning,
                onChanged: (value) {
                  setState(() {
                    _hasAirConditioning = value!;
                  });
                },
              ),

            ],

            const SizedBox(height: 16),
            _buildDetailCard(
              Icons.attach_money,
              'Prix Total',
              '${totalPrice.toStringAsFixed(2)} DH',
              Colors.purple,
            ),

            const SizedBox(height: 24),  // Replaced Spacer with SizedBox for better control
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (widget.isTaxi) {
                    // Création d'un billet pour le taxi
                    final ticket = Ticket(
                      stopName: widget.stopName,
                      lineNumber: 'Taxi',
                      departureTime: widget.departureTime,
                      price: widget.price,
                      isTaxi: true, // Marquer comme billet de taxi
                    );

                    Provider.of<TicketProvider>(context, listen: false).addTicket(ticket);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Votre taxi a été réservé!')),
                    );
                  } else {
                    // Logique existante pour les transports en commun
                    for (int i = 0; i < _ticketCount; i++) {
                      final ticket = Ticket(
                        stopName: widget.stopName,
                        lineNumber: widget.lineNumber,
                        departureTime: widget.departureTime,
                        price: widget.price,
                        isTaxi: false,
                      );
                      Provider.of<TicketProvider>(context, listen: false).addTicket(ticket);
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$_ticketCount billet(s) réservé(s) pour ${totalPrice.toStringAsFixed(2)} DH')),
                    );
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: widget.isTaxi ? Colors.purple : Theme.of(context).primaryColor,
                ),
                child: Text(
                  widget.isTaxi ? 'Confirmer la réservation' : 'Confirmer la réservation',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),  // Added bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildTicketSelector() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.event_seat, color: Colors.teal, size: 32),
            const SizedBox(width: 16),
            const Text(
              'Nombre de billets:',
              style: TextStyle(fontSize: 16),
            ),
            const Spacer(),
            DropdownButton<int>(
              value: _ticketCount,
              onChanged: (int? newValue) {
                setState(() {
                  _ticketCount = newValue!;
                });
              },
              items: List.generate(10, (index) => index + 1)
                  .map<DropdownMenuItem<int>>(
                    (int value) => DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value'),
                ),
              )
                  .toList(),
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
        padding: const EdgeInsets.all(12.0),  // Reduced padding
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),  // Reduced icon size
            const SizedBox(width: 12),  // Reduced spacing
            Expanded(  // Added Expanded to prevent overflow
              child: Column(
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
                      fontSize: 16,  // Reduced font size
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}