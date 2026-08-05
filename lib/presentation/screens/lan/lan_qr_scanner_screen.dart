import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:trigrid/core/network/trigrid_network.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';

class LanQrScannerScreen extends StatefulWidget {
  const LanQrScannerScreen({super.key});

  @override
  State<LanQrScannerScreen> createState() => _LanQrScannerScreenState();
}

class _LanQrScannerScreenState extends State<LanQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  var _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.qrScannerTitle)),
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(controller: _controller, onDetect: _onDetect),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: Card(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.94),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.qrInstruction, textAlign: TextAlign.center),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) {
      return;
    }
    final value = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (value == null) {
      return;
    }
    try {
      final link = LanJoinLink.parse(value);
      if (link.protocolVersion != LanEnvelope.currentProtocolVersion) {
        throw const FormatException('Protocol mismatch.');
      }
      _handled = true;
      Get.back<LanJoinLink>(result: link);
    } on Object {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).invalidRoomQr)),
      );
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
