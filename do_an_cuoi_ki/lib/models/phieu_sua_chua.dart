import 'package:cloud_firestore/cloud_firestore.dart';

enum RepairStatus {
  pending,    // Chờ xử lý
  completed,  // Đã hoàn thành
  cancelled,  // Đã hủy
}

enum FaultSource {
  tenant,    // Lỗi do khách thuê
  landlord,  // Lỗi do chủ trọ
}

/// Class representing compensation data with info and cost
class PhieuSuaChua {
  final String? id; // Document ID (will be null for new documents before saving)
  final String? DVSSId; // DVSS ID (optional)
  final String roomId; // Room ID
  final String tenantId; // Tenant ID
  final String? requestId; // Request ID (optional)
  final List<CompensationItem>? items; // List of compensation items (optional)
  final DateTime ngaySua; // Date of repair in dd/mm/yyyy format
  final double tongTien; // Total compensation amount
  final RepairStatus status; // Trạng thái sửa chữa
  final FaultSource faultSource; // Nguồn lỗi (tenant hoặc landlord)

  PhieuSuaChua({
    this.id,
    this.DVSSId,
    required this.roomId,
    required this.tenantId,
    this.requestId,
    this.items,
    required this.ngaySua,
    required this.tongTien,
    this.status = RepairStatus.pending, // Giá trị mặc định
    required this.faultSource, // Trường bắt buộc
  });

  /// Factory constructor to create PhieuSuaChua from Firestore document
  factory PhieuSuaChua.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    final itemsData = data['items'] as List<dynamic>?;
    final statusString = data['status'] as String? ?? 'pending';
    final faultSourceString = data['faultSource'] as String? ?? 'tenant';
    return PhieuSuaChua(
      id: snapshot.id,
      DVSSId: data['DVSSId'] as String?,
      roomId: data['roomId'] as String? ?? '',
      tenantId: data['tenantId'] as String? ?? '',
      requestId: data['requestId'] as String?,
      items: itemsData?.map((item) => CompensationItem.fromMap(item)).toList(),
      ngaySua: (data['ngaySua'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tongTien: (data['tongTien'] as num?)?.toDouble() ?? 0.0,
      status: RepairStatus.values.firstWhere(
        (e) => e.name == statusString,
        orElse: () => RepairStatus.pending,
      ),
      faultSource: FaultSource.values.firstWhere(
        (e) => e.name == faultSourceString,
        orElse: () => FaultSource.tenant,
      ),
    );
  }

  /// Convert PhieuSuaChua to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'DVSSId': DVSSId,
      'roomId': roomId,
      'tenantId': tenantId,
      'requestId': requestId,
      'items': items?.map((item) => item.toMap()).toList(),
      'ngaySua': Timestamp.fromDate(ngaySua),
      'tongTien': tongTien,
      'status': status.name,
      'faultSource': faultSource.name,
    };
  }

  /// Create a copy of the model with updated fields
  PhieuSuaChua copyWith({
    String? id,
    String? DVSSId,
    String? roomId,
    String? tenantId,
    String? requestId,
    List<CompensationItem>? items,
    DateTime? ngaySua,
    double? tongTien,
    RepairStatus? status,
    FaultSource? faultSource,
  }) {
    return PhieuSuaChua(
      id: id ?? this.id,
      DVSSId: DVSSId ?? this.DVSSId,
      roomId: roomId ?? this.roomId,
      tenantId: tenantId ?? this.tenantId,
      requestId: requestId ?? this.requestId,
      items: items ?? this.items,
      ngaySua: ngaySua ?? this.ngaySua,
      tongTien: tongTien ?? this.tongTien,
      status: status ?? this.status,
      faultSource: faultSource ?? this.faultSource,
    );
  }

  /// Calculate total amount from items if they exist
  static double calculateTotal(List<CompensationItem>? items) {
    if (items == null || items.isEmpty) return 0.0;
    return items.fold(0.0, (sum, item) => sum + item.cost);
  }

  /// Filter valid items (with non-empty info or cost > 0)
  static List<CompensationItem>? filterValidItems(List<CompensationItem>? items) {
    if (items == null) return null;
    return items.where((item) => 
      item.info.trim().isNotEmpty || 
      item.cost > 0
    ).toList();
  }

  String get statusText {
    switch (status) {
      case RepairStatus.pending:
        return 'Chờ xử lý';
      case RepairStatus.completed:
        return 'Đã hoàn thành';
      case RepairStatus.cancelled:
        return 'Đã hủy';
    }
  }

  String get faultSourceText {
    switch (faultSource) {
      case FaultSource.tenant:
        return 'Khách thuê';
      case FaultSource.landlord:
        return 'Chủ trọ';
    }
  }
}

/// Class representing a single compensation item
class CompensationItem {
  final String info; // Description of the compensation
  final double cost; // Amount of compensation

  CompensationItem({
    required this.info,
    required this.cost,
  });

  /// Create CompensationItem from a Map
  factory CompensationItem.fromMap(Map<String, dynamic> map) {
    return CompensationItem(
      info: map['info'] as String? ?? '',
      cost: (map['cost'] is String)
          ? double.tryParse(map['cost']) ?? 0
          : (map['cost'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Convert CompensationItem to a Map
  Map<String, dynamic> toMap() {
    return {
      'info': info,
      'cost': cost,
    };
  }

  /// Create a copy of the item with updated fields
  CompensationItem copyWith({
    String? info,
    double? cost,
  }) {
    return CompensationItem(
      info: info ?? this.info,
      cost: cost ?? this.cost,
    );
  }
}