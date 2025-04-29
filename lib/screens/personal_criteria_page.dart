import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalCriteriaPage extends StatefulWidget {
  const PersonalCriteriaPage({Key? key}) : super(key: key);

  @override
  _PersonalCriteriaPageState createState() => _PersonalCriteriaPageState();
}

class _PersonalCriteriaPageState extends State<PersonalCriteriaPage> {
  double _maxWalkingDistance = 500.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _maxWalkingDistance = prefs.getDouble('max_walking_distance') ?? 500.0;
      _isLoading = false;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('max_walking_distance', _maxWalkingDistance);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Préférences sauvegardées avec succès!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Préférences de Marche'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePreferences,
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Distance maximale de marche',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Définissez la distance maximale que vous êtes prêt à marcher :',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('100 m'),
                  Text('${_maxWalkingDistance.toInt()} m',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text('2000 m'),
                ],
              ),
              Slider(
                value: _maxWalkingDistance,
                min: 100,
                max: 2000,
                divisions: 19,
                label: '${_maxWalkingDistance.toInt()} mètres',
                onChanged: (value) {
                  setState(() {
                    _maxWalkingDistance = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cette préférence affectera les trajets en suggérant des taxis lorsque la distance de marche dépasse cette valeur.',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40), // Espace avant le bouton
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.directions_walk),
                  label: const Text('Appliquer les Préférences'),
                  onPressed: _savePreferences,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20), // Espace pour la barre de navigation
            ],
          ),
        ),
      ),
    );
  }
}