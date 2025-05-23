import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:snap2chef/core/extensions/to_file.dart';
import 'package:snap2chef/core/extensions/to_file2.dart';
import '../../presentation/components/toast_info.dart';
import '../constants/enums/status.dart';

@immutable
class ImagePickerHelper {
  static final ImagePicker _imagePicker = ImagePicker();

  static Future<PickedFileWithInfo?> pickImageFromGallery2() async {
    final isGranted = await Permission.photos.isGranted;
    if (!isGranted) {
      await Permission.photos.request();
      toastInfo(
          msg: "You didn't allow access", status: Status.error);
    }
    final pickedFile =
    await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = await pickedFile.toFile();
      log(pickedFile.name.split(".").join(","));
      return PickedFileWithInfo(file: file, fileName: pickedFile.name);
    } else {
      return null;
    }
  }

  static Future<FilePickerResult?> pickFileFromGallery() =>
      FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ["pdf", "doc", "docx", "png", "jpg", "jpeg"]);

  static Future<File?> pickImageFromGallery() =>
      _imagePicker.pickImage(source: ImageSource.gallery).toFile();

  static Future<File?> takePictureFromCamera() =>
      _imagePicker.pickImage(source: ImageSource.camera).toFile();

  static Future<File?> pickVideoFromGallery() =>
      _imagePicker.pickVideo(source: ImageSource.gallery).toFile();

  static Future<FilePickerResult?> pickSinglePDFFileFromGallery() =>
      FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ["pdf"]);
}

class PickedFileWithInfo {
  final File file;
  final String fileName;

  PickedFileWithInfo({required this.file, required this.fileName});
}

PlatformFile? file;
