class GetAllReviewsByVendorId {
  int? status;
  List<Data>? data;
  int? totalreviews;
  String? message;

  GetAllReviewsByVendorId({
    this.status,
    this.data,
    this.totalreviews,
    this.message,
  });

  GetAllReviewsByVendorId.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
    totalreviews = json['totalreviews'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['totalreviews'] = this.totalreviews;
    data['message'] = this.message;
    return data;
  }
}

class Data {
  int? id;
  int? userId;
  int? productId;
  int? stars;
  String? image;
  String? description;
  String? createdAt;
  String? updatedAt;
  int? vendorId;
  String? userName;

  Data({
    this.id,
    this.userId,
    this.productId,
    this.stars,
    this.image,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.vendorId,
    this.userName,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    productId = json['product_id'];
    stars = json['stars'];
    image = json['image'];
    description = json['description'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    vendorId = json['vendor_id'];
    userName = json['user_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['product_id'] = this.productId;
    data['stars'] = this.stars;
    data['image'] = this.image;
    data['description'] = this.description;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['vendor_id'] = this.vendorId;
    data['user_name'] = this.userName;
    return data;
  }
}
