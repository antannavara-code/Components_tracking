import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../widgets/status_chip.dart';
import '../widgets/create_form_dialog.dart';
import 'project_detail_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().fetchProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => provider.fetchProjects(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.projects.isEmpty
                        ? 2
                        : provider.projects.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Projects (${provider.projects.length})',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      if (provider.projects.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.folder_outlined,
                                    size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('No projects yet',
                                    style:
                                        TextStyle(color: Colors.grey, fontSize: 16)),
                              ],
                            ),
                          ),
                        );
                      }
                      final project = provider.projects[index - 1];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProjectDetailScreen(
                                  projectId: project.id,
                                  projectName: project.name,
                                  description: project.description,
                                  status: project.status,
                                ),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: Colors.amber.withValues(alpha: 0.1),
                            child: const Icon(Icons.folder,
                                color: Colors.amber, size: 20),
                          ),
                          title: Text(project.name,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Row(
                            children: [
                              if (project.description != null)
                                Expanded(
                                  child: Text(project.description!,
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              const SizedBox(width: 8),
                              StatusChip(status: project.status),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Project'),
                                  content: Text('Delete ${project.name}?'),
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
                                final ok = await provider.deleteProject(
                                    project.id);
                                if (!ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Failed to delete project. Please try again.'),
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
        title: 'Add Project',
        fields: const [
          FormFieldConfig(key: 'name', label: 'Project Name', required: true),
          FormFieldConfig(
            key: 'status',
            label: 'Status',
            type: FormFieldType.dropdown,
            options: ['active', 'completed', 'on_hold'],
          ),
        ],
        onSubmit: (data) => context.read<ProjectProvider>().createProject(data),
      ),
    );
  }
}
