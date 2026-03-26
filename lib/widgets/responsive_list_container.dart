import 'package:flutter/material.dart';

class ResponsiveListContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveListContainer({
    super.key,
    required this.child,
    this.maxWidth = 700,
  });

  @override
  Widget build(BuildContext context) {
    // Si el ancho es mayor que el maxWidth, lo centramos y le damos un aire de "tarjeta"
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > maxWidth;

    if (!isLargeScreen) return child;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: child,
          ),
        ),
      ),
    );
  }
}
