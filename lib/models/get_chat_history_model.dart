class GetChatHistoryModel {
  String? message;
  List<Data>? data;

  GetChatHistoryModel({this.message, this.data});

  GetChatHistoryModel.fromJson(Map<String, dynamic> json) {
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
  String? name;
  String? image;
  int? count;
  String? lastMessage;
  String? lastMessageTime;
  String? lastInquiryMessage;
  int? lastInquiryRecipientId;

  Data({
    this.id,
    this.name,
    this.image,
    this.count,
    this.lastMessage,
    this.lastMessageTime,
    this.lastInquiryMessage,
    this.lastInquiryRecipientId,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    image = json['image'];
    count = json['count'];
    lastMessage = json['last_message'];
    lastMessageTime = json['last_message_time'];
    lastInquiryMessage = json['last_inquiry_message'];
    lastInquiryRecipientId = json['last_inquiry_recipient_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['image'] = this.image;
    data['count'] = this.count;
    data['last_message'] = this.lastMessage;
    data['last_message_time'] = this.lastMessageTime;
    data['last_inquiry_message'] = this.lastInquiryMessage;
    data['last_inquiry_recipient_id'] = this.lastInquiryRecipientId;
    return data;
  }
}
