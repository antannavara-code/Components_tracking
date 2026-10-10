import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/models.dart';

class DroneProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Drone> _drones = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _droneAssets = [];
  bool _isLoadingAssets = false;

  List<Drone> get drones => _drones;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get droneAssets => _droneAssets;
  bool get isLoadingAssets => _isLoadingAssets;

  Future<void> fetchDrones() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _db.fetchDrones();
      _drones = data.map((e) => Drone.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching drones: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createDrone(Map<String, dynamic> form) async {
    try {
      await _db.createDrone(form);
      await fetchDrones();
      return true;
    } catch (e) {
      debugPrint('Error creating drone: $e');
      return false;
    }
  }

  Future<bool> deleteDrone(int id) async {
    try {
      final db = await _db.database;
      await db.update('assets', {'current_drone_id': null},
          where: 'current_drone_id = ?', whereArgs: [id]);
      await _db.delete('drones', id);
      _drones.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchDroneAssets(int droneId) async {
    _isLoadingAssets = true;
    _droneAssets = [];
    notifyListeners();
    try {
      final data = await _db.fetchDroneAssets(droneId);
      _droneAssets = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching drone assets: $e');
    } finally {
      _isLoadingAssets = false;
      notifyListeners();
    }
  }
}
