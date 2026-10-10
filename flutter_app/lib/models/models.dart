class Asset {
  final int id;
  final String assetId;
  final String category;
  final String name;
  final String? serialNumber;
  final String? model;
  final String status;
  final String conditionType;
  final int? currentUserId;
  final int? currentLocationId;
  final int? currentDroneId;
  final int? projectId;
  final String? remarks;
  final String? photoPath;
  final String createdAt;
  final String updatedAt;
  final Employee? currentUser;
  final Location? currentLocation;
  final Drone? currentDrone;
  final Project? project;

  Asset({
    required this.id,
    required this.assetId,
    required this.category,
    required this.name,
    this.serialNumber,
    this.model,
    required this.status,
    required this.conditionType,
    this.currentUserId,
    this.currentLocationId,
    this.currentDroneId,
    this.projectId,
    this.remarks,
    this.photoPath,
    required this.createdAt,
    required this.updatedAt,
    this.currentUser,
    this.currentLocation,
    this.currentDrone,
    this.project,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'],
      assetId: json['asset_id'],
      category: json['category'],
      name: json['name'],
      serialNumber: json['serial_number'],
      model: json['model'],
      status: json['status'],
      conditionType: json['condition_type'],
      currentUserId: json['current_user_id'],
      currentLocationId: json['current_location_id'],
      currentDroneId: json['current_drone_id'],
      projectId: json['project_id'],
      remarks: json['remarks'],
      photoPath: json['photo_path'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      currentUser: json['current_user'] != null
          ? Employee.fromJson(json['current_user'])
          : null,
      currentLocation: json['current_location'] != null
          ? Location.fromJson(json['current_location'])
          : null,
      currentDrone: json['current_drone'] != null
          ? Drone.fromJson(json['current_drone'])
          : null,
      project: json['project'] != null
          ? Project.fromJson(json['project'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_id': assetId,
      'category': category,
      'name': name,
      'serial_number': serialNumber,
      'model': model,
      'status': status,
      'condition_type': conditionType,
      'current_user_id': currentUserId,
      'current_location_id': currentLocationId,
      'current_drone_id': currentDroneId,
      'project_id': projectId,
      'remarks': remarks,
      'photo_path': photoPath,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

Map<String, dynamic> assetFromRow(Map<String, dynamic> row,
    {Employee? currentUser,
    Location? currentLocation,
    Drone? currentDrone,
    Project? project}) {
  row['current_user'] = currentUser == null
      ? null
      : {
          'id': currentUser.id,
          'name': currentUser.name,
          'email': currentUser.email,
          'department': currentUser.department,
          'phone': currentUser.phone,
        };
  row['current_location'] = currentLocation == null
      ? null
      : {
          'id': currentLocation.id,
          'name': currentLocation.name,
          'building': currentLocation.building,
          'room': currentLocation.room,
          'description': currentLocation.description,
        };
  row['current_drone'] = currentDrone == null
      ? null
      : {
          'id': currentDrone.id,
          'drone_id': currentDrone.droneId,
          'name': currentDrone.name,
          'model': currentDrone.model,
          'status': currentDrone.status,
          'description': currentDrone.description,
        };
  row['project'] = project == null
      ? null
      : {
          'id': project.id,
          'name': project.name,
          'description': project.description,
          'status': project.status,
        };
  return row;
}

class Employee {
  final int id;
  final String name;
  final String email;
  final String? department;
  final String? phone;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    this.department,
    this.phone,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      department: json['department'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'department': department,
      'phone': phone,
    };
  }
}

class Drone {
  final int id;
  final String droneId;
  final String name;
  final String? model;
  final String status;
  final String? description;

  Drone({
    required this.id,
    required this.droneId,
    required this.name,
    this.model,
    required this.status,
    this.description,
  });

  factory Drone.fromJson(Map<String, dynamic> json) {
    return Drone(
      id: json['id'],
      droneId: json['drone_id'],
      name: json['name'],
      model: json['model'],
      status: json['status'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'drone_id': droneId,
      'name': name,
      'model': model,
      'status': status,
      'description': description,
    };
  }
}

class Location {
  final int id;
  final String name;
  final String? building;
  final String? room;
  final String? description;

  Location({
    required this.id,
    required this.name,
    this.building,
    this.room,
    this.description,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      name: json['name'],
      building: json['building'],
      room: json['room'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'building': building,
      'room': room,
      'description': description,
    };
  }
}

class Project {
  final int id;
  final String name;
  final String? description;
  final String status;

  Project({
    required this.id,
    required this.name,
    this.description,
    required this.status,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
    };
  }
}

class AssetMovement {
  final int id;
  final int assetId;
  final String action;
  final int? fromUserId;
  final int? toUserId;
  final int? fromLocationId;
  final int? toLocationId;
  final int? fromDroneId;
  final int? toDroneId;
  final String? fromStatus;
  final String? toStatus;
  final String? purpose;
  final String? remarks;
  final int? performedBy;
  final String createdAt;

  // Resolved display names for referenced records.
  final String? fromUserName;
  final String? toUserName;
  final String? fromDroneName;
  final String? toDroneName;
  final String? fromLocationName;
  final String? toLocationName;

  AssetMovement({
    required this.id,
    required this.assetId,
    required this.action,
    this.fromUserId,
    this.toUserId,
    this.fromLocationId,
    this.toLocationId,
    this.fromDroneId,
    this.toDroneId,
    this.fromStatus,
    this.toStatus,
    this.purpose,
    this.remarks,
    this.performedBy,
    required this.createdAt,
    this.fromUserName,
    this.toUserName,
    this.fromDroneName,
    this.toDroneName,
    this.fromLocationName,
    this.toLocationName,
  });

  factory AssetMovement.fromJson(Map<String, dynamic> json) {
    return AssetMovement(
      id: json['id'],
      assetId: json['asset_id'],
      action: json['action'],
      fromUserId: json['from_user_id'],
      toUserId: json['to_user_id'],
      fromLocationId: json['from_location_id'],
      toLocationId: json['to_location_id'],
      fromDroneId: json['from_drone_id'],
      toDroneId: json['to_drone_id'],
      fromStatus: json['from_status'],
      toStatus: json['to_status'],
      purpose: json['purpose'],
      remarks: json['remarks'],
      performedBy: json['performed_by'],
      createdAt: json['created_at'] ?? '',
      fromUserName: json['from_user_name'],
      toUserName: json['to_user_name'],
      fromDroneName: json['from_drone_name'],
      toDroneName: json['to_drone_name'],
      fromLocationName: json['from_location_name'],
      toLocationName: json['to_location_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_id': assetId,
      'action': action,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'from_location_id': fromLocationId,
      'to_location_id': toLocationId,
      'from_drone_id': fromDroneId,
      'to_drone_id': toDroneId,
      'from_status': fromStatus,
      'to_status': toStatus,
      'purpose': purpose,
      'remarks': remarks,
      'performed_by': performedBy,
      'created_at': createdAt,
    };
  }
}

class DashboardStats {
  final int totalAssets;
  final int available;
  final int assigned;
  final int inDrone;
  final int testing;
  final int maintenance;
  final int missing;
  final int damaged;

  DashboardStats({
    required this.totalAssets,
    required this.available,
    required this.assigned,
    required this.inDrone,
    required this.testing,
    required this.maintenance,
    required this.missing,
    required this.damaged,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalAssets: json['total_assets'] ?? 0,
      available: json['available'] ?? 0,
      assigned: json['assigned'] ?? 0,
      inDrone: json['in_drone'] ?? 0,
      testing: json['testing'] ?? 0,
      maintenance: json['maintenance'] ?? 0,
      missing: json['missing'] ?? 0,
      damaged: json['damaged'] ?? 0,
    );
  }
}
