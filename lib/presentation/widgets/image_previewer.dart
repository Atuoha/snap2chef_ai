import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snap2chef/infrastructure/image_upload_controller.dart';

class ImagePreviewer extends StatelessWidget {
  const ImagePreviewer({
    super.key,
    required this.size,
    required this.pickedFile,
    required this.removeFile,
    required this.context,
    required this.completer,
    required this.setFile,
    required this.assignCroppedImage,
  });

  final Size size;
  final File? pickedFile;
  final Function removeFile;
 final BuildContext context;
  final Completer? completer;
  final Function setFile;
  final Function assignCroppedImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size.height * 0.13,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        // border: Border.all(
        //   color: AppColors.borderColor,
        // ),
        image: DecorationImage(
          image: FileImage(
            File(pickedFile!.path),
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          // Centered content
          Center(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 20,
              children: [
                GestureDetector(
                  onTap: () {
                    ImageUploadController.showFilePickerButtonSheet(context,completer,setFile,assignCroppedImage);
                  },
                  child: Column(
                    children: [
                      Icon(
                        Iconsax.edit_2,
                        size: 20,
                        color: Colors.white,
                      ),
                      const Text(
                        'Edit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      )
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    removeFile();
                  },
                  child: Column(
                    children: [
                      Icon(
                        Iconsax.note_remove,
                        color: Colors.white,
                        size: 20,
                      ),
                      const Text(
                        'Remove',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}