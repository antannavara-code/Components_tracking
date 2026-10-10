import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/stat_card.dart';
import 'assets_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDashboard();
    });
  }

  void _openStatus(String? status) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssetsScreen(initialStatus: status),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchDashboard(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Admin Dashboard',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (provider.stats != null)
                GridView.count(
                  crossAxisCount: _getCrossAxisCount(context),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    StatCard(
                      label: 'Total Assets',
                      value: provider.stats!.totalAssets,
                      icon: Icons.inventory_2,
                      color: Colors.blue,
                      onTap: () => _openStatus(null),
                    ),
                    StatCard(
                      label: 'Available',
                      value: provider.stats!.available,
                      icon: Icons.check_circle,
                      color: Colors.green,
                      onTap: () => _openStatus('available'),
                    ),
                    StatCard(
                      label: 'Assigned',
                      value: provider.stats!.assigned,
                      icon: Icons.person,
                      color: Colors.orange,
                      onTap: () => _openStatus('assigned'),
                    ),
                    StatCard(
                      label: 'In Drones',
                      value: provider.stats!.inDrone,
                      icon: Icons.flight,
                      color: Colors.purple,
                      onTap: () => _openStatus('in_drone'),
                    ),
                    StatCard(
                      label: 'Testing',
                      value: provider.stats!.testing,
                      icon: Icons.science,
                      color: Colors.indigo,
                      onTap: () => _openStatus('testing'),
                    ),
                    StatCard(
                      label: 'Maintenance',
                      value: provider.stats!.maintenance,
                      icon: Icons.build,
                      color: Colors.deepOrange,
                      onTap: () => _openStatus('maintenance'),
                    ),
                    StatCard(
                      label: 'Missing',
                      value: provider.stats!.missing,
                      icon: Icons.warning,
                      color: Colors.red,
                      onTap: () => _openStatus('missing'),
                    ),
                    StatCard(
                      label: 'Damaged',
                      value: provider.stats!.damaged,
                      icon: Icons.broken_image,
                      color: Colors.pink,
                      onTap: () => _openStatus('damaged'),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              if (provider.stats != null)
                _buildStatusChart(provider.stats!),
              const SizedBox(height: 16),
              _buildRecentMovements(provider),
              const SizedBox(height: 16),
              _buildMissingAssets(provider),
            ],
          ),
        );
      },
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width > 900) return 4;
    if (width > 600) return 3;
    return 2;
  }

  Widget _buildStatusChart(DashboardStats stats) {
    final entries = <(String, int, Color)>[
      ('Available', stats.available, Colors.green),
      ('Assigned', stats.assigned, Colors.orange),
      ('In Drone', stats.inDrone, Colors.purple),
      ('Testing', stats.testing, Colors.indigo),
      ('Maint.', stats.maintenance, Colors.deepOrange),
      ('Missing', stats.missing, Colors.red),
      ('Damaged', stats.damaged, Colors.pink),
    ];

    final hasData = entries.any((e) => e.$2 > 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Assets by Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${stats.totalAssets} total',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 16),
            if (!hasData)
              const SizedBox(
                height: 180,
                child: Center(
                    child: Text('No data to display',
                        style: TextStyle(color: Colors.grey))),
              )
            else
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _maxY(stats).toDouble(),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                            BarTooltipItem(
                          '${entries[groupIndex].$1}\n${rod.toY.round()}',
                          const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true, reservedSize: 30),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= entries.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                entries[i].$1.substring(0, 1),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600]),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles:
                          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                          color: Colors.grey.withValues(alpha: 0.2),
                          strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      for (var i = 0; i < entries.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: entries[i].$2.toDouble(),
                              color: entries[i].$3,
                              width: 18,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _maxY(DashboardStats stats) {
    final vals = [
      stats.available,
      stats.assigned,
      stats.inDrone,
      stats.testing,
      stats.maintenance,
      stats.missing,
      stats.damaged,
    ];
    final maxV = vals.reduce((a, b) => a > b ? a : b).toDouble();
    return maxV <= 0 ? 1 : (maxV + 2);
  }

  Widget _buildRecentMovements(DashboardProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recently Moved Assets',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (provider.recentMovements.isEmpty)
              const Text('No recent movements',
                  style: TextStyle(color: Colors.grey)),
            ...provider.recentMovements.take(8).map((m) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(m.action,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text('Asset #${m.assetId}'),
                  trailing: Text(
                    _formatDate(m.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingAssets(DashboardProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                const Text('Missing Assets',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red)),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.missingAssets.isEmpty)
              const Text('No missing assets',
                  style: TextStyle(color: Colors.green)),
            ...provider.missingAssets.map((a) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    child: const Icon(Icons.warning, size: 16, color: Colors.red),
                  ),
                  title: Text(a.assetId,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontWeight: FontWeight.w500)),
                  subtitle: Text(a.name),
                  trailing: Text(
                    a.currentUser?.name ?? a.currentLocation?.name ?? 'Unknown',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}
