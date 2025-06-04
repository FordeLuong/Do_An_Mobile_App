import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/building.dart';
import 'package:do_an_cuoi_ki/models/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  final UserModel currentUser;

  const MapScreen({super.key, required this.currentUser});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController(); // Khởi tạo trực tiếp
  List<BuildingModel> _buildings = [];
  bool _isLoading = true;
  String? _selectedBuildingId; // ID của nhà trọ được chọn trong ComboBox

  @override
  void initState() {
    super.initState();
    _fetchBuildings();
  }

  Future<void> _fetchBuildings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('buildings')
          .where('managerId', isEqualTo: widget.currentUser.id)
          .get();

      setState(() {
        _buildings = querySnapshot.docs
            .map((doc) => BuildingModel.fromJson(doc.data()))
            .toList();
        _isLoading = false;
        if (_buildings.isNotEmpty) {
          _selectedBuildingId = _buildings[0].buildingId; // Chọn nhà trọ đầu tiên mặc định
          _fitBounds();
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách nhà trọ: ${e.toString()}')),
      );
    }
  }

  void _fitBounds() {
    if (_buildings.isEmpty) return;

    final bounds = LatLngBounds(
      LatLng(_buildings[0].latitude, _buildings[0].longitude),
      LatLng(_buildings[0].latitude, _buildings[0].longitude),
    );

    for (var building in _buildings.skip(1)) {
      bounds.extend(LatLng(building.latitude, building.longitude));
    }

    _mapController.fitBounds(
      bounds,
      options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
    );
  }

  void _zoomIn() {
    _mapController.move(
      _mapController.center,
      _mapController.zoom + 1,
    );
  }

  void _zoomOut() {
    _mapController.move(
      _mapController.center,
      _mapController.zoom - 1,
    );
  }

  void _onBuildingSelected(String? buildingId) {
    setState(() {
      _selectedBuildingId = buildingId;
      final selectedBuilding = _buildings.firstWhere(
        (building) => building.buildingId == buildingId,
        orElse: () => _buildings[0],
      );
      _mapController.move(
        LatLng(selectedBuilding.latitude, selectedBuilding.longitude),
        15, // Zoom level
      );
    });
  }

  // Hàm rỗng để xử lý nhấp nháy marker
  void blinkMarker(String buildingId) {
    // TODO: Thêm logic để làm marker nhấp nháy
    print('Blink marker for building: $buildingId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ nhà trọ'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButton<String>(
                    hint: const Text('Chọn nhà trọ'),
                    value: _selectedBuildingId,
                    items: _buildings.map((building) {
                      return DropdownMenuItem<String>(
                        value: building.buildingId,
                        child: Text(building.buildingName),
                      );
                    }).toList(),
                    onChanged: _onBuildingSelected,
                    isExpanded: true,
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _buildings.isNotEmpty
                              ? LatLng(_buildings[0].latitude, _buildings[0].longitude)
                              : const LatLng(10.7769, 106.7009),
                          initialZoom: 13,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c'],
                          ),
                          MarkerLayer(
                            markers: _buildings.map((building) {
                              return Marker(
                                point: LatLng(building.latitude, building.longitude),
                                width: 80,
                                height: 100,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        building.buildingName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Column(
                          children: [
                            FloatingActionButton(
                              onPressed: _zoomIn,
                              mini: true,
                              child: const Icon(Icons.add),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton(
                              onPressed: _zoomOut,
                              mini: true,
                              child: const Icon(Icons.remove),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}