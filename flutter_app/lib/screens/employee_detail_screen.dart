import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/employee_provider.dart';
import '../widgets/status_chip.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;
  final String employeeEmail;
  final String? department;
  final String? phone;

  const EmployeeDetailScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
    this.department,
    this.phone,
  });

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().fetchEmployeeAssets(widget.employeeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.employeeName)),
      body: Consumer<EmployeeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingAssets) {
            return const Center(child: CircularProgressIndicator());
          }

          final assets = provider.employeeAssets;

          if (assets.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildEmployeeHeader(),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('No assets assigned',
                          style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                    ],
                  ),
                ),
              ],
            );
          }

          final grouped = _groupByCategory(assets);
          final total = assets.length;

          return RefreshIndicator(
            onRefresh: () => provider.fetchEmployeeAssets(widget.employeeId),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildEmployeeHeader(),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '$total asset${total == 1 ? '' : 's'} assigned',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...grouped.entries.map((entry) {
                  return _buildCategorySection(entry.key, entry.value);
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmployeeHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              child: Text(
                widget.employeeName.isNotEmpty
                    ? widget.employeeName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.employeeName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(widget.employeeEmail,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  if (widget.department != null || widget.phone != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      [widget.department, widget.phone]
                          .where((e) => e != null)
                          .join(' | '),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupByCategory(
      List<Map<String, dynamic>> assets) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final asset in assets) {
      final cat = asset['category'] ?? 'Other';
      grouped.putIfAbsent(cat, () => []).add(asset);
    }
    return grouped;
  }

  Widget _buildCategorySection(
      String category, List<Map<String, dynamic>> assets) {
    final icon = _categoryIcon(category);
    final color = _categoryColor(category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$category (${assets.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ...assets.map((a) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Text(
                      (a['asset_id'] ?? '?').toString().split('-').last,
                      style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    a['asset_id'] ?? '',
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                  subtitle: Text(
                    a['name'] ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  trailing: StatusChip(status: a['status'] ?? ''),
                )),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Jetson':
        return Icons.memory;
      case 'Raspberry Pi':
        return Icons.developer_board;
      case 'SSD':
        return Icons.storage;
      case 'SD Card':
        return Icons.sd_card;
      case 'USB Cable':
        return Icons.cable;
      case 'Adapter':
        return Icons.power;
      case 'Camera':
        return Icons.camera_alt;
      default:
        return Icons.inventory_2;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Jetson':
        return Colors.green;
      case 'Raspberry Pi':
        return Colors.blue;
      case 'SSD':
        return Colors.orange;
      case 'SD Card':
        return Colors.purple;
      case 'USB Cable':
        return Colors.teal;
      case 'Adapter':
        return Colors.brown;
      case 'Camera':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}
