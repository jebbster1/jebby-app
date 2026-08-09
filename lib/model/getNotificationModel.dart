class GetNotificationModel {
  String? message;
  List<Data>? data;
  int? unseen;

  GetNotificationModel({this.message, this.data, this.unseen});

  GetNotificationModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
    unseen = json['unseen'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['unseen'] = this.unseen;
    return data;
  }
}

class Data {
  int? id;
  String? description;
  String? name;
  String? createdAt;
  String? updatedAt;
  int? seen;
  int? userId;
  int? productId;

  Data({
    this.id,
    this.description,
    this.name,
    this.createdAt,
    this.updatedAt,
    this.seen,
    this.userId,
    this.productId,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    description = json['description'];
    name = json['name'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    seen = json['seen'];
    userId = json['user_id'];
    productId = json['product_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['description'] = this.description;
    data['name'] = this.name;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['seen'] = this.seen;
    data['user_id'] = this.userId;
    data['product_id'] = this.productId;
    return data;
  }
}
