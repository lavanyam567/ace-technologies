import 'product_model.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
}

class OrderItem {
  final String? orderItemId;
  final Product product;
  final String? _productId;
  final int quantity;
  final double price;

  OrderItem({
    this.orderItemId,
    required this.product,
    String? productId,
    required this.quantity,
    required this.price,
  }) : _productId = productId;

  double get totalPrice => price * quantity;

  String get id => product.id;
  String get productId => _productId ?? product.id;
  String get name => product.name;
  String get image => product.image;
  String get category => product.category;

  factory OrderItem.fromSupabase(Map<String, dynamic> json) {
    final productJson = json['products'] as Map<String, dynamic>?;
    final product = productJson != null
        ? Product.fromSupabase(productJson)
        : Product(
            id: json['product_id'] as String? ?? '',
            name: 'Product unavailable',
            brand: '',
            price: (json['price'] as num? ?? 0).toDouble(),
            rating: 0,
            image: '',
            category: '',
          );

    return OrderItem(
      orderItemId: json['id'] as String?,
      product: product,
      productId: json['product_id'] as String? ?? product.id,
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num? ?? 0).toDouble(),
    );
  }
}

class Order {
  final String id;
  final List<OrderItem> items;
  final Address? shippingAddress;
  final OrderStatus status;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final double totalAmount;
  final String? trackingNumber;
  final String paymentMethod;
  final String paymentStatus;
  final String? paymentReference;
  final String? addressId;

  const Order({
    required this.id,
    required this.items,
    required this.shippingAddress,
    required this.status,
    required this.orderDate,
    this.deliveryDate,
    required this.totalAmount,
    this.trackingNumber,
    this.paymentMethod = 'Credit Card',
    this.paymentStatus = 'pending',
    this.paymentReference,
    this.addressId,
  });

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  Order copyWith({
    String? id,
    List<OrderItem>? items,
    Address? shippingAddress,
    OrderStatus? status,
    DateTime? orderDate,
    DateTime? deliveryDate,
    double? totalAmount,
    String? trackingNumber,
    String? paymentMethod,
    String? paymentStatus,
    String? paymentReference,
    String? addressId,
  }) {
    return Order(
      id: id ?? this.id,
      items: items ?? this.items,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      status: status ?? this.status,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      totalAmount: totalAmount ?? this.totalAmount,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentReference: paymentReference ?? this.paymentReference,
      addressId: addressId ?? this.addressId,
    );
  }

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  factory Order.fromSupabase(Map<String, dynamic> json) {
    final rawItems = json['order_items'] as List<dynamic>? ?? const [];

    return Order(
      id: json['id'] as String,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(OrderItem.fromSupabase)
          .toList(),
      shippingAddress: null,
      status: orderStatusFromSupabase(json['status'] as String?),
      orderDate:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      totalAmount: (json['total_amount'] as num? ?? 0).toDouble(),
      trackingNumber: json['tracking_number'] as String?,
      paymentMethod: json['payment_method'] as String? ?? 'Unknown',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      paymentReference: json['payment_reference'] as String?,
      addressId: json['address_id'] as String?,
    );
  }
}

OrderStatus orderStatusFromSupabase(String? status) {
  return OrderStatus.values.firstWhere(
    (value) => value.name == status,
    orElse: () => OrderStatus.pending,
  );
}

String orderStatusToSupabase(OrderStatus status) => status.name;

class Address {
  final String id;
  final String name;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;
  final String? label;
  final String? street;
  final String? type;

  const Address({
    required this.id,
    required this.name,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
    this.label,
    this.street,
    this.type,
  });

  String get fullAddress =>
      '$addressLine1${addressLine2 != null ? ', $addressLine2' : ''}, $city, $state - $pincode';

  factory Address.fromSupabase(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      addressLine1: json['address_line1'] as String? ?? '',
      addressLine2: json['address_line2'] as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
      label: json['label'] as String?,
      street: json['address_line1'] as String?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'name': name,
      'phone': phone,
      'address_line1': street ?? addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'label': label,
      'type': type,
      'is_default': isDefault,
    };
  }

  Address copyWith({
    String? id,
    String? name,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? pincode,
    bool? isDefault,
    String? label,
    String? street,
    String? type,
  }) {
    return Address(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      isDefault: isDefault ?? this.isDefault,
      label: label ?? this.label,
      street: street ?? this.street,
      type: type ?? this.type,
    );
  }
}
