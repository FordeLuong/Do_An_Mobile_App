import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/user.dart';
import 'package:do_an_cuoi_ki/screens/owner/Contract/lap_hop_dong.dart';
import 'package:do_an_cuoi_ki/screens/owner/sua_chua.dart';
import 'package:do_an_cuoi_ki/screens/owner/quanlysuachua_screen.dart';
import 'package:do_an_cuoi_ki/screens/owner/Contract/thanh_ly_hop_dong.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class RoomListScreen extends StatelessWidget {
  final String buildingId;
  final ownerID;
  final UserModel currentUser;
  const RoomListScreen({super.key, required this.buildingId, required this.ownerID, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh sách phòng"),
        backgroundColor: Colors.green.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .where('buildingId', isEqualTo: buildingId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Không có phòng nào."));
          }

          final rooms = snapshot.data!.docs;

          return ListView.builder(

            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final data = rooms[index].data() as Map<String, dynamic>;

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: data['imageUrls']?[0] ?? '',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 180,
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                    Text(
                                      data['title'] ?? 'Phòng không tên',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    // Sử dụng StreamBuilder để hiển thị số lượng yêu cầu chờ xử lý
                                    StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('requests')
                                          // ĐÃ SẮP XẾP LẠI THỨ TỰ WHERE ĐỂ KHỚP VỚI INDEX (loai_request, room_id, status, thoi_gian)
                                          .where('loai_request', isEqualTo: 'sua_chua')
                                          .where('room_id', isEqualTo: rooms[index].id)
                                          .where('status', isEqualTo: 'pending')
                                          .orderBy('thoi_gian', descending: true)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: Center(
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          );
                                        }
                                        if (snapshot.hasError) {
                                          print("Lỗi StreamBuilder Request Count: ${snapshot.error}");
                                          return const Icon(Icons.error, color: Colors.red);
                                        }

                                        int requestCount = snapshot.data?.docs.length ?? 0;

                                        return GestureDetector(
                                          onTap: () {
                                            final List<QueryDocumentSnapshot> pendingRequests = snapshot.data?.docs ?? [];
                                            if (pendingRequests.isNotEmpty) {
                                              showDialog(
                                                context: context,
                                                builder: (context) => RequestDialog(pendingRequests),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Không có yêu cầu chờ xử lý nào.')),
                                              );
                                            }
                                          },
                                          child: Stack(
                                            alignment: Alignment.topRight,
                                            children: [
                                              Icon(
                                                requestCount > 0 ? Icons.notifications_active : Icons.notifications_none,
                                                color: requestCount > 0 ? Colors.red : Colors.grey,
                                                size: 28,
                                              ),
                                              if (requestCount > 0)
                                                Container(
                                                  padding: const EdgeInsets.all(2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.redAccent,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  constraints: const BoxConstraints(
                                                    minWidth: 18,
                                                    minHeight: 18,
                                                  ),
                                                  child: Text(
                                                    '$requestCount',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                              ],
                            ),

                            const SizedBox(height: 4),
                            Text("Giá: ${data['price']} VNĐ / tháng"),
                            const SizedBox(height: 4),
                            Text("Diện tích: ${data['area']} m²"),
                            const SizedBox(height: 4),
                            Text("Sức chứa: ${data['capacity']} người"),
                            const SizedBox(height: 4),
                            Text("Trạng thái: ${data['status']}"),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [

                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: data['status'] == 'rented' ? Colors.grey : Colors.amber,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  onPressed: data['status'] == 'rented'
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ContractFormPage(
                                                roomId: rooms[index].id,
                                                ownerId: ownerID,
                                              ),
                                            ),
                                          );
                                        },
                                  child: const Text('Lập hợp đồng'),
                                ),
                                ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ThanhLyHopDong(
                                                currentUser: currentUser,
                                                roomId: rooms[index].id,
                                              ),
                                            ),
                                          );
                                      },

                                      child: const Text('Thanh lý'),
                                ),

                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    // Chuyển sang trang chỉnh sửa phòng nếu cần
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    // Xử lý xóa phòng
                                    FirebaseFirestore.instance
                                        .collection('rooms')
                                        .doc(rooms[index].id)
                                        .delete();
                                  },
                                ),

                              ],
                            ),
                            ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => QuanLyPhieuSuaChuaScreen(
                                                roomId: rooms[index].id,
                                              ),
                                            ),
                                          );
                                      },

                                      child: const Text('Sửa Chữa'),
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ĐÃ CHUYỂN ĐỔI RequestDialog THÀNH StatefulWidget
class RequestDialog extends StatefulWidget {
  final List<QueryDocumentSnapshot> initialRequestDocs;

