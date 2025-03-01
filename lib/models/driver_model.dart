class Driver {
  final String id;
  final String? email;
  final String mobile;
  final String name;
  final String storeId;
  final bool isActive;
  final bool isLive;
  final bool isReady;
  final DateTime createdAt;
  final DateTime updatedAt;

  Driver({
    required this.id,
    this.email,
    required this.mobile,
    required this.name,
    required this.storeId,
    required this.isActive,
    required this.isLive,
    required this.isReady,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['_id'],
      email: json['email'],
      mobile: json['mobile'],
      name: json['name'],
      storeId: json['storeId'],
      isActive: json['isActive'],
      isLive: json['isLive'],
      isReady: json['isReady'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'mobile': mobile,
      'name': name,
      'storeId': storeId,
      'isActive': isActive,
      'isLive': isLive,
      'isReady': isReady,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
