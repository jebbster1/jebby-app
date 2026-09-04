class PostlMessagesModel {
  String? content;
  int? senderId;
  int? recipientId;

  PostlMessagesModel({this.content, this.senderId, this.recipientId});

  PostlMessagesModel.fromJson(Map<String, dynamic> json) {
    content = json['content'];
    senderId = json['sender_id'];
    recipientId = json['recipient_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['content'] = this.content;
    data['sender_id'] = this.senderId;
    data['recipient_id'] = this.recipientId;
    return data;
  }
}
