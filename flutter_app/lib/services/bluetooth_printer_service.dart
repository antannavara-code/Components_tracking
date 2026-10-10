import 'dart:async';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';

/// Centralized ESC/POS Bluetooth printing service.
///
/// Consolidates the working thermal-print flow so every entry point
/// (BT Print from asset detail, printer select screen) shares the same
/// scan -> connect -> print logic. Includes automatic scan retry to make
/// BLE discovery reliable and a balanced label layout to prevent barcode
/// overlap between consecutive labels.
class BluetoothPrinterService {
  static final BluetoothPrinterService _instance = BluetoothPrinterService._();
  factory BluetoothPrinterService() => _instance;
  BluetoothPrinterService._();

  final PrinterManager _manager = PrinterManager();

  PrinterConnectionState get state => _manager.state;
  bool get isConnected => _manager.isConnected;

  Stream<PrinterConnectionState> get stateStream => _manager.stateStream;

  /// Scan for Bluetooth printers, automatically retrying when BLE discovery
  /// intermittently returns no devices.
  Future<List<PrinterDevice>> scanDevices({
    int retries = 3,
    Duration scanTimeout = const Duration(seconds: 8),
    Duration retryDelay = const Duration(milliseconds: 1500),
  }) async {
    for (var attempt = 0; attempt < retries; attempt++) {
      try {
        final devices = await _manager.scanPrinters(
          timeout: scanTimeout,
          types: {PrinterConnectionType.bluetooth},
        );
        if (devices.isNotEmpty) return devices;
      } catch (_) {
        // ignore scan errors on early attempts; retry below
      }
      if (attempt < retries - 1) {
        await Future<void>.delayed(retryDelay);
      }
    }
    return const [];
  }

  Future<bool> connect(PrinterDevice device) async {
    try {
      await _manager.connect(device);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _manager.disconnect();
    } catch (_) {}
  }

  /// Build a balanced Code128 barcode label.
  ///
  /// - Prints only the barcode with its small human-readable text below, so
  ///   the label is clean and scannable without extra name/text lines.
  /// - Code128 requires at least 2 chars; short asset IDs are padded with a
  ///   leading '0' to produce a scannable code.
  /// - Barcode height is moderate and explicit feed lines separate the label
  ///   from the next one so labels never overlap when printed back-to-back.
  /// - Uses barcode width 2, which prints reliably on the in-house T10 units
  ///   (width 4 prints nothing on those printers).
  Future<Ticket> buildBarcodeTicket({
    required String assetId,
    String? assetName,
  }) async {
    final barcodeText = assetId.length < 2 ? '0$assetId' : assetId;

    final ticket = await Ticket.create(PaperSize.mm58);

    // Small top margin so the barcode starts cleanly after the previous label.
    ticket.feed(1);

    // Barcode with the asset ID printed small beneath it (HRI text).
    ticket.barcode(
      barcodeText,
      type: BarcodeType.code128,
      height: 40,
      width: 2,
      textPosition: BarcodeTextPosition.below,
    );

    // Feed past the HRI text before cutting so labels don't overlap.
    ticket.feed(4);
    ticket.cut();

    return ticket;
  }

  /// Connect, print one label, and disconnect. Returns true on success.
  Future<bool> printBarcodeLabel({
    required String assetId,
    String? assetName,
  }) async {
    if (!_manager.isConnected) return false;

    try {
      final ticket = await buildBarcodeTicket(
        assetId: assetId,
        assetName: assetName,
      );
      await _manager.printTicket(ticket);
      await _manager.disconnect();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await _manager.dispose();
  }
}
