import 'package:flutter/material.dart';

class CustomInputDialog extends StatelessWidget {
  final String title;
  final List<Widget> children; // Aquí vna los TextFields
  final String confirmText;
  final VoidCallback onConfirm;
  final bool isLoading;

  const CustomInputDialog({
    super.key,
    required this.title,
    required this.children,
    required this.onConfirm, // LÓGICA
    this.confirmText = 'Guardar',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : onConfirm,
          child: isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(confirmText),
        ),
      ],
    );
  }
}
