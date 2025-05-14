// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '/models/room.dart';
// import 'room_detail_screen.dart';

// class MapScreen extends StatefulWidget {
//   const MapScreen({Key? key}) : super(key: key);

//   @override
//   State<MapScreen> createState() => _MapScreenState();
// }

// class _MapScreenState extends State<MapScreen> {
//   final Set<Marker> _markers = {};
//   late GoogleMapController _mapController;

//   @override
//   void initState() {
//     super.initState();
//     _loadRoomMarkers();
//   }

//   Future<void> _loadRoomMarkers() async {
//     final snapshot = await FirebaseFirestore.instance
//         .collection('rooms')
//         .where('status', isEqualTo: 'available')
//         .get();

//     final markers = snapshot.docs.map((doc) {
//       final room = RoomModel.fromJson(doc.data());
//       return Marker(
//         markerId: MarkerId(room.id),
//         position: LatLng(room.latitude, room.longitude),
//         infoWindow: InfoWindow(
//           title: room.title,
//           snippet: '${room.price.toStringAsFixed(0)} VNĐ / tháng',
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => RoomDetailScreen(room: room),
//               ),
//             );
//           },
//         ),
//       );
//     }).toSet();

//     setState(() {
//       _markers.addAll(markers);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Phòng trọ gần bạn'),
//       ),
//       body: GoogleMap(
//         initialCameraPosition: const CameraPosition(
//           target: LatLng(10.762622, 106.660172), // Vị trí trung tâm TP.HCM
//           zoom: 14,
//         ),
//         markers: _markers,
//         onMapCreated: (controller) => _mapController = controller,
//         myLocationEnabled: true,
//         myLocationButtonEnabled: true,
//       ),
//     );
//   }
// }
