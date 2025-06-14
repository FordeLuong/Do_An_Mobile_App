// models/DVSC.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model đại diện cho Nhà cung cấp
class DonViSuaChua {
  final String? id; // ID tài liệu (null khi tạo mới)
  final String ten; // Tên nhà cung cấp
  final String diaChi; // Địa chỉ nhà cung cấp

  DonViSuaChua({
    this.id,
    required this.ten,
    required this.diaChi,
  });

  /// Factory constructor để tạo DonViSuaChua từ Firestore document
  factory DonViSuaChua.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return DonViSuaChua(
      id: snapshot.id,
      ten: data['ten'] as String? ?? '',
      diaChi: data['diaChi'] as String? ?? '',
    );
  }

  /// Convert DonViSuaChua thành Map để lưu vào Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'ten': ten,
      'diaChi': diaChi,
    };
  }

  /// Tạo bản sao với các trường được cập nhật
  DonViSuaChua copyWith({
    String? id,
    String? ten,
    String? diaChi,
  }) {
    return DonViSuaChua(
      id: id ?? this.id,
      ten: ten ?? this.ten,
      diaChi: diaChi ?? this.diaChi,
    );
  }

  @override
  String toString() {
    return 'DonViSuaChua{id: $id, ten: $ten, diaChi: $diaChi}';
  }

  /// So sánh 2 nhà cung cấp có giống nhau không
  /// Đã đơn giản hóa để chỉ so sánh dựa trên id
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DonViSuaChua && other.id == id;
  }

  @override
  int get hashCode => id.hashCode; // Đã đơn giản hóa để chỉ dùng id
}