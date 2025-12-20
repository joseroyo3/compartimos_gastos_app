import 'package:flutter/material.dart';

import '../../../models/group_model.dart';

class BalanceScreen extends StatelessWidget {
  final GroupModel groupModel;

  const BalanceScreen({super.key, required this.groupModel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_balance_wallet,
              size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          Text("Balance del grupo: ${groupModel.nombre}"),
        ],
      ),
    );
  }
}
