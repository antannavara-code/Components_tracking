import 'package:flutter/material.dart';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';
import '../models/models.dart';
import '../services/bluetooth_printer_service.dart';

class PrinterSelectScreen extends StatefulWidget {
  final Asset asset;
  const PrinterSelectScreen({super.key, required this.asset});

  @override
  State<PrinterSelectScreen> createState() => _PrinterSelectScreenState();
}

class _PrinterSelectScreenState extends State<PrinterSelectScreen> {
  final BluetoothPrinterService _service = BluetoothPrinterService();
  final List<PrinterDevice> _devices = [];
  bool _isScanning = false;
  bool _isPrinting = false;
  PrinterDevice? _selectedDevice;
  String _status = 'Tap scan to find Bluetooth printers';

  @override
  void initState() {
    super.initState();
    _scanDevices();
  }

  Future<void> _scanDevices() async {
    setState(() {
      _isScanning = true;
      _devices.clear();
      _selectedDevice = null;
      _status = 'Scanning for Bluetooth printers...';
    });

    final devices = await _service.scanDevices(retries: 3);

    if (mounted) {
      setState(() {
        _isScanning = false;
        _devices.addAll(devices);
        _status = devices.isEmpty
            ? 'No printers found.\nMake sure printer is ON and paired in Android Settings > Bluetooth.'
            : 'Found ${devices.length} device(s). Select one:';
      });
    }
  }

  Future<void> _connectAndPrint(PrinterDevice device) async {
    setState(() {
      _isPrinting = true;
      _status = 'Connecting to ${device.name}...';
    });

    final connected = await _service.connect(device);
    if (!connected) {
      if (mounted) {
        setState(() {
          _isPrinting = false;
          _status = 'Connection failed. Please retry.';
        });
      }
      return;
    }

    if (mounted) setState(() => _status = 'Connected! Printing...');

    final ok = await _service.printBarcodeLabel(
      assetId: widget.asset.assetId,
      assetName: widget.asset.name,
    );

    await _service.disconnect();

    if (mounted) {
      setState(() => _isPrinting = false);
      if (ok) {
        _status = 'Printed successfully!';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Barcode label printed!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        _status = 'Print failed. Please retry.';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Print failed. Please retry.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Printer'),
        actions: [
          IconButton(
            onPressed: _isScanning || _isPrinting ? null : _scanDevices,
            icon: _isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bluetooth_searching),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.qr_code, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.asset.assetId,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      widget.asset.name,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _status,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bluetooth_disabled,
                            size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('No printers found',
                            style:
                                TextStyle(color: Colors.grey[500], fontSize: 16)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _isScanning ? null : _scanDevices,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Scan Again'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final isSelected = _selectedDevice == device;
                      return ListTile(
                        leading: Icon(
                          Icons.bluetooth,
                          color: isSelected ? Colors.blue : Colors.grey,
                        ),
                        title: Text(device.name),
                        subtitle: Text(
                          device.toString(),
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 11),
                        ),
                        trailing: _isPrinting && isSelected
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : null,
                        onTap: _isPrinting
                            ? null
                            : () {
                                setState(() => _selectedDevice = device);
                              },
                      );
                    },
                  ),
          ),
          if (_selectedDevice != null && !_isPrinting)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => _connectAndPrint(_selectedDevice!),
                    icon: const Icon(Icons.print),
                    label: Text('Print on ${_selectedDevice!.name}'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
