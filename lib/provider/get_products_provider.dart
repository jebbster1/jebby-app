import 'package:flutter/material.dart';
import '../Services/product_services.dart';

class ProductProvider extends ChangeNotifier {
  var data;
  getProduct(id) async {
    debugPrint("Start");

    data = await ProductServices().getProducts(id);

    notifyListeners();
    debugPrint("running");
  }

  fetchproducts()
  {
    notifyListeners();
    return data;
  }

}
