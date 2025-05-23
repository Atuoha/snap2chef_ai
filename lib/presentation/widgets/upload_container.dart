import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/app_colors.dart';



class UploadContainer extends StatelessWidget {
  const UploadContainer({
    super.key,
    required this.size,
    required this.title,
  });

  final Size size;
  final String title;

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      color: AppColors.primaryColor,
      radius: const Radius.circular(15),
      borderType: BorderType.RRect,
      strokeWidth: 1,
      child: SizedBox(
        height: size.height * 0.13,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 70,
              width: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.litePrimary,
              ),
              child: Padding(
                padding: const EdgeInsets.all(13.0),
                child: Icon(
                  Iconsax.document_upload,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            const Gap(5),
            RichText(
              text: TextSpan(
                text: 'Click to select ',
                style: TextStyle(
                  color: AppColors.primaryColor,
                ),
                children: [
                  TextSpan(
                    text: title,
                    style: TextStyle(
                      color: Color(0xff555555),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
