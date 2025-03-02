class Order {
  final String id;
  final int orderPK;
  final String deliveryBoy;
  final String deliveryStatus;
  final List<Item> items;
  final int onlineReferenceNo;
  final int ordTimestamp;
  final String paymentMode;
  final String shippingAddress1;
  final String shippingName;
  final String shippingPhone;
  final String shippingPincode;
  final num totalAmount;
  final num totalQuantity;
  final String createdAt;
  // final String updatedAt;
  final Timeline timeline;

  Order({
    required this.id,
    required this.orderPK,
    required this.deliveryBoy,
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
    // required this.updatedAt,
    required this.timeline,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] ?? "",
      orderPK: json['orderPK'] ?? 0,
      deliveryBoy: json['deliveryBoy'] ?? "",
      deliveryStatus: json['deliveryStatus'] ?? "",
      items: (json['items'] as List?)?.map((item) => Item.fromJson(item)).toList() ?? [],
      onlineReferenceNo: json['onlineReferenceNo'] ?? 0,
      ordTimestamp: json['ordTimestamp'] ?? 0,
      paymentMode: json['paymentMode'] ?? "",
      shippingAddress1: json['shippingAddress1'] ?? "",
      shippingName: json['shippingName'] ?? "",
      shippingPhone: json['shippingPhone'] ?? "",
      shippingPincode: json['shippingPincode'] ?? "",
      totalAmount: json['totalAmount'] ?? 0,
      totalQuantity: json['totalQuantity'] ?? 0,
      createdAt: json['createdAt'] ?? "",
      // updatedAt: json['updatedAt'] ?? "",
      timeline: json['timeline'] != null ? Timeline.fromJson(json['timeline']) : Timeline(acceptedAt: ""),
    );
  }
}

class Item {
  final String name;
  final num quantity;
  final num price;

  Item({
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      name: json['name'] ?? "",
      quantity: json['quantity'] ?? 0,
      price: json['price'] ?? 0.0,
    );
  }
}

// Updated Timeline class to return empty values
class Timeline {
  final String acceptedAt;

  Timeline({required this.acceptedAt});

  factory Timeline.fromJson(Map<String, dynamic> json) {
    return Timeline(acceptedAt: json['acceptedAt'] ?? "");
  }
}
