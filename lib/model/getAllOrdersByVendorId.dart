class GetAllOrderByVendorIdModel {
  List<Data>? data;
  String? message;

  GetAllOrderByVendorIdModel({this.data, this.message});

  GetAllOrderByVendorIdModel.fromJson(Map<String, dynamic> json) {
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
  String? rentStart;
  String? originalReturn;
  String? name;
  String? email;
  String? location;
  int? latitude;
  int? longitude;
  String? createdAt;
  String? updatedAt;
  int? status;
  int? vendorId;
  String? approveDate;
  String? completeDate;
  String? cancelDate;

  Data({
    this.id,
    this.userId,
    this.productId,
    this.totalPrice,
    this.rentStart,
    this.originalReturn,
    this.name,
    this.email,
    this.location,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.status,
    this.vendorId,
    this.approveDate,
    this.completeDate,
    this.cancelDate,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    productId = json['product_id'];
    totalPrice = json['total_price'];
    rentStart = json['rent_start'];
    originalReturn = json['original_return'];
    name = json['name'];
    email = json['email'];
    location = json['location'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    status = json['status'];
    vendorId = json['vendor_id'];
    approveDate = json['approve_date'];
    completeDate = json['complete_date'];
    cancelDate = json['cancel_date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['product_id'] = this.productId;
    data['total_price'] = this.totalPrice;
    data['rent_start'] = this.rentStart;
    data['original_return'] = this.originalReturn;
    data['name'] = this.name;
    data['email'] = this.email;
    data['location'] = this.location;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['status'] = this.status;
    data['vendor_id'] = this.vendorId;
    data['approve_date'] = this.approveDate;
    data['complete_date'] = this.completeDate;
    data['cancel_date'] = this.cancelDate;
    return data;
  }
}
