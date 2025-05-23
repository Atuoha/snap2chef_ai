import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_cropper/image_cropper.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/enums/record_source.dart';
import '../core/shared/image_picker_helper.dart';
import '../presentation/widgets/image_picker_component.dart';

class ImageUploadController {
  /// crop image
  static Future<void> _cropImage(
    File? selectedFile,
    Function assignCroppedImage,
  ) async {
    if (selectedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: selectedFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: AppColors.primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            statusBarColor: AppColors.primaryColor,
            activeControlsWidgetColor: AppColors.primaryColor,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPresetCustom(),
            ],
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPresetCustom(),
            ],
          ),
        ],
      );
      assignCroppedImage(croppedFile);
    }
  }

  // /// pick image from camera and gallery
  static void imagePicker(
    RecordSource recordSource,
    Completer? completer,
    BuildContext context,
    Function setFile,
    Function assignCroppedImage,
  ) async {
    if (recordSource == RecordSource.gallery) {
      final pickedFile = await ImagePickerHelper.pickImageFromGallery();
      if (pickedFile == null) {
        return;
      }
      completer?.complete(pickedFile.path);
      if (!context.mounted) {
        return;
      }
      setFile(pickedFile);

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } else if (recordSource == RecordSource.camera) {
      final pickedFile = await ImagePickerHelper.takePictureFromCamera();
      if (pickedFile == null) {
        return;
      }

      completer?.complete(pickedFile.path);
      if (!context.mounted) {
        return;
      }
      setFile(pickedFile);
      // crop image
      _cropImage(pickedFile, assignCroppedImage);

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// modal for selecting file source
static  Future showFilePickerButtonSheet(BuildContext context,     Completer? completer,
    Function setFile,
    Function assignCroppedImage,) {
    return showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(35),
          topRight: Radius.circular(35),
        ),
      ),
      context: context,
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 14, 15, 20),
            child: Column(
              children: [
                Container(
                  height: 4,
                  width: 50,
                  padding: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color: const Color(0xffE4E4E4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Align(
                          alignment: Alignment.topRight,
                          child: Icon(Icons.close, color: Colors.grey),
                        ),
                      ),
                      const Gap(10),
                      const Text(
                        'Select Image Source',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(20),
                      ImagePickerTile(
                        title: 'Capture from Camera',
                        subtitle: 'Take a live snapshot',
                        icon: Iconsax.camera,
                        recordSource: RecordSource.camera,
                        completer: completer,
                        context: context,
                        setFile: setFile,
                        assignCroppedImage: assignCroppedImage,




                      ),
                      const Divider(color: Color(0xffE4E4E4)),
                      ImagePickerTile(
                        title: 'Upload from Gallery',
                        subtitle: 'Select image from gallery',
                        icon: Iconsax.gallery,
                        recordSource: RecordSource.gallery,
                        completer: completer,
                        context: context,
                        setFile: setFile,
                        assignCroppedImage: assignCroppedImage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CropAspectRatioPresetCustom implements CropAspectRatioPresetData {
  @override
  (int, int)? get data => (2, 3);

  @override
  String get name => '2x3 (customized)';
}
