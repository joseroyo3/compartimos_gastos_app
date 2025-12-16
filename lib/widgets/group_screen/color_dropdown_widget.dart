import 'package:flutter/material.dart';
import '../../controllers/themes_controller.dart';

class ColorDropdownWidget extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorChanged;

  const ColorDropdownWidget({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<Color>(
      value: selectedColor,
      // Mapeamos tu lista del ThemeController a opciones del menú
      items: ThemeController.groupColors.map((item) {
        return DropdownMenuItem<Color>(
          value: item['color'],
          child: Row(
            children: [
              Icon(Icons.circle, color: item['color'], size: 16),
              const SizedBox(width: 10),
              Text(item['name']),
            ],
          ),
        );
      }).toList(),
      // Cuando cambias la opción, llamamos a la función del padre
      onChanged: (Color? newColor) {
        if (newColor != null) {
          onColorChanged(newColor);
        }
      },
    );
  }
}
