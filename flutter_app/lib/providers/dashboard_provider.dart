import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/models.dart';

class DashboardProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  DashboardStats? _stats;
  List<AssetMovement> _recentMovements = [];
  List<Asset> _missingAssets = [];
  bool _isLoading = false;

  DashboardStats? get stats => _stats;
  List<AssetMovement> get recentMovements => _recentMovements;
  List<Asset> get missingAssets => _missingAssets;
  bool get isLoading => _isLoading;

  Future<void> fetchDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final stats = await _db.fetchDashboardStats();
      _stats = DashboardStats.fromJson(stats);

      final movements = await _db.fetchRecentMovements();
      _recentMovements = movements
          .map((e) => AssetMovement.fromJson(e))
          .toList();

      final missing = await _db.fetchAssets(status: 'missing');
      _missingAssets = missing.map((e) => Asset.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
