import 'package:flutter/material.dart';
import '../../../controllers/pay_controller.dart';
import '../../../models/balance_model.dart';
import '../../../models/group_model.dart';

class BalanceScreen extends StatelessWidget {
  final GroupModel groupModel;

  BalanceScreen({super.key, required this.groupModel});

  // Reutilizamos el mismo controlador que ya tiene la lógica de balances
  final PayController _payController = PayController();

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: StreamBuilder<List<BalanceModel>>(
        stream: _payController.obtenerBalancesDelGrupo(groupModel.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(primaryColor);
          }

          final balances = snapshot.data!;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Pagos pendientes para cuadrar cuentas",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              // Lista de Balances
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: balances.length,
                  itemBuilder: (context, index) {
                    final balance = balances[index];
                    return _buildBalanceCard(balance, primaryColor);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // idget para cuando no hay deudas -------------------------
  Widget _buildEmptyState(Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline,
              size: 100, color: color.withOpacity(0.5)),
          const SizedBox(height: 20),
          Text(
            "¡Cuentas saldadas!",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          const Text("Nadie debe nada a nadie en este grupo."),
        ],
      ),
    );
  }

  // Tarjeta individual de Deuda ----------------------------
  Widget _buildBalanceCard(BalanceModel balance, Color color) {
    final nombreDeudor = _obtenerNombre(balance.deudorId);
    final nombreAcreedor = _obtenerNombre(balance.acreedorId);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            // DEUDOR (Izquierda)
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.red[100],
                    child: Text(
                      _getInitials(nombreDeudor),
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nombreDeudor,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // FLECHA Y CANTIDAD (Centro)
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    "paga a",
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  // Flecha decorativa
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                          height: 2,
                          color: Colors.grey[300],
                          width: double.infinity),
                      Icon(Icons.arrow_forward,
                          color: Colors.grey[400], size: 16),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Precio Grande
                  Text(
                    "${balance.cantidad.toStringAsFixed(2)} €",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),

            // ACREEDOR (Derecha)
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Text(
                      _getInitials(nombreAcreedor),
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nombreAcreedor,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper para obtener nombres desde el Mapa del Modelo
  String _obtenerNombre(String uid) {
    if (groupModel.miembros.containsKey(uid)) {
      return groupModel.miembros[uid]!;
    }
    return "Usuario";
  }

  // Helper para sacar las iniciales
  String _getInitials(String name) {
    if (name.isEmpty) return "";
    List<String> parts = name.trim().split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
