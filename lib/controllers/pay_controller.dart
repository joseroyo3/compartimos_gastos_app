import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pay_model.dart' show PayModel;
import '../models/balance_model.dart';

class PayController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // CREAR PAGO Y ACTUALIZAR BALANCES AUTOMÁTICAMENTE
  Future<void> crearPago(String groupId, PayModel pago) async {
    final groupRef = firestore.collection('grupos').doc(groupId);
    final paymentsRef = groupRef.collection('pagos');

    await firestore.runTransaction((transaction) async {
      // referencia para el nuevo documento de pago
      final newPaymentDoc = paymentsRef.doc();

      //Guardar el Pago
      transaction.set(newPaymentDoc, pago.toMap());

      //ACTUALIZAR BALANCES
      for (var entry in pago.distribucion.entries) {
        String deudorId = entry.key; // El que debe
        double cantidadQueDebe = entry.value;
        String acreedorId = pago.idPagador; // El que pago

        // no creamos deuda al pagado
        if (deudorId == acreedorId) continue;
        if (cantidadQueDebe <= 0) continue;

        // Llamamos a la lógica de actualizar deuda
        await _actualizarBalanceTransaccional(
            transaction,
            groupRef,
            deudorId,
            acreedorId,
            cantidadQueDebe
        );
      }
    });
  }

  // LÓGICA DE ACTUALIZACIÓN DE BALANCE
  // Esta función comprueba si ya existía deuda entre las dos personas
  Future<void> _actualizarBalanceTransaccional(
      Transaction transaction,
      DocumentReference groupRef,
      String deudorId, // El que debe
      String acreedorId, // Al que le deben
      double monto, // 20€
      ) async {
    final balancesRef = groupRef.collection('balances');

    // Si ya existe un documento de deuda
    final queryDirecta = await balancesRef
        .where('deudorId', isEqualTo: deudorId)
        .where('acreedorId', isEqualTo: acreedorId)
        .get();

    if (queryDirecta.docs.isNotEmpty) {
      //Simplemente SUMAMOS la deuda----------------------
      DocumentReference docRef = queryDirecta.docs.first.reference;
      double deudaActual = (queryDirecta.docs.first.data()['cantidad'] as num).toDouble();
      transaction.update(docRef, {'cantidad': deudaActual + monto});
      return;
    }

    // Si la deuda que existe es al revés solo lo restamos-------------
    final queryInversa = await balancesRef
        .where('deudorId', isEqualTo: acreedorId)
        .where('acreedorId', isEqualTo: deudorId)
        .get();

    if (queryInversa.docs.isNotEmpty) {
      DocumentReference docRef = queryInversa.docs.first.reference;
      double deudaExistente = (queryInversa.docs.first.data()['cantidad'] as num).toDouble();

      double nuevoBalance = deudaExistente - monto;

      if (nuevoBalance > 0) {
        // Aún queda deuda en esa dirección, solo actualizamos la resta
        transaction.update(docRef, {'cantidad': nuevoBalance});
      } else if (nuevoBalance == 0) {
        // En paz
        transaction.delete(docRef);
      } else {
        // Se queda el balance en negativo y tenemos que cambiar la dirección
        // Borramos la deuda vieja
        transaction.delete(docRef);

        // Creamos la deuda nueva
        DocumentReference newDoc = balancesRef.doc();
        transaction.set(newDoc, {
          'deudorId': deudorId,
          'acreedorId': acreedorId,
          'cantidad': nuevoBalance.abs(), // Convertimos negativo en positivo
        });
      }
      return;
    }

    //No existe relación previa - Creamos balance nuevo
    DocumentReference newDoc = balancesRef.doc();
    // Usamos toMap() pero sin el ID porque firestore lo genera
    transaction.set(newDoc, {
      'deudorId': deudorId,
      'acreedorId': acreedorId,
      'cantidad': monto,
    });
  }

  // LEER PAGOS CO STREAM
  Stream<List<PayModel>> obtenerPagosDelGrupo(String groupId) {
    return firestore
        .collection('grupos')
        .doc(groupId)
        .collection('pagos')
        .orderBy('fecha', descending: true) // Los más recientes primero
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PayModel.fromFirestore(doc))
          .toList();
    });
  }

  // LEER BALANCES CON STREAM
  Stream<List<BalanceModel>> obtenerBalancesDelGrupo(String groupId) {
    return firestore
        .collection('grupos')
        .doc(groupId)
        .collection('balances')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BalanceModel.fromFirestore(doc))
          .toList();
    });
  }

  Map<String, double> calcularDistribucion(double total, List<String> participantesIds) {
    if (participantesIds.isEmpty) return {};

    int n = participantesIds.length;

    // Calculamos la cuota base TRUNCADA a 2 decimales.
    double cuotaBase = (total / n * 100).floorToDouble() / 100;

    // Inicializamos el mapa y calculamos cuánto suma esa base
    Map<String, double> distribucion = {};
    double sumaAcumulada = 0;

    for (var id in participantesIds) {
      distribucion[id] = cuotaBase;
      sumaAcumulada += cuotaBase;
    }

    // Calculamos cuántos céntimos faltan para llegar al total
    // Redondeamos para evitar errores
    double diferencia = total - sumaAcumulada;
    int centimosFaltantes = (diferencia * 100).round();

    // Repartimos los céntimos Uno a uno
    // "sumándole 0,01€ al primer participante, luego al segundo..."
    for (int i = 0; i < centimosFaltantes; i++) {
      String idAfortunado = participantesIds[i % n];

      // Sumamos 0.01 y forzamos redondeo a 2 decimales para que quede bonito en BD
      double nuevoValor = distribucion[idAfortunado]! + 0.01;
      distribucion[idAfortunado] = double.parse(nuevoValor.toStringAsFixed(2));
    }

    return distribucion;
  }
}