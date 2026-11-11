import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final String title;
  final List<String> items;
  final String? value;
  final ValueChanged<String?>? onChanged; // null = dropdown nonaktif

  // Opsional, dipakai form pendaftaran
  final String? hint;
  final String? Function(String?)? validator;
  final IconData? icon;

  const CustomDropdown({
    super.key,
    required this.title,
    required this.items,
    this.value,
    this.onChanged,
    this.hint,
    this.validator,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool aktif = onChanged != null;

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      hint: hint == null ? null : Text(hint!, overflow: TextOverflow.ellipsis),
      validator: validator,
      decoration: InputDecoration(
        labelText: title,
        prefixIcon: icon == null ? null : Icon(icon),
        filled: true,
        fillColor: aktif ? Colors.white : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}