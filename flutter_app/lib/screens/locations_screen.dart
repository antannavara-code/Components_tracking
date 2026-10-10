import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../widgets/create_form_dialog.dart';
import 'location_detail_screen.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().fetchLocations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => provider.fetchLocations(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.locations.isEmpty
                        ? 2
                        : provider.locations.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Locations (${provider.locations.length})',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      if (provider.locations.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('No locations yet',
                                    style:
                                        TextStyle(color: Colors.grey, fontSize: 16)),
                              ],
                            ),
                          ),
                        );
                      }
                      final loc = provider.locations[index - 1];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LocationDetailScreen(
                                  locationId: loc.id,
                                  locationName: loc.name,
                                  building: loc.building,
                                  room: loc.room,
                                  description: loc.description,
                                ),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.withValues(alpha: 0.1),
                            child: const Icon(Icons.location_on,
                                color: Colors.green, size: 20),
                          ),
                          title: Text(loc.name,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            [loc.building, loc.room].where((e) => e != null).join(', ') +
                                (loc.description != null ? ' - ${loc.description}' : ''),
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Location'),
                                  content: Text('Delete ${loc.name}?'),
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
                                final ok = await provider.deleteLocation(loc.id);
                                if (!ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Failed to delete location. Please try again.'),
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
        title: 'Add Location',
        fields: const [
          FormFieldConfig(key: 'name', label: 'Name', hint: 'e.g. Office, Lab', required: true),
        ],
        onSubmit: (data) async {
          final id = await context.read<LocationProvider>().createLocation(data);
          return id != null;
        },
      ),
    );
  }
}
