import 'package:flutter/material.dart';

class QueryInputField extends StatelessWidget {
  const QueryInputField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(maxLines: 10, controller: controller);
  }
}
