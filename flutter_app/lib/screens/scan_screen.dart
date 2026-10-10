import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/drone_provider.dart';
import '../providers/location_provider.dart';
import '../providers/project_provider.dart';
import '../models/models.dart';
import '../widgets/status_chip.dart';
import 'asset_detail_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  static const int _manualLocationId = -1;
  MobileScannerController? _scannerController;
  bool _isScanning = false;
  Asset? _scannedAsset;
  final _manualController = TextEditingController();
  String _error = '';
  String _success = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().fetchEmployees();
      context.read<DroneProvider>().fetchDrones();
      context.read<LocationProvider>().fetchLocations();
      context.read<ProjectProvider>().fetchProjects();
    });
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _error = '';
      _success = '';
      _isScanning = true;
    });
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  void _stopScan() {
    _scannerController?.dispose();
    _scannerController = null;
    setState(() => _isScanning = false);
  }

  void _onDetect(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;
    _stopScan();
    _lookupAsset(code.trim());
  }

  Future<void> _lookupAsset(String assetId) async {
    setState(() {
      _error = '';
      _success = '';
    });
    final asset =
        await context.read<AssetProvider>().fetchByAssetId(assetId);
    if (asset == null) {
      setState(() => _error = 'Asset "$assetId" not found');
    } else {
      setState(() => _scannedAsset = asset);
    }
  }

  void _resetScan() {
    setState(() {
      _scannedAsset = null;
      _error = '';
      _success = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('QR Scanner',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Scan a QR code on any asset to view details and perform actions.',
            style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 16),
        if (_success.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_success,
                        style: TextStyle(color: Colors.green.shade700))),
              ],
            ),
          ),
        if (_error.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_error,
                        style: TextStyle(color: Colors.red.shade700))),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _error = ''),
                ),
              ],
            ),
          ),
        if (_scannedAsset == null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_isScanning && _scannerController != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 250,
                        child: MobileScanner(
                          controller: _scannerController!,
                          onDetect: _onDetect,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _isScanning ? _stopScan : _startScan,
                      icon: Icon(
                          _isScanning ? Icons.stop : Icons.qr_code_scanner),
                      label: Text(
                          _isScanning ? 'Stop Scanner' : 'Start Camera Scan'),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            _isScanning ? Colors.red : Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Or enter Asset ID manually:',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. JET-001',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          textCapitalization: TextCapitalization.characters,
                          onSubmitted: (_) => _manualLookup(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _manualLookup,
                        child: const Text('Look Up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_scannedAsset != null) _buildScannedAsset(),
      ],
    );
  }

  void _manualLookup() {
    final id = _manualController.text.trim();
    if (id.isNotEmpty) {
      _lookupAsset(id);
      _manualController.clear();
    }
  }

  Widget _buildScannedAsset() {
    final asset = _scannedAsset!;
    return Card(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(asset.assetId,
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      Text(asset.name,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 14)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _resetScan,
                  child: const Text('Scan Another'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _infoGrid(asset),
                const SizedBox(height: 16),
                if (asset.status != 'missing' && asset.status != 'damaged')
                  _buildActionButtons(asset),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AssetDetailScreen(asset: asset),
                        ),
                      ).then((_) => _refreshAsset()),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Full Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshAsset() async {
    final updated =
        await context.read<AssetProvider>().fetchAssetById(_scannedAsset!.id);
    if (updated != null && mounted) {
      setState(() => _scannedAsset = updated);
    }
  }

  Widget _infoGrid(Asset asset) {
    final items = [
      ('Category', asset.category),
      ('Model', asset.model ?? 'N/A'),
      ('Serial', asset.serialNumber ?? 'N/A'),
      ('Status', asset.status),
      ('Condition', asset.conditionType),
      ('Owner', asset.currentUser?.name ?? 'None'),
      ('Location', asset.currentLocation?.name ?? 'None'),
      ('Drone', asset.currentDrone?.name ?? 'None'),
      ('Project', asset.project?.name ?? 'None'),
    ];

    return Column(
      children: items.map((item) {
        if (item.$1 == 'Status') {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                    width: 80,
                    child: Text(item.$1,
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 13))),
                StatusChip(status: item.$2),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                  width: 80,
                  child: Text(item.$1,
                      style:
                          TextStyle(color: Colors.grey[500], fontSize: 13))),
              Expanded(
                  child: Text(item.$2,
                      style: const TextStyle(fontSize: 13))),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(Asset asset) {
    final actions = <Widget>[];

    if (asset.status == 'available') {
      actions.add(_actionBtn('Assign to Employee', Colors.blue,
          () => _showActionForm('assign', asset)));
    }
    if (asset.status == 'assigned') {
      actions.add(_actionBtn('Transfer', Colors.orange,
          () => _showActionForm('transfer', asset)));
      actions.add(_actionBtn('Return', Colors.green,
          () => _showActionForm('return', asset)));
      actions.add(_actionBtn('Install in Drone', Colors.purple,
          () => _showActionForm('assign-drone', asset)));
    }
    if (asset.status == 'in_drone') {
      actions.add(_actionBtn('Remove from Drone', Colors.deepOrange,
          () => _executeAction('remove-drone', asset, {})));
      actions.add(_actionBtn('Return', Colors.green,
          () => _showActionForm('return', asset)));
    }
    actions.add(_actionBtn(
        'Report Missing', Colors.red, () => _showReportDialog('missing', asset)));
    actions.add(_actionBtn(
        'Report Damaged', Colors.pink, () => _showReportDialog('damaged', asset)));

    return Wrap(spacing: 8, runSpacing: 8, children: actions);
  }

  Widget _actionBtn(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 44,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(backgroundColor: color),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  void _showActionForm(String action, Asset asset) {
    final employees = context.read<EmployeeProvider>().employees;
    final drones = context
        .read<DroneProvider>()
        .drones
        .where((d) => d.status == 'active')
        .toList();

    int? selectedId;
    int selectedLocationValue = 0;
    String? manualLocationError;
    final manualLocationController = TextEditingController();
    final purposeController = TextEditingController();
    final locationsProvider = context.read<LocationProvider>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (action == 'return') {
            return AlertDialog(
              title: const Text('Return Asset'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Return to Location',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 6),
                  FutureBuilder<void>(
                    future: locationsProvider.fetchLocations(),
                    builder: (context, snapshot) {
                      final locations = locationsProvider.locations;
                      if (snapshot.connectionState != ConnectionState.done &&
                          locations.isEmpty) {
                        return const SizedBox(
                          height: 56,
                          child: Center(
                              child:
                                  CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<int>(
                            initialValue: selectedLocationValue,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              hintText: 'Select Location',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            items: [
                              ...locations.map((l) => DropdownMenuItem<int>(
                                  value: l.id, child: Text(l.name))),
                              const DropdownMenuItem<int>(
                                  value: _manualLocationId,
                                  child: Text('Other (Manual)')),
                            ],
                            onChanged: (v) => setDialogState(() {
                              selectedLocationValue = v ?? 0;
                              manualLocationError = null;
                            }),
                          ),
                          if (selectedLocationValue == _manualLocationId) ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: manualLocationController,
                              decoration: InputDecoration(
                                hintText: 'Enter Location',
                                border: const OutlineInputBorder(),
                                errorText: manualLocationError,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: selectedLocationValue == 0
                      ? null
                      : () async {
                          int? resolvedLocationId;
                          if (selectedLocationValue == _manualLocationId) {
                            final name = manualLocationController.text.trim();
                            if (name.isEmpty) {
                              setDialogState(() =>
                                  manualLocationError = 'Enter a location name');
                              return;
                            }
                            final existing = locationsProvider.locations
                                .map((l) => l.name.toLowerCase());
                            if (existing.contains(name.toLowerCase())) {
                              setDialogState(() => manualLocationError =
                                  'Location "$name" already exists');
                              return;
                            }
                            final id = await locationsProvider
                                .createLocation({'name': name});
                            if (id == null) {
                              setDialogState(() => manualLocationError =
                                  'Failed to create location');
                              return;
                            }
                            resolvedLocationId = id;
                          } else {
                            resolvedLocationId = selectedLocationValue;
                          }
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          _executeAction(action, asset, {
                            'location_id': resolvedLocationId
                          });
                        },
                  child: const Text('Confirm'),
                ),
              ],
            );
          }

          List<DropdownMenuItem<int>> items = [];
          String label = '';

          switch (action) {
            case 'assign':
              label = 'Select Employee';
              items = employees
                  .map((e) =>
                      DropdownMenuItem(value: e.id, child: Text(e.name)))
                  .toList();
              break;
            case 'transfer':
              label = 'Transfer to Employee';
              items = employees
                  .where((e) => e.id != asset.currentUserId)
                  .map((e) =>
                      DropdownMenuItem(value: e.id, child: Text(e.name)))
                  .toList();
              break;
            case 'assign-drone':
              label = 'Select Drone';
              items = drones
                  .map((d) => DropdownMenuItem(
                      value: d.id,
                      child: Text('${d.droneId} - ${d.name}')))
                  .toList();
              break;
          }

          return AlertDialog(
            title: Text(action.replaceAll('-', ' ').toUpperCase()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                      labelText: label, border: const OutlineInputBorder()),
                  items: items,
                  onChanged: (v) =>
                      setDialogState(() => selectedId = v),
                ),
                if (action != 'return') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: purposeController,
                    decoration: const InputDecoration(
                        labelText: 'Purpose',
                        border: OutlineInputBorder()),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: selectedId == null
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        final data = <String, dynamic>{};
                        switch (action) {
                          case 'assign':
                            data['employee_id'] = selectedId;
                            break;
                          case 'transfer':
                            data['to_employee_id'] = selectedId;
                            break;
                          case 'return':
                            data['location_id'] = selectedId;
                            break;
                          case 'assign-drone':
                            data['drone_id'] = selectedId;
                            break;
                        }
                        if (purposeController.text.isNotEmpty) {
                          data['purpose'] = purposeController.text;
                        }
                        _executeAction(action, asset, data);
                      },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReportDialog(String type, Asset asset) {
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Report ${type == 'missing' ? 'Missing' : 'Damaged'}'),
        content: TextField(
          controller: descController,
          decoration: const InputDecoration(
            labelText: 'Describe the issue...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final data = <String, dynamic>{};
              if (descController.text.isNotEmpty) {
                data['description'] = descController.text;
              }
              _executeAction(type == 'missing' ? 'report-missing' : 'report-damaged',
                  asset, data);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeAction(
      String action, Asset asset, Map<String, dynamic> data) async {
    final provider = context.read<AssetProvider>();
    bool success = false;

    switch (action) {
      case 'assign':
        success = await provider.assignAsset(asset.id, data);
        break;
      case 'transfer':
        success = await provider.transferAsset(asset.id, data);
        break;
      case 'return':
        success = await provider.returnAsset(asset.id, data: data);
        break;
      case 'assign-drone':
        success = await provider.assignDrone(asset.id, data);
        break;
      case 'remove-drone':
        success = await provider.removeDrone(asset.id);
        break;
      case 'report-missing':
        success = await provider.reportMissing(asset.id,
            description: data['description']);
        break;
      case 'report-damaged':
        success = await provider.reportDamaged(asset.id,
            description: data['description']);
        break;
    }

    if (success) {
      setState(() => _success = 'Action completed successfully');
      _refreshAsset();
    } else {
      setState(() => _error = 'Action failed. Please try again.');
    }
  }
}
