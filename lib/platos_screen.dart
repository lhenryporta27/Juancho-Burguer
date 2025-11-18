import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlatosScreen extends StatefulWidget {
  final bool isAdmin;

  const PlatosScreen({super.key, required this.isAdmin});

  @override
  State<PlatosScreen> createState() => _PlatosScreenState();
}

class _PlatosScreenState extends State<PlatosScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    // 🚫 Protección total → solo admins reales pueden entrar
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || widget.isAdmin == false) {
      Future.microtask(() {
        if (Navigator.canPop(context)) Navigator.pop(context);
      });
    }
  }

  // ===============================================================
  // 🔥 FUNCIÓN DE ERROR LIMPIO
  // ===============================================================
  String _errorMessage(Object e) {
    String msg = e.toString();
    if (msg.contains("permission-denied")) {
      return "No tienes permisos para esta acción.";
    }
    return msg;
  }

  // ===============================================================
  // 🔥 ELIMINAR PLATO
  // ===============================================================
  Future<void> _deletePlato(String id, BuildContext context) async {
    try {
      await _db.collection("platos").doc(id).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Plato eliminado correctamente 🗑️")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${_errorMessage(e)}")));
    }
  }

  // ===============================================================
  // 🔥 AGREGAR / EDITAR PLATO
  // ===============================================================
  Future<void> _showPlatoDialog(
    BuildContext context, {
    String? id,
    Map<String, dynamic>? data,
  }) async {
    final nombreController = TextEditingController(text: data?["nombre"] ?? "");
    final precioController = TextEditingController(
      text: data?["precio"]?.toString() ?? "",
    );
    final categoriaController = TextEditingController(
      text: data?["categoria"] ?? "",
    );
    final descripcionController = TextEditingController(
      text: data?["descripcion"] ?? "",
    );
    final imagenController = TextEditingController(text: data?["imagen"] ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(id == null ? "Agregar Plato" : "Editar Plato"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: "Nombre"),
              ),
              TextField(
                controller: precioController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Precio"),
              ),
              TextField(
                controller: categoriaController,
                decoration: const InputDecoration(labelText: "Categoría"),
              ),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(labelText: "Descripción"),
              ),
              TextField(
                controller: imagenController,
                decoration: const InputDecoration(
                  labelText: "URL de imagen (Drive o enlace directo)",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Guardar"),
            onPressed: () async {
              if (nombreController.text.trim().isEmpty ||
                  precioController.text.trim().isEmpty ||
                  categoriaController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Completa los campos obligatorios"),
                  ),
                );
                return;
              }

              final plato = {
                "nombre": nombreController.text.trim(),
                "precio": double.tryParse(precioController.text.trim()) ?? 0.0,
                "categoria": categoriaController.text.trim(),
                "descripcion": descripcionController.text.trim(),
                "imagen": imagenController.text.trim(),
              };

              try {
                if (id == null) {
                  await _db.collection("platos").add(plato);
                } else {
                  await _db.collection("platos").doc(id).update(plato);
                }

                if (Navigator.canPop(context)) Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      id == null
                          ? "Plato agregado correctamente 🍔"
                          : "Plato actualizado correctamente ✏️",
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: ${_errorMessage(e)}")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // 🔥 UI PRINCIPAL – LISTA DE PLATOS
  // ===============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Panel de Admin",
          style: TextStyle(
            color: Color(0xFFFFC107),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection("platos").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Error al cargar los platos ❌",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC107)),
            );
          }

          final platos = snapshot.data!.docs;

          if (platos.isEmpty) {
            return const Center(
              child: Text(
                "No hay platos registrados 🍔",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: platos.length,
            itemBuilder: (context, index) {
              final plato = platos[index];
              final data = plato.data() as Map<String, dynamic>;

              final nombre = data["nombre"] ?? "";
              final precio = (data["precio"] ?? 0).toDouble();
              final descripcion = data["descripcion"] ?? "";
              final imagen = data["imagen"] ?? "";

              return Card(
                color: Colors.white.withOpacity(0.08),
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      child: Image.network(
                        imagen,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            height: 180,
                            color: Colors.black26,
                            child: const Center(
                              child: Icon(
                                Icons.fastfood,
                                color: Color(0xFFFFC107),
                                size: 50,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Info
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "S/. ${precio.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Color(0xFFFFC107),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            descripcion,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Botones admin
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showPlatoDialog(
                            context,
                            id: plato.id,
                            data: data,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePlato(plato.id, context),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFC107),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => _showPlatoDialog(context),
      ),
    );
  }
}
