import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:transport_app/screens/reservation_page.dart';
import 'transport_step.dart';

class RouteDetailsPage extends StatefulWidget {
  final List<TransportStep> cheaperSteps;
  final List<TransportStep> fasterSteps;
  final double cheaperDistance;
  final double fasterDistance;
  final double cheaperDuration;
  final double fasterDuration;
  final String startAddress;
  final String endAddress;
  final String departureTime;
  final String arrivalTime;
  final int initialTab;

  const RouteDetailsPage({
    Key? key,
    required this.cheaperSteps,
    required this.fasterSteps,
    required this.cheaperDistance,
    required this.fasterDistance,
    required this.cheaperDuration,
    required this.fasterDuration,
    required this.startAddress,
    required this.endAddress,
    required this.departureTime,
    required this.arrivalTime,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  _RouteDetailsPageState createState() => _RouteDetailsPageState();
}

class _RouteDetailsPageState extends State<RouteDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showCheaper = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _tabController.addListener(_handleTabSelection);
    _showCheaper = widget.initialTab == 0;
  }

  void _handleTabSelection() {
    setState(() {
      _showCheaper = _tabController.index == 0;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du trajet'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Theme.of(context).primaryColor,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Cheaper (Transport)'),
                Tab(text: 'Faster (Voiture)'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContent(widget.cheaperSteps, widget.cheaperDistance, widget.cheaperDuration, false),
          _buildContent(widget.fasterSteps, widget.fasterDistance, widget.fasterDuration, true),
        ],
      ),
    );
  }

  Widget _buildTransportStep(TransportStep step) {
    final isTransport = step.type == 'transport';
    final isWalking = step.type == 'walk';
    final isTrain = step.type == 'train';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: step.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isTrain ? Icons.train : step.icon,
                    color: isTrain ? Colors.red : step.color,
                    size: 24,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isTransport) _buildTransportDetails(step),
            if (isWalking) _buildWalkingDetails(step),
            if (isTrain) _buildTrainDetails(step),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: step.distance > 0
                  ? step.distance / (_showCheaper ? widget.cheaperDistance : widget.fasterDistance)
                  : 0.1,
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
            if (isTransport)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showTransportReservation(context, step),
                  child: const Text(
                    'Réserver',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<TransportStep> steps, double distance, double duration, bool isCarTrip) {
    final durationInMinutes = (duration / 60).round();
    final distanceInKm = (distance / 1000).toStringAsFixed(1);
    final isTrainTrip = steps.any((step) => step.type == 'train');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCarTrip ? Colors.purple[50] :
            isTrainTrip ? Colors.red[50] : Colors.blue[50],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                Icons.timer,
                '$durationInMinutes min',
                isCarTrip ? Colors.purple :
                isTrainTrip ? Colors.red : Colors.blue,
              ),
              _buildInfoItem(
                isCarTrip ? Icons.directions_car :
                isTrainTrip ? Icons.train : Icons.linear_scale,
                '$distanceInKm km',
                isCarTrip ? Colors.purple :
                isTrainTrip ? Colors.red : Colors.blue,
              ),
              if (!isCarTrip)
                _buildInfoItem(
                  isTrainTrip ? Icons.train : Icons.directions_bus,
                  isTrainTrip ? 'Train inter-villes' : '${_countTransports(steps)} transport(s)',
                  isTrainTrip ? Colors.red : Colors.blue,
                ),
            ],
          ),
        ),
        Expanded(
          child: isCarTrip ? SingleChildScrollView(child: _buildCarView()) : _buildPublicTransportView(steps),
        ),
      ],
    );
  }

  Widget _buildCarView() {
    return Padding(
      padding: const EdgeInsets.only(top: 32, left: 16, right: 16, bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLocationCard(
            Icons.location_on,
            'Départ',
            widget.startAddress,
            widget.departureTime,
            Colors.purple,
          ),
          const SizedBox(height: 24),
          const Icon(Icons.arrow_downward, size: 36, color: Colors.purple),
          const SizedBox(height: 24),
          _buildLocationCard(
            Icons.flag,
            'Arrivée',
            widget.endAddress,
            widget.arrivalTime,
            Colors.purple,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _showTaxiReservation(context),
            child: const Text(
              'Réserver un Driver',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicTransportView(List<TransportStep> steps) {
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

  void _showTransportReservation(BuildContext context, TransportStep step) {
    final now = DateTime.now();
    final departureTime = now.add(const Duration(minutes: 5));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationPage(
          stopName: step.departureStop ?? widget.startAddress,
          lineNumber: step.lineNumber ?? 'Transport',
          departureTime: departureTime,
          price: _calculateTransportPrice(step),
          isTaxi: false,
        ),
      ),
    );
  }

  void _showTaxiReservation(BuildContext context) {
    final now = DateTime.now();
    final departureTime = now.add(const Duration(minutes: 5));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationPage(
          stopName: widget.startAddress,
          lineNumber: 'Taxi',
          departureTime: departureTime,
          price: _calculateTaxiPrice(),
          isTaxi: true,
        ),
      ),
    );
  }

  double _calculateTransportPrice(TransportStep step) {
    if (step.type == 'train') return 15.0;
    if (step.lineNumber?.contains('Tram') ?? false) return 6.0;
    return 8.0;
  }

  double _calculateTaxiPrice() {
    final pricePerKm = 3.0;
    final distanceInKm = widget.fasterDistance / 1000;
    return (distanceInKm * pricePerKm).roundToDouble();
  }

  int _countTransports(List<TransportStep> steps) {
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
