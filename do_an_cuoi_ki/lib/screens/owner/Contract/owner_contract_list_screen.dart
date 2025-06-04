// lib/screens/owner/owner_contract_list_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/contract/contract.dart'; // Đảm bảo import đúng ContractModel
import 'package:do_an_cuoi_ki/models/contract/contract_status.dart';
import 'package:do_an_cuoi_ki/models/user.dart';
import 'package:intl/intl.dart';

class OwnerContractListScreen extends StatefulWidget {
  final UserModel currentUser;

  const OwnerContractListScreen({super.key, required this.currentUser});

  @override
  State<OwnerContractListScreen> createState() => _OwnerContractListScreenState();
}

class _OwnerContractListScreenState extends State<OwnerContractListScreen> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  Future<String> _getTenantName(String tenantId) async {
    if (tenantId.isEmpty) return "Chưa có";
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(tenantId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['userName'] as String? ?? 'Người thuê không tên';
      }
    } catch (e) {
      print("Lỗi khi lấy tên người thuê: $e");
    }
    return "ID: $tenantId";
  }

  Future<String> _getRoomTitle(String roomId) async {
    if (roomId.isEmpty) return "Không rõ phòng";
    try {
      final doc = await FirebaseFirestore.instance.collection('rooms').doc(roomId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['title'] as String? ?? 'Phòng không tên';
      }
    } catch (e) {
      print("Lỗi khi lấy tên phòng: $e");
    }
    return "ID: $roomId";
  }

  // Ví dụ hàm xử lý khi nhấn vào hợp đồng (bạn có thể mở màn hình chi tiết)
  void _viewContractDetails(BuildContext context, ContractModel contract) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Chi tiết Hợp đồng", style: TextStyle(color: _getStatusColor(contract.status))),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildDetailRow("ID Hợp đồng:", contract.id),
                FutureBuilder<String>(
                  future: _getRoomTitle(contract.roomId),
                  builder: (context, snapshot) => _buildDetailRow("Phòng:", snapshot.data ?? "Đang tải..."),
                ),
                FutureBuilder<String>(
                  future: _getTenantName(contract.tenantId),
                  builder: (context, snapshot) => _buildDetailRow("Người Thuê:", snapshot.data ?? "Đang tải..."),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh sách hợp đồng"),
        backgroundColor: Colors.indigo.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('contracts')
            .where('ownerId', isEqualTo: widget.currentUser.id)
            .orderBy('createdAt', descending: true) // Sắp xếp theo String ISO 8601 vẫn khá ổn
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Đã xảy ra lỗi: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_off_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text("Chưa có hợp đồng nào.", style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          final contractDocs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
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
                print("Lỗi parse ContractModel: $e. Data: ${contractDoc.data()}");
                print("Stack Trace: $s");
                return Card( /* ... Card lỗi ... */ );
              }

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _getStatusBorderColor(contract.status), width: 1.2),
                ),
                child: InkWell(
                  onTap: () => _viewContractDetails(context, contract),
                  borderRadius: BorderRadius.circular(12),
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
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: _getStatusColor(contract.status),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        FutureBuilder<String>(
                          future: _getTenantName(contract.tenantId),
                          builder: (context, snapshot) {
                            return _buildInfoRow(Icons.person_outline, "Người thuê:", snapshot.data ?? (snapshot.connectionState == ConnectionState.waiting ? "Đang tải..." : "N/A"));
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
      case ContractStatus.active:
        return Colors.green.shade600;
      case ContractStatus.pending:
        return Colors.blue.shade600;
      case ContractStatus.expired:
        return Colors.orange.shade700;
      case ContractStatus.terminated:
        return Colors.purple.shade600;
      case ContractStatus.cancelled:
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBorderColor(ContractStatus status) {
    switch (status) {
      case ContractStatus.active:
        return Colors.green.shade300;
      case ContractStatus.pending:
        return Colors.blue.shade300;
      default:
        return Colors.grey.shade300;
    }
  }
}