import 'package:flutter/material.dart';
import '../screens/ticket.dart';

class TicketProvider extends ChangeNotifier {
  final List<Ticket> _tickets = [];

  List<Ticket> get tickets => _tickets;

  void addTicket(Ticket ticket) {
    _tickets.add(ticket);
    notifyListeners();
  }

  void markAsRead(int index) {
    _tickets[index].isRead = true;
    notifyListeners();
  }
}
