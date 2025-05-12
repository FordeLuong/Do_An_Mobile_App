/// Enum định nghĩa các loại hóa đơn
enum BillType {
  rent,        // Tiền thuê nhà
  electricity, // Tiền điện
  water,       // Tiền nước
  internet,    // Tiền Internet
  service,     // Phí dịch vụ khác (ví dụ: vệ sinh, an ninh)
  other,       // Khác
}

// Helper extension cho BillType
extension BillTypeExtension on BillType {
  String toJson() {
    return name;
  }

  static BillType fromJson(String json) {
    return BillType.values.firstWhere(
      (e) => e.name.toLowerCase() == json.toLowerCase(),
      orElse: () {
        print('Warning: Invalid BillType string "$json", defaulting to other.');
        return BillType.other;
      },
    );
  }
}