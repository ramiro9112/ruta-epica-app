class DestinationModel {
  final String id;
  final String name;
  final String country;
  final String description;
  final String imageUrl;
  final List<String> gallery;
  final double priceFrom;
  final String currency;
  final List<String> includes;
  final int durationDays;
  final double rating;
  final int reviewCount;
  final bool isFeatured;
  final bool isPromotion;
  final double? discountPercent;
  final String category; // beach, city, adventure, cultural, international
  final Map<String, dynamic> metadata;
  final bool isActive;

  const DestinationModel({
    required this.id,
    required this.name,
    required this.country,
    required this.description,
    required this.imageUrl,
    required this.gallery,
    required this.priceFrom,
    required this.currency,
    required this.includes,
    required this.durationDays,
    required this.rating,
    required this.reviewCount,
    required this.isFeatured,
    required this.isPromotion,
    this.discountPercent,
    required this.category,
    required this.metadata,
    this.isActive = true,
  });

  factory DestinationModel.fromJson(Map<String, dynamic> json) {
    return DestinationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      country: json['country'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      gallery: (json['gallery'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      priceFrom: (json['price_from'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'COP',
      includes: (json['includes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      durationDays: json['duration_days'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      isPromotion: json['is_promotion'] as bool? ?? false,
      discountPercent: (json['discount_percent'] as num?)?.toDouble(),
      category: json['category'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'description': description,
      'image_url': imageUrl,
      'gallery': gallery,
      'price_from': priceFrom,
      'currency': currency,
      'includes': includes,
      'duration_days': durationDays,
      'rating': rating,
      'review_count': reviewCount,
      'is_featured': isFeatured,
      'is_promotion': isPromotion,
      'discount_percent': discountPercent,
      'category': category,
      'metadata': metadata,
      'is_active': isActive,
    };
  }

  DestinationModel copyWith({
    String? id,
    String? name,
    String? country,
    String? description,
    String? imageUrl,
    List<String>? gallery,
    double? priceFrom,
    String? currency,
    List<String>? includes,
    int? durationDays,
    double? rating,
    int? reviewCount,
    bool? isFeatured,
    bool? isPromotion,
    double? discountPercent,
    String? category,
    Map<String, dynamic>? metadata,
    bool? isActive,
  }) {
    return DestinationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      gallery: gallery ?? this.gallery,
      priceFrom: priceFrom ?? this.priceFrom,
      currency: currency ?? this.currency,
      includes: includes ?? this.includes,
      durationDays: durationDays ?? this.durationDays,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isFeatured: isFeatured ?? this.isFeatured,
      isPromotion: isPromotion ?? this.isPromotion,
      discountPercent: discountPercent ?? this.discountPercent,
      category: category ?? this.category,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DestinationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Sample data for UI development / empty states
class DestinationSamples {
  static final List<DestinationModel> samples = [
    DestinationModel(
      id: 'sample-1',
      name: 'San Andrés',
      country: 'Colombia',
      description:
          'El paraíso del Caribe colombiano con playas de aguas cristalinas.',
      imageUrl:
          'https://images.unsplash.com/photo-1573843981267-be1999ff37cd?w=800',
      gallery: [],
      priceFrom: 890000,
      currency: 'COP',
      includes: ['Tiquetes aéreos', 'Hotel 4 noches', 'Traslados'],
      durationDays: 5,
      rating: 4.8,
      reviewCount: 256,
      isFeatured: true,
      isPromotion: false,
      category: 'beach',
      metadata: {},
    ),
    DestinationModel(
      id: 'sample-2',
      name: 'Cartagena',
      country: 'Colombia',
      description: 'La ciudad amurallada más hermosa de América Latina.',
      imageUrl:
          'https://images.unsplash.com/photo-1599689018034-48e2ead82951?w=800',
      gallery: [],
      priceFrom: 650000,
      currency: 'COP',
      includes: ['Tiquetes aéreos', 'Hotel 3 noches', 'City tour'],
      durationDays: 4,
      rating: 4.7,
      reviewCount: 312,
      isFeatured: true,
      isPromotion: false,
      category: 'city',
      metadata: {},
    ),
  ];
}
