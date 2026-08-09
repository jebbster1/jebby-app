class GetUserCredentialModel {
  var status;
  List<Data>? data;
  String? message;

  GetUserCredentialModel({this.status, this.data, this.message});

  GetUserCredentialModel.fromJson(Map<String, dynamic> json) {
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
  var id;
  String? profileImage;
  String? name;
  String? email;
  String? phoneNumber;
  String? address;
  var userId;
  var latitude;
  var longitude;
  String? coverImage;
  String? stripeEmail;
  String? stripeAccountType;
  String? accountId;

  Data({
    this.id,
    this.profileImage,
    this.name,
    this.email,
    this.phoneNumber,
    this.address,
    this.userId,
    this.latitude,
    this.longitude,
    this.coverImage,
    this.stripeEmail,
    this.stripeAccountType,
    this.accountId,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    profileImage = json['profile_image'];
    name = json['name'];
    email = json['email'];
    phoneNumber = json['phone_number'];
    address = json['address'];
    userId = json['user_id'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    coverImage = json['cover_image'];
    stripeEmail = json['stripe_email'];
    stripeAccountType = json['stripe_account_type'];
    accountId = json['account_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['profile_image'] = this.profileImage;
    data['name'] = this.name;
    data['email'] = this.email;
    data['phone_number'] = this.phoneNumber;
    data['address'] = this.address;
    data['user_id'] = this.userId;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['cover_image'] = this.coverImage;
    data['stripe_email'] = this.stripeEmail;
    data['stripe_account_type'] = this.stripeAccountType;
    data['account_id'] = this.accountId;
    return data;
  }
}
