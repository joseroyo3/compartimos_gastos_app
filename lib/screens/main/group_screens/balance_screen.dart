import 'package:flutter/material.dart';
import '../../../controllers/pay_controller.dart';
import '../../../models/balance_model.dart';
import '../../../models/group_model.dart';
import '../../../models/pay_model.dart';
import '../../../widgets/appbar_custom.dart';
import '../../../controllers/themes_controller.dart';
import '../../../widgets/responsive_list_container.dart';
import 'settings_group_screen.dart';

class BalanceScreen extends StatelessWidget {
  final GroupModel groupModel;

  BalanceScreen({super.key, required this.groupModel});

  // Reutilizamos el mismo controlador que ya tiene la lógica de balances
  final PayController _payController = PayController();

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Theme(
      data: ThemeController.crearTema(primaryColor),
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Balance',
          showLogout: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Ajustes',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SettingsGroupScreen(groupModel: groupModel),
                  ),
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          mini: true,
          tooltip: "Recalcular balances",
          onPressed: () => _payController.recalcularTodoElGrupo(groupModel.id),
          child: const Icon(Icons.refresh),
        ),
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

            // Ordenar alfabéticamente por el nombre de quien debe (deudor)
            balances.sort((a, b) {
              final nombreA = _obtenerNombre(a.deudorId).toLowerCase();
              final nombreB = _obtenerNombre(b.deudorId).toLowerCase();
              return nombreA.compareTo(nombreB);
            });

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          "Pagos pendientes para cuadrar cuentas",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                      // Lista de Balances
                      ...balances.map((b) => _buildBalanceCard(b, primaryColor)),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 10),

                      // SECCIÓN GASTOS INDIVIDUALES
                      _buildGastosIndividualesSection(primaryColor),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Widget para cuando no hay deudas -------------------------
  Widget _buildEmptyState(Color color) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 80, color: color.withOpacity(0.5)),
                const SizedBox(height: 15),
                Text(
                  "¡Cuentas saldadas!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 5),
                const Text("Nadie debe nada a nadie."),
              ],
            ),
          ),
        ),
        const Divider(),
        _buildGastosIndividualesSection(color),
        const SizedBox(height: 30),
      ],
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

            // Acreedor (Derecha)
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

  // Sección de gastos que NO generan deuda (individuales)
  Widget _buildGastosIndividualesSection(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.person_pin_circle_outlined, color: color, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Gastos Individuales",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Suma de gastos personales que no generan deuda.",
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<PayModel>>(
          stream: _payController.obtenerPagosDelGrupo(groupModel.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                    child: Text("Sin gastos individuales",
                        style: TextStyle(fontSize: 12, color: Colors.grey))),
              );
            }

            final pagos = snapshot.data!;
            final Map<String, double> totales = {};

            // Inicializar todos los miembros a 0
            for (var uid in groupModel.miembros.keys) {
              totales[uid] = 0;
            }

            // Sumar solo si es individual (un solo involucrado y es el pagador)
            for (var p in pagos) {
              if (p.distribucion.length == 1 &&
                  p.distribucion.containsKey(p.idPagador)) {
                totales[p.idPagador] = (totales[p.idPagador] ?? 0) + p.cantidad;
              }
            }

            // Filtrar y ordenar los que tienen algo (o mostrar todos si se prefiere)
            final listaTotales = totales.entries.where((e) => e.value > 0).toList();
            listaTotales.sort((a, b) => b.value.compareTo(a.value));

            if (listaTotales.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                    child: Text("No hay gastos registrados como individuales",
                        style: TextStyle(fontSize: 12, color: Colors.grey))),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 0,
                color: color.withOpacity(0.03),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: color.withOpacity(0.1))),
                child: Column(
                  children: listaTotales.map((entry) {
                    final nombre = _obtenerNombre(entry.key);
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: color.withOpacity(0.1),
                        child: Text(nombre[0].toUpperCase(),
                            style: TextStyle(fontSize: 10, color: color)),
                      ),
                      title: Text(nombre,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      trailing: Text(
                        "${entry.value.toStringAsFixed(2)} €",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.grey[700]),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Helper para saca las iniciales
  String _getInitials(String name) {
    if (name.isEmpty) return "";
    List<String> parts = name.trim().split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
