import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jebby/model/sub_category_list_model.dart';

import '../model/categoryList_model.dart';
import '../res/app_url.dart';

class GetAPiFromModel {
  Future<CategoryList> getCategoryList() async {
    final response = await http.get(Uri.parse(AppUrl.categoryGetUrl));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      return CategoryList.fromJson(data);
    } else {
      throw Exception("Error");
    }
  }

  Future<SubCategoryList> getSubCategoryList(String id) async {
    final response = await http.get(Uri.parse(AppUrl.subcategoryGetUrl + id));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      return SubCategoryList.fromJson(data);
    } else {
      throw Exception("Error");
    }
  }
}
