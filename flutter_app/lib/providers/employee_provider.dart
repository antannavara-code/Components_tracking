import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/models.dart';

class EmployeeProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Employee> _employees = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _employeeAssets = [];
  bool _isLoadingAssets = false;

  List<Employee> get employees => _employees;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get employeeAssets => _employeeAssets;
  bool get isLoadingAssets => _isLoadingAssets;

  Future<void> fetchEmployees() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _db.fetchEmployees();
      _employees = data.map((e) => Employee.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching employees: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createEmployee(Map<String, dynamic> form) async {
    try {
      await _db.createEmployee(form);
      await fetchEmployees();
      return true;
    } catch (e) {
      debugPrint('Error creating employee: $e');
      return false;
    }
  }

  Future<bool> deleteEmployee(int id) async {
    try {
      final db = await _db.database;
      await db.update('assets', {'current_user_id': null},
          where: 'current_user_id = ?', whereArgs: [id]);
      await _db.delete('employees', id);
      _employees.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchEmployeeAssets(int employeeId) async {
    _isLoadingAssets = true;
    _employeeAssets = [];
    notifyListeners();
    try {
      final data = await _db.fetchEmployeeAssets(employeeId);
      _employeeAssets = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching employee assets: $e');
    } finally {
      _isLoadingAssets = false;
      notifyListeners();
    }
  }
}
