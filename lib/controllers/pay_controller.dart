import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pay_model.dart' show PayModel;
import '../models/balance_model.dart';

class PayController {
  //final FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

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
            transaction, groupRef, deudorId, acreedorId, cantidadQueDebe);
      }
    });

    // Optimizar balances (simplificación de deuda)
    await simplificarDeudas(groupId);
  }

  // LÓGICA DE ACTUALIZACIÓN DE BALANCE
  // Esta función comprueba si ya existía deuda entre las dos personas
  Future<void> _actualizarBalanceTransaccional(
    Transaction transaction,
    DocumentReference groupRef,
    String deudorId, // El que debe
    String acreedorId, // Al que le deben
    double monto, // 20€ (o negativo si estamos borrando)
  ) async {
    final balancesRef = groupRef.collection('balances');

    // Buscamos si existe deuda en dirección DIRECTA (A debe a B)
    final queryDirecta = await balancesRef
        .where('deudorId', isEqualTo: deudorId)
        .where('acreedorId', isEqualTo: acreedorId)
        .get();

    if (queryDirecta.docs.isNotEmpty) {
      DocumentReference docRef = queryDirecta.docs.first.reference;
      double deudaActual =
          (queryDirecta.docs.first.data()['cantidad'] as num).toDouble();

      // Calculamos el nuevo balance
      double nuevoBalance = deudaActual + monto;

      if (nuevoBalance.abs() < 0.01) {
        // Si es casi cero, BORRAMOS EL DOCUMENTO
        transaction.delete(docRef);
      } else if (nuevoBalance > 0) {
        // Si sigue siendo positivo, actualizamos
        transaction.update(docRef, {'cantidad': nuevoBalance});
      } else {
        // Se invirtió la deuda (se volvió negativa)
        transaction.delete(docRef); // Borramos la vieja

        // Creamos la nueva invertida
        DocumentReference newDoc = balancesRef.doc();
        transaction.set(newDoc, {
          'deudorId': acreedorId, // Invertimos roles
          'acreedorId': deudorId,
          'cantidad': nuevoBalance.abs(), // Guardamos positivo
        });
      }
      return;
    }

    // Buscamos si existe deuda en dirección INVERSA (B debe a A)
    final queryInversa = await balancesRef
        .where('deudorId', isEqualTo: acreedorId)
        .where('acreedorId', isEqualTo: deudorId)
        .get();

    if (queryInversa.docs.isNotEmpty) {
      DocumentReference docRef = queryInversa.docs.first.reference;
      double deudaExistente =
          (queryInversa.docs.first.data()['cantidad'] as num).toDouble();

      // Al ser inversa, restamos el monto
      double nuevoBalance = deudaExistente - monto;

      if (nuevoBalance.abs() < 0.01) {
        // En paz -> BORRAMOS EL DOCUMENTO
        transaction.delete(docRef);
      } else if (nuevoBalance > 0) {
        // Aún queda deuda en esa dirección
        transaction.update(docRef, {'cantidad': nuevoBalance});
      } else {
        // Se queda el balance en negativo, cambiamos dirección (volvemos a la original)
        transaction.delete(docRef);

        DocumentReference newDoc = balancesRef.doc();
        transaction.set(newDoc, {
          'deudorId': deudorId, // Volvemos a la dirección original
          'acreedorId': acreedorId,
          'cantidad': nuevoBalance.abs(),
        });
      }
      return;
    }

    // No existe relación previa - Creamos balance nuevo
    if (monto.abs() > 0.01) {
      DocumentReference newDoc = balancesRef.doc();
      transaction.set(newDoc, {
        'deudorId': deudorId,
        'acreedorId': acreedorId,
        'cantidad': monto.abs(),
      });
    }
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

  // ELIMINAR PAGO Y REVERTIR
  Future<void> eliminarPago(String groupId, PayModel pago) async {
    final groupRef = firestore.collection('grupos').doc(groupId);
    final pagoRef = groupRef.collection('pagos').doc(pago.id);

    await firestore.runTransaction((transaction) async {
      // Eliminamos el documento del pago
      transaction.delete(pagoRef);

      // REVERTIMOS LOS BALANCES
      for (var entry in pago.distribucion.entries) {
        String deudorId = entry.key;
        double cantidadQueDebia = entry.value;
        String acreedorId = pago.idPagador;

        if (deudorId == acreedorId) continue;

        await _actualizarBalanceTransaccional(transaction, groupRef, deudorId,
            acreedorId, -cantidadQueDebia // INVERTIMOS EL SIGNO
            );
      }
    });

    // Optimizar balances tras eliminar
    await simplificarDeudas(groupId);
  }

  Future<void> borrarTodosLosDatosDelGrupo(String groupId) async {
    final groupRef = firestore.collection('grupos').doc(groupId);
    final batch = firestore.batch();

    // Obtener todos los pagos
    final pagosSnapshot = await groupRef.collection('pagos').get();
    for (var doc in pagosSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Obtener todos los balances
    final balancesSnapshot = await groupRef.collection('balances').get();
    for (var doc in balancesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Ejecutar to do a la vez
    await batch.commit();
  }

  // OPTIMIZAR BALANCES (Simplificación de deudas: A->B, B->C  =>  A->C)
  Future<void> simplificarDeudas(String groupId) async {
    final groupRef = firestore.collection('grupos').doc(groupId);
    final balancesRef = groupRef.collection('balances');

    try {
      // 1. Obtener todos los balances actuales
      final snapshot = await balancesRef.get();
      if (snapshot.docs.isEmpty) return;

      // 2. Calcular saldos netos por persona
      Map<String, double> netos = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String deudor = data['deudorId'];
        String acreedor = data['acreedorId'];
        double cantidad = (data['cantidad'] as num).toDouble();

        netos[deudor] = (netos[deudor] ?? 0) - cantidad;
        netos[acreedor] = (netos[acreedor] ?? 0) + cantidad;
      }

      // 3. Separar deudores y acreedores
      List<MapEntry<String, double>> deudores = [];
      List<MapEntry<String, double>> acreedores = [];

      netos.forEach((uid, amount) {
        if (amount.abs() < 0.01) return; // Saldo cero
        if (amount < 0) {
          deudores.add(MapEntry(uid, amount));
        } else {
          acreedores.add(MapEntry(uid, amount));
        }
      });

      // 4. Ordenar para optimizar
      // Deudores de mayor deuda (más negativo) a menor
      deudores.sort((a, b) => a.value.compareTo(b.value));
      // Acreedores de mayor crédito (más positivo) a menor
      acreedores.sort((a, b) => b.value.compareTo(a.value));

      // 5. Redistribuir deudas (Matching)
      WriteBatch batch = firestore.batch();

      // Borramos todos los balances antiguos
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      int i = 0; // Índice deudores
      int j = 0; // Índice acreedores

      while (i < deudores.length && j < acreedores.length) {
        var deudor = deudores[i];
        var acreedor = acreedores[j];

        double debit = deudor.value.abs();
        double credit = acreedor.value;

        // El monto a saldar es el mínimo entre lo que debe uno y le deben al otro
        double amount = (debit < credit) ? debit : credit;
        amount = double.parse(amount.toStringAsFixed(2)); // Redondear

        if (amount > 0) {
          DocumentReference newDoc = balancesRef.doc();
          batch.set(newDoc, {
            'deudorId': deudor.key,
            'acreedorId': acreedor.key,
            'cantidad': amount,
          });
        }

        // Ajustar remanentes
        double newDebit = debit - amount;
        double newCredit = credit - amount;

        // Actualizar valores para la siguiente iteración
        if (newDebit < 0.01) {
          i++; // Deudor liquidado
        } else {
          deudores[i] = MapEntry(deudor.key, -newDebit);
        }

        if (newCredit < 0.01) {
          j++; // Acreedor liquidado
        } else {
          acreedores[j] = MapEntry(acreedor.key, newCredit);
        }
      }

      // 6. Ejecutar cambios
      await batch.commit();
    } catch (e) {
      print("Error al optimizar balances: $e");
    }
  }
}
