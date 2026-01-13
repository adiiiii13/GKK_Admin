enum UserRole { customer, kitchen, delivery }

enum VerificationStatus { pending, verified, rejected }

class WarningLog {
  final DateTime date;
  final String message;
  final String adminName;

  WarningLog({
    required this.date,
    required this.message,
    required this.adminName,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'message': message,
    'adminName': adminName,
  };

  factory WarningLog.fromJson(Map<String, dynamic> json) => WarningLog(
    date: DateTime.parse(json['date']),
    message: json['message'],
    adminName: json['adminName'] ?? 'Admin',
  );
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  VerificationStatus status;
  final DateTime dateApplied;
  final String? profileImage; // URL or asset path
  final List<WarningLog> warnings;

  // Role specific details (nullable)
  final KitchenDetails? kitchenDetails;
  final UserDetails? userDetails;
  final DeliveryDetails? deliveryDetails;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.status = VerificationStatus.pending,
    required this.dateApplied,
    this.profileImage,
    this.warnings = const [],
    this.kitchenDetails,
    this.userDetails,
    this.deliveryDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.toString(),
      'status': status.toString(),
      'dateApplied': dateApplied.toIso8601String(),
      'profileImage': profileImage,
      'warnings': warnings.map((x) => x.toJson()).toList(),
      'kitchenDetails': kitchenDetails?.toJson(),
      'userDetails': userDetails?.toJson(),
      'deliveryDetails': deliveryDetails?.toJson(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? json['full_name'] ?? 'Unknown',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: _parseRole(json['role'] ?? 'customer'),
      status: _parseStatus(json['status'] ?? 'verified'),
      dateApplied: json['dateApplied'] != null 
          ? DateTime.parse(json['dateApplied']) 
          : (json['created_at'] != null 
              ? DateTime.parse(json['created_at']) 
              : DateTime.now()),
      profileImage: json['profileImage'] ?? json['avatar_url'],
      warnings:
          (json['warnings'] as List?)
              ?.map((e) => WarningLog.fromJson(e))
              .toList() ??
          [],
      kitchenDetails: json['kitchenDetails'] != null
          ? KitchenDetails.fromJson(json['kitchenDetails'])
          : null,
      userDetails: json['userDetails'] != null
          ? UserDetails.fromJson(json['userDetails'])
          : null,
      deliveryDetails: json['deliveryDetails'] != null
          ? DeliveryDetails.fromJson(json['deliveryDetails'])
          : null,
    );
  }

  static UserRole _parseRole(String str) {
    // Handle both enum format "UserRole.customer" and simple "customer"
    final cleanStr = str.replaceAll('UserRole.', '');
    return UserRole.values.firstWhere(
      (e) => e.name == cleanStr,
      orElse: () => UserRole.customer,
    );
  }

  static VerificationStatus _parseStatus(String str) {
    // Handle both enum format and simple string
    final cleanStr = str.replaceAll('VerificationStatus.', '');
    return VerificationStatus.values.firstWhere(
      (e) => e.name == cleanStr,
      orElse: () => VerificationStatus.verified,
    );
  }
}

// --- Specific Details Models ---

class FoodItem {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  bool isEnabled;

  FoodItem({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'imageUrl': imageUrl,
    'isEnabled': isEnabled,
  };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
    id: json['id'],
    name: json['name'],
    price: json['price'],
    imageUrl: json['imageUrl'],
    isEnabled: json['isEnabled'],
  );
}

class Order {
  final String id;
  final DateTime date;
  final String customerName;
  final double amount;
  final String status; // "Delivered", "Cooking", etc.

  Order({
    required this.id,
    required this.date,
    required this.customerName,
    required this.amount,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'customerName': customerName,
    'amount': amount,
    'status': status,
  };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'],
    date: DateTime.parse(json['date']),
    customerName: json['customerName'],
    amount: json['amount'],
    status: json['status'],
  );
}

class TokenTxn {
  final String id;
  final DateTime date;
  final String description;
  final int amount; // + for buy, - for spend

  TokenTxn({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'description': description,
    'amount': amount,
  };

  factory TokenTxn.fromJson(Map<String, dynamic> json) => TokenTxn(
    id: json['id'],
    date: DateTime.parse(json['date']),
    description: json['description'],
    amount: json['amount'],
  );
}

class KitchenDetails {
  final String address;
  final double rating;
  final List<FoodItem> menuItems;
  final List<Order> orderHistory;

  KitchenDetails({
    required this.address,
    required this.rating,
    required this.menuItems,
    required this.orderHistory,
  });

  Map<String, dynamic> toJson() => {
    'address': address,
    'rating': rating,
    'menuItems': menuItems.map((x) => x.toJson()).toList(),
    'orderHistory': orderHistory.map((x) => x.toJson()).toList(),
  };

  factory KitchenDetails.fromJson(Map<String, dynamic> json) => KitchenDetails(
    address: json['address'],
    rating: json['rating'],
    menuItems: (json['menuItems'] as List)
        .map((x) => FoodItem.fromJson(x))
        .toList(),
    orderHistory: (json['orderHistory'] as List)
        .map((x) => Order.fromJson(x))
        .toList(),
  );
}

class UserDetails {
  final int tokenBalance;
  final List<TokenTxn> tokenHistory;
  final List<Order> orderHistory;

  UserDetails({
    required this.tokenBalance,
    required this.tokenHistory,
    required this.orderHistory,
  });

  Map<String, dynamic> toJson() => {
    'tokenBalance': tokenBalance,
    'tokenHistory': tokenHistory.map((x) => x.toJson()).toList(),
    'orderHistory': orderHistory.map((x) => x.toJson()).toList(),
  };

  factory UserDetails.fromJson(Map<String, dynamic> json) => UserDetails(
    tokenBalance: json['tokenBalance'],
    tokenHistory: (json['tokenHistory'] as List)
        .map((x) => TokenTxn.fromJson(x))
        .toList(),
    orderHistory: (json['orderHistory'] as List)
        .map((x) => Order.fromJson(x))
        .toList(),
  );
}

class DeliveryDetails {
  final String vehicleNumber;
  final String licenseId;
  final bool isOnline;
  final List<Order> deliveriesCompleted;

  DeliveryDetails({
    required this.vehicleNumber,
    required this.licenseId,
    this.isOnline = false,
    required this.deliveriesCompleted,
  });

  Map<String, dynamic> toJson() => {
    'vehicleNumber': vehicleNumber,
    'licenseId': licenseId,
    'isOnline': isOnline,
    'deliveriesCompleted': deliveriesCompleted.map((x) => x.toJson()).toList(),
  };

  factory DeliveryDetails.fromJson(Map<String, dynamic> json) =>
      DeliveryDetails(
        vehicleNumber: json['vehicleNumber'],
        licenseId: json['licenseId'],
        isOnline: json['isOnline'] ?? false,
        deliveriesCompleted: (json['deliveriesCompleted'] as List)
            .map((x) => Order.fromJson(x))
            .toList(),
      );
}
