import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/models.dart';

class AssetProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Asset> _assets = [];
  bool _isLoading = false;
  String? _error;

  List<Asset> get assets => _assets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    await fetchAssets();
  }

  Future<void> fetchAssets({
    String? search,
    String? status,
    String? category,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rows = await _db.fetchAssets(
        search: search,
        status: status,
        category: category,
      );
      _assets = rows.map((e) => Asset.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Asset?> fetchAssetById(int id) async {
    try {
      final data = await _db.fetchAssetById(id);
      return data == null ? null : Asset.fromJson(data);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Asset?> fetchByAssetId(String assetId) async {
    try {
      final data = await _db.fetchByAssetId(assetId);
      return data == null ? null : Asset.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateAssetPhoto(int id, String? photoPath) async {
    try {
      await _db.updateAssetPhoto(id, photoPath);
      await fetchAssets();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<String>> fetchCategories() async {
    try {
      return await _db.fetchCategories();
    } catch (e) {
      return [];
    }
  }

  Future<bool> addCategory(String name) async {
    try {
      await _db.createCategory(name);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<String>> fetchStoredCategories() async {
    try {
      return await _db.fetchStoredCategories();
    } catch (e) {
      return [];
    }
  }

  Future<bool> createAsset(Map<String, dynamic> payload) async {
    try {
      await _db.createAsset(payload);
      await fetchAssets();
      return true;
    } catch (e) {
      debugPrint('Error creating asset: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAsset(int id, Map<String, dynamic> payload) async {
    try {
      await _db.updateAsset(id, payload);
      await fetchAssets();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAsset(int id) async {
    try {
      await _db.deleteAssetWithHistory(id);
      _assets.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignAsset(int id, Map<String, dynamic> data) async {
    try {
      final asset = await _db.fetchAssetById(id);
      final oldUserId = asset?['current_user_id'];
      final oldLocationId = asset?['current_location_id'];

      final updates = <String, dynamic>{'status': 'assigned'};
      if (data['employee_id'] != null) updates['current_user_id'] = data['employee_id'];
      if (data['location_id'] != null) updates['current_location_id'] = data['location_id'];
      if (data['project_id'] != null) updates['project_id'] = data['project_id'];

      await _db.updateAsset(id, updates);

      await _db.logMovement(
        id,
        action: 'assigned',
        fromUserId: oldUserId,
        toUserId: data['employee_id'],
        fromLocationId: oldLocationId,
        toLocationId: data['location_id'],
        fromStatus: asset?['status'],
        toStatus: 'assigned',
        purpose: data['purpose'],
        remarks: data['remarks'],
      );

      await fetchAssets();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> transferAsset(int id, Map<String, dynamic> data) async {
    try {
      final asset = await _db.fetchAssetById(id);
      final oldUserId = asset?['current_user_id'];

      final updates = <String, dynamic>{'current_user_id': data['to_employee_id']};
      await _db.updateAsset(id, updates);

      await _db.logMovement(
        id,
        action: 'transferred',
        fromUserId: oldUserId,
        toUserId: data['to_employee_id'],
        fromStatus: 'assigned',
        toStatus: 'assigned',
        purpose: data['purpose'],
        remarks: data['remarks'],
      );

      await fetchAssets();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> returnAsset(int id, {Map<String, dynamic>? data}) async {
    try {
      final asset = await _db.fetchAssetById(id);
      final oldUserId = asset?['current_user_id'];
      final oldLocationId = asset?['current_location_id'];

      final updates = <String, dynamic>{
        'status': 'available',
        'current_user_id': null,
      };
      if (data?['location_id'] != null) {
        updates['current_location_id'] = data!['location_id'];
      }

      await _db.updateAsset(id, updates);

      await _db.logMovement(
        id,
        action: 'returned',
        fromUserId: oldUserId,
        fromLocationId: oldLocationId,
        toLocationId: data?['location_id'],
        fromStatus: asset?['status'],
        toStatus: 'available',
        remarks: data?['remarks'],
      );

      await fetchAssets();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignDrone(int id, Map<String, dynamic> data) async {
    try {
      final asset = await _db.fetchAssetById(id);
      final oldDroneId = asset?['current_drone_id'];

      final updates = <String, dynamic>{
        'status': 'in_drone',
        'current_drone_id': data['drone_id'],
      };
      await _db.updateAsset(id, updates);

      await _db.logMovement(
        id,
        action: 'installed_drone',
        fromDroneId: oldDroneId,
        toDroneId: data['drone_id'],
        fromStatus: asset?['status'],
        toStatus: 'in_drone',
        purpose: data['purpose'],
        remarks: data['remarks'],
      );

      await fetchAssets();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeDrone(int id) async {
    try {
      final asset = await _db.fetchAssetById(id);
      final oldDroneId = asset?['current_drone_id'];

      final updates = <String, dynamic>{
        'status': 'available',
        'current_drone_id': null,
      };
      await _db.updateAsset(id, updates);

      await _db.logMovement(
        id,
        action: 'removed_drone',
        fromDroneId: oldDroneId,
        fromStatus: 'in_drone',
        toStatus: 'available',
      );

      await fetchAssets();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> reportMissing(int id, {String? description}) async {
    try {
      final asset = await _db.fetchAssetById(id);

      final updates = <String, dynamic>{'status': 'missing'};
      if (description != null && description.isNotEmpty) {
        updates['remarks'] = description;
      }
      await _db.updateAsset(id, updates);

      await _db.logMovement(
        id,
        action: 'reported_missing',
        fromStatus: asset?['status'],
        toStatus: 'missing',
      );

      await fetchAssets();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> reportDamaged(int id, {String? description}) async {
    try {
      final asset = await _db.fetchAssetById(id);

      final updates = <String, dynamic>{
        'status': 'damaged',
        'condition_type': 'poor',
      };
      if (description != null && description.isNotEmpty) {
        updates['remarks'] = description;
      }
      await _db.updateAsset(id, updates);

      await _db.logMovement(
        id,
        action: 'reported_damaged',
        fromStatus: asset?['status'],
        toStatus: 'damaged',
      );

      await fetchAssets();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<AssetMovement>> fetchHistory(int id) async {
    try {
      final rows = await _db.fetchMovements(id);
      return rows.map((e) => AssetMovement.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }
}
