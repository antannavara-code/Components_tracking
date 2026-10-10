import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/asset_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/drone_provider.dart';
import '../providers/location_provider.dart';
import '../providers/project_provider.dart';
import '../models/models.dart';
import '../widgets/status_chip.dart';
import '../widgets/create_form_dialog.dart';
import '../widgets/asset_category_options.dart';
import '../services/qr_service.dart';
import '../services/photo_service.dart';
import 'printer_select_screen.dart';

class AssetDetailScreen extends StatefulWidget {
  final Asset asset;
  const AssetDetailScreen({super.key, required this.asset});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  static const int _manualLocationId = -1;
  late Asset _asset;
  String? _successMsg;
  String? _errorMsg;
  List<AssetMovement> _history = [];
  bool _historyLoading = true;

  @override
  void initState() {
    super.initState();
    _asset = widget.asset;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().fetchEmployees();
      context.read<DroneProvider>().fetchDrones();
      context.read<LocationProvider>().fetchLocations();
      context.read<ProjectProvider>().fetchProjects();
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    final history = await context.read<AssetProvider>().fetchHistory(_asset.id);
    if (mounted) {
      setState(() {
        _history = history;
        _historyLoading = false;
      });
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    setState(() {
      if (isError) {
        _errorMsg = msg;
        _successMsg = null;
      } else {
        _successMsg = msg;
        _errorMsg = null;
      }
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _successMsg = _errorMsg = null);
    });
  }

  Future<void> _refreshAsset() async {
    final updated =
        await context.read<AssetProvider>().fetchAssetById(_asset.id);
    if (updated != null && mounted) {
      setState(() => _asset = updated);
    }
    await _loadHistory();
  }

