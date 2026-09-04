import 'package:get/get_state_manager/get_state_manager.dart';

class BottomNavController extends GetxController {
  var navigationBarIndexValue = 0;

  Function? onIndexChanged;

  void navBarChange(value) {
    navigationBarIndexValue = value;
    update();

    // Call the callback if defined
    if (onIndexChanged != null) {
      onIndexChanged!(value);
    }
  }
}
