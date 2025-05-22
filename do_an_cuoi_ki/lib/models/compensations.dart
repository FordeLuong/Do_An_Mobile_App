import 'package:cloud_firestore/cloud_firestore.dart';

/// Class representing compensation data with info and cost
class CompensationModel {
  final String? id; // Document ID (will be null for new documents before saving)
  final String contactId; // Associated contract ID
  final List<CompensationItem> items; // List of compensation items
  final double totalAmount; // Sum of all compensation costs
  final DateTime createdAt; // When the compensation was created
  final DateTime date; // Date associated with the compensation

  CompensationModel({
    this.id,
    required this.contactId,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    required this.date,
  });

  /// Factory constructor to create CompensationModel from Firestore document
  factory CompensationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    final itemsData = data['items'] as List<dynamic>? ?? [];
    
    return CompensationModel(
      id: snapshot.id,
      contactId: data['ContactID'] as String? ?? '',
      items: itemsData.map((item) => CompensationItem.fromMap(item)).toList(),
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert CompensationModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'ContactID': contactId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'createdAt': FieldValue.serverTimestamp(),
      'date': date,
    };
  }

  /// Create a copy of the model with updated fields
  CompensationModel copyWith({
    String? id,
    String? contactId,
    List<CompensationItem>? items,
    double? totalAmount,
    DateTime? createdAt,
    DateTime? date,
  }) {
    return CompensationModel(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      date: date ?? this.date,
    );
  }

  /// Calculate total amount from items
  static double calculateTotal(List<CompensationItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.cost);
  }

  /// Filter valid items (with non-empty info or cost > 0)
  static List<CompensationItem> filterValidItems(List<CompensationItem> items) {
    return items.where((item) => 
      item.info.trim().isNotEmpty || 
      item.cost > 0
    ).toList();
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