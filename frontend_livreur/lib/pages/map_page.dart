import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapPage extends StatefulWidget {
  final List<Map<String, dynamic>> depots;

  MapPage({Key? key, required this.depots}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng startPoint = LatLng(48.2528634, 6.4268873);
  LatLng? nextDepot;
  int? nextDepotIndex;
  List<LatLng> routePoints = [];
  bool returningToStart = false;
  bool isReturningDisplayed = false;
  Map<String, dynamic>? nextDepotDetails; // Stocke les infos du prochain dépôt

  @override
  void initState() {
    super.initState();
    _setInitialPosition();
  }

  void _setInitialPosition() {
    if (widget.depots.isNotEmpty) {
      setState(() {
        nextDepotIndex = 0;
        nextDepot = LatLng(
          widget.depots[0]['coordonnees']['coordinates'][1],
          widget.depots[0]['coordonnees']['coordinates'][0],
        );
        nextDepotDetails = widget.depots[0];
      });
      _fetchRoute(startPoint, nextDepot!);
    }
  }

  void _findClosestDepot() {
    if (widget.depots.isEmpty) return;

    double minDistance = double.infinity;
    LatLng? closestDepot;
    int? closestIndex;

    for (int i = 0; i < widget.depots.length; i++) {
      double lat = widget.depots[i]['coordonnees']['coordinates'][1];
      double lon = widget.depots[i]['coordonnees']['coordinates'][0];
      LatLng depotPos = LatLng(lat, lon);

      double distance =
          Distance().as(LengthUnit.Kilometer, startPoint, depotPos);

      if (distance < minDistance) {
        minDistance = distance;
        closestDepot = depotPos;
        closestIndex = i;
      }
    }

    if (closestDepot != null && closestIndex != null) {
      setState(() {
        nextDepot = closestDepot;
        nextDepotIndex = closestIndex!; // Forcer non-nullabilité
        nextDepotDetails = widget.depots[closestIndex!];
      });
      _fetchRoute(startPoint, closestDepot);
    }
  }

  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
        "https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coords = data['routes'][0]['geometry']['coordinates'];

        setState(() {
          routePoints = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
        });
      } else {
        print("❌ Erreur OSRM: ${response.body}");
      }
    } catch (e) {
      print("⚠️ Erreur requête itinéraire : $e");
    }
  }

  void _validateDelivery() {
    if (nextDepotIndex != null && widget.depots.isNotEmpty) {
      setState(() {
        widget.depots.removeAt(nextDepotIndex!);
        startPoint = nextDepot!;
        nextDepotDetails = null; // Masquer les détails du dépôt livré
      });

      if (widget.depots.isNotEmpty) {
        _findClosestDepot(); // Trouver le dépôt suivant
      } else {
        _returnToStart();
      }
    }
  }

  void _returnToStart() {
    setState(() {
      returningToStart = true;
      isReturningDisplayed = true;
    });

    _fetchRoute(startPoint, LatLng(48.2528634, 6.4268873)).then((_) {
      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          returningToStart = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("🎉 Tournée terminée, retour au dépôt effectué !"),
        ));
      });
    });
  }

  void _showNextDepotDetails() {
    if (nextDepotDetails == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          height: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "📍 Prochain dépôt : ${nextDepotDetails!['nom']}",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                  "🏠 Adresse : ${nextDepotDetails!['adresse'] ?? 'Non disponible'}"),
              SizedBox(height: 8),
              Text(
                  "📌 Coordonnées : ${nextDepotDetails!['coordonnees']['coordinates'][1]}, ${nextDepotDetails!['coordonnees']['coordinates'][0]}"),
              SizedBox(height: 8),
              Text("📦 Paniers à livrer :",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  itemCount: (nextDepotDetails!['paniers'] ?? []).length,
                  itemBuilder: (context, index) {
                    var panier = nextDepotDetails!['paniers'][index];
                    return ListTile(
                      leading: Icon(Icons.shopping_cart),
                      title: Text(panier['produit']),
                      trailing: Text("${panier['qte']}x"),
                    );
                  },
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Fermer"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Carte de la tournée")),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              center: startPoint,
              zoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              if (routePoints.isNotEmpty || isReturningDisplayed)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: returningToStart ? Colors.green : Colors.blue,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
          ),
          if (nextDepotDetails != null)
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: _showNextDepotDetails,
                child: Text("📍 Voir le prochain dépôt"),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: returningToStart ? null : _validateDelivery,
        child: Icon(Icons.check),
        backgroundColor: returningToStart ? Colors.grey : Colors.green,
      ),
    );
  }

  List<Marker> _buildMarkers() {
    return widget.depots.map((depot) {
      double lat = depot['coordonnees']['coordinates'][1];
      double lon = depot['coordonnees']['coordinates'][0];
      return Marker(
        width: 40.0,
        height: 40.0,
        point: LatLng(lat, lon),
        builder: (ctx) => Icon(Icons.location_on, color: Colors.red, size: 40),
      );
    }).toList();
  }
}
