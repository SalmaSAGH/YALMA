import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../screens/ticket.dart';

class TicketDetailPage extends StatelessWidget {
  final Ticket ticket;

  const TicketDetailPage({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(ticket.isTaxi ? "Détail du taxi" : "Détail du billet")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            BarcodeWidget(
              data: '${ticket.isTaxi ? 'TAXI' : ticket.lineNumber}_${ticket.stopName}_${ticket.departureTime}',
              barcode: Barcode.qrCode(), // Génération d'un QR code
              width: 200,
              height: 200, // Taille carrée du QR code
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        ticket.isTaxi ? Icons.local_taxi : Icons.directions_bus,
                        color: ticket.isTaxi ? Colors.purple : Colors.blue,
                      ),
                      title: Text(ticket.isTaxi ? 'Service de Taxi' : 'Ligne ${ticket.lineNumber}'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text('Point de départ'),
                      subtitle: Text(ticket.stopName),
                    ),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Heure de départ'),
                      subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(ticket.departureTime)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.attach_money),
                      title: const Text('Prix'),
                      subtitle: Text('${ticket.price.toStringAsFixed(2)} DH'),
                    ),
                    if (ticket.isTaxi)
                      const ListTile(
                        leading: Icon(Icons.info),
                        title: Text('Présentez ce code au chauffeur'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
