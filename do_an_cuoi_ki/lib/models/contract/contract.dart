import 'contract_status.dart'; // Import enum ContractStatus

/// Class đại diện cho thông tin một hợp đồng thuê trọ
class ContractModel {
  final String id; // ID duy nhất của hợp đồng
  final String roomId; // ID của phòng trọ được thuê (liên kết với RoomModel)
  final String tenantId; // ID của người thuê (liên kết với UserModel)
  final String ownerId; // ID của chủ trọ (liên kết với UserModel)
  final DateTime startDate; // Ngày bắt đầu hợp đồng
  final DateTime endDate; // Ngày kết thúc hợp đồng
  final double rentAmount; // Số tiền thuê hàng tháng/kỳ
  final double depositAmount; // Số tiền cọc
  final String? termsAndConditions; // Điều khoản và điều kiện của hợp đồng (có thể null)
  final ContractStatus status; // Trạng thái của hợp đồng
  final List<String>? paymentHistoryIds; // Danh sách ID các lần thanh toán (liên kết với BillModel hoặc PaymentModel riêng)
  final DateTime createdAt; // Thời gian tạo hợp đồng
  final DateTime? updatedAt; // Thời gian cập nhật cuối cùng

  ContractModel({
    required this.id,
    required this.roomId,
    required this.tenantId,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.rentAmount,
    required this.depositAmount,
    this.termsAndConditions,
    required this.status,
    this.paymentHistoryIds,
    required this.createdAt,
    this.updatedAt,
  });

  /// Hàm tạo ContractModel từ một Map (thường dùng khi đọc dữ liệu từ Firestore/API)
  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      id: json['id'] as String? ?? '',
      roomId: json['roomId'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      startDate: (json['startDate'] != null)
          ? DateTime.parse(json['startDate'] as String)
          : DateTime.now(), // Cần xử lý cẩn thận hơn ở đây
      endDate: (json['endDate'] != null)
          ? DateTime.parse(json['endDate'] as String)
          : DateTime.now().add(const Duration(days: 365)), // Ví dụ mặc định 1 năm
      rentAmount: (json['rentAmount'] as num?)?.toDouble() ?? 0.0,
      depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0.0,
      termsAndConditions: json['termsAndConditions'] as String?,
      status: ContractStatusExtension.fromJson(json['status'] as String? ?? 'pending'),
      paymentHistoryIds: (json['paymentHistoryIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      createdAt: (json['createdAt'] != null)
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Hàm chuyển đổi ContractModel thành một Map (thường dùng khi ghi dữ liệu lên Firestore/API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'tenantId': tenantId,
      'ownerId': ownerId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'rentAmount': rentAmount,
      'depositAmount': depositAmount,
      'termsAndConditions': termsAndConditions,
      'status': status.toJson(),
      'paymentHistoryIds': paymentHistoryIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Hàm copyWith để tạo bản sao của đối tượng với một vài thuộc tính được thay đổi
  ContractModel copyWith({
    String? id,
    String? roomId,
    String? tenantId,
    String? ownerId,
    DateTime? startDate,
    DateTime? endDate,
    double? rentAmount,
    double? depositAmount,
    String? termsAndConditions,
    ContractStatus? status,
    List<String>? paymentHistoryIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool setUpdatedAtToNull = false, // Thêm cờ để cho phép đặt updatedAt thành null
  }) {
    return ContractModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      tenantId: tenantId ?? this.tenantId,
      ownerId: ownerId ?? this.ownerId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rentAmount: rentAmount ?? this.rentAmount,
      depositAmount: depositAmount ?? this.depositAmount,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      status: status ?? this.status,
      paymentHistoryIds: paymentHistoryIds ?? this.paymentHistoryIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: setUpdatedAtToNull ? null : (updatedAt ?? this.updatedAt),
    );
  }
}

