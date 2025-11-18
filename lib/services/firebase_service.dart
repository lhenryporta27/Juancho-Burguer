import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================================
  // 🔥 OBTENER CATEGORÍAS (con nombre + imagen)
  // ============================================================
  Future<List<Map<String, dynamic>>> obtenerCategoriasConImagen() async {
    try {
      final snapshot = await _db.collection("categorias").get();

      final lista = snapshot.docs.map((doc) {
        return {
          "id": doc.id,
          "nombre": doc["nombre"] ?? "Sin nombre",
          "imagen": doc["imagen"] ?? "",
        };
      }).toList();

      return lista;
    } catch (e) {
      print("ERROR obteniendo categorías con imagen: $e");
      return [];
    }
  }

  // ============================================================
  // 🔥 CRUD COMPLETO CATEGORÍAS
  // ============================================================

  Future<void> agregarCategoria(String nombre, String imagen) async {
    await _db.collection("categorias").add({
      "nombre": nombre,
      "imagen": imagen,
    });
  }

  Future<void> editarCategoria(String id, String nombre, String imagen) async {
    await _db.collection("categorias").doc(id).update({
      "nombre": nombre,
      "imagen": imagen,
    });
  }

  Future<void> eliminarCategoria(String id) async {
    await _db.collection("categorias").doc(id).delete();
  }

  // ============================================================
  // 🔥 OBTENER SOLO NOMBRES DE CATEGORÍAS (si lo necesitas)
  // ============================================================
  Future<List<String>> obtenerCategorias() async {
    try {
      final snapshot = await _db.collection("platos").get();

      final categorias = snapshot.docs
          .map((doc) => (doc["categoria"] ?? "").toString())
          .where((c) => c.trim().isNotEmpty)
          .toSet()
          .toList();

      categorias.sort();
      return categorias;
    } catch (e) {
      print("ERROR obteniendo categorías: $e");
      return [];
    }
  }

  // ============================================================
  // 🔥 CRUD COMPLETO PLATOS
  // ============================================================

  Future<void> agregarPlato(Map<String, dynamic> data) async {
    await _db.collection("platos").add(data);
  }

  Future<void> editarPlato(String id, Map<String, dynamic> data) async {
    await _db.collection("platos").doc(id).update(data);
  }

  Future<void> eliminarPlato(String id) async {
    await _db.collection("platos").doc(id).delete();
  }

  // ============================================================
  // 🔥 OBTENER PLATOS POR CATEGORÍA
  // ============================================================
  Stream<QuerySnapshot> obtenerPlatosPorCategoria(String categoria) {
    return _db
        .collection("platos")
        .where("categoria", isEqualTo: categoria)
        .snapshots();
  }

  // ============================================================
  // 🔥 OBTENER PEDIDOS SOLO DEL USUARIO
  // ============================================================
  Stream<QuerySnapshot> obtenerPedidosPorUsuario() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _db
          .collection("pedidos")
          .where("clienteEmail", isEqualTo: "__NO_USER__")
          .snapshots();
    }

    return _db
        .collection("pedidos")
        .where("clienteEmail", isEqualTo: user.email)
        .snapshots();
  }

  // ============================================================
  // 🔥 OBTENER TODOS LOS PEDIDOS (ADMIN)
  // ============================================================
  Stream<QuerySnapshot> obtenerTodosLosPedidos() {
    return _db
        .collection("pedidos")
        .orderBy("fecha", descending: true)
        .snapshots();
  }

  // ============================================================
  // 🔥 CAMBIAR ESTADO DE UN PEDIDO (ADMIN)
  // ============================================================
  Future<void> updateEstadoPedido(String pedidoId, String nuevoEstado) async {
    await _db.collection("pedidos").doc(pedidoId).update({
      "estado": nuevoEstado,
    });
  }
}
