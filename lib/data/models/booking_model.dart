class BookingModel {
  final String id;
  final String userId;
  final String destinationId;
  final String destinationName;
  final DateTime travelDate;
  final int adults;
  final int children;
  final String fullName;
  final String phone;
  final String? email;
  final String? observations;
  final String status; // pending, confirmed, cancelled
  final DateTime createdAt;
  final double totalPrice;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.destinationId,
    required this.destinationName,
    required this.travelDate,
    required this.adults,
    required this.children,
    required this.fullName,
    required this.phone,
    this.email,
    this.observations,
    required this.status,
    required this.createdAt,
    required this.totalPrice,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      destinationId: json['destination_id'] as String,
      destinationName: json['destination_name'] as String,
      travelDate: DateTime.parse(json['travel_date'] as String),
      adults: json['adults'] as int? ?? 1,
      children: json['children'] as int? ?? 0,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      observations: json['observations'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'destination_id': destinationId,
      'destination_name': destinationName,
      'travel_date': travelDate.toIso8601String().split('T').first,
      'adults': adults,
      'children': children,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'observations': observations,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'total_price': totalPrice,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'destination_id': destinationId,
      'destination_name': destinationName,
      'travel_date': travelDate.toIso8601String().split('T').first,
      'adults': adults,
      'children': children,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'observations': observations,
      'status': status,
      'total_price': totalPrice,
    };
  }

  BookingModel copyWith({
    String? id,
    String? userId,
    String? destinationId,
    String? destinationName,
    DateTime? travelDate,
    int? adults,
    int? children,
    String? fullName,
    String? phone,
    String? email,
    String? observations,
    String? status,
    DateTime? createdAt,
    double? totalPrice,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      destinationId: destinationId ?? this.destinationId,
      destinationName: destinationName ?? this.destinationName,
      travelDate: travelDate ?? this.travelDate,
      adults: adults ?? this.adults,
      children: children ?? this.children,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      observations: observations ?? this.observations,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isActive => isPending || isConfirmed;

  int get totalPeople => adults + children;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