  const RequestDialog(this.initialRequestDocs, {super.key});

  @override
  State<RequestDialog> createState() => _RequestDialogState();
}

class _RequestDialogState extends State<RequestDialog> {
  late ValueNotifier<List<QueryDocumentSnapshot>> _requestsNotifier;

  @override
  void initState() {
    super.initState();
    _requestsNotifier = ValueNotifier(List.from(widget.initialRequestDocs));
  }

  @override
  void dispose() {
    _requestsNotifier.dispose();
    super.dispose();
  }

  Future<void> _deleteRequestById(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .delete();
      debugPrint("Request có ID '$requestId' đã được xóa thành công.");
    } catch (e) {
      debugPrint("Lỗi khi xóa request: $e");
    }
  }

  Future<void> _markRequestAsApproved(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({'status': 'approved'});
      debugPrint("Request có ID '$requestId' đã được đánh dấu là 'approved'.");
    } catch (e) {
      debugPrint("Lỗi khi đánh dấu request là 'approved': $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Danh sách yêu cầu chờ xử lý'),
      content: ValueListenableBuilder<List<QueryDocumentSnapshot>>(
        valueListenable: _requestsNotifier,
        builder: (context, currentRequests, child) {
          return SizedBox(
            width: double.maxFinite,
            child: currentRequests.isEmpty
                ? const Center(child: Text('Không có yêu cầu chờ xử lý nào.'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: currentRequests.length,
                    itemBuilder: (context, index) {
                      final data = currentRequests[index].data() as Map<String, dynamic>;
                      final requestId = currentRequests[index].id;

                      final name = data['Name'] ?? 'Không rõ';
                      final loai = data['loai_request'] ?? 'Không rõ';
                      final moTa = data['mo_ta'] ?? 'Không có mô tả';
                      final dynamic thoiGianRaw = data['thoi_gian'];
                      DateTime? thoiGian;
                      if (thoiGianRaw is Timestamp) {
                        thoiGian = thoiGianRaw.toDate();
                      } else if (thoiGianRaw is String) {
                        try {
                          thoiGian = DateTime.parse(thoiGianRaw);
                        } catch (e) {
                          debugPrint('Lỗi parsing thời gian: $e');
                        }
                      }
                      final sdt = data['sdt'] ?? 'Không có SĐT';
                      final roomId = data['room_id'] ?? 'Không rõ';
                      final tenantId = data['user_khach_id'] ?? 'Không rõ';
                      final isSuaChua = loai == 'sua_chua';

                      return ListTile(
                        title: Text('Yêu cầu: $loai'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tên: $name'),
                            Text('Mô tả: $moTa'),
                            if (thoiGian != null)
                              Text(
                                'Thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(thoiGian)}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            Text('SĐT: $sdt'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSuaChua)
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Xác nhận'),
                                      content: const Text('Bạn có chắc chắn muốn tạo phiếu sửa chữa cho yêu cầu này?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Hủy'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.pop(context, true);
                                            final bool? result = await Navigator.push(
                                              context,
                                              MaterialPageRoute<bool>(
                                                builder: (ctx) => SuaChua(
                                                  roomId: roomId,
                                                  tenantId: tenantId,
                                                  requestId: requestId,
                                                ),
                                              ),
                                            );

                                            if (result == true) {
                                              await _markRequestAsApproved(requestId);
                                              _requestsNotifier.value = currentRequests
                                                  .where((doc) => doc.id != requestId)
                                                  .toList();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Phiếu sửa chữa đã được tạo và yêu cầu đã được xử lý!')),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Tạo phiếu sửa chữa bị hủy hoặc thất bại.')),
                                              );
                                            }
                                          },
                                          child: const Text('Tạo phiếu'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Xác nhận'),
                                    content: const Text('Bạn có chắc muốn xóa yêu cầu này không?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Hủy'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Xóa'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await _deleteRequestById(requestId);
                                  _requestsNotifier.value = currentRequests
                                      .where((doc) => doc.id != requestId)
                                      .toList();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Yêu cầu đã được xóa.')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}