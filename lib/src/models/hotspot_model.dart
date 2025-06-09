import 'dart:convert';

/// Model class for hotspot data received from JavaScript
class HotspotModel {
  /// Coordinates of the hotspot click
  final double x;
  final double y;
  
  /// Hotspot ID
  final String id;
  
  /// All data-* attributes from the hotspot element
  final Map<String, dynamic> dataset;
  
  /// Position information (if available)
  final String? position;
  
  /// Orbit information (if available)
  final String? orbit;
  
  /// Target information (if available)
  final String? target;
  
  /// Text content of the hotspot (if available)
  final String? textContent;
  
  /// CSS class name of the hotspot element
  final String? className;
  
  /// Slot attribute of the hotspot element
  final String? slot;

  HotspotModel({
    required this.x,
    required this.y,
    required this.id,
    required this.dataset,
    this.position,
    this.orbit,
    this.target,
    this.textContent,
    this.className,
    this.slot,
  });

  /// Parse a hotspot data string in the format "x,y|{hotspotInfoJson}"
  static HotspotModel? fromString(String data) {
    try {
      // Split the data into coordinates and JSON parts
      final parts = data.split('|');
      if (parts.length != 2) {
        return null;
      }

      // Parse coordinates
      final coordinates = parts[0].split(',');
      if (coordinates.length != 2) {
        return null;
      }
      
      final x = double.tryParse(coordinates[0]) ?? 0;
      final y = double.tryParse(coordinates[1]) ?? 0;

      // Parse JSON data
      final jsonData = json.decode(parts[1]) as Map<String, dynamic>;

      return HotspotModel(
        x: x,
        y: y,
        id: jsonData['id'] as String? ?? '',
        dataset: jsonData['dataset'] as Map<String, dynamic>? ?? {},
        position: jsonData['position'] as String?,
        orbit: jsonData['orbit'] as String?,
        target: jsonData['target'] as String?,
        textContent: jsonData['textContent'] as String?,
        className: jsonData['className'] as String?,
        slot: jsonData['slot'] as String?,
      );
    } catch (e) {
      print('Error parsing hotspot data: $e');
      return null;
    }
  }

  @override
  String toString() {
    return 'HotspotModel(id: $id, position: $position, orbit: $orbit, target: $target, textContent: $textContent)';
  }
}
