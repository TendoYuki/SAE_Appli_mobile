import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPage extends StatefulWidget {
  final Function(String) onScanSuccess;

  QRScannerPage({required this.onScanSuccess});

  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  MobileScannerController scannerController = MobileScannerController();
  bool isScanningEnabled = false;
  String? scannedData;

  @override
  Widget build(BuildContext context) {
    final double frameSize = 250; // Taille du cadre vert

    return Scaffold(
      appBar: AppBar(title: Text("Scanner un QR Code")),
      body: Stack(
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: (capture) {
              if (!isScanningEnabled) return; // Bloque la détection si pas activée

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                setState(() {
                  scannedData = barcodes.first.rawValue!;
                  isScanningEnabled = false;
                });

                scannerController.stop();
                widget.onScanSuccess(scannedData!);
                Navigator.pop(context);
              }
            },
          ),
          // Masque noir avec trou au centre (cadre de scan)
          _buildScanOverlay(frameSize),
          Positioned(
            bottom: 100,
            left: 50,
            right: 50,
            child: ElevatedButton(
              onPressed: isScanningEnabled
                  ? null
                  : () {
                      setState(() {
                        isScanningEnabled = true;
                      });
                    },
              child: Text("Scanner"),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                scannerController.stop();
                Navigator.pop(context);
              },
              child: Text("Annuler"),
            ),
          ),
        ],
      ),
    );
  }

  /// Création d'une surcouche avec un trou pour forcer le scan dans une zone précise
  Widget _buildScanOverlay(double frameSize) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.5),
        ),
        Center(
          child: Container(
            width: frameSize,
            height: frameSize,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 4),
              borderRadius: BorderRadius.circular(10),
              color: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}
