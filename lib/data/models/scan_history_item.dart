class ScanHistoryItem {
  final int? id;
  final int productId;
  final String evaluationStatus;
  final String? violationReasons;
  final String scannedAt;

  final String? productName;
  final String? brand;
  final String? imageUrl;

  ScanHistoryItem({
    this.id,
    required this.productId,
    required this.evaluationStatus,
    this.violationReasons,
    required this.scannedAt,
    this.productName,
    this.brand,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'evaluation_status': evaluationStatus,
      'violation_reasons': violationReasons,
      'scanned_at': scannedAt,
    };
  }

  factory ScanHistoryItem.fromMap(Map<String, dynamic> map) {
    return ScanHistoryItem(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      evaluationStatus: map['evaluation_status'] as String,
      violationReasons: map['violation_reasons'] as String?,
      scannedAt: map['scanned_at'] as String,
      productName: map['product_name'] as String?,
      brand: map['brand'] as String?,
      imageUrl: map['image_url'] as String?,
    );
  }
}