  void _showEditDialog() {
    final currentCategory = _asset.category;
    String? selectedCategory = currentCategory;
    String? categoryError;
    final customCategoryController =
        TextEditingController(text: currentCategory);

    final knownNames = predefinedCategories.map((c) => c.$1).toSet();
    final categoryOptions = <String>[
      ...predefinedCategories.map((c) => c.$1),
      if (currentCategory.trim().isNotEmpty &&
          !knownNames.contains(currentCategory))
        currentCategory,
      manualCategoryKey,
    ];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => CreateFormDialog(
          title: 'Edit Asset',
          fields: [
            FormFieldConfig(
              key: 'asset_id',
              label: 'Asset ID',
              hint: 'e.g. JET-001',
              value: _asset.assetId,
              required: true,
            ),
            FormFieldConfig(
              key: 'category',
              label: 'Category',
              type: FormFieldType.dropdown,
              options: categoryOptions,
              value: categoryOptions.contains(currentCategory)
                  ? currentCategory
                  : categoryOptions.first,
            ),
            FormFieldConfig(
                key: 'name', label: 'Name', value: _asset.name, required: true),
            FormFieldConfig(
                key: 'serial_number',
                label: 'Serial Number',
                value: _asset.serialNumber),
            FormFieldConfig(key: 'model', label: 'Model', value: _asset.model),
          ],
          extraWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedCategory == manualCategoryKey) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: customCategoryController,
                  decoration: InputDecoration(
                    labelText: 'Enter Category',
                    hintText: 'e.g. Sensor, Battery, Motor',
                    border: const OutlineInputBorder(),
                    errorText: categoryError,
                  ),
                ),
              ],
            ],
          ),
          onAddFieldChanged: (key, value) {
            if (key == 'category') {
              setDialogState(() {
                selectedCategory = value;
                categoryError = null;
              });
            }
          },
          onSubmit: (data) async {
            if (selectedCategory == manualCategoryKey &&
                customCategoryController.text.trim().isEmpty) {
              setDialogState(() =>
                  categoryError = 'Enter a category name for this asset');
              return false;
            }
            final category = selectedCategory == manualCategoryKey
                ? customCategoryController.text.trim()
                : selectedCategory!;

            final payload = <String, dynamic>{
              'asset_id': data['asset_id'],
              'name': data['name'],
              'category': category,
              if ((data['serial_number'] ?? '').toString().isNotEmpty)
                'serial_number': data['serial_number'],
              if ((data['model'] ?? '').toString().isNotEmpty)
                'model': data['model'],
            };
            final ok = await context
                .read<AssetProvider>()
                .updateAsset(_asset.id, payload);
            if (ok) _refreshAsset();
            return ok;
          },
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (_asset.photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove photo',
                    style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    if (choice == 'remove') {
      await PhotoService.instance.deletePhoto(_asset.photoPath);
      if (!mounted) return;
      await context.read<AssetProvider>().updateAssetPhoto(_asset.id, null);
      _showMsg('Photo removed');
      await _refreshAsset();
      return;
    }

    final picked = await ImagePicker().pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 82,
    );
    if (picked == null || !mounted) return;

    final newPath = await PhotoService.instance
        .savePhoto(picked.path, assetId: _asset.id);
    if (newPath == null) {
      _showMsg('Failed to save photo', isError: true);
      return;
    }
    if (!mounted) return;
    final ok = await context
        .read<AssetProvider>()
        .updateAssetPhoto(_asset.id, newPath);
    if (mounted) {
      _showMsg(ok ? 'Photo saved' : 'Failed to save photo', isError: !ok);
    }
    await _refreshAsset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_asset.assetId),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: _showEditDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_successMsg != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_successMsg!,
                  style: TextStyle(color: Colors.green.shade700)),
            ),
          if (_errorMsg != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_errorMsg!,
                  style: TextStyle(color: Colors.red.shade700)),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_asset.photoPath != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_asset.photoPath!),
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(
                              height: 180,
                              child: Center(child: Text('Photo unavailable')),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton.filled(
                            tooltip: 'Change photo',
                            icon: const Icon(Icons.photo_camera, size: 20),
                            onPressed: () => _pickPhoto(),
                          ),
                        ),
                      ],
                    )
                  else
                    InkWell(
                      onTap: _pickPhoto,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 90,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo,
                                color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Text('Add photo',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        radius: 24,
                        child: Text(
                          _asset.category.isNotEmpty
                              ? _asset.category[0]
                              : '?',
                          style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_asset.assetId,
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                            Text(_asset.name,
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 14)),
                          ],
                        ),
                      ),
                      StatusChip(status: _asset.status),
                    ],
                  ),
                  const Divider(height: 24),
                  _detailRow('Category', _asset.category),
                  _detailRow('Model', _asset.model ?? 'N/A'),
                  _detailRow('Serial', _asset.serialNumber ?? 'N/A'),
                  _detailRow('Condition', _asset.conditionType),
                  _detailRow('Owner', _asset.currentUser?.name ?? 'None'),
                  _detailRow(
                      'Location', _asset.currentLocation?.name ?? 'None'),
                  _detailRow('Drone', _asset.currentDrone?.name ?? 'None'),
                  _detailRow('Project', _asset.project?.name ?? 'None'),
                  if (_asset.remarks != null && _asset.remarks!.isNotEmpty)
                    _detailRow('Remarks', _asset.remarks!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrinterSelectScreen(asset: _asset),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bluetooth, size: 18),
                  label: const Text('BT Print'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (!mounted) return;
                    final imageBytes = await QrService.fetchQrImage(_asset.assetId);
                    if (imageBytes == null) return;
                    if (!context.mounted) return;
                    showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.memory(imageBytes, width: 300),
                                  const SizedBox(height: 8),
                                  Text(_asset.assetId,
                                      style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18)),
                                  Text(_asset.name,
                                      style: TextStyle(color: Colors.grey[600])),
                                  if (_asset.currentUser != null)
                                    Text('With: ${_asset.currentUser!.name}',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[500])),
                                ],
                              ),
                            ),
                          ),
                        );
                  },
                  icon: const Icon(Icons.bar_chart, size: 18),
                  label: const Text('View'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_asset.status != 'missing' && _asset.status != 'damaged') ...[
            const Text('Actions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_asset.status == 'available')
                  _actionButton('Assign', Icons.person_add, Colors.blue,
                      () => _showAssignDialog()),
                if (_asset.status == 'assigned') ...[
                  _actionButton('Transfer', Icons.swap_horiz, Colors.orange,
                      () => _showTransferDialog()),
                  _actionButton('Return', Icons.undo, Colors.green,
                      () => _returnAsset()),
                  _actionButton('Install in Drone', Icons.flight, Colors.purple,
                      () => _showAssignDroneDialog()),
                ],
                if (_asset.status == 'in_drone') ...[
                  _actionButton('Remove from Drone', Icons.flight_takeoff,
                      Colors.deepOrange, () => _removeDrone()),
                  _actionButton('Return', Icons.undo, Colors.green,
                      () => _returnAsset()),
                ],
                _actionButton('Report Missing', Icons.warning, Colors.red,
                    () => _reportMissing()),
                _actionButton('Report Damaged', Icons.broken_image,
                    Colors.pink, () => _reportDamaged()),
              ],
            ),
          ],
          const SizedBox(height: 16),
          _buildHistory(),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Movement History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_historyLoading)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_history.isEmpty)
              const Text('No recorded movements yet.',
                  style: TextStyle(color: Colors.grey))
            else
              ..._history.map(_historyTile),
          ],
        ),
      ),
    );
  }

  Widget _historyTile(AssetMovement m) {
    final desc = _describeMovement(m);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      isThreeLine: desc.length > 1,
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        child: Icon(_actionIcon(m.action), size: 16, color: Colors.blue),
      ),
      title: Text(
        _actionTitle(m.action, m.toStatus ?? ''),
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(desc.join('\n'),
          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      trailing: Text(_formatDate(m.createdAt),
          style: TextStyle(fontSize: 11, color: Colors.grey[500])),
    );
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'assigned':
        return Icons.person_add;
      case 'transferred':
        return Icons.swap_horiz;
      case 'returned':
        return Icons.undo;
      case 'installed_drone':
        return Icons.flight;
      case 'removed_drone':
        return Icons.flight_takeoff;
      case 'reported_missing':
        return Icons.warning;
      case 'reported_damaged':
        return Icons.broken_image;
      case 'created':
        return Icons.add_box;
      default:
        return Icons.timeline;
    }
  }

  String _actionTitle(String action, String toStatus) {
    switch (action) {
      case 'assigned':
        return 'Assigned';
      case 'transferred':
        return 'Transferred';
      case 'returned':
        return 'Returned';
      case 'installed_drone':
        return 'Installed in drone';
      case 'removed_drone':
        return 'Removed from drone';
      case 'reported_missing':
        return 'Reported missing';
      case 'reported_damaged':
        return 'Reported damaged';
      case 'created':
        return 'Asset created';
      default:
        return action;
    }
  }

  List<String> _describeMovement(AssetMovement m) {
    final parts = <String>[];
    final from = m.fromUserName ?? m.fromDroneName ?? m.fromLocationName;
    final to = m.toUserName ?? m.toDroneName ?? m.toLocationName;
    if (from != null && to != null) {
      parts.add('$from → $to');
    } else if (to != null) {
      parts.add('To: $to');
    }
    if (m.purpose != null && m.purpose!.isNotEmpty) parts.add(m.purpose!);
    if (m.remarks != null && m.remarks!.isNotEmpty) parts.add(m.remarks!);
    if (parts.isEmpty) parts.add('-');
    return parts;
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAssignDialog() {
    final employees = context.read<EmployeeProvider>().employees;
    final drones = context.read<DroneProvider>().drones;
    final projects = context.read<ProjectProvider>().projects;
    final locationsProvider = context.read<LocationProvider>();

    int? selectedEmployeeId;
    int selectedLocationValue = 0;
    int? selectedDroneId;
    int? selectedProjectId;
    String? manualLocationError;
    final manualLocationController = TextEditingController();
    final purposeController = TextEditingController();

    bool isSelectedDroneLocation(List<Location> locations) {
      if (selectedLocationValue == _manualLocationId) return false;
      if (selectedLocationValue == 0) return false;
      for (final l in locations) {
        if (l.id == selectedLocationValue) {
          return l.name.toLowerCase().contains('drone');
        }
      }
      return false;
    }

    Future<void> assign(int? resolvedLocationId) async {
      final data = <String, dynamic>{};
      final droneLocation = isSelectedDroneLocation(locationsProvider.locations);
      if (!droneLocation && selectedEmployeeId != null) {
        data['employee_id'] = selectedEmployeeId;
      }
      if (resolvedLocationId != null) {
        data['location_id'] = resolvedLocationId;
      }
      if (selectedProjectId != null) {
        data['project_id'] = selectedProjectId;
      }
      if (purposeController.text.isNotEmpty) {
        data['purpose'] = purposeController.text;
      }
      final provider = context.read<AssetProvider>();
      var success = await provider.assignAsset(_asset.id, data);
      if (success && selectedDroneId != null) {
        await provider.assignDrone(_asset.id, {'drone_id': selectedDroneId});
      }
      _showMsg(success ? 'Asset assigned' : 'Failed to assign',
          isError: !success);
      if (success) _refreshAsset();
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final droneLocation =
              isSelectedDroneLocation(locationsProvider.locations);
          return AlertDialog(
            title: const Text('Assign Asset'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!droneLocation) ...[
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                          labelText: 'Employee', border: OutlineInputBorder()),
                      items: employees
                          .map((e) => DropdownMenuItem(
                              value: e.id, child: Text(e.name)))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedEmployeeId = v),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text('Location',
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
                              const DropdownMenuItem<int>(
                                  value: 0, child: Text('No Location')),
                              ...locations.map((l) => DropdownMenuItem<int>(
                                  value: l.id, child: Text(l.name))),
                              const DropdownMenuItem<int>(
                                  value: _manualLocationId,
                                  child: Text('Other (Manual)')),
                            ],
                            onChanged: (v) => setDialogState(() {
                              selectedLocationValue = v ?? 0;
                              manualLocationError = null;
                              if (v == _manualLocationId) {
                                selectedDroneId = null;
                              } else if (v != 0) {
                                Location? loc;
                                for (final l in locations) {
                                  if (l.id == v) {
                                    loc = l;
                                    break;
                                  }
                                }
                                final isDrone = loc != null &&
                                    loc.name.toLowerCase().contains('drone');
                                if (isDrone) selectedEmployeeId = null;
                                if (!isDrone) selectedDroneId = null;
                              } else {
                                selectedDroneId = null;
                              }
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
                  if (droneLocation) ...[
                    const SizedBox(height: 12),
                    const Text('Drone',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: drones
                          .where((d) => d.status == 'active')
                          .map((d) {
                        final isSelected = selectedDroneId == d.id;
                        return ChoiceChip(
                          label: Text(d.name),
                          selected: isSelected,
                          selectedColor:
                              Colors.orange.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.orange
                                : Colors.grey[700],
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.orange
                                : Colors.grey[300]!,
                          ),
                          onSelected: (_) =>
                              setDialogState(() => selectedDroneId = d.id),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                        labelText: 'Project', border: OutlineInputBorder()),
                    items: projects
                        .map((p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.name)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedProjectId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: purposeController,
                    decoration: const InputDecoration(
                        labelText: 'Purpose', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: (() async {
                  if (droneLocation) {
                    if (selectedDroneId == null) return;
                  } else {
                    if (selectedEmployeeId == null) return;
                  }
                  int? resolvedLocationId;
                  if (selectedLocationValue == _manualLocationId) {
                    final name = manualLocationController.text.trim();
                    if (name.isEmpty) {
                      setDialogState(
                          () => manualLocationError = 'Enter a location name');
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
                  } else if (selectedLocationValue != 0) {
                    resolvedLocationId = selectedLocationValue;
                  }
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  await assign(resolvedLocationId);
                }),
                child: const Text('Assign'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTransferDialog() {
    final employees = context.read<EmployeeProvider>().employees;
    int? toEmployeeId;
    final purposeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Transfer Asset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                    labelText: 'Transfer to', border: OutlineInputBorder()),
                items: employees
                    .where((e) => e.id != _asset.currentUserId)
                    .map((e) =>
                        DropdownMenuItem(value: e.id, child: Text(e.name)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => toEmployeeId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: purposeController,
                decoration: const InputDecoration(
                    labelText: 'Purpose', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: toEmployeeId == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final success = await context
                          .read<AssetProvider>()
                          .transferAsset(_asset.id, {
                        'to_employee_id': toEmployeeId,
                        if (purposeController.text.isNotEmpty)
                          'purpose': purposeController.text,
                      });
                      _showMsg(
                          success ? 'Asset transferred' : 'Failed',
                          isError: !success);
                      if (success) _refreshAsset();
                    },
              child: const Text('Transfer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignDroneDialog() {
    final drones = context
        .read<DroneProvider>()
        .drones
        .where((d) => d.status == 'active')
        .toList();
    int? selectedDroneId;
    final purposeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Install in Drone'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                    labelText: 'Select Drone', border: OutlineInputBorder()),
                items: drones
                    .map((d) => DropdownMenuItem(
                        value: d.id,
                        child: Text('${d.droneId} - ${d.name}')))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedDroneId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: purposeController,
                decoration: const InputDecoration(
                    labelText: 'Purpose', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedDroneId == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final success = await context
                          .read<AssetProvider>()
                          .assignDrone(_asset.id, {
                        'drone_id': selectedDroneId,
                        if (purposeController.text.isNotEmpty)
                          'purpose': purposeController.text,
                      });
                      _showMsg(
                          success ? 'Installed in drone' : 'Failed',
                          isError: !success);
                      if (success) _refreshAsset();
                    },
              child: const Text('Install'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _returnAsset() async {
    final success = await context.read<AssetProvider>().returnAsset(_asset.id);
    _showMsg(success ? 'Asset returned' : 'Failed', isError: !success);
    if (success) _refreshAsset();
  }

  Future<void> _removeDrone() async {
    final success = await context.read<AssetProvider>().removeDrone(_asset.id);
    _showMsg(success ? 'Removed from drone' : 'Failed', isError: !success);
    if (success) _refreshAsset();
  }

  Future<void> _reportMissing() async {
    final descController = TextEditingController();
    final desc = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Missing'),
        content: TextField(
          controller: descController,
          decoration: const InputDecoration(
            labelText: 'Description',
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
            onPressed: () => Navigator.pop(ctx, descController.text),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Report'),
          ),
        ],
      ),
    );
    if (desc != null) {
      if (!mounted) return;
      final success = await context
          .read<AssetProvider>()
          .reportMissing(_asset.id, description: desc.isNotEmpty ? desc : null);
      _showMsg(
          success ? 'Reported as missing' : 'Failed',
          isError: !success);
      if (success) _refreshAsset();
    }
  }

  Future<void> _reportDamaged() async {
    final descController = TextEditingController();
    final desc = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Damaged'),
        content: TextField(
          controller: descController,
          decoration: const InputDecoration(
            labelText: 'Description',
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
            onPressed: () => Navigator.pop(ctx, descController.text),
            style: FilledButton.styleFrom(backgroundColor: Colors.pink),
            child: const Text('Report'),
          ),
        ],
      ),
    );
    if (desc != null) {
      if (!mounted) return;
      final success = await context
          .read<AssetProvider>()
          .reportDamaged(_asset.id, description: desc.isNotEmpty ? desc : null);
      _showMsg(
          success ? 'Reported as damaged' : 'Failed',
          isError: !success);
      if (success) _refreshAsset();
    }
  }
}
