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
      final groupSnap = await transaction.get(groupRef);
      if (!groupSnap.exists) return;

      final GroupModel group = GroupModel.fromFirestore(groupSnap);

      // 1. Guardar el pago primero
      final newPaymentDoc = paymentsRef.doc();
      transaction.set(newPaymentDoc, pago.toMap());

      // 2. Recalcular netos desde cero para asegurar consistencia total
      // (Es más seguro que acumular sobre el mapa anterior si éste pudiera estar corrupto)
      final allPaymentsSnap = await groupRef.collection('pagos').get();
      Map<String, double> nuevosNetos = {};

      // Sumar todos los pagos existentes + el nuevo
      for (var doc in allPaymentsSnap.docs) {
        final p = PayModel.fromFirestore(doc);
        nuevosNetos[p.idPagador] = (nuevosNetos[p.idPagador] ?? 0) + p.cantidad;
        p.distribucion.forEach((uid, cant) {
          nuevosNetos[uid] = (nuevosNetos[uid] ?? 0) - cant;
        });
      }

      // Añadir el pago actual que estamos procesando en la transacción
      nuevosNetos[pago.idPagador] =
          (nuevosNetos[pago.idPagador] ?? 0) + pago.cantidad;
      pago.distribucion.forEach((uid, cant) {
        nuevosNetos[uid] = (nuevosNetos[uid] ?? 0) - cant;
      });

      // 3. Simplificar
      List<BalanceModel> nuevosBalances = _calcularSimplificacion(nuevosNetos);

      // 4. Guardar
      transaction.update(groupRef, {
        'netos': nuevosNetos,
        'balancesSimplificados': nuevosBalances.map((b) => b.toMap()).toList(),
      });
    });
  }

  // ALGORITMO DE SIMPLIFICACIÓN (Greedy Matching)
  List<BalanceModel> _calcularSimplificacion(Map<String, double> netos) {
    List<MapEntry<String, double>> deudores = [];
    List<MapEntry<String, double>> acreedores = [];

    netos.forEach((uid, amount) {
      // Redondeo preventivo a 2 decimales para evitar errores de coma flotante
      double cleanAmount = double.parse(amount.toStringAsFixed(2));
      if (cleanAmount.abs() < 0.01) return;

      if (cleanAmount < 0) {
        deudores.add(MapEntry(uid, cleanAmount.abs()));
      } else {
        acreedores.add(MapEntry(uid, cleanAmount));
      }
    });

    // Ordenar de mayor a menor para minimizar transferencias
    deudores.sort((a, b) => b.value.compareTo(a.value));
    acreedores.sort((a, b) => b.value.compareTo(a.value));

    List<BalanceModel> resultado = [];
    int i = 0; // puntero deudores
    int j = 0; // puntero acreedores

    while (i < deudores.length && j < acreedores.length) {
      double deuda = deudores[i].value;
      double credito = acreedores[j].value;

      double pago = (deuda < credito) ? deuda : credito;
      pago = double.parse(pago.toStringAsFixed(2));

      if (pago > 0) {
        resultado.add(BalanceModel(
          id: '',
          deudorId: deudores[i].key,
          acreedorId: acreedores[j].key,
          cantidad: pago,
        ));
      }

      // Actualizar remanentes
      deudores[i] = MapEntry(
          deudores[i].key, double.parse((deuda - pago).toStringAsFixed(2)));
      acreedores[j] = MapEntry(
          acreedores[j].key, double.parse((credito - pago).toStringAsFixed(2)));

      if (deudores[i].value < 0.01) i++;
      if (acreedores[j].value < 0.01) j++;
    }
    return resultado;
  }

  // RECALCULAR DESDE CERO (BOTÓN REFRESCAR)
  Future<void> recalcularTodoElGrupo(String groupId) async {
    final groupRef = firestore.collection('grupos').doc(groupId);

    // Primero, obtener todos los pagos fuera de la transacción para evitar bloqueos largos
    final paymentsSnap = await groupRef.collection('pagos').get();

    await firestore.runTransaction((transaction) async {
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

  // ELIMINAR VARIOS PAGOS
  Future<void> eliminarVariosPagos(String groupId, List<PayModel> pagos) async {
    if (pagos.isEmpty) return;
    final groupRef = firestore.collection('grupos').doc(groupId);

    await firestore.runTransaction((transaction) async {
      for (var pago in pagos) {
        transaction.delete(groupRef.collection('pagos').doc(pago.id));
      }

      // Forzamos recalculo total tras borrar masivamente
      final allPaymentsSnap = await groupRef.collection('pagos').get();
      Map<String, double> nuevosNetos = {};

      for (var doc in allPaymentsSnap.docs) {
        final p = PayModel.fromFirestore(doc);
        // Excluir los que estamos borrando en esta transacción
        if (pagos.any((toDelete) => toDelete.id == p.id)) continue;

        nuevosNetos[p.idPagador] = (nuevosNetos[p.idPagador] ?? 0) + p.cantidad;
        p.distribucion.forEach((uid, cant) {
          nuevosNetos[uid] = (nuevosNetos[uid] ?? 0) - cant;
        });
      }

      List<BalanceModel> nuevosBalances = _calcularSimplificacion(nuevosNetos);

      transaction.update(groupRef, {
        'netos': nuevosNetos,
        'balancesSimplificados': nuevosBalances.map((b) => b.toMap()).toList(),
      });
    });
  }

  // ELIMINAR PAGO INDIVIDUAL
  Future<void> eliminarPago(String groupId, PayModel pago) async {
    await eliminarVariosPagos(groupId, [pago]);
  }

  // STREAMS (Se mantienen leyendo del documento central)
  Stream<List<PayModel>> obtenerPagosDelGrupo(String groupId) {
    return firestore
        .collection('grupos')
        .doc(groupId)
        .collection('pagos')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => PayModel.fromFirestore(doc)).toList());
  }

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
      distribucion[idAfortunado] =
          double.parse((distribucion[idAfortunado]! + 0.01).toStringAsFixed(2));
    }
    return distribucion;
  }

  Future<void> borrarTodosLosDatosDelGrupo(String groupId) async {
    final groupRef = firestore.collection('grupos').doc(groupId);
    final batch = firestore.batch();
    final pagosSnapshot = await groupRef.collection('pagos').get();
    for (var doc in pagosSnapshot.docs) batch.delete(doc.reference);
    batch.update(groupRef, {
      'netos': {},
      'balancesSimplificados': [],
      'listaCompraCentralizada': []
    });
    await batch.commit();
  }
}
