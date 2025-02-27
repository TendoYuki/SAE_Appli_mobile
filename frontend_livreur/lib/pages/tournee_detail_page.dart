import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'map_page.dart';
import 'dart:math';

class TourneeDetailPage extends StatefulWidget {
  final Map<String, dynamic> tournee;

  TourneeDetailPage({Key? key, required this.tournee}) : super(key: key);

  @override
  _TourneeDetailPageState createState() => _TourneeDetailPageState();
}

class _TourneeDetailPageState extends State<TourneeDetailPage> {
  List<Map<String, dynamic>> depots = [];
  List<Map<String, dynamic>> paniers = [];
  bool isLoading = true;
  bool hasError = false;
  int mois = DateTime.now().month;
  List<String> months = [
    "Janvier",
    "Février",
    "Mars",
    "Avril",
    "Mai",
    "Juin",
    "Juillet",
    "Aout",
    "Septembre",
    "Octobre",
    "Novembre",
    "Décembre"
  ];

  @override
  void initState() {
    super.initState();
    _loadDepots();
    _fetchPaniers(months[mois - 1]);
  }

  void _loadDepots() {
    print("🔍 Dépôts reçus : ${widget.tournee['depots']}"); // Debug

    if (widget.tournee['depots'] is List) {
      try {
        depots = widget.tournee['depots']
            .where((depot) =>
                depot['nom'] !=
                "Jardins de Cocagne") // ❌ Exclut le Jardin de Cocagne
            .map((depot) {
              if (depot == null) {
                return {'depot': 'Dépôt inconnu'};
              }
              if (depot is String) {
                return {'depot': depot};
              }
              return depot;
            })
            .toList()
            .cast<Map<String, dynamic>>();

        setState(() {});
      } catch (e) {
        print("❌ Erreur de conversion des dépôts : $e");
      }
    } else {
      print("⚠️ Les données des dépôts ne sont pas une liste !");
    }
  }

//   Future<void> _createDefaultPanierComposition(int tourneeId) async {
//   final String apiUrl =
//       "https://qjnieztpwnwroinqrolm.supabase.co/rest/v1/detail_livraisons";

//   // 📦 Composition par défaut
//   List<Map<String, dynamic>> defaultPaniers = [
//     {"tournee_id": tourneeId, "produit_id": 1, "produit": "Panier Simple", "qte": 5},
//     {"tournee_id": tourneeId, "produit_id": 2, "produit": "Panier Familial", "qte": 3},
//     {"tournee_id": tourneeId, "produit_id": 3, "produit": "Panier Fruits", "qte": 2},
//     {"tournee_id": tourneeId, "produit_id": 4, "produit": "Œufs Bio", "qte": 6}
//   ];

//   try {
//     final response = await http.post(
//       Uri.parse(apiUrl),
//       headers: {
//         "apikey":
//             "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqbmllenRwd253cm9pbnFyb2xtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc4MTEwNTAsImV4cCI6MjA1MzM4NzA1MH0.orLZFmX3i_qR0H4H6WwhUilNf5a1EAfrFhbbeRvN41M",
//         "Content-Type": "application/json",
//         "Prefer": "return=minimal"
//       },
//       body: jsonEncode(defaultPaniers),
//     );

//     if (response.statusCode == 201) {
//       print("✅ Composition de paniers créée pour la tournée $tourneeId");
//       await _fetchPaniers(); // Recharge les paniers
//     } else {
//       print("❌ Erreur lors de la création de la composition : ${response.body}");
//     }
//   } catch (e) {
//     print("⚠️ Erreur envoi requête création panier : $e");
//   }
// }

// Future<void> _fetchPaniers() async {
//   final int? tourneeId = widget.tournee['id'];

//   if (tourneeId == null) {
//     print("❌ Aucun ID de tournée trouvé !");
//     setState(() {
//       hasError = true;
//       isLoading = false;
//     });
//     return;
//   }

//   print("🔍 ID de la tournée utilisée pour l'API : $tourneeId");

//   final String apiUrl =
//       "https://qjnieztpwnwroinqrolm.supabase.co/rest/v1/detail_livraisons?"
//       "tournee_id=eq.$tourneeId&select=produit_id,produit,qte.sum()";

//   try {
//     final response = await http.get(
//       Uri.parse(apiUrl),
//       headers: {
//         'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqbmllenRwd253cm9pbnFyb2xtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc4MTEwNTAsImV4cCI6MjA1MzM4NzA1MH0.orLZFmX3i_qR0H4H6WwhUilNf5a1EAfrFhbbeRvN41M',
//       },
//     );

//     print("📡 Réponse brute API : ${response.body}");

//     if (response.statusCode == 200) {
//       final List<dynamic> data = jsonDecode(response.body);

//       if (data.isEmpty) {
//         print("⚠️ Aucun panier trouvé pour cette tournée. ➡️ Création d'une composition par défaut.");
//         await _createDefaultPanierComposition(tourneeId);
//         return;
//       }

//       setState(() {
//         paniers = data.map((item) => {
//               'produit': item['produit'] ?? 'Inconnu',
//               'quantite': item['qte.sum()'] ?? 0
//             }).toList();
//         isLoading = false;
//       });
//     } else {
//       print("❌ Erreur lors de la récupération des paniers : ${response.body}");
//       setState(() {
//         hasError = true;
//         isLoading = false;
//       });
//     }
//   } catch (e) {
//     print("⚠️ Erreur requête API paniers : $e");
//     setState(() {
//       hasError = true;
//       isLoading = false;
//     });
//   }
// }

