import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'tournee_detail_page.dart';

class TourneePage extends StatefulWidget {
  @override
  _TourneePageState createState() => _TourneePageState();
}

class _TourneePageState extends State<TourneePage> {
  TextEditingController _nomController = TextEditingController();
  bool isCreatingTournee = false;
  bool _nomError = false;
  List<Map<String, dynamic>> tournees = [];
  List depots = [];
  List<bool> selectedDepots = [];

  final String jardinDeCocagne = "Jardins de Cocagne";

  @override
  void initState() {
    super.initState();
    _loadTournees();
    _fetchDepots();
  }

  Future<void> _fetchDepots() async {
    final response = await http.get(
      Uri.parse(
          'https://qjnieztpwnwroinqrolm.supabase.co/rest/v1/detail_depots'),
      headers: {
        'apikey':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqbmllenRwd253cm9pbnFyb2xtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc4MTEwNTAsImV4cCI6MjA1MzM4NzA1MH0.orLZFmX3i_qR0H4H6WwhUilNf5a1EAfrFhbbeRvN41M',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        depots = jsonDecode(response.body);
        selectedDepots = List<bool>.filled(depots.length, false);

        for (int i = 0; i < depots.length; i++) {
          if (depots[i]['depot'] == jardinDeCocagne) {
            selectedDepots[i] = true;
            break;
          }
        }
      });
    }
  }

  Future<void> _loadTournees() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tourneesData = prefs.getString('tournees');
    if (tourneesData != null) {
      setState(() {
        tournees = List<Map<String, dynamic>>.from(json.decode(tourneesData));
      });
    }
  }

  Future<int> _generateUniqueId() async {
  final prefs = await SharedPreferences.getInstance();
  int id = (prefs.getInt('lastTourneeId') ?? 0) + 1;

  if (id > 1000) {
    id = 1; // On boucle pour rester sous 1000
  }

  await prefs.setInt('lastTourneeId', id);
  return id;
}

  Future<void> _saveTournee() async {
  if (_nomController.text.isEmpty) {
    setState(() {
      _nomError = true;
    });
    return;
  }

  setState(() {
    _nomError = false;
  });

  if (!selectedDepots.contains(true)) return;

  List<Map<String, dynamic>> depotsSelectionnes = [];
  for (int i = 0; i < depots.length; i++) {
    if (selectedDepots[i]) {
      depotsSelectionnes.add({
        "nom": depots[i]['depot'],
        "adresse": depots[i]['adresse'] ?? "Adresse inconnue",
        "coordonnees": depots[i]['localisation'] ?? {"lat": 0, "lng": 0}
      });
    }
  }

  int id = await _generateUniqueId(); // Génère un ID ≤ 1000

  Map<String, dynamic> nouvelleTournee = {
    "id": id, // 📌 Utilisation de l'ID généré
    "nom": _nomController.text,
    "depots": depotsSelectionnes,
    "total_depots": depotsSelectionnes.length
  };

  setState(() {
    tournees.add(nouvelleTournee);
    isCreatingTournee = false;
  });

  final prefs = await SharedPreferences.getInstance();
  prefs.setString('tournees', json.encode(tournees));

  _nomController.clear();
  selectedDepots = List<bool>.filled(depots.length, false);
}

  Future<void> _deleteTournee(int index) async {
    setState(() {
      tournees.removeAt(index);
    });

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('tournees', json.encode(tournees));
  }

  Future<void> _confirmDeleteTournee(int index) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Supprimer la tournée ?"),
          content: Text(
              "Êtes-vous sûr de vouloir supprimer cette tournée ? Cette action est irréversible."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text("Annuler"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text("Oui, supprimer"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _deleteTournee(index);
    }
  }

  Future<void> _confirmRemoveJardin(int index) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Supprimer le point de départ ?"),
          content: Text(
              "Vous êtes sur le point de retirer 'Jardins de Cocagne', qui est le point de départ de la tournée. Voulez-vous continuer ?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text("Annuler"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text("Oui, supprimer"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        selectedDepots[index] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gestion des Tournées')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                isCreatingTournee = !isCreatingTournee;
                _nomError = false;
              });
            },
            child: Text(isCreatingTournee ? 'Annuler' : 'Créer une Tournée'),
          ),
          if (isCreatingTournee) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _nomController,
                decoration: InputDecoration(
                  labelText: 'Nom de la tournée',
                  errorText:
                      _nomError ? "Le nom de la tournée est requis" : null,
                ),
              ),
            ),
            Expanded(
              child: depots.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: depots.length,
                      itemBuilder: (context, index) {
                        bool isJardin =
                            depots[index]['depot'] == jardinDeCocagne;

                        return CheckboxListTile(
                          title: Text(depots[index]['depot']),
                          value: selectedDepots[index],
                          onChanged: (bool? value) {
                            if (isJardin && value == false) {
                              _confirmRemoveJardin(index);
                            } else {
                              setState(() {
                                selectedDepots[index] = value!;
                              });
                            }
                          },
                        );
                      },
                    ),
            ),
            ElevatedButton(
              onPressed: _saveTournee,
              child: Text('Sauvegarder Tournée'),
            ),
            Divider(),
          ],
          Expanded(
            child: ListView.builder(
              itemCount: tournees.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(tournees[index]['nom']),
                  subtitle: Text("Dépôts: ${tournees[index]['total_depots']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteTournee(index),
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward),
                        onPressed: () {
                          print(
                              "🔍 ID de la tournée envoyée : ${tournees[index]['id']}"); // Vérifier l’ID avant d’ouvrir la page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TourneeDetailPage(tournee: tournees[index]),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
