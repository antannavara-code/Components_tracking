import 'package:flutter/material.dart';
import '../models/models.dart';
import 'status_chip.dart';

class AssetTile extends StatelessWidget {
  final Asset asset;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AssetTile({
    super.key,
    required this.asset,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: Text(
            asset.category.isNotEmpty ? asset.category[0] : '?',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          asset.assetId,
          style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(asset.name, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              children: [
                StatusChip(status: asset.status),
                const SizedBox(width: 8),
                if (asset.currentUser != null)
                  Text(
                    asset.currentUser!.name,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: trailing,
      ),
    );
  }
}
