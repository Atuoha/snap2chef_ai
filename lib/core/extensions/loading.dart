import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';

extension LoaderOverlayExtension on BuildContext {
  void showLoader() {
    loaderOverlay.show();
  }

  void hideLoader() {
    loaderOverlay.hide();
  }
}