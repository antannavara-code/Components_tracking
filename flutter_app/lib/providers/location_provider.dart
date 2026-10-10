import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/models.dart';

class LocationProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Location> _locations = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _locationAssets = [];
  bool _isLoadingAssets = false;

  List<Location> get locations => _locations;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get locationAssets => _locationAssets;
  bool get isLoadingAssets => _isLoadingAssets;

  Future<void> fetchLocations() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _db.fetchLocations();
      _locations = data.map((e) => Location.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching locations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a location. Returns the new location ID, or null on error.
  Future<int?> createLocation(Map<String, dynamic> form) async {
    try {
      final id = await _db.createLocation(form);
      await fetchLocations();
      return id;
    } catch (e) {
      debugPrint('Error creating location: $e');
      return null;
    }
  }

  Future<bool> deleteLocation(int id) async {
    try {
      final db = await _db.database;
      await db.update('assets', {'current_location_id': null},
          where: 'current_location_id = ?', whereArgs: [id]);
      await _db.delete('locations', id);
      _locations.removeWhere((l) => l.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchLocationAssets(int locationId) async {
    _isLoadingAssets = true;
    _locationAssets = [];
    notifyListeners();
    try {
      final data = await _db.fetchLocationAssets(locationId);
      _locationAssets = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching location assets: $e');
    } finally {
      _isLoadingAssets = false;
      notifyListeners();
    }
  }
}
