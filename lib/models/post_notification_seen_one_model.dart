class GetNotificationSeenOneModel {
  int? Id;

  GetNotificationSeenOneModel({this.Id});

  GetNotificationSeenOneModel.fromJson(Map<String, dynamic> json) {
    Id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.Id;
    return data;
  }
}
