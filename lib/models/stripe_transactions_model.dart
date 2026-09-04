import '../utils/api_datetime.dart';

class StripeTransactionsModel {
  List<StripeTransactionData>? data;
  String? message;
  bool? success;

  StripeTransactionsModel({this.data, this.message, this.success});

  StripeTransactionsModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <StripeTransactionData>[];
      json['data'].forEach((v) {
        data!.add(new StripeTransactionData.fromJson(v));
      });
    }
    message = json['message'];
    success = json['success'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['message'] = this.message;
    data['success'] = this.success;
    return data;
  }
}

class StripeTransactionData {
  String? id;
  double? amount;
  String? currency;
  String? status;
  DateTime? created;
  List<String>? paymentMethodTypes;
  String? productName;
  int? orderId;
  int? totalPrice;
  String? orderStatus;
  String? createdAt;

  StripeTransactionData({
    this.id,
    this.amount,
    this.currency,
    this.status,
    this.created,
    this.paymentMethodTypes,
    this.productName,
    this.orderId,
    this.totalPrice,
    this.orderStatus,
    this.createdAt,
  });

  StripeTransactionData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    amount = json['amount']?.toDouble();
    currency = json['currency'];
    status = json['status'];
    created = json['created'] != null
        ? parseApiDateTime(json['created'].toString())
        : null;
    paymentMethodTypes = json['payment_method_types'] != null 
        ? List<String>.from(json['payment_method_types'])
        : null;
    productName = json['product_name'];
    orderId = json['order_id'];
    totalPrice = json['total_price'];
    orderStatus = json['order_status']?.toString();
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['amount'] = this.amount;
    data['currency'] = this.currency;
    data['status'] = this.status;
    data['created'] = this.created?.toIso8601String();
    data['payment_method_types'] = this.paymentMethodTypes;
    data['product_name'] = this.productName;
    data['order_id'] = this.orderId;
    data['total_price'] = this.totalPrice;
    data['order_status'] = this.orderStatus;
    data['created_at'] = this.createdAt;
    return data;
  }
} 