import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'tournee_detail_page.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final Color primaryColor = Color(0xFF2196F3);
  final Color accentColor = Color(0xFFFF9800);

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

  void _saveTournee() {
    if (_nomController.text.isEmpty) {
      setState(() => _nomError = true);
      return;
    }

    List<String> depotsSelectionnes = [];
    for (int i = 0; i < selectedDepots.length; i++) {
      if (selectedDepots[i]) {
        depotsSelectionnes.add(depots[i]['depot']);
      }
    }

    if (depotsSelectionnes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez sélectionner au moins un dépôt")),
      );
      return;
    }

    setState(() {
      tournees.add({
        'nom': _nomController.text,
        'total_depots': depotsSelectionnes.length,
        'depots': depotsSelectionnes, // Ajoute la liste des dépôts sélectionnés
      });

      // Réinitialisation des champs après l'ajout
      _nomController.clear();
      isCreatingTournee = false;
      _nomError = false;
      selectedDepots = List<bool>.filled(depots.length, false);
    });

    print("Nouvelle tournée créée: ${tournees.last}"); // Debugging
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            "Supprimer la tournée ?",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Cette action est irréversible.",
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Annuler", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("Oui, supprimer"),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      setState(() => tournees.removeAt(index));
    }
  }

  Future<void> _confirmRemoveJardin(int index) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            "Supprimer le point de départ ?",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Vous êtes sur le point de retirer 'Jardins de Cocagne', le point de départ de la tournée. Voulez-vous continuer ?",
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Annuler", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("Oui, supprimer"),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      setState(() => selectedDepots[index] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Tournées', style: GoogleFonts.poppins()),
        centerTitle: true,
        backgroundColor: Colors.green.shade600,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green.shade600,
        onPressed: () {
          setState(() => isCreatingTournee = !isCreatingTournee);
        },
        icon: Icon(isCreatingTournee ? Icons.cancel : Icons.add,
            color: Colors.white),
        label: Text(isCreatingTournee ? 'Annuler' : 'Nouvelle tournée',
            style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            if (isCreatingTournee) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Nom de la tournée",
                          style: GoogleFonts.poppins(fontSize: 16)),
                      SizedBox(height: 8),
                      TextField(
                        controller: _nomController,
                        decoration: InputDecoration(
                          errorText: _nomError ? "Champ requis" : null,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      SizedBox(
                        height: 200, // Hauteur fixe pour éviter l'overflow
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: depots.length,
                          itemBuilder: (context, index) {
                            bool isJardin =
                                depots[index]['depot'] == "Jardins de Cocagne";
                            return CheckboxListTile(
                              title: Text(depots[index]['depot']),
                              value: selectedDepots[index],
                              onChanged: (bool? value) {
                                if (isJardin && value == false) {
                                  _confirmRemoveJardin(index);
                                } else {
                                  setState(
                                      () => selectedDepots[index] = value!);
                                }
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: Icon(Icons.save),
                        onPressed: _saveTournee,
                        label:
                            Text("Sauvegarder", style: GoogleFonts.poppins()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            Expanded(
              child: ListView.builder(
                itemCount: tournees.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(12),
                      title: Text(
                        tournees[index]['nom'],
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "Dépôts: ${tournees[index]['total_depots']}",
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDeleteTournee(index),
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_forward,
                                color: Colors.green.shade600),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TourneeDetailPage(
                                      tournee: tournees[index]),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
