import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'dart:ui';
import '../providers/asset_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/drone_provider.dart';
import '../providers/project_provider.dart';
import '../providers/location_provider.dart';
import '../models/models.dart';
import '../widgets/status_chip.dart';
import '../widgets/create_form_dialog.dart';
import '../widgets/asset_category_options.dart';
import '../services/qr_service.dart';
import '../services/photo_service.dart';
import 'dart:io';
import 'asset_detail_screen.dart';

class AssetsScreen extends StatefulWidget {
  final String? initialStatus;
  const AssetsScreen({super.key, this.initialStatus});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  final _searchController = TextEditingController();
  String _filterStatus = '';
  String? _selectedCategory;
  List<String> _storedCategories = [];
  static const _categories = predefinedCategories;

  bool get _isFilteredScreen => widget.initialStatus != null;
  AssetProvider? _assetProvider;

  @override
  void initState() {
    super.initState();
    _assetProvider = context.read<AssetProvider>();
    if (widget.initialStatus != null) {
      _filterStatus = widget.initialStatus!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _assetProvider!.fetchAssets(
            status: _isFilteredScreen ? _filterStatus : null,
          );
      _loadStoredCategories();
      context.read<EmployeeProvider>().fetchEmployees();
      context.read<DroneProvider>().fetchDrones();
      context.read<ProjectProvider>().fetchProjects();
    });
  }

  Future<void> _loadStoredCategories() async {
    final stored = await _assetProvider!.fetchStoredCategories();
    if (mounted) setState(() => _storedCategories = stored);
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_isFilteredScreen) {
      _assetProvider?.fetchAssets();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFilteredScreen) {
      return _buildStatusListView();
    }
    if (_selectedCategory != null) {
      return _buildCategoryListView();
    }
    return _buildCategoryGridView();
  }

  Widget _buildCategoryGridView() {
    final searching = _searchController.text.trim().isNotEmpty;
    return Consumer<AssetProvider>(
      builder: (context, provider, _) {
        final allAssets = provider.assets;
        final counts = <String, int>{};
        for (final a in allAssets) {
          counts[a.category] = (counts[a.category] ?? 0) + 1;
        }

        final known = _categories.map((c) => c.$1).toSet();
        final extra = <String>{
          ..._storedCategories,
          ...allAssets.map((a) => a.category),
        }
            .where((c) => c.trim().isNotEmpty && !known.contains(c))
            .toList()
          ..sort();
        final tiles = <(String, IconData, Color, String?)>[
          ..._categories,
          ...extra
              .map((c) => (c, Icons.category, customCategoryColor, null)),
        ];

        final query = _searchController.text.trim().toLowerCase();
        final results = searching
            ? allAssets.where((a) {
                final hay = '${a.assetId} ${a.name} ${a.category} ${a.serialNumber ?? ''} ${a.model ?? ''}'
                    .toLowerCase();
                return hay.contains(query);
              }).toList()
            : <Asset>[];

        return Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Asset Categories',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by ID, name, serial, model...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  searching
                      ? '${results.length} result${results.length == 1 ? '' : 's'} for "$query"'
                      : '${allAssets.length} total assets',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : searching
                        ? results.isEmpty
                            ? _emptyState(
                                icon: Icons.search_off,
                                text: 'No assets match your search',
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 80),
                                itemCount: results.length,
                                itemBuilder: (context, index) {
                                  return _buildAssetCard(
                                      results[index], provider);
                                },
                              )
                        : Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: GridView.builder(
                              padding: const EdgeInsets.only(bottom: 80),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.3,
                              ),
                              itemCount: tiles.length,
                              itemBuilder: (context, index) {
                                final (name, icon, color, imagePath) =
                                    tiles[index];
                                final count = counts[name] ?? 0;
                                return _buildCategoryCard(
                                    name, icon, color, count, imagePath);
                              },
                            ),
                          ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddCategoryDialog(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _emptyState({required IconData icon, required String text}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(text,
              style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String name, IconData icon, Color color,
      int count, String? imagePath) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: InkWell(
        onTap: () {
          setState(() => _selectedCategory = name);
          context
              .read<AssetProvider>()
              .fetchAssets(category: name);
        },
        child: imagePath != null
            ? _buildFullBleedBackground(
                name, icon, color, count, imagePath)
            : _buildNoImageCard(name, icon, color, count),
      ),
    );
  }

  Widget _buildFullBleedBackground(String name, IconData icon, Color color,
      int count, String imagePath) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: color.withValues(alpha: 0.35),
            child: Icon(icon, color: Colors.white, size: 40),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.black.withValues(alpha: 0.25)),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count ${count == 1 ? 'asset' : 'assets'}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: count > 0 ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoImageCard(
      String name, IconData icon, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$count ${count == 1 ? 'asset' : 'assets'}',
            style: TextStyle(
              color: count > 0 ? color : Colors.grey[400],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryListView() {
    return Consumer<AssetProvider>(
      builder: (context, provider, _) {
        final categoryData = _categories.firstWhere(
          (c) => c.$1 == _selectedCategory,
          orElse: () => ('Other', Icons.devices_other, Colors.grey, null),
        );

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                  _filterStatus = '';
                  _searchController.clear();
                });
                context.read<AssetProvider>().fetchAssets();
              },
            ),
            title: Row(
              children: [
                Icon(categoryData.$2, size: 22),
                const SizedBox(width: 8),
                Text(_selectedCategory!),
              ],
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search $_selectedCategory...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          isDense: true,
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _applyFilters();
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) {
                          setState(() {});
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(_filterStatus),
                        initialValue: _filterStatus.isEmpty ? null : _filterStatus,
                        hint: const Text('Status',
                            style: TextStyle(fontSize: 13)),
                        isDense: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: '', child: Text('All Status')),
                          DropdownMenuItem(
                              value: 'available', child: Text('Available')),
                          DropdownMenuItem(
                              value: 'assigned', child: Text('Assigned')),
                          DropdownMenuItem(
                              value: 'in_drone', child: Text('In Drone')),
                          DropdownMenuItem(
                              value: 'testing', child: Text('Testing')),
                          DropdownMenuItem(
                              value: 'maintenance',
                              child: Text('Maintenance')),
                          DropdownMenuItem(
                              value: 'missing', child: Text('Missing')),
                          DropdownMenuItem(
                              value: 'damaged', child: Text('Damaged')),
                        ],
                        onChanged: (v) {
                          _filterStatus = v ?? '';
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.assets.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(categoryData.$2,
                                    size: 48, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  'No $_selectedCategory assets found',
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: provider.assets.length,
                            itemBuilder: (context, index) {
                              final asset = provider.assets[index];
                              return _buildAssetCard(asset, provider);
                            },
                          ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () =>
                _showCreateAssetDialog(context, initialCategory: _selectedCategory),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _applyFilters() {
    context.read<AssetProvider>().fetchAssets(
          search:
              _searchController.text.isNotEmpty ? _searchController.text : null,
          status: _filterStatus.isNotEmpty ? _filterStatus : null,
          category: _selectedCategory,
        );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'assigned':
        return 'Assigned';
      case 'in_drone':
        return 'In Drones';
      case 'testing':
        return 'Testing';
      case 'maintenance':
        return 'Maintenance';
      case 'missing':
        return 'Missing';
      case 'damaged':
        return 'Damaged';
      default:
        return 'All Assets';
    }
  }

  Widget _buildStatusListView() {
    return Consumer<AssetProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(_filterStatus.isNotEmpty
                ? '${_statusLabel(_filterStatus)} Assets'
                : 'All Assets'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search assets...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          isDense: true,
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _applyFilters();
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) {
                          setState(() {});
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(_filterStatus),
                        initialValue: _filterStatus.isEmpty ? null : _filterStatus,
                        hint: const Text('Status',
                            style: TextStyle(fontSize: 13)),
                        isDense: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: '', child: Text('All Status')),
                          DropdownMenuItem(
                              value: 'available', child: Text('Available')),
                          DropdownMenuItem(
                              value: 'assigned', child: Text('Assigned')),
                          DropdownMenuItem(
                              value: 'in_drone', child: Text('In Drone')),
                          DropdownMenuItem(
                              value: 'testing', child: Text('Testing')),
                          DropdownMenuItem(
                              value: 'maintenance',
                              child: Text('Maintenance')),
                          DropdownMenuItem(
                              value: 'missing', child: Text('Missing')),
                          DropdownMenuItem(
                              value: 'damaged', child: Text('Damaged')),
                        ],
                        onChanged: (v) {
                          _filterStatus = v ?? '';
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.assets.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.inventory_2_outlined,
                                    size: 48, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  _filterStatus.isNotEmpty
                                      ? 'No ${_statusLabel(_filterStatus).toLowerCase()} assets found'
                                      : 'No assets found',
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: provider.assets.length,
                            itemBuilder: (context, index) {
                              final asset = provider.assets[index];
                              return _buildAssetCard(asset, provider);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildAssetCard(Asset asset, AssetProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssetDetailScreen(asset: asset),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  asset.photoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(asset.photoPath!),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _letterAvatar(asset),
                          ),
                        )
                      : _letterAvatar(asset),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(asset.assetId,
                            style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        Text(asset.name,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  StatusChip(status: asset.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (asset.currentUser != null)
                    _infoChip(Icons.person_outline, asset.currentUser!.name),
                  if (asset.currentDrone != null) ...[
                    const SizedBox(width: 12),
                    _infoChip(Icons.speed, asset.currentDrone!.name),
                  ],
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (action) =>
                        _handleAction(action, asset, provider),
                    itemBuilder: (_) => [
                      if (asset.status == 'available')
                        const PopupMenuItem(
                          value: 'assign',
                          child: Row(children: [
                            Icon(Icons.person_add, size: 18, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Assign'),
                          ]),
                        ),
                      if (asset.status == 'assigned' ||
                          asset.status == 'in_drone')
                        const PopupMenuItem(
                          value: 'return',
                          child: Row(children: [
                            Icon(Icons.undo, size: 18, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Return'),
                          ]),
                        ),
                      if (asset.status != 'missing' &&
                          asset.status != 'damaged') ...[
                        const PopupMenuItem(
                          value: 'missing',
                          child: Row(children: [
                            Icon(Icons.warning, size: 18, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Report Missing'),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'damaged',
                          child: Row(children: [
                            Icon(Icons.broken_image,
                                size: 18, color: Colors.deepOrange),
                            SizedBox(width: 8),
                            Text('Report Damaged'),
                          ]),
                        ),
                      ],
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'qr',
                        child: Row(children: [
                          Icon(Icons.qr_code, size: 18, color: Colors.indigo),
                          SizedBox(width: 8),
                          Text('View QR'),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: 'print',
                        child: Row(children: [
                          Icon(Icons.print, size: 18, color: Colors.teal),
                          SizedBox(width: 8),
                          Text('Print Label'),
                        ]),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _letterAvatar(Asset asset) {
    return CircleAvatar(
      backgroundColor: Colors.blue.withValues(alpha: 0.1),
      radius: 18,
      child: Text(
        asset.category.isNotEmpty ? asset.category[0] : '?',
        style: const TextStyle(
            color: Colors.blue, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _handleAction(String action, Asset asset, AssetProvider provider) async {
    switch (action) {
      case 'assign':
        _showAssignDialog(asset);
        break;
      case 'return':
        final success = await provider.returnAsset(asset.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(success ? 'Asset returned' : 'Failed to return asset'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
        break;
      case 'missing':
        final success = await provider.reportMissing(asset.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'Reported as missing' : 'Failed'),
              backgroundColor: success ? Colors.orange : Colors.red,
            ),
          );
        }
        break;
      case 'damaged':
        final success = await provider.reportDamaged(asset.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'Reported as damaged' : 'Failed'),
              backgroundColor: success ? Colors.deepOrange : Colors.red,
            ),
          );
        }
        break;
      case 'qr':
        _showQrDialog(asset);
        break;
      case 'print':
        await _printLabel(asset);
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Asset'),
            content: Text('Delete ${asset.assetId}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await PhotoService.instance.deletePhoto(asset.photoPath);
          final ok = await provider.deleteAsset(asset.id);
          if (!ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Failed to delete asset. Please try again.'),
              backgroundColor: Colors.red,
            ));
          }
        }
        break;
    }
  }

  void _showAssignDialog(Asset asset) {
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
      final droneLocation =
          isSelectedDroneLocation(locationsProvider.locations);
      if (!droneLocation && selectedEmployeeId != null) {
        data['employee_id'] = selectedEmployeeId;
      }
      if (selectedProjectId != null) {
        data['project_id'] = selectedProjectId;
      }
      if (purposeController.text.isNotEmpty) {
        data['purpose'] = purposeController.text;
      }
      if (resolvedLocationId != null) {
        data['location_id'] = resolvedLocationId;
      }
      final provider = context.read<AssetProvider>();
      var success = await provider.assignAsset(asset.id, data);
      if (success && selectedDroneId != null) {
        await provider.assignDrone(asset.id, {'drone_id': selectedDroneId});
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Asset assigned' : 'Failed to assign'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
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
                        labelText: 'Employee',
                        border: OutlineInputBorder(),
                      ),
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
                      labelText: 'Project',
                      border: OutlineInputBorder(),
                    ),
                    items: projects
                        .map((p) => DropdownMenuItem(
                            value: p.id, child: Text(p.name)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedProjectId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: purposeController,
                    decoration: const InputDecoration(
                      labelText: 'Purpose',
                      border: OutlineInputBorder(),
                    ),
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

  void _showQrDialog(Asset asset) async {
    final qrImage = await _fetchQrImage(asset.assetId);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(asset.assetId,
                style:
                    const TextStyle(fontFamily: 'monospace', color: Colors.grey)),
            const SizedBox(height: 12),
            if (qrImage != null)
              Image.memory(qrImage, width: 200, height: 200)
            else
              const SizedBox(
                width: 200,
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _printLabel(asset);
            },
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _shareQr(asset);
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _fetchQrImage(String assetId) async {
    return QrService.fetchQrImage(assetId);
  }

  Future<void> _printLabel(Asset asset) async {
    final qrImage = await _fetchQrImage(asset.assetId);
    if (qrImage == null || !mounted) return;

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Image(pw.MemoryImage(qrImage), width: 200, height: 200),
              pw.SizedBox(height: 20),
              pw.Text(asset.assetId,
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(asset.name, style: const pw.TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'QR_${asset.assetId}',
    );
  }

  Future<void> _shareQr(Asset asset) async {
    final qrImage = await _fetchQrImage(asset.assetId);
    if (qrImage == null || !mounted) return;

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Image(pw.MemoryImage(qrImage), width: 200, height: 200),
              pw.SizedBox(height: 20),
              pw.Text(asset.assetId,
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(asset.name, style: const pw.TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'QR_${asset.assetId}.pdf',
    );
  }

  /// Sentinel ID for the "Other (Manual)" location dropdown option.
  static const int _manualLocationId = -1;

  void _showCreateAssetDialog(BuildContext context, {String? initialCategory}) {
    int selectedLocationValue = 0;
    String? selectedCategory = initialCategory;
    String? customCategoryError;
    final customCategoryController = TextEditingController();
    String? manualLocationError;
    final manualLocationController = TextEditingController();

    final locationsProvider = context.read<LocationProvider>();

    final predefinedNames = _categories.map((c) => c.$1).toSet();
    final categoryOptions = <String>[
      ..._categories.map((c) => c.$1),
      if (initialCategory != null &&
          !predefinedNames.contains(initialCategory) &&
          initialCategory != manualCategoryKey)
        initialCategory,
      manualCategoryKey,
    ];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => CreateFormDialog(
          title: 'Create New Asset',
          fields: [
            const FormFieldConfig(
                key: 'asset_id',
                label: 'Asset ID',
                hint: 'e.g. JET-001'),
            FormFieldConfig(
              key: 'category',
              label: 'Category',
              type: FormFieldType.dropdown,
              options: categoryOptions,
              value: categoryOptions.contains(selectedCategory)
                  ? selectedCategory
                  : categoryOptions.first,
            ),
            const FormFieldConfig(
                key: 'name', label: 'Name', required: true),
            const FormFieldConfig(key: 'serial_number', label: 'Serial Number'),
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
                    errorText: customCategoryError,
                  ),
                ),
                const SizedBox(height: 12),
              ],
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
                          child: CircularProgressIndicator(strokeWidth: 2)),
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
          onAddFieldChanged: (key, value) {
            if (key == 'category') {
              setDialogState(() {
                selectedCategory = value;
                customCategoryError = null;
              });
            }
          },
          onSubmit: (data) async {
            final assetProvider = context.read<AssetProvider>();
            if (selectedCategory == manualCategoryKey &&
                customCategoryController.text.trim().isEmpty) {
              setDialogState(() => customCategoryError =
                  'Enter a category name for this asset');
              return false;
            }

            final payload = <String, dynamic>{};
            if (selectedCategory == manualCategoryKey) {
              payload['category'] = customCategoryController.text.trim();
            }
            data.forEach((key, value) {
              if (key == 'category' &&
                  selectedCategory == manualCategoryKey) {
                return;
              }
              if (value != null && value.toString().isNotEmpty) {
                payload[key] = value;
              }
            });

            int? locationId;
            if (selectedLocationValue == _manualLocationId) {
              final name = manualLocationController.text.trim();
              if (name.isEmpty) {
                setDialogState(
                    () => manualLocationError = 'Enter a location name');
                return false;
              }
              final existing =
                  locationsProvider.locations.map((l) => l.name.toLowerCase());
              if (existing.contains(name.toLowerCase())) {
                setDialogState(() =>
                    manualLocationError = 'Location "$name" already exists');
                return false;
              }
              locationId =
                  await locationsProvider.createLocation({'name': name});
              if (locationId == null) {
                setDialogState(
                    () => manualLocationError = 'Failed to create location');
                return false;
              }
            } else if (selectedLocationValue != 0) {
              locationId = selectedLocationValue;
            }
            if (locationId != null) {
              payload['current_location_id'] = locationId;
            }

            final assetId = (payload['asset_id'] ?? '').toString().trim();
            if (assetId.isEmpty) {
              final category =
                  (payload['category'] ?? '').toString().trim();
              payload['asset_id'] = _generateAssetId(category, assetProvider);
            }
            return assetProvider.createAsset(payload);
          },
        ),
      ),
    );
  }

  /// Generates a placeholder asset ID when the user leaves the field blank,
  /// e.g. "Card Reader" -> "CAR-001". The user can change it later via Edit.
  String _generateAssetId(String category, AssetProvider assetProvider) {
    final base = category
        .toUpperCase()
        .replaceAll(RegExp('[^A-Z0-9]'), '');
    final prefix = base.length >= 3 ? base.substring(0, 3) : 'AST';
    final count = assetProvider.assets
            .where((a) => a.category == category)
            .length +
        1;
    return '$prefix-${count.toString().padLeft(3, '0')}';
  }

  void _showAddCategoryDialog(BuildContext context) {
    String? nameError;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => CreateFormDialog(
          title: 'Add Category',
          fields: const [
            FormFieldConfig(
              key: 'name',
              label: 'Category Name',
              hint: 'e.g. Card Reader, Sensor, Motor',
              required: true,
            ),
          ],
          extraWidget: (nameError == null)
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(nameError!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
          onSubmit: (data) async {
            final name = (data['name'] ?? '').toString().trim();
            if (name.isEmpty) {
              setDialogState(
                  () => nameError = 'Category name is required');
              return false;
            }
            final existing = <String>{
              ..._categories.map((c) => c.$1),
              ..._storedCategories,
              ...context
                  .read<AssetProvider>()
                  .assets
                  .map((a) => a.category),
            };
            final lower = name.toLowerCase();
            if (existing.any((e) => e.toLowerCase() == lower)) {
              setDialogState(
                  () => nameError = 'Category "$name" already exists');
              return false;
            }
            final provider = context.read<AssetProvider>();
            final ok = await provider.addCategory(name);
            if (ok) {
              await _loadStoredCategories();
              await provider.fetchAssets();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Category "$name" added'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
            return ok;
          },
        ),
      ),
    );
  }
}
