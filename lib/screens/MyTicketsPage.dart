import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'ticket.dart';
import '../providers/ticket_provider.dart';
import 'ticket_detail_page.dart';

class MyTicketsPage extends StatelessWidget {
  const MyTicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ticketProvider = Provider.of<TicketProvider>(context);
    final tickets = ticketProvider.tickets;

    return Scaffold(
      appBar: AppBar(title: const Text("Mes billets")),
      body: tickets.isEmpty
          ? const Center(child: Text("Aucun billet réservé"))
          : ListView.builder(
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return Card(
            color: ticket.isRead
                ? Colors.grey[300]
                : (ticket.isTaxi ? Colors.purple[100] : Colors.green[100]),
            child: ListTile(
              leading: Icon(
                ticket.isTaxi ? Icons.local_taxi : Icons.directions_bus,
                color: ticket.isTaxi ? Colors.purple : Colors.green,
              ),
              title: Text(ticket.isTaxi
                  ? 'Taxi - ${ticket.stopName}'
                  : '${ticket.lineNumber} - ${ticket.stopName}'),
              subtitle: Text('Départ: ${DateFormat('dd/MM HH:mm').format(ticket.departureTime)}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                ticketProvider.markAsRead(index);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TicketDetailPage(ticket: ticket),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}