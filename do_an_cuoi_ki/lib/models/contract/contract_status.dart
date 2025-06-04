// File: models/contract_status.dart

enum ContractStatus {
  pending,   // Chờ duyệt/ký
  active,    // Đang hiệu lực
  expired,   // Đã hết hạn
  terminated, // Đã thanh lý/chấm dứt sớm
  cancelled, // Đã hủy (trước khi có hiệu lực)
}

extension ContractStatusExtension on ContractStatus {
  String toJson() {
    return name; // Sử dụng name của enum cho đơn giản (ví dụ: 'pending', 'active')
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

  // Hàm để lấy tên hiển thị đẹp hơn
  String getDisplayName() {
    switch (this) {
      case ContractStatus.pending:
        return 'Chờ duyệt';
      case ContractStatus.active:
        return 'Đang hiệu lực';
      case ContractStatus.expired:
        return 'Đã hết hạn';
      case ContractStatus.terminated:
        return 'Đã thanh lý';
      case ContractStatus.cancelled:
        return 'Đã hủy';
    }
  }
}