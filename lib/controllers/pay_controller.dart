import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pay_model.dart' show PayModel;
import '../models/balance_model.dart';
import '../models/group_model.dart';

class PayController {
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  // CREAR PAGO Y ACTUALIZAR BALANCES CENTRALIZADOS
  Future<void> crearPago(String groupId, PayModel pago) async {
    final groupRef = firestore.collection('grupos').doc(groupId);
    final paymentsRef = groupRef.collection('pagos');

    await firestore.runTransaction((transaction) async {
      // 1. Obtener datos actuales del grupo
      final groupSnap = await transaction.get(groupRef);
      if (!groupSnap.exists) return;

      final GroupModel group = GroupModel.fromFirestore(groupSnap);
      Map<String, double> nuevosNetos = Map.from(group.netos);

      // 2. Guardar el Pago
      final newPaymentDoc = paymentsRef.doc();
      transaction.set(newPaymentDoc, pago.toMap());

      // 3. ACTUALIZAR NETOS
      // Al que paga le sumamos el total
      nuevosNetos[pago.idPagador] =
          (nuevosNetos[pago.idPagador] ?? 0) + pago.cantidad;

      // A cada participante le restamos su parte
      pago.distribucion.forEach((uid, cantidadQueDebe) {
        nuevosNetos[uid] = (nuevosNetos[uid] ?? 0) - cantidadQueDebe;
      });

      // 4. Simplificar deudas a partir de los nuevos netos
      List<BalanceModel> nuevosBalances = _calcularSimplificacion(nuevosNetos);

      // 5. Guardar todo en el documento del grupo
      transaction.update(groupRef, {
        'netos': nuevosNetos,
        'balancesSimplificados': nuevosBalances.map((b) => b.toMap()).toList(),
      });
    });
  }

  // ELIMINAR PAGO Y REVERTIR NETOS
  Future<void> eliminarPago(String groupId, PayModel pago) async {
    final groupRef = firestore.collection('grupos').doc(groupId);
    final pagoRef = groupRef.collection('pagos').doc(pago.id);

    await firestore.runTransaction((transaction) async {
      // 1. Obtener datos actuales
      final groupSnap = await transaction.get(groupRef);
      if (!groupSnap.exists) return;

      final GroupModel group = GroupModel.fromFirestore(groupSnap);
      Map<String, double> nuevosNetos = Map.from(group.netos);

      // 2. Eliminar el pago
      transaction.delete(pagoRef);

      // 3. REVERTIR NETOS
      // Al que pagó le restamos (porque ya no puso ese dinero)
      nuevosNetos[pago.idPagador] =
          (nuevosNetos[pago.idPagador] ?? 0) - pago.cantidad;

      // A los participantes les devolvemos su parte (sumamos)
      pago.distribucion.forEach((uid, cantidadQueDebia) {
        nuevosNetos[uid] = (nuevosNetos[uid] ?? 0) + cantidadQueDebia;
      });

      // 4. Recalcular
      List<BalanceModel> nuevosBalances = _calcularSimplificacion(nuevosNetos);

      // 5. Actualizar grupo
      transaction.update(groupRef, {
        'netos': nuevosNetos,
        'balancesSimplificados': nuevosBalances.map((b) => b.toMap()).toList(),
      });
    });
  }

