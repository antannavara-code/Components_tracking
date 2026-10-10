import 'package:flutter/material.dart';

/// The fixed, always-visible asset categories shown on the assets grid.
///
/// Records are: (name, icon, accent color, optional background image).
const List<(String, IconData, Color, String?)> predefinedCategories = [
  ('Jetson', Icons.developer_board, Color(0xFF1565C0),
      'assets/images/categories/jetson.png'),
  ('SSD', Icons.storage, Color(0xFF2E7D32),
      'assets/images/categories/ssd.png'),
  ('Raspberry Pi', Icons.memory, Color(0xFFD84315),
      'assets/images/categories/raspberry_pi.png'),
  ('SD Card', Icons.sd_card, Color(0xFF6A1B9A), null),
  ('USB Cable', Icons.cable, Color(0xFF00838F), null),
  ('Adapter', Icons.power, Color(0xFFEF6C00), null),
  ('Camera', Icons.camera_alt, Color(0xFFAD1457),
      'assets/images/categories/camera.png'),
  ('Other', Icons.devices_other, Color(0xFF546E7A), null),
];

const String manualCategoryKey = 'Other (Manual)';

const Color customCategoryColor = Color(0xFF546E7A);