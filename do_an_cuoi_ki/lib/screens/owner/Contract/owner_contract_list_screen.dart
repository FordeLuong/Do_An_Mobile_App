// lib/screens/owner/owner_contract_list_screen.dart
// lib/screens/owner/owner_contract_list_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:do_an_cuoi_ki/models/contract/contract.dart';
import 'package:do_an_cuoi_ki/models/contract/contract_status.dart';
import 'package:do_an_cuoi_ki/models/user.dart';
import 'package:intl/intl.dart';
import 'package:do_an_cuoi_ki/services/contract_service.dart';
import 'package:do_an_cuoi_ki/services/user_service.dart';
import 'package:do_an_cuoi_ki/services/room_service.dart';

class OwnerContractListScreen extends StatefulWidget {
  final UserModel currentUser;

  const OwnerContractListScreen({super.key, required this.currentUser});

  @override
  State<OwnerContractListScreen> createState() => _OwnerContractListScreenState();
}

class _OwnerContractListScreenState extends State<OwnerContractListScreen> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final ContractService _contractService = ContractService();
  final UserService _userService = UserService();
  final RoomService _roomService = RoomService();

  void _viewContractDetails(BuildContext context, ContractModel contract) {
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
                  future: _roomService.getRoomTitle(contract.roomId),
                  builder: (context, snapshot) => _buildDetailRow("Phòng:", snapshot.data ?? (snapshot.connectionState == ConnectionState.waiting ? "Đang tải..." : "N/A")),
                ),
                FutureBuilder<String>(
                  future: _userService.getTenantName(contract.tenantId),
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

  // ... (giữ nguyên các hàm _buildDetailRow, _buildInfoRow, _getStatusColor, _getStatusBorderColor)

  // Hàm mới để hiển thị dialog thay đổi trạng thái
  void _showChangeStatusDialog(BuildContext context, ContractModel contract) {
    ContractStatus? selectedStatus = contract.status;
    List<ContractStatus> availableOptions = [];

    if (contract.status == ContractStatus.pending) {
      availableOptions = [
        ContractStatus.active,
        ContractStatus.expired,
        ContractStatus.terminated,
        ContractStatus.cancelled,
      ];
    } else if (contract.status == ContractStatus.active) {
      availableOptions = [
        ContractStatus.expired,
        ContractStatus.terminated,
        ContractStatus.cancelled,
      ];
    } else {
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
    
    if (!availableOptions.contains(selectedStatus)){
      selectedStatus = availableOptions.first;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
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
                          setDialogState(() {
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

  Future<void> _updateContractStatus(BuildContext scaffoldContext, ContractModel contract, ContractStatus newStatus) async {
    try {
      // Cập nhật trạng thái hợp đồng
      await _contractService.updateContractStatus(
        contractId: contract.id,
        newStatus: newStatus,
      );

      // Cập nhật trạng thái phòng
      await _roomService.updateRoomStatusForContract(
        roomId: contract.roomId,
        newContractStatus: newStatus,
        tenantId: contract.tenantId,
      );

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
        stream: _contractService.getContractsByOwner(widget.currentUser.id),
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
                contract = _contractService.parseContractDocument(contractDoc);
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
                child: Column(
                  children: [
                    InkWell(
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
                                    future: _roomService.getRoomTitle(contract.roomId),
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
                              future: _userService.getTenantName(contract.tenantId),
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
                    if (contract.status == ContractStatus.pending || contract.status == ContractStatus.active)
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