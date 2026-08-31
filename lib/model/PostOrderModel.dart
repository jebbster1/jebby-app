import '../utils/rental_date.dart';

class PostOrderModel {
  int? userId;
  int? productId;
  int? orderId;
  String? orderStatus;
  String? rentalStartDate;
  String? rentalEndDate;
  String? location;
  int? latitude;
  int? longitude;
  String? CurrentAddress;

  PostOrderModel({
    this.userId,
    this.productId,
    this.rentalStartDate,
    this.rentalEndDate,
    this.location,
    this.latitude,
    this.longitude,
  });

  PostOrderModel.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    productId = json['product_id'];
    rentalStartDate = parseRentalDate(json['rental_start_date']);
    rentalEndDate = parseRentalDate(json['rental_end_date']);
    location = json['location'];
    latitude = json['latitude'];
    longitude = json['longitude'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['user_id'] = this.userId;
    data['product_id'] = this.productId;
    data['rental_start_date'] = this.rentalStartDate;
    data['rental_end_date'] = this.rentalEndDate;
    data['location'] = this.location;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    return data;
  }
}
