import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/drone_provider.dart';
import '../widgets/status_chip.dart';
import '../widgets/create_form_dialog.dart';
import 'drone_detail_screen.dart';

class DronesScreen extends StatefulWidget {
  const DronesScreen({super.key});

  @override
  State<DronesScreen> createState() => _DronesScreenState();
}

class _DronesScreenState extends State<DronesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DroneProvider>().fetchDrones();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DroneProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => provider.fetchDrones(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.drones.isEmpty
                        ? 2
                        : provider.drones.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Drones (${provider.drones.length})',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      if (provider.drones.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.flight_outlined,
                                    size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('No drones yet',
                                    style:
                                        TextStyle(color: Colors.grey, fontSize: 16)),
                              ],
                            ),
                          ),
                        );
                      }
                      final drone = provider.drones[index - 1];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DroneDetailScreen(
                                  droneId: drone.id,
                                  droneName: drone.name,
                                  droneCode: drone.droneId,
                                  model: drone.model,
                                  status: drone.status,
                                  description: drone.description,
                                ),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple.withValues(alpha: 0.1),
                            child: const Icon(Icons.flight,
                                color: Colors.purple, size: 20),
                          ),
                          title: Text(drone.name,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Row(
                            children: [
                              Text(drone.droneId,
                                  style: const TextStyle(
                                      fontFamily: 'monospace', fontSize: 13)),
                              const SizedBox(width: 8),
                              StatusChip(status: drone.status),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Drone'),
                                  content: Text('Delete ${drone.name}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: FilledButton.styleFrom(
                                          backgroundColor: Colors.red),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                final ok = await provider.deleteDrone(drone.id);
                                if (!ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Failed to delete drone. Please try again.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateDialog(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CreateFormDialog(
        title: 'Add Drone',
        fields: const [
          FormFieldConfig(
              key: 'drone_id', label: 'Drone ID', hint: 'e.g. DRONE-01', required: true),
          FormFieldConfig(key: 'name', label: 'Name', required: true),
        ],
        onSubmit: (data) => context.read<DroneProvider>().createDrone(data),
      ),
    );
  }
}
