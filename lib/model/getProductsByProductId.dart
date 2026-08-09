class GetProductsByProductId {
  int? status;
  List<Data>? data;
  String? message;

  GetProductsByProductId({this.status, this.data, this.message});

  GetProductsByProductId.fromJson(Map<String, dynamic> json) {
    status = json['status'];
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
    data['status'] = this.status;
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
  int? categoryId;
  int? subcategoryId;
  String? name;
  int? price;
  String? specifications;
  String? description;
  String? createdAt;
  String? updatedAt;
  String? stars;
  String? length;
  int? productId;
  int? isDelivery;
  String? availableFrom;
  String? availableTo;
  String? address;
  var latitude;
  var longitude;
  int? security_deposit;
  List<Images>? images;
  String? delivery_charges;

  Data({
    this.id,
    this.userId,
    this.categoryId,
    this.subcategoryId,
    this.name,
    this.price,
    this.specifications,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.stars,
    this.length,
    this.productId,
    this.isDelivery,
    this.availableFrom,
    this.availableTo,
    this.address,
    this.latitude,
    this.longitude,
    this.security_deposit,
    this.images,
    this.delivery_charges,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    categoryId = json['category_id'];
    subcategoryId = json['subcategory_id'];
    name = json['name'];
    price = json['price'];
    specifications = json['specifications'];
    description = json['description'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    stars = json['stars'];
    length = json['length'];
    productId = json['product_id'];
    isDelivery = json['is_delivery'];
    availableFrom = json['available_from'];
    availableTo = json['available_to'];
    address = json['address']?.toString();
    latitude = json['latitude'];
    longitude = json['longitude'];
    security_deposit = json['security_deposit'];
    if (json['images'] != null) {
      images = <Images>[];
      final rawImages = json['images'];
      if (rawImages is List) {
        for (var i = 0; i < rawImages.length; i++) {
          final v = rawImages[i];
          if (v is String) {
            images!.add(Images(id: i, path: v));
          } else if (v is Map<String, dynamic>) {
            images!.add(Images.fromJson(v));
          } else if (v is Map) {
            images!.add(Images.fromJson(Map<String, dynamic>.from(v)));
          }
        }
      }
    }
    delivery_charges = json['delivery_charges']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['category_id'] = this.categoryId;
    data['subcategory_id'] = this.subcategoryId;
    data['name'] = this.name;
    data['price'] = this.price;
    data['specifications'] = this.specifications;
    data['description'] = this.description;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['stars'] = this.stars;
    data['length'] = this.length;
    data['product_id'] = this.productId;
    data['is_delivery'] = this.isDelivery;
    data['available_from'] = this.availableFrom;
    data['available_to'] = this.availableTo;
    data['address'] = this.address;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['security_deposit'] = this.security_deposit;
    if (this.images != null) {
      data['images'] = this.images!.map((v) => v.toJson()).toList();
    }
    data['delivery_charges'] = this.delivery_charges;
    return data;
  }
}

class Images {
  int? id;
  int? productId;
  String? path;
  String? createdAt;
  String? updatedAt;

  Images({this.id, this.productId, this.path, this.createdAt, this.updatedAt});

  Images.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    productId = json['product_id'];
    path = json['path'];
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['product_id'] = this.productId;
    data['path'] = this.path;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
