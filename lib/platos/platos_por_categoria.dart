import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import 'pedido_screen.dart';
import '../login_screen.dart';

class PlatosPorCategoriaScreen extends StatefulWidget {
  final String categoria;
  final bool isAdmin;
  final List<Map<String, dynamic>> carrito;

  const PlatosPorCategoriaScreen({
    super.key,
    required this.categoria,
    required this.isAdmin,
    required this.carrito,
  });

  @override
  State<PlatosPorCategoriaScreen> createState() =>
      _PlatosPorCategoriaScreenState();
}

class _PlatosPorCategoriaScreenState extends State<PlatosPorCategoriaScreen> {
  final FirebaseService _service = FirebaseService();

  // ===============================================================
  // 🔥 POPUP LOGIN
  // ===============================================================
  void _mostrarLoginPopup(String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "Inicia sesión",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(mensaje, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            child: const Text(
              "Cerrar",
              style: TextStyle(color: Colors.white70),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFFC107)),
            child: const Text(
              "Iniciar sesión",
              style: TextStyle(color: Colors.black),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // 🔥 AGREGAR AL CARRITO
  // ===============================================================
  void _agregarAlCarrito(Map<String, dynamic> data) {
    // El admin NO usa carrito
    if (widget.isAdmin) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _mostrarLoginPopup(
        "Para agregar productos al carrito debes iniciar sesión.",
      );
      return;
    }

    final nombre = (data["nombre"] ?? "").toString();
    final precio = double.tryParse(data["precio"].toString()) ?? 0.0;
    final imagen = (data["link"] ?? "").toString();

    final index = widget.carrito.indexWhere((item) => item["nombre"] == nombre);

    setState(() {
      if (index >= 0) {
        widget.carrito[index]["cantidad"]++;
      } else {
        widget.carrito.add({
          "nombre": nombre,
          "precio": precio,
          "cantidad": 1,
          "imagen": imagen,
        });
      }
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("$nombre agregado al carrito 🛒")));
  }

  // ===============================================================
  // 🔥 POPUP DETALLES DEL PLATO (solo cliente)
  // ===============================================================
  void _mostrarDetallesPlato(Map<String, dynamic> data) {
    final imageUrl = (data["link"] ?? "").toString();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // IMAGEN CON PLACEHOLDER
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: imageUrl.isNotEmpty
                    ? FadeInImage.assetNetwork(
                        placeholder: 'lib/assets/burgerjuancho.jpg',
                        image: imageUrl,
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        'lib/assets/burgerjuancho.jpg',
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),

              const SizedBox(height: 12),

              // NOMBRE
              Text(
                (data["nombre"] ?? "Sin nombre").toString(),
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // DESCRIPCIÓN
              Text(
                (data["descripcion"] ?? "").toString(),
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // PRECIO
              Text(
                "S/ ${(double.tryParse(data["precio"]?.toString() ?? "0") ?? 0.0).toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Color(0xFFFFC107),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              // BOTÓN AGREGAR AL CARRITO SOLO PARA CLIENTE
              if (!widget.isAdmin)
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.add_shopping_cart,
                    color: Colors.black,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFC107),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                  ),
                  label: const Text(
                    "Agregar al carrito",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _agregarAlCarrito(data);
                  },
                ),

              TextButton(
                child: const Text(
                  "Cerrar",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // 🔥 ADMIN: POPUP AGREGAR / EDITAR PLATO
  // ===============================================================
  void _dialogoPlato({Map<String, dynamic>? plato, String? id}) {
    final editar = plato != null;

    final nombre = TextEditingController(text: plato?["nombre"] ?? "");
    final desc = TextEditingController(text: plato?["descripcion"] ?? "");
    final precio = TextEditingController(
      text: plato?["precio"]?.toString() ?? "",
    );
    final imagen = TextEditingController(text: plato?["link"] ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          editar ? "Editar plato" : "Nuevo plato",
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _input(nombre, "Nombre"),
              _input(desc, "Descripción"),
              _input(precio, "Precio"),
              _input(imagen, "URL de imagen"),
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
              editar ? "Guardar" : "Crear",
              style: const TextStyle(color: Colors.black),
            ),
            onPressed: () async {
              final data = {
                "nombre": nombre.text.trim(),
                "descripcion": desc.text.trim(),
                "precio": double.tryParse(precio.text.trim()) ?? 0.0,
                "categoria": widget.categoria,
                "link": imagen.text.trim(),
              };

              if (editar) {
                await _service.editarPlato(id!, data);
              } else {
                await _service.agregarPlato(data);
              }

              if (!mounted) return;
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _input(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
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
      ),
    );
  }

  // ===============================================================
  // 🔥 ADMIN: ELIMINAR PLATO
  // ===============================================================
  Future<void> _eliminarPlato(String id, String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          "Eliminar $nombre",
          style: const TextStyle(color: Colors.white),
        ),
        content: const Text(
          "¿Seguro que deseas eliminar este plato?",
          style: TextStyle(color: Colors.white70),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Eliminar"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _service.eliminarPlato(id);
    }
  }

  // ===============================================================
  // 🔥 ABRIR CARRITO (CLIENTE)
  // ===============================================================
  void _abrirCarrito() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _mostrarLoginPopup("Debes iniciar sesión para ver tu carrito.");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PedidoScreen(carrito: widget.carrito)),
    );
  }

  // ===============================================================
  // 🔥 UI
  // ===============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.categoria,
          style: const TextStyle(
            color: Color(0xFFFFC107),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.shopping_cart, color: Color(0xFFFFC107)),
              onPressed: _abrirCarrito,
            ),
        ],
      ),

      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFFFC107),
              child: const Icon(Icons.add, color: Colors.black),
              onPressed: () => _dialogoPlato(),
            )
          : null,

      body: StreamBuilder<QuerySnapshot>(
        stream: _service.obtenerPlatosPorCategoria(widget.categoria),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC107)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No hay platos en esta categoría 🍟",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final id = docs[i].id;
              final data = docs[i].data() as Map<String, dynamic>;
              final img = (data["link"] ?? "").toString();

              // 👉 Cliente: puede tocar la card para ver el popup
              // 👉 Admin: solo gestiona con los iconos
              Widget card = Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: img.isNotEmpty
                          ? FadeInImage.assetNetwork(
                              placeholder: 'lib/assets/burgerjuancho.jpg',
                              image: img,
                              height: 110,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'lib/assets/burgerjuancho.jpg',
                              height: 110,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (data["nombre"] ?? "Sin nombre").toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 4),

                            Text(
                              (data["descripcion"] ?? "").toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),

                            const Spacer(),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "S/ ${(double.tryParse(data["precio"]?.toString() ?? "0") ?? 0.0).toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    color: Color(0xFFFFC107),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17, // 🔥 Aumentado
                                  ),
                                ),

                                widget.isAdmin
                                    ? Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blueAccent,
                                            ),
                                            onPressed: () => _dialogoPlato(
                                              plato: data,
                                              id: id,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => _eliminarPlato(
                                              id,
                                              (data["nombre"] ?? "este plato")
                                                  .toString(),
                                            ),
                                          ),
                                        ],
                                      )
                                    : IconButton(
                                        icon: const Icon(
                                          Icons.add_shopping_cart,
                                          color: Color(0xFFFFC107),
                                        ),
                                        onPressed: () =>
                                            _agregarAlCarrito(data),
                                      ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (!widget.isAdmin) {
                // Cliente: el cuadro también abre el popup
                card = GestureDetector(
                  onTap: () => _mostrarDetallesPlato(data),
                  child: card,
                );
              }

              return card;
            },
          );
        },
      ),
    );
  }
}
