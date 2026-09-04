import '../utils/order_status.dart';
import '../utils/rental_date.dart';

class GetAllOrdersByUserIdModel {
  List<Data>? data;
  String? message;

  GetAllOrdersByUserIdModel({this.data, this.message});

  GetAllOrdersByUserIdModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['message'] = this.message;
    return data;
  }
}

class Data {
  int? id;
  int? userId;
  int? productId;
  int? totalPrice;
  String? rentalStartDate;
  String? rentalEndDate;
  String? name;
  String? email;
  String? location;
  var latitude;
  var longitude;
  String? createdAt;
  String? updatedAt;
  String? orderStatus;
  String? completedAt;
  int? vendorId;
  String? productName;
  String? productImage;

  Data({
    this.id,
    this.userId,
    this.productId,
    this.totalPrice,
    this.rentalStartDate,
    this.rentalEndDate,
    this.name,
    this.email,
    this.location,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.orderStatus,
    this.completedAt,
    this.vendorId,
    this.productName,
    this.productImage,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    productId = json['product_id'];
    totalPrice = json['total_price'];
    rentalStartDate = parseRentalDate(json['rental_start_date']);
    rentalEndDate = parseRentalDate(json['rental_end_date']);
    name = json['name'];
    email = json['email'];
    location = json['location'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    orderStatus = OrderStatus.normalize(json['order_status']?.toString());
    completedAt = json['completed_at']?.toString();
    vendorId = json['vendor_id'];
    productName = json['product_name'];
    productImage = json['product_image'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['product_id'] = this.productId;
    data['total_price'] = this.totalPrice;
    data['rental_start_date'] = this.rentalStartDate;
    data['rental_end_date'] = this.rentalEndDate;
    data['name'] = this.name;
    data['email'] = this.email;
    data['location'] = this.location;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['order_status'] = this.orderStatus;
    data['completed_at'] = this.completedAt;
    data['vendor_id'] = this.vendorId;
    data['product_name'] = this.productName;
    data['product_image'] = this.productImage;
    return data;
  }
}
