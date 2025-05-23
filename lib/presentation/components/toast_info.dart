import 'package:fluttertoast/fluttertoast.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/enums/status.dart';

toastInfo({
  required String msg,
  required Status status,

}) {
  return Fluttertoast.showToast(
    msg: msg,
    backgroundColor:
    status == Status.error ? AppColors.errorColor : AppColors.primaryColor,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.TOP,
  );
}
