import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/models.dart';

class ProjectProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Project> _projects = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _projectAssets = [];
  bool _isLoadingAssets = false;

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get projectAssets => _projectAssets;
  bool get isLoadingAssets => _isLoadingAssets;

  Future<void> fetchProjects() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _db.fetchProjects();
      _projects = data.map((e) => Project.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching projects: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createProject(Map<String, dynamic> form) async {
    try {
      await _db.createProject(form);
      await fetchProjects();
      return true;
    } catch (e) {
      debugPrint('Error creating project: $e');
      return false;
    }
  }

  Future<bool> deleteProject(int id) async {
    try {
      final db = await _db.database;
      await db.update('assets', {'project_id': null},
          where: 'project_id = ?', whereArgs: [id]);
      await _db.delete('projects', id);
      _projects.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchProjectAssets(int projectId) async {
    _isLoadingAssets = true;
    _projectAssets = [];
    notifyListeners();
    try {
      final data = await _db.fetchProjectAssets(projectId);
      _projectAssets = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching project assets: $e');
    } finally {
      _isLoadingAssets = false;
      notifyListeners();
    }
  }
}
