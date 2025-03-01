class Order {
  final String id;
  final int orderPK;
  final String? deliveryBoy;
  final String deliveryStatus;
  final List<Item> items;
  final int onlineReferenceNo;
  final int ordTimestamp;
  final String paymentMode;
  final String shippingAddress1;
  final String shippingName;
  final String shippingPhone;
  final String shippingPincode;
  final int totalAmount;
  final int totalQuantity;
  final String createdAt;
  final String updatedAt;
  final Timeline? timeline; // New field

  Order({
    required this.id,
    required this.orderPK,
    this.deliveryBoy,
    required this.deliveryStatus,
    required this.items,
    required this.onlineReferenceNo,
    required this.ordTimestamp,
    required this.paymentMode,
    required this.shippingAddress1,
    required this.shippingName,
    required this.shippingPhone,
    required this.shippingPincode,
    required this.totalAmount,
    required this.totalQuantity,
    required this.createdAt,
    required this.updatedAt,
    this.timeline, // New field
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'],
      orderPK: json['orderPK'],
      deliveryBoy: json['deliveryBoy'],
      deliveryStatus: json['deliveryStatus'],
      items: (json['items'] as List).map((item) => Item.fromJson(item)).toList(),
      onlineReferenceNo: json['onlineReferenceNo'],
      ordTimestamp: json['ordTimestamp'],
      paymentMode: json['paymentMode'],
      shippingAddress1: json['shippingAddress1'] ?? "",
      shippingName: json['shippingName'] ?? "",
      shippingPhone: json['shippingPhone'] ?? "",
      shippingPincode: json['shippingPincode'] ?? "",
      totalAmount: json['totalAmount'],
      totalQuantity: json['totalQuantity'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      timeline: json['timeline'] != null ? Timeline.fromJson(json['timeline']) : null,
    );
  }
}

class Item {
  final String name;
  final int quantity;
  final double price;

  Item({
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      name: json['name'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
    );
  }
}

// New Timeline class
class Timeline {
  final String acceptedAt;

  Timeline({required this.acceptedAt});

  factory Timeline.fromJson(Map<String, dynamic> json) {
    return Timeline(acceptedAt: json['acceptedAt']);
  }
}
