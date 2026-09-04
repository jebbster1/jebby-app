class AddFavouriteModel {
  int? userId;
  int? productId;
  int? fav;

  AddFavouriteModel({this.userId, this.productId, this.fav});

  AddFavouriteModel.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    productId = json['product_id'];
    fav = json['fav'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['user_id'] = this.userId;
    data['product_id'] = this.productId;
    data['fav'] = this.fav;
    return data;
  }
}
