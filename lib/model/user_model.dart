class UserModel {
  int? status;
  String? name;
  String? email;
  String? phoneNumber;
  String? address;
  String? id;
  String? role;
  String? source;
  String? token;
  bool? isGuest;

  UserModel({
    this.status,
    this.name,
    this.email,
    this.address,
    this.id,
    this.role,
    this.source,
    this.token,
    this.isGuest = false,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['name'] = this.name;
    data['email'] = this.email;
    data['address'] = this.address;
    data['id'] = this.id;
    data['role'] = this.role;
    data['source'] = this.source;
    data['token'] = this.token;
    data['isGuest'] = this.isGuest;
    return data;
  }
}

class UpdatedModel {
  int? status;
  List<Data>? data;
  String? message;

  UpdatedModel({this.status, this.data, this.message});

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
  String? id;
  String? profileImage;
  String? name;
  String? email;
  String? phoneNumber;
  String? address;
  String? userId;
  String? latitude;
  String? longitude;

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
    return data;
  }
}