  // Algoritmo de simplificación puro (sin efectos secundarios de DB)
  List<BalanceModel> _calcularSimplificacion(Map<String, double> netos) {
    List<MapEntry<String, double>> deudores = [];
    List<MapEntry<String, double>> acreedores = [];

    netos.forEach((uid, amount) {
      if (amount.abs() < 0.01) return;
      if (amount < 0) {
        deudores.add(MapEntry(uid, amount));
      } else {
        acreedores.add(MapEntry(uid, amount));
      }
    });

    deudores.sort((a, b) => a.value.compareTo(b.value));
    acreedores.sort((a, b) => b.value.compareTo(a.value));

    List<BalanceModel> resultado = [];
    int i = 0;
    int j = 0;

    // Copias para no mutar las listas originales durante el matching
    List<MapEntry<String, double>> d = List.from(deudores);
    List<MapEntry<String, double>> a = List.from(acreedores);

    while (i < d.length && j < a.length) {
      double debit = d[i].value.abs();
      double credit = a[j].value;

      double amount = (debit < credit) ? debit : credit;
      amount = (amount * 100).roundToDouble() / 100;

      if (amount > 0.009) {
        resultado.add(BalanceModel(
          id: '',
          deudorId: d[i].key,
          acreedorId: a[j].key,
          cantidad: amount,
        ));
      }

      double newDebit = debit - amount;
      double newCredit = credit - amount;

      if (newDebit < 0.009) {
        i++;
      } else {
        d[i] = MapEntry(d[i].key, -newDebit);
      }

      if (newCredit < 0.009) {
        j++;
      } else {
        a[j] = MapEntry(a[j].key, newCredit);
      }
    }
    return resultado;
  }

  // LEER PAGOS CON STREAM
  Stream<List<PayModel>> obtenerPagosDelGrupo(String groupId) {
    return firestore
        .collection('grupos')
        .doc(groupId)
        .collection('pagos')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PayModel.fromFirestore(doc)).toList();
    });
  }

  // LEER BALANCES CON STREAM (Ahora lee del documento del grupo)
  Stream<List<BalanceModel>> obtenerBalancesDelGrupo(String groupId) {
    return firestore.collection('grupos').doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return [];
      return GroupModel.fromFirestore(doc).balances;
    });
  }

  Map<String, double> calcularDistribucion(
      double total, List<String> participantesIds) {
    if (participantesIds.isEmpty) return {};

    int n = participantesIds.length;
    double cuotaBase = (total / n * 100).floorToDouble() / 100;

    Map<String, double> distribucion = {};
    double sumaAcumulada = 0;

    for (var id in participantesIds) {
      distribucion[id] = cuotaBase;
      sumaAcumulada += cuotaBase;
    }

    double diferencia = total - sumaAcumulada;
    int centimosFaltantes = (diferencia * 100).round();

    for (int i = 0; i < centimosFaltantes; i++) {
      String idAfortunado = participantesIds[i % n];
      double nuevoValor = distribucion[idAfortunado]! + 0.01;
      distribucion[idAfortunado] = double.parse(nuevoValor.toStringAsFixed(2));
    }

    return distribucion;
  }

  Future<void> borrarTodosLosDatosDelGrupo(String groupId) async {
    final groupRef = firestore.collection('grupos').doc(groupId);
    final batch = firestore.batch();

    // Obtener todos los pagos
    final pagosSnapshot = await groupRef.collection('pagos').get();
    for (var doc in pagosSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Resetear netos y balances en el grupo
    batch.update(groupRef, {
      'netos': {},
      'balancesSimplificados': [],
    });

    await batch.commit();
  }

  // Función para forzar recalcular todo desde cero (útil si hay inconsistencias)
  Future<void> recalcularTodoElGrupo(String groupId) async {
    final groupRef = firestore.collection('grupos').doc(groupId);

    await firestore.runTransaction((transaction) async {
      final paymentsSnap = await groupRef.collection('pagos').get();
      Map<String, double> nuevosNetos = {};

      for (var doc in paymentsSnap.docs) {
        final pago = PayModel.fromFirestore(doc);
        nuevosNetos[pago.idPagador] =
            (nuevosNetos[pago.idPagador] ?? 0) + pago.cantidad;

        pago.distribucion.forEach((uid, cantidad) {
          nuevosNetos[uid] = (nuevosNetos[uid] ?? 0) - cantidad;
        });
      }

      List<BalanceModel> nuevosBalances = _calcularSimplificacion(nuevosNetos);

      transaction.update(groupRef, {
        'netos': nuevosNetos,
        'balancesSimplificados': nuevosBalances.map((b) => b.toMap()).toList(),
      });
    });
  }
}
