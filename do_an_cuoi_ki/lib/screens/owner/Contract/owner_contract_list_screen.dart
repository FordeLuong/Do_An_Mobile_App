// lib/screens/owner/owner_contract_list_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/contract/contract.dart';
import 'package:do_an_cuoi_ki/models/contract/contract_status.dart';
import 'package:do_an_cuoi_ki/models/user.dart';
import 'package:do_an_cuoi_ki/models/room.dart'; // Import RoomModel và RoomStatus
import 'package:intl/intl.dart';

class OwnerContractListScreen extends StatefulWidget {
  final UserModel currentUser;

  const OwnerContractListScreen({super.key, required this.currentUser});

  @override
  State<OwnerContractListScreen> createState() => _OwnerContractListScreenState();
}

class _OwnerContractListScreenState extends State<OwnerContractListScreen> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> _getTenantName(String userIdFromContract) async {
    if (userIdFromContract.isEmpty) return "Chưa có người thuê";
    try {
      final doc = await _firestore.collection('users').doc(userIdFromContract).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['name'] as String? ?? 'Người thuê không tên';
      } else {
        return "ID: $userIdFromContract (Không tìm thấy)";
      }
    } catch (e) {
      print("Lỗi khi lấy tên người thuê ($userIdFromContract): $e");
    }
    return "ID: $userIdFromContract (Lỗi)";
  }

  Future<String> _getRoomTitle(String roomId) async {
    if (roomId.isEmpty) return "Không rõ phòng";
    try {
      final doc = await _firestore.collection('rooms').doc(roomId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['title'] as String? ?? 'Phòng không tên';
      } else {
        return "ID: $roomId (Không tìm thấy)";
      }
    } catch (e) {
      print("Lỗi khi lấy tên phòng ($roomId): $e");
    }
    return "ID: $roomId (Lỗi)";
  }

  void _viewContractDetails(BuildContext context, ContractModel contract) {
    // ... (Giữ nguyên hàm này)
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Chi tiết Hợp đồng", style: TextStyle(color: _getStatusColor(contract.status))),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildDetailRow("ID Hợp đồng:", contract.id.isNotEmpty ? contract.id : "N/A"),
                FutureBuilder<String>(
                  future: _getRoomTitle(contract.roomId),
                  builder: (context, snapshot) => _buildDetailRow("Phòng:", snapshot.data ?? (snapshot.connectionState == ConnectionState.waiting ? "Đang tải..." : "N/A")),
                ),
                FutureBuilder<String>(
                  future: _getTenantName(contract.tenantId),
                  builder: (context, snapshot) => _buildDetailRow("Người Thuê:", snapshot.data ?? (snapshot.connectionState == ConnectionState.waiting ? "Đang tải..." : "N/A")),
                ),
                _buildDetailRow("Ngày Bắt Đầu:", _dateFormat.format(contract.startDate)),
                _buildDetailRow("Ngày Kết Thúc:", _dateFormat.format(contract.endDate)),
                _buildDetailRow("Tiền Thuê:", "${NumberFormat("#,##0", "vi_VN").format(contract.rentAmount)} VNĐ"),
                _buildDetailRow("Tiền Cọc:", "${NumberFormat("#,##0", "vi_VN").format(contract.depositAmount)} VNĐ"),
                _buildDetailRow("Trạng Thái:", contract.status.getDisplayName()),
                _buildDetailRow("Ngày Tạo:", _dateFormat.format(contract.createdAt)),
                if (contract.updatedAt != null)
                  _buildDetailRow("Cập Nhật Lần Cuối:", _dateFormat.format(contract.updatedAt!)),
                if (contract.termsAndConditions != null && contract.termsAndConditions!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text("Điều Khoản:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(contract.termsAndConditions!),
                ],
                 if (contract.paymentHistoryIds != null && contract.paymentHistoryIds!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text("IDs Lịch sử TT:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(contract.paymentHistoryIds!.join(', ')),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Đóng'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    // ... (Giữ nguyên hàm này)
     return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          Expanded(child: Text(value, style: TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  // Hàm mới để hiển thị dialog thay đổi trạng thái
  void _showChangeStatusDialog(BuildContext context, ContractModel contract) {
    ContractStatus? selectedStatus = contract.status; // Trạng thái được chọn ban đầu là trạng thái hiện tại
    List<ContractStatus> availableOptions = [];

    // Xác định các tùy chọn trạng thái dựa trên trạng thái hiện tại
    if (contract.status == ContractStatus.pending) {
      // Nếu đang chờ duyệt, có thể chuyển sang active, expired, terminated, cancelled
      availableOptions = [
        ContractStatus.active,
        ContractStatus.expired,
        ContractStatus.terminated,
        ContractStatus.cancelled,
      ];
    } else if (contract.status == ContractStatus.active) {
      // Nếu đang hiệu lực, có thể chuyển sang expired, terminated, cancelled
      availableOptions = [
        ContractStatus.expired,
        ContractStatus.terminated,
        ContractStatus.cancelled,
      ];
    } else {
      // Đối với các trạng thái khác (expired, terminated, cancelled), không cho phép thay đổi nữa (hoặc tùy logic của bạn)
      // Ví dụ: có thể cho phép chuyển từ expired -> terminated nếu cần
      // Hiện tại, nếu không phải pending hoặc active, sẽ không có tùy chọn nào
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể thay đổi trạng thái từ "${contract.status.getDisplayName()}".')),
      );
      return;
    }

    if (availableOptions.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không có tùy chọn thay đổi trạng thái cho hợp đồng này.')),
      );
      return;
    }
    // Mặc định chọn option đầu tiên nếu trạng thái hiện tại không nằm trong list (ít khi xảy ra)
    if (!availableOptions.contains(selectedStatus)){
        selectedStatus = availableOptions.first;
    }


    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder( // Sử dụng StatefulBuilder để cập nhật UI trong dialog
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Thay đổi trạng thái hợp đồng'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: availableOptions.map((statusOption) {
                    return RadioListTile<ContractStatus>(
                      title: Text(statusOption.getDisplayName()),
                      value: statusOption,
                      groupValue: selectedStatus,
                      onChanged: (ContractStatus? value) {
                        if (value != null) {
                          setDialogState(() { // Cập nhật UI của dialog
                            selectedStatus = value;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Hủy'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Lưu thay đổi'),
                  onPressed: () async {
                    if (selectedStatus != null && selectedStatus != contract.status) {
                      await _updateContractStatus(context, contract, selectedStatus!);
                    }
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  // Hàm mới để cập nhật trạng thái hợp đồng và phòng (nếu cần)
  Future<void> _updateContractStatus(BuildContext scaffoldContext, ContractModel contract, ContractStatus newStatus) async {
    try {
      // Cập nhật trạng thái hợp đồng
      await _firestore.collection('contracts').doc(contract.id).update({
        'status': newStatus.toJson(),
        'updatedAt': Timestamp.now(), // Cập nhật thời gian
      });

      // Xử lý cập nhật trạng thái phòng dựa trên trạng thái hợp đồng mới
      RoomStatus? newRoomStatus;
      String? newCurrentTenantId = contract.tenantId; // Mặc định vẫn là người thuê hiện tại

      if (newStatus == ContractStatus.active) {
        newRoomStatus = RoomStatus.rented;
      } else if (newStatus == ContractStatus.pending) {
         // Chuyển từ active/khác về pending (ít xảy ra nhưng để phòng)
        newRoomStatus = RoomStatus.pending_payment;
      }
      else if (newStatus == ContractStatus.cancelled || newStatus == ContractStatus.terminated || newStatus == ContractStatus.expired) {
        // Nếu hợp đồng bị hủy, thanh lý, hoặc hết hạn, phòng trở nên trống
        newRoomStatus = RoomStatus.available;
        newCurrentTenantId = null; // Xóa người thuê hiện tại khỏi phòng
      }

      if (newRoomStatus != null) {
        await _firestore.collection('rooms').doc(contract.roomId).update({
          'status': newRoomStatus.toJson(),
          'currentTenantId': newCurrentTenantId, // Cập nhật hoặc xóa người thuê
          'updatedAt': Timestamp.now(),
        });
      }

      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(content: Text('Đã cập nhật trạng thái hợp đồng thành "${newStatus.getDisplayName()}".')),
      );
    } catch (e) {
      print("Lỗi khi cập nhật trạng thái hợp đồng: $e");
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(content: Text('Lỗi: Không thể cập nhật trạng thái. $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh sách hợp đồng"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('contracts')
            .where('ownerId', isEqualTo: widget.currentUser.id)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}\nKiểm tra chỉ mục Firestore."));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_off_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Chưa có hợp đồng nào.", style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final contractDocs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(12.0),
            itemCount: contractDocs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final contractDoc = contractDocs[index];
              ContractModel contract;
              try {
                Map<String, dynamic> data = contractDoc.data() as Map<String, dynamic>;
                if (!data.containsKey('id') || (data['id'] as String? ?? '').isEmpty) {
                   data['id'] = contractDoc.id;
                }
                contract = ContractModel.fromJson(data);
              } catch (e,s) {
                print("Lỗi parse ContractModel (ID: ${contractDoc.id}): $e. \nData: ${contractDoc.data()} \nStack: $s");
                return Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text( "Lỗi hiển thị hợp đồng ID: ${contractDoc.id}.\nLỗi: $e", style: TextStyle(color: Colors.red.shade900)),
                  ),
                );
              }

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _getStatusBorderColor(contract.status), width: 1.2),
                ),
                child: Column( // Sử dụng Column để thêm hàng nút điều chỉnh
                  children: [
                    InkWell( // Phần thông tin hợp đồng có thể nhấn để xem chi tiết
                      onTap: () => _viewContractDetails(context, contract),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: FutureBuilder<String>(
                                    future: _getRoomTitle(contract.roomId),
                                    builder: (context, snapshot) {
                                      return Text(
                                        snapshot.data ?? (snapshot.connectionState == ConnectionState.waiting ? "Phòng..." : "N/A"),
                                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(
                                    contract.status.getDisplayName().toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: _getStatusColor(contract.status),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            FutureBuilder<String>(
                              future: _getTenantName(contract.tenantId),
                              builder: (context, snapshot) {
                                return _buildInfoRow(Icons.person_outline, "Người thuê:", snapshot.data ?? (snapshot.connectionState == ConnectionState.waiting ? "Đang tải..." : "Chưa có"));
                              },
                            ),
                            _buildInfoRow(Icons.calendar_today_outlined, "Từ ngày:", _dateFormat.format(contract.startDate)),
                            _buildInfoRow(Icons.event_busy_outlined, "Đến ngày:", _dateFormat.format(contract.endDate)),
                            _buildInfoRow(Icons.attach_money_outlined, "Tiền thuê:", "${NumberFormat("#,##0", "vi_VN").format(contract.rentAmount)} VNĐ"),
                            _buildInfoRow(Icons.money_outlined, "Tiền cọc:", "${NumberFormat("#,##0", "vi_VN").format(contract.depositAmount)} VNĐ"),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "Tạo lúc: ${_dateFormat.format(contract.createdAt)}",
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Hàng chứa nút điều chỉnh trạng thái
                    if (contract.status == ContractStatus.pending || contract.status == ContractStatus.active) // Chỉ hiện nút nếu là pending hoặc active
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: Icon(Icons.edit_note, color: Theme.of(context).colorScheme.primary),
                            label: Text(
                              'Điều chỉnh trạng thái',
                              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => _showChangeStatusDialog(context, contract),
                             style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5))
                              )
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text("$label ", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
          Expanded(child: Text(value, style: TextStyle(color: Colors.black87), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

 Color _getStatusColor(ContractStatus status) {
    switch (status) {
      case ContractStatus.active: return Colors.green.shade600;
      case ContractStatus.pending: return Colors.blue.shade600;
      case ContractStatus.expired: return Colors.orange.shade700;
      case ContractStatus.terminated: return Colors.purple.shade600;
      case ContractStatus.cancelled: return Colors.red.shade700;
      // Mặc định nếu có trạng thái mới chưa xử lý
      // default: return Colors.grey;
    }
  }

  Color _getStatusBorderColor(ContractStatus status) {
     switch (status) {
      case ContractStatus.active: return Colors.green.shade300;
      case ContractStatus.pending: return Colors.blue.shade300;
      case ContractStatus.expired: return Colors.orange.shade300;
      case ContractStatus.terminated: return Colors.purple.shade300;
      case ContractStatus.cancelled: return Colors.red.shade300;
      // default: return Colors.grey.shade300;
    }
  }
}