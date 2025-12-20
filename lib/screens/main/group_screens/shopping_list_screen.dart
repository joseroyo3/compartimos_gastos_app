import 'package:flutter/material.dart';
import '../../../models/group_model.dart';

class ShoppingListScreen extends StatelessWidget {
  final GroupModel groupModel;

  const ShoppingListScreen({super.key, required this.groupModel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          Text("Lista de compra de: ${groupModel.nombre}"),
        ],
      ),
    );
  }
}
