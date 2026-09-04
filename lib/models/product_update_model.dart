class ProductUpdateModel {
  int? userId;
  int? categoryId;
  int? subcategoryId;
  String? name;
  int? price;
  String? specifications;
  String? description;
  int? id;

  ProductUpdateModel({
    this.userId,
    this.categoryId,
    this.subcategoryId,
    this.name,
    this.price,
    this.specifications,
    this.description,
    this.id,
  });

  ProductUpdateModel.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    categoryId = json['category_id'];
    subcategoryId = json['subcategory_id'];
    name = json['name'];
    price = json['price'];
    specifications = json['specifications'];
    description = json['description'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['user_id'] = this.userId;
    data['category_id'] = this.categoryId;
    data['subcategory_id'] = this.subcategoryId;
    data['name'] = this.name;
    data['price'] = this.price;
    data['specifications'] = this.specifications;
    data['description'] = this.description;
    data['id'] = this.id;
    return data;
  }
}
