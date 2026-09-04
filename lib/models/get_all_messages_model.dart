class GetAllMessagesModel {
  String? message;
  List<Data>? data;

  GetAllMessagesModel({this.message, this.data});

  GetAllMessagesModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  int? id;
  String? content;
  int? senderId;
  int? recipientId;
  String? createdAt;
  int? isShow;
  int? productId;

  Data({
    this.id,
    this.content,
    this.senderId,
    this.recipientId,
    this.createdAt,
    this.isShow,
    this.productId,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    content = json['content'];
    senderId = json['sender_id'];
    recipientId = json['recipient_id'];
    createdAt = json['created_at']?.toString();
    isShow = json['isShow'];
    productId = json['product_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['content'] = this.content;
    data['sender_id'] = this.senderId;
    data['recipient_id'] = this.recipientId;
    data['created_at'] = this.createdAt;
    data['isShow'] = this.isShow;
    data['product_id'] = this.productId;
    return data;
  }
}
