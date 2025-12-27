import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_model.dart';

class GroupController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  // Función para GUARDAR (Crear grupo)
  Future<void> crearGrupo(GroupModel grupo) async {
    // Guardamos el grupo en la colección 'grupos'
    await firestore.collection('grupos').doc(grupo.id).set(grupo.toMap());

    // ACTUALIZAMOS al usuario creador para que tenga este grupo en su lista
    await firestore.collection('usuarios').doc(grupo.creadoPor).update({
      'grupos': FieldValue.arrayUnion([grupo.id])
    });
  }

  // Función para LEER un solo grupo
  Future<GroupModel?> obtenerGrupo(String id) async {
    var doc = await firestore.collection('grupos').doc(id).get();
    if (!doc.exists) return null;
    return GroupModel.fromFirestore(doc);
  }

  // Función para ACTUALIZAR
  Future<void> actualizarGrupo(
    String groupId,
    Map<String, dynamic> datosAActualizar,
  ) async {
    await firestore.collection('grupos').doc(groupId).update(datosAActualizar);
  }

  // OBTENER GRUPOS ----------------------------
  Stream<List<GroupModel>> obtenerGruposStream() {
    // TODOS los grupos por UID
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null)
      return const Stream.empty(); // Por seguridad si no hay login

    return firestore
        .collection('grupos')
        .where('miembros.$uid',
            isNull: false) // no hace falta que esté creado por
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GroupModel.fromFirestore(doc)).toList());
  }

  // obtener MIEMBROS del grupo ----------------------------------------
  Future<Map<String, String>> obtenerMiembrosDelGrupo(String groupId) async {
    var doc = await firestore.collection('grupos').doc(groupId).get();
    if (!doc.exists) throw Exception("Grupo no encontrado");

    // Retorna mapa {uid: nombre}
    return Map<String, String>.from(doc.data()?['miembros'] ?? {});
  }

  // REEMPLAZO
  Future<void> unirseReemplazandoInvitado({
    required String groupId,
    required String guestId,
  }) async {
    final user = auth.currentUser;
    if (user == null) return;

    final groupRef = firestore.collection('grupos').doc(groupId);
    final batch = firestore.batch();

    //Migrar pagos realizados por el invitado
    final pagosComoPagador = await groupRef
        .collection('pagos')
        .where('idPagador', isEqualTo: guestId)
        .get();

    for (var doc in pagosComoPagador.docs) {
      batch.update(doc.reference, {'idPagador': user.uid});
    }

    // Migrar participación en pagos (dentro del mapa 'distribucion')
    // Leemos todos porque Firestore no permite buscar claves específicas dentro de mapas
    final todosLosPagos = await groupRef.collection('pagos').get();

    for (var doc in todosLosPagos.docs) {
      Map<String, dynamic> distribucion = doc.data()['distribucion'] ?? {};

      if (distribucion.containsKey(guestId)) {
        double cantidad = (distribucion[guestId] as num).toDouble();

        batch.update(doc.reference, {
          'distribucion.$guestId': FieldValue.delete(), // Eliminar invitado
          'distribucion.${user.uid}': cantidad // Asignar al usuario
        });
      }
    }

    // Migrar Balances (Deudas y Créditos)
    final balancesDeudor = await groupRef
        .collection('balances')
        .where('deudorId', isEqualTo: guestId)
        .get();
    for (var doc in balancesDeudor.docs) {
      batch.update(doc.reference, {'deudorId': user.uid});
    }

    final balancesAcreedor = await groupRef
        .collection('balances')
        .where('acreedorId', isEqualTo: guestId)
        .get();
    for (var doc in balancesAcreedor.docs) {
      batch.update(doc.reference, {'acreedorId': user.uid});
    }

    // Migrar Lista de Compra
    final listaCompra = await groupRef
        .collection('listaCompra')
        .where('creadoPor', isEqualTo: guestId)
        .get();
    for (var doc in listaCompra.docs) {
      batch.update(doc.reference, {'creadoPor': user.uid});
    }

    // Ejecutar todas las migraciones
    await batch.commit();

    // Reemplazar ID en el mapa de miembros del grupo
    String userName = user.displayName ?? user.email!.split('@')[0];

    await groupRef.update({
      'miembros.$guestId': FieldValue.delete(),
      'miembros.${user.uid}': userName
    });

    // Vincular grupo al perfil del usuario real
    await firestore.collection('usuarios').doc(user.uid).update({
      'grupos': FieldValue.arrayUnion([groupId])
    });
  }

  // UNIRSE A UN GRUPO -------------------------------------
  Future<void> unirseAGrupo(String groupId) async {
    final user = auth.currentUser;
    if (user == null) return;

    final groupRef = firestore.collection('grupos').doc(groupId);
    final groupDoc = await groupRef.get();

    // Verificamos si el grupo existe
    if (!groupDoc.exists) {
      throw Exception("El grupo no existe. Comprueba el código.");
    }

    // Definimos el nombre
    String userName = user.displayName ?? user.email!.split('@')[0];

    // Añadimos al usuario al mapa de miembros
    // Usamos SetOptions(merge: true) para NO borrar a los otros miembros
    await groupRef.set({
      'miembros': {user.uid: userName}
    }, SetOptions(merge: true));

    // Añadimos el grupo a la lista del usuario (Vital para que salga en el Home)
    await firestore.collection('usuarios').doc(user.uid).update({
      'grupos': FieldValue.arrayUnion([groupId])
    });
  }
}
