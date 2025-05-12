// File: models/bill.dart

import 'bill_type.dart'; // Import enum BillType
import 'bill_status.dart'; // Import enum BillStatus

/// Class đại diện cho thông tin một hóa đơn
class BillModel {
  final String id; // ID duy nhất của hóa đơn
  final String contractId; // ID của hợp đồng liên quan (liên kết với ContractModel)
  final String roomId; // ID của phòng trọ (để tiện truy vấn, liên kết với RoomModel)
  final String tenantId; // ID của người thuê chịu trách nhiệm thanh toán (liên kết với UserModel)
  final String ownerId; // ID của chủ trọ / người tạo hóa đơn
  final BillType type; // Loại hóa đơn (điện, nước, thuê nhà,...)
  final double amount; // Số tiền cần thanh toán
  final DateTime issueDate; // Ngày phát hành hóa đơn
  final DateTime dueDate; // Ngày đến hạn thanh toán
  final DateTime? paidDate; // Ngày thanh toán (null nếu chưa thanh toán)
  final BillStatus status; // Trạng thái hóa đơn (chờ thanh toán, đã thanh toán, quá hạn)
  final String? description; // Mô tả thêm cho hóa đơn (ví dụ: "Tiền điện tháng 5/2025")
  final String? paymentMethod; // Phương thức thanh toán (ví dụ: "Chuyển khoản", "Tiền mặt")
  final String? transactionId; // Mã giao dịch nếu có
  final DateTime createdAt; // Thời gian tạo hóa đơn
  final DateTime? updatedAt; // Thời gian cập nhật cuối cùng

  BillModel({
    required this.id,
    required this.contractId,
    required this.roomId,
    required this.tenantId,
    required this.ownerId,
    required this.type,
    required this.amount,
    required this.issueDate,
    required this.dueDate,
    this.paidDate,
    required this.status,
    this.description,
    this.paymentMethod,
    this.transactionId,
    required this.createdAt,
    this.updatedAt,
  });

  /// Hàm tạo BillModel từ một Map
  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'] as String? ?? '',
      contractId: json['contractId'] as String? ?? '',
      roomId: json['roomId'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      type: BillTypeExtension.fromJson(json['type'] as String? ?? 'other'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      issueDate: (json['issueDate'] != null)
          ? DateTime.parse(json['issueDate'] as String)
          : DateTime.now(),
      dueDate: (json['dueDate'] != null)
          ? DateTime.parse(json['dueDate'] as String)
          : DateTime.now().add(const Duration(days: 7)), // Mặc định 7 ngày sau ngày phát hành
      paidDate: json['paidDate'] != null
          ? DateTime.parse(json['paidDate'] as String)
          : null,
      status: BillStatusExtension.fromJson(json['status'] as String? ?? 'pending'),
      description: json['description'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      transactionId: json['transactionId'] as String?,
      createdAt: (json['createdAt'] != null)
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Hàm chuyển đổi BillModel thành một Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contractId': contractId,
      'roomId': roomId,
      'tenantId': tenantId,
      'ownerId': ownerId,
      'type': type.toJson(),
      'amount': amount,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'status': status.toJson(),
      'description': description,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Hàm copyWith
  BillModel copyWith({
    String? id,
    String? contractId,
    String? roomId,
    String? tenantId,
    String? ownerId,
    BillType? type,
    double? amount,
    DateTime? issueDate,
    DateTime? dueDate,
    DateTime? paidDate,
    BillStatus? status,
    String? description,
    String? paymentMethod,
    String? transactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool setPaidDateToNull = false,
    bool setUpdatedAtToNull = false,
  }) {
    return BillModel(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      roomId: roomId ?? this.roomId,
      tenantId: tenantId ?? this.tenantId,
      ownerId: ownerId ?? this.ownerId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      paidDate: setPaidDateToNull ? null : (paidDate ?? this.paidDate),
      status: status ?? this.status,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: setUpdatedAtToNull ? null : (updatedAt ?? this.updatedAt),
    );
  }
}
