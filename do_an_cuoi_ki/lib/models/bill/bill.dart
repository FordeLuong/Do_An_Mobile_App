// File: models/electricity_bill.dart

// Enum định nghĩa trạng thái thanh toán
enum PaymentStatus {
  paid,       // Đã thanh toán
  pending,    // Chờ thanh toán
  overdue     // Quá hạn thanh toán
}

// Extension cho PaymentStatus để chuyển đổi sang/từ JSON
extension PaymentStatusExtension on PaymentStatus {
  String toJson() {
    switch (this) {
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.overdue:
        return 'overdue';
    }
  }

  static PaymentStatus fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'paid':
        return PaymentStatus.paid;
      case 'pending':
        return PaymentStatus.pending;
      case 'overdue':
        return PaymentStatus.overdue;
      default:
        return PaymentStatus.pending; // Mặc định là chờ thanh toán
    }
  }
}

class BillModel {
  final String id;
  final String roomId;
  final String ownerId;
  final String khachThueId;
  final int sodienCu;
  final int sodienMoi;
  final int soNguoi;
  final double priceRoom;
  final double priceDien;
  final double priceWater;
  final double amenitiesPrice;
  final DateTime date;
  final String thangNam;
  final double sumPrice;
  final PaymentStatus status; // Trạng thái thanh toán

  BillModel({
    required this.id,
    required this.roomId,
    required this.ownerId,
    required this.khachThueId,
    required this.sodienCu,
    required this.sodienMoi,
    required this.soNguoi,
    required this.priceRoom,
    required this.priceDien,
    required this.priceWater,
    required this.amenitiesPrice,
    required this.date,
    required this.thangNam,
    required this.sumPrice,
    this.status = PaymentStatus.pending, // Mặc định là chờ thanh toán
  });

  // Phương thức tính tiền điện
  double get tienDien => (sodienMoi - sodienCu) * priceDien;

  // Phương thức tính tiền nước
  double get tienNuoc => priceWater * soNguoi;

  // Phương thức tính tổng tiền
  double get tinhTongTien => tienDien + tienNuoc + priceRoom + amenitiesPrice;

  /// Hàm tạo từ Map (JSON)
  factory BillModel.fromJson(Map<String, dynamic> json) {
    final model = BillModel(
      id: json['id'] as String? ?? '',
      roomId: json['roomId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      khachThueId: json['khachThueId'] as String? ?? '',
      sodienCu: json['sodienCu'] as int? ?? 0,
      sodienMoi: json['sodienMoi'] as int? ?? 0,
      soNguoi: json['soNguoi'] as int? ?? 0,
      priceRoom: (json['priceRoom'] as num?)?.toDouble() ?? 0.0,
      priceDien: (json['priceDien'] as num?)?.toDouble() ?? 0.0,
      priceWater: (json['priceWater'] as num?)?.toDouble() ?? 0.0,
      amenitiesPrice: (json['amenitiesPrice'] as num?)?.toDouble() ?? 0.0,
      date: (json['date'] != null)
          ? (json['date'] is String
              ? DateTime.parse(json['date'] as String)
              : DateTime.now())
          : DateTime.now(),
      thangNam: json['thangNam'] as String? ?? '',
      sumPrice: (json['sumPrice'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] != null 
          ? PaymentStatusExtension.fromJson(json['status'] as String)
          : PaymentStatus.pending,
    );
    
    // Nếu sumPrice = 0, tự động tính toán lại
    if (model.sumPrice == 0) {
      return model.copyWith(sumPrice: model.tinhTongTien);
    }
    return model;
  }

  /// Hàm chuyển đổi thành Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'ownerId': ownerId,
      'khachThueId': khachThueId,
      'sodienCu': sodienCu,
      'sodienMoi': sodienMoi,
      'soNguoi': soNguoi,
      'priceRoom': priceRoom,
      'priceDien': priceDien,
      'priceWater': priceWater,
      'amenitiesPrice': amenitiesPrice,
      'date': date.toIso8601String(),
      'thangNam': thangNam,
      'sumPrice': sumPrice,
      'status': status.toJson(),
    };
  }

  /// Hàm copyWith để tạo bản sao và cập nhật
  BillModel copyWith({
    String? id,
    String? roomId,
    String? ownerId,
    String? khachThueId,
    int? sodienCu,
    int? sodienMoi,
    int? soNguoi,
    double? priceRoom,
    double? priceDien,
    double? priceWater,
    double? amenitiesPrice,
    DateTime? date,
    String? thangNam,
    double? sumPrice,
    PaymentStatus? status,
  }) {
    final newModel = BillModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      ownerId: ownerId ?? this.ownerId,
      khachThueId: khachThueId ?? this.khachThueId,
      sodienCu: sodienCu ?? this.sodienCu,
      sodienMoi: sodienMoi ?? this.sodienMoi,
      soNguoi: soNguoi ?? this.soNguoi,
      priceRoom: priceRoom ?? this.priceRoom,
      priceDien: priceDien ?? this.priceDien,
      priceWater: priceWater ?? this.priceWater,
      amenitiesPrice: amenitiesPrice ?? this.amenitiesPrice,
      date: date ?? this.date,
      thangNam: thangNam ?? this.thangNam,
      sumPrice: sumPrice ?? this.sumPrice,
      status: status ?? this.status,
    );
    
    // Nếu có thay đổi các thông số tính toán, tự động cập nhật sumPrice
    if (sodienCu != null || sodienMoi != null || soNguoi != null ||
        priceDien != null || priceWater != null || 
        priceRoom != null || amenitiesPrice != null) {
      return newModel.copyWith(sumPrice: newModel.tinhTongTien);
    }
    return newModel;
  }
}