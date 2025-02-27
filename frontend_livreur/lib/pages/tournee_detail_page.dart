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

  Future<void> _fetchPaniers(String mois) async {
    //  final String apiUrl = "http://127.0.0.1:5000/basket?mois=$mois";
    final String apiUrl = "http://192.168.1.24:5000/basket?mois=$mois";
    print("Mois choisi : $mois");
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.isEmpty || data.containsKey("error")) {
          print(
              "⚠️ Aucun panier trouvé pour $mois. ➡️ Création d'une composition par défaut.");
          return;
        }

        final Random random = Random();

        int nombrePetitPanier = data["nombrePetitPanier"].toInt();
        int nombreMoyenPanier = data["nombreMoyenPanier"].toInt();
        int nombreGrandPanier = data["nombreGrandPanier"].toInt();

        // Utilisation de la liste filtrée des dépôts chargée par _loadDepots
        int nombreDepots = depots.length;

        int basePetitPanier = nombrePetitPanier ~/ nombreDepots;
        int baseMoyenPanier = nombreMoyenPanier ~/ nombreDepots;
        int baseGrandPanier = nombreGrandPanier ~/ nombreDepots;

        int restePetitPanier = nombrePetitPanier % nombreDepots;
        int resteMoyenPanier = nombreMoyenPanier % nombreDepots;
        int resteGrandPanier = nombreGrandPanier % nombreDepots;

        List<Map<String, dynamic>> paniersDistribues = [];
        for (int i = 0; i < nombreDepots; i++) {
          int randomPetit = basePetitPanier +
              (i < restePetitPanier ? 1 : 0) -
              random.nextInt(basePetitPanier + 1);
          int randomMoyen = baseMoyenPanier +
              (i < resteMoyenPanier ? 1 : 0) -
              random.nextInt(baseMoyenPanier + 1);
          int randomGrand = baseGrandPanier +
              (i < resteGrandPanier ? 1 : 0) -
              random.nextInt(baseGrandPanier + 1);

          // S'assurer d'avoir des quantités positives
          randomPetit = randomPetit < 0
              ? 0
              : (randomPetit > nombrePetitPanier
                  ? nombrePetitPanier
                  : randomPetit);
          randomMoyen = randomMoyen < 0
              ? 0
              : (randomMoyen > nombreMoyenPanier
                  ? nombreMoyenPanier
                  : randomMoyen);
          randomGrand = randomGrand < 0
              ? 0
              : (randomGrand > nombreGrandPanier
                  ? nombreGrandPanier
                  : randomGrand);

          paniersDistribues.add({
            "depot": depots[i]['nom'], // Utilisation du dépôt filtré
            "adresse": depots[i]['adresse'],
            "panier": [
              {"nom": "Petit Panier", "quantite": randomPetit},
              {"nom": "Moyen Panier", "quantite": randomMoyen},
              {"nom": "Grand Panier", "quantite": randomGrand}
            ]
          });
          print("PASS 3");

          nombrePetitPanier -= randomPetit;
          nombreMoyenPanier -= randomMoyen;
          nombreGrandPanier -= randomGrand;
        }

        setState(() {
          paniers = paniersDistribues;
          print("PASS 4");
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
                  var depot = paniers[index]; // Chaque dépôt
                  return ExpansionTile(
                    leading: Icon(Icons.location_on),
                    title: Text(depot['depot']), // Nom du dépôt
                    children: depot['panier'].map<Widget>((panier) {
                      return ListTile(
                        leading: Icon(Icons.shopping_cart),
                        title: Text(
                            panier['nom']), // Nom du panier (ex: Petit Panier)
                        trailing: Text(
                          "${panier['quantite']}x", // Quantité de paniers
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
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
                // Combinaison des infos dépôts et paniers
                List<Map<String, dynamic>> combinedDepots = depots.map((depot) {
                  var basketInfo = paniers.firstWhere(
                      (p) => p['depot'] == depot['nom'],
                      orElse: () => {});
                  return {...depot, "paniers": basketInfo['panier'] ?? []};
                }).toList();

                print("🔍 Dépôts envoyés à la carte : $combinedDepots");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapPage(depots: combinedDepots),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text("Aucun dépôt disponible pour cette tournée.")));
              }
            },
            child: Text('🚗 Démarrer la Tournée'),
          ),
        ],
      ),
    );
  }
}
