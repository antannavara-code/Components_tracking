import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/employee_provider.dart';
import '../widgets/create_form_dialog.dart';
import 'employee_detail_screen.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().fetchEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmployeeProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => provider.fetchEmployees(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.employees.isEmpty
                        ? 2
                        : provider.employees.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Employees (${provider.employees.length})',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }
                      if (provider.employees.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.people_outline,
                                    size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('No employees yet',
                                    style:
                                        TextStyle(color: Colors.grey, fontSize: 16)),
                              ],
                            ),
                          ),
                        );
                      }
                      final emp = provider.employees[index - 1];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EmployeeDetailScreen(
                                  employeeId: emp.id,
                                  employeeName: emp.name,
                                  employeeEmail: emp.email,
                                  department: emp.department,
                                  phone: emp.phone,
                                ),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                            child: Text(
                              emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(emp.name,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(emp.email, style: const TextStyle(fontSize: 13)),
                              if (emp.department != null || emp.phone != null)
                                Text(
                                  [emp.department, emp.phone].where((e) => e != null).join(' | '),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Employee'),
                                  content: Text('Delete ${emp.name}?'),
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
                                final ok = await provider.deleteEmployee(emp.id);
                                if (!ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Failed to delete employee. Please try again.'),
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
        title: 'Add Employee',
        fields: const [
          FormFieldConfig(key: 'name', label: 'Name', required: true),
          FormFieldConfig(key: 'email', label: 'Email', required: true),
          FormFieldConfig(key: 'department', label: 'Department'),
          FormFieldConfig(key: 'phone', label: 'Phone'),
        ],
        onSubmit: (data) => context.read<EmployeeProvider>().createEmployee(data),
      ),
    );
  }
}
