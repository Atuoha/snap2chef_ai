import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class QueryTextBox extends StatelessWidget {
  const QueryTextBox({
    super.key,
    required TextEditingController query,
  }) : _query = query;

  final TextEditingController _query;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _query,
      maxLines: 4,
      autofocus: true,
      decoration: InputDecoration(
        hintStyle: TextStyle(color: AppColors.lighterGrey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(
            color: AppColors.primaryColor,
            width: 2.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 16.0,
        ),
      ),
      style: const TextStyle(
        fontSize: 14.0,
        color: Colors.black,
      ),
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
    );
  }
}
