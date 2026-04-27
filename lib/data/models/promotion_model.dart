class PromotionModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String? destinationId;
  final double? discountPercent;
  final DateTime validUntil;
  final bool isActive;

  const PromotionModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.destinationId,
    this.discountPercent,
    required this.validUntil,
    required this.isActive,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      destinationId: json['destination_id'] as String?,
      discountPercent: (json['discount_percent'] as num?)?.toDouble(),
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'] as String)
          : DateTime.now().add(const Duration(days: 30)),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'destination_id': destinationId,
      'discount_percent': discountPercent,
      'valid_until': validUntil.toIso8601String(),
      'is_active': isActive,
    };
  }

  PromotionModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? destinationId,
    double? discountPercent,
    DateTime? validUntil,
    bool? isActive,
  }) {
    return PromotionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      destinationId: destinationId ?? this.destinationId,
      discountPercent: discountPercent ?? this.discountPercent,
      validUntil: validUntil ?? this.validUntil,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isExpired => validUntil.isBefore(DateTime.now());
  bool get hasDiscount => discountPercent != null && discountPercent! > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromotionModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Sample promotions for UI development
class PromotionSamples {
  static final List<PromotionModel> samples = [
    PromotionModel(
      id: 'promo-1',
      title: 'San Andrés en Semana Santa',
      subtitle: 'Desde \$890.000 COP — Todo incluido',
      imageUrl:
          'https://images.unsplash.com/photo-1573843981267-be1999ff37cd?w=800',
      discountPercent: 20,
      validUntil: DateTime.now().add(const Duration(days: 30)),
      isActive: true,
    ),
    PromotionModel(
      id: 'promo-2',
      title: 'Cancún 6 noches All-Inclusive',
      subtitle: 'Oferta limitada — Solo esta semana',
      imageUrl:
          'https://images.unsplash.com/photo-1510097467424-192d713fd8b2?w=800',
      discountPercent: 15,
      validUntil: DateTime.now().add(const Duration(days: 7)),
      isActive: true,
    ),
    PromotionModel(
      id: 'promo-3',
      title: 'Europa Clásica — 12 días',
      subtitle: 'París, Roma y Barcelona te esperan',
      imageUrl:
          'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=800',
      discountPercent: 10,
      validUntil: DateTime.now().add(const Duration(days: 60)),
      isActive: true,
    ),
  ];
}
