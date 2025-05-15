class Ticket {
  final String stopName;
  final String lineNumber;
  final DateTime departureTime;
  final double price;
  bool isRead;
  final bool isTaxi; // Nouveau champ pour distinguer les taxis

  Ticket({
    required this.stopName,
    required this.lineNumber,
    required this.departureTime,
    required this.price,
    this.isRead = false,
    this.isTaxi = false, // Par défaut false (transport en commun)
  });
}