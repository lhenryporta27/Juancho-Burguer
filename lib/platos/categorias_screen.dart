import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firebase_service.dart';
import 'platos_por_categoria.dart';
import 'pedido_screen.dart';
import 'historial_pedidos_screen.dart';
import 'pedidos_admin_screen.dart'; // <-- 🔥 IMPORTANTE
import '../home_screen.dart';

class CategoriasScreen extends StatefulWidget {
  final String rol; // admin / cliente / visitante

  const CategoriasScreen({super.key, required this.rol});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  List<Map<String, dynamic>> categorias = [];
  bool cargando = true;

  final List<Map<String, dynamic>> carrito = [];

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    final resultado = await _firebaseService.obtenerCategoriasConImagen();

    if (!mounted) return;

    setState(() {
      categorias = resultado;

      final orden = [
        "Hamburguesa",
        "Broaster's",
        "Salchipapa",
        "Alitas",
        "Bebidas",
      ];

      categorias.sort((a, b) {
        final A = orden.indexOf(a["nombre"]);
        final B = orden.indexOf(b["nombre"]);

        if (A == -1 && B == -1) return a["nombre"].compareTo(b["nombre"]);
        if (A == -1) return 1;
        if (B == -1) return -1;
        return A.compareTo(B);
      });

      cargando = false;
    });
  }

  void _mostrarLoginRequerido() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          "Inicia sesión",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Debes iniciar sesión para usar esta función.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text(
              "Cerrar",
              style: TextStyle(color: Colors.white70),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _abrirCarrito() {
    if (FirebaseAuth.instance.currentUser == null) {
      _mostrarLoginRequerido();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PedidoScreen(carrito: carrito)),
    );
  }

  void _abrirHistorial() {
    if (FirebaseAuth.instance.currentUser == null) {
      _mostrarLoginRequerido();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistorialPedidosScreen()),
    );
  }

  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  Future<void> _mostrarDialogCategoria({
    Map<String, dynamic>? categoria,
  }) async {
    final esEditar = categoria != null;

    final nombreC = TextEditingController(text: categoria?["nombre"] ?? "");
    final imagenC = TextEditingController(text: categoria?["imagen"] ?? "");

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          esEditar ? "Editar categoría" : "Nueva categoría",
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _input(nombreC, "Nombre de la categoría"),
              const SizedBox(height: 8),
              _input(imagenC, "URL de imagen"),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white70),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFFC107)),
            child: Text(
              esEditar ? "Guardar cambios" : "Crear",
              style: TextStyle(color: Colors.black),
            ),
            onPressed: () async {
              final nombre = nombreC.text.trim();
              final imagen = imagenC.text.trim();

              if (nombre.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("El nombre es obligatorio")),
                );
                return;
              }

              if (esEditar) {
                await _firebaseService.editarCategoria(
                  categoria!["id"],
                  nombre,
                  imagen,
                );
              } else {
                await _firebaseService.agregarCategoria(nombre, imagen);
              }

              if (!mounted) return;
              Navigator.pop(context);
              _cargarCategorias();
            },
          ),
        ],
      ),
    );
  }

  Widget _input(TextEditingController c, String label) {
    return TextField(
      controller: c,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white38),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFFFC107)),
        ),
      ),
    );
  }

  Future<void> _eliminarCategoria(Map<String, dynamic> categoria) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          "Eliminar categoría",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "¿Eliminar \"${categoria["nombre"]}\"?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white70),
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Eliminar"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _firebaseService.eliminarCategoria(categoria["id"]);
      _cargarCategorias();
    }
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = widget.rol == "admin";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          esAdmin ? "Categorías (Empleado)" : "Categorías",
          style: const TextStyle(
            color: Color(0xFFFFC107),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (esAdmin) ...[
            IconButton(
              icon: const Icon(Icons.receipt_long, color: Color(0xFFFFC107)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PedidosAdminScreen()),
                );
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.receipt_long, color: Color(0xFFFFC107)),
              onPressed: _abrirHistorial,
            ),
            IconButton(
              icon: const Icon(Icons.shopping_cart, color: Color(0xFFFFC107)),
              onPressed: _abrirCarrito,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFFFC107)),
            onPressed: _cerrarSesion,
          ),
        ],
      ),

      body: cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC107)),
            )
          : ListView.builder(
              itemCount: categorias.length,
              itemBuilder: (_, i) {
                final cat = categorias[i];

                return Card(
                  color: Colors.white.withOpacity(0.06),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        cat["imagen"] ?? "",
                        width: 55,
                        height: 55,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    title: Text(
                      cat["nombre"],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlatosPorCategoriaScreen(
                            categoria: cat["nombre"],
                            isAdmin: esAdmin,
                            carrito: carrito,
                          ),
                        ),
                      );
                    },
                    trailing: esAdmin
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blueAccent,
                                ),
                                onPressed: () =>
                                    _mostrarDialogCategoria(categoria: cat),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _eliminarCategoria(cat),
                              ),
                            ],
                          )
                        : const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white70,
                          ),
                  ),
                );
              },
            ),

      floatingActionButton: esAdmin
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFFFC107),
              child: const Icon(Icons.add, color: Colors.black),
              onPressed: () => _mostrarDialogCategoria(),
            )
          : null,
    );
  }
}