  Future<void> _fetchPaniers(String mois) async {
    final String apiUrl =
        "http://192.168.1.24:5000/basket?mois=$mois"; // URL correcte
    print("Mois choisi : $mois");
    try {
      final response = await http.get(Uri.parse(apiUrl));

      // print("📡 Réponse brute API : ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        // print("Réponse brute data : $data");
        if (data.isEmpty || data.containsKey("error")) {
          print(
              "⚠️ Aucun panier trouvé pour $mois. ➡️ Création d'une composition par défaut.");
          return;
        }

        final Random random = Random();

        // Générer un nombre aléatoire de paniers sur le nombre disponible
        int randomPetit = random.nextInt(data["nombrePetitPanier"].toInt() + 1);
        int randomMoyen = random.nextInt(data["nombreMoyenPanier"].toInt() + 1);
        int randomGrand = random.nextInt(data["nombreGrandPanier"].toInt() + 1);

        setState(() {
          paniers = [
            {"nom": "Petit Panier", "quantite": randomPetit},
            {"nom": "Moyen Panier", "quantite": randomMoyen},
            {"nom": "Grand Panier", "quantite": randomGrand}
          ];

          isLoading = false;
        });
      } else {
        print(
            "❌ Erreur lors de la récupération des paniers : ${response.body}");
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      print("⚠️ Erreur requête API paniers : $e");
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Détails de ${widget.tournee['nom']}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Tournée : ${widget.tournee['nom']}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Nombre de dépôts : ${widget.tournee['total_depots']}',
              style: TextStyle(fontSize: 18),
            ),
          ),
          Divider(),

          // 🔹 Affichage des paniers à livrer 🔹
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '📦 Récapitulatif des Paniers à Livrer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (isLoading)
            Center(child: CircularProgressIndicator())
          else if (hasError)
            Center(
              child: Text(
                "❌ Impossible de récupérer les paniers",
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            )
          else if (paniers.isEmpty)
            Center(child: Text("Aucun panier à livrer pour cette tournée."))
          else
            Expanded(
              child: ListView.builder(
                itemCount: paniers.length,
                itemBuilder: (context, index) {
                  var panier = paniers[index];
                  return ListTile(
                    leading: Icon(Icons.shopping_cart),
                    title: Text(panier['nom']),
                    trailing: Text(
                      "${panier['quantite']}x",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          Divider(),

          // 🔹 Liste des dépôts 🔹
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '🏠 Dépôts de la tournée',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: depots.length,
              itemBuilder: (context, index) {
                var depot = depots[index];
                return ListTile(
                  title: Text(depot['nom']),
                  subtitle: Text("Adresse : ${depot['adresse']}"),
                  leading: Icon(Icons.store),
                );
              },
            ),
          ),

          // 🔹 Bouton pour démarrer la tournée 🔹
          ElevatedButton(
            onPressed: () {
              if (depots.isNotEmpty) {
                print("🔍 Dépôts envoyés à la carte : $depots");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapPage(depots: depots),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text("Aucun dépôt disponible pour cette tournée.")),
                );
              }
            },
            child: Text('🚗 Démarrer la Tournée'),
          ),
        ],
      ),
    );
  }
}
