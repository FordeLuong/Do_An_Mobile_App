// File: models/bill_status.dart

/// Enum định nghĩa các trạng thái của hóa đơn
enum BillStatus {
  pending,   // Đang chờ thanh toán
  paid,      // Đã thanh toán
  overdue,   // Quá hạn
  cancelled, // Đã hủy
}

// Helper extension cho BillStatus
extension BillStatusExtension on BillStatus {
  String toJson() {
    return name;
  }

  static BillStatus fromJson(String json) {
    return BillStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == json.toLowerCase(),
      orElse: () {
        print('Warning: Invalid BillStatus string "$json", defaulting to pending.');
        return BillStatus.pending;
      },
    );
  }
}