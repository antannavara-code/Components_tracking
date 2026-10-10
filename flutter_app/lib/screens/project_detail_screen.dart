import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../widgets/status_chip.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;
  final String projectName;
  final String? description;
  final String status;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    this.description,
    required this.status,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().fetchProjectAssets(widget.projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.projectName)),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingAssets) {
            return const Center(child: CircularProgressIndicator());
          }

          final assets = provider.projectAssets;

          return RefreshIndicator(
            onRefresh: () => provider.fetchProjectAssets(widget.projectId),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.amber.withValues(alpha: 0.1),
                              child: const Icon(Icons.folder, color: Colors.amber, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.projectName,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            StatusChip(status: widget.status),
                          ],
                        ),
                        if (widget.description != null) ...[
                          const SizedBox(height: 8),
                          Text(widget.description!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildAssetCount(assets),
                const SizedBox(height: 12),
                if (assets.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('No assets in this project', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      ],
                    ),
                  )
                else
                  ..._groupByCategory(assets).entries.map((entry) =>
                      _buildCategorySection(entry.key, entry.value)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAssetCount(List<Map<String, dynamic>> assets) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2, color: Colors.amber.shade700, size: 20),
          const SizedBox(width: 8),
          Text(
            '${assets.length} asset${assets.length == 1 ? '' : 's'} in project',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.amber.shade700),
          ),
        ],
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupByCategory(List<Map<String, dynamic>> assets) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final asset in assets) {
      final cat = asset['category'] ?? 'Other';
      grouped.putIfAbsent(cat, () => []).add(asset);
    }
    return grouped;
  }

  Widget _buildCategorySection(String category, List<Map<String, dynamic>> assets) {
    final color = Colors.amber.shade700;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: color, size: 20),
                const SizedBox(width: 8),
                Text('$category (${assets.length})',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
              ],
            ),
            const Divider(height: 16),
            ...assets.map((a) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Text((a['asset_id'] ?? '?').toString().split('-').last,
                        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(a['asset_id'] ?? '',
                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(a['name'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  trailing: StatusChip(status: a['status'] ?? ''),
                )),
          ],
        ),
      ),
    );
  }
}
