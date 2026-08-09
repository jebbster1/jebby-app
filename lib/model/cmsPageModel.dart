class CmsPageModel {
  int? status;
  List<CmsPageData>? data;
  String? message;

  CmsPageModel({this.status, this.data, this.message});

  CmsPageModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['data'] != null) {
      data = <CmsPageData>[];
      json['data'].forEach((v) {
        data!.add(CmsPageData.fromJson(v));
      });
    }
    message = json['message'];
  }
}

class CmsPageData {
  int? id;
  String? slug;
  String? title;
  String? description;
  String? createdAt;
  String? updatedAt;

  CmsPageData({
    this.id,
    this.slug,
    this.title,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  CmsPageData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    slug = json['slug'];
    title = json['title'];
    description = json['description'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
}
