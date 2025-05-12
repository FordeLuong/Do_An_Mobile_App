// File: models/contract_status.dart

/// Enum định nghĩa các trạng thái của hợp đồng
enum ContractStatus {
  pending,   // Đang chờ duyệt/xác nhận
  active,    // Đang có hiệu lực
  expired,   // Đã hết hạn
  terminated, // Đã chấm dứt (ví dụ: do vi phạm)
  cancelled, // Đã hủy (trước khi có hiệu lực)
}

// Helper extension cho ContractStatus
extension ContractStatusExtension on ContractStatus {
  String toJson() {
    return name; // Sử dụng 'name' của enum cho đơn giản (ví dụ: 'active')
  }

  static ContractStatus fromJson(String json) {
    return ContractStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == json.toLowerCase(),
      orElse: () {
        print('Warning: Invalid ContractStatus string "$json", defaulting to pending.');
        return ContractStatus.pending;
      },
    );
  }
}