import 'package:flutter_test/flutter_test.dart';
import 'package:qr_asset_tracker/models/models.dart';

void main() {
  test('Asset model fromJson', () {
    final json = {
      'id': 1,
      'asset_id': 'JET-001',
      'category': 'Jetson',
      'name': 'Jetson Nano',
      'serial_number': 'SN123',
      'model': 'Nano',
      'status': 'available',
      'condition_type': 'good',
      'current_user_id': null,
      'current_location_id': null,
      'current_drone_id': null,
      'project_id': null,
      'remarks': null,
      'created_at': '2024-01-01',
      'updated_at': '2024-01-01',
      'current_user': null,
      'current_location': null,
      'current_drone': null,
      'project': null,
    };

    final asset = Asset.fromJson(json);
    expect(asset.id, 1);
    expect(asset.assetId, 'JET-001');
    expect(asset.status, 'available');
  });

  test('DashboardStats fromJson', () {
    final json = {
      'total_assets': 10,
      'available': 5,
      'assigned': 3,
      'in_drone': 1,
      'testing': 0,
      'maintenance': 1,
      'missing': 0,
      'damaged': 0,
    };

    final stats = DashboardStats.fromJson(json);
    expect(stats.totalAssets, 10);
    expect(stats.available, 5);
  });
}
