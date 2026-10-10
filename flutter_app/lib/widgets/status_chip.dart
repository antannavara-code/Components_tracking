import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  static const Map<String, Color> _colors = {
    'available': Colors.green,
    'assigned': Colors.orange,
    'in_drone': Colors.purple,
    'testing': Colors.indigo,
    'maintenance': Colors.deepOrange,
    'missing': Colors.red,
    'damaged': Colors.pink,
    'active': Colors.green,
    'grounded': Colors.red,
    'completed': Colors.blue,
    'on_hold': Colors.amber,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
