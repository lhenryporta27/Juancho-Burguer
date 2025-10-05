import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlatosScreen extends StatelessWidget {
  final bool isAdmin;

  PlatosScreen({required this.isAdmin});

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔹 Método para eliminar un plato
  Future<void> _deletePlato(String id, BuildContext context) async {
    try {
      await _db.collection("platos").doc(id).delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Plato eliminado ✅")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al eliminar: $e")));
    }
  }

  // 🔹 Método para agregar o editar un plato
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
                decoration: const InputDecoration(labelText: "Precio"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: categoriaController,
                decoration: const InputDecoration(labelText: "Categoría"),
              ),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(labelText: "Descripción"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final plato = {
                "nombre": nombreController.text.trim(),
                "precio": double.tryParse(precioController.text.trim()) ?? 0.0,
                "categoria": categoriaController.text.trim(),
                "descripcion": descripcionController.text.trim(),
              };

              try {
                if (id == null) {
                  await _db.collection("platos").add(plato);
                } else {
                  await _db.collection("platos").doc(id).update(plato);
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      id == null ? "Plato agregado ✅" : "Plato actualizado ✅",
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          isAdmin ? "Panel de Admin" : "Platos disponibles",
          style: const TextStyle(
            color: Color(0xFFFFC107),
            fontWeight: FontWeight.bold,
            fontSize: 18, // 👈 más pequeño
          ),
        ),
        centerTitle: true,
        elevation: 0,
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
            return const Center(child: CircularProgressIndicator());
          }

          final platos = snapshot.data!.docs;

          if (platos.isEmpty) {
            return const Center(
              child: Text(
                "No hay platos registrados 🍔",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: platos.length,
            itemBuilder: (context, index) {
              final plato = platos[index];
              final data = plato.data() as Map<String, dynamic>;
              final nombre = data["nombre"] ?? "";
              final precio = data["precio"] ?? 0.0;
              final categoria = data["categoria"] ?? "";
              final descripcion = data["descripcion"] ?? "";

              return Card(
                color: Colors.white.withOpacity(0.08),
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.fastfood,
                      color: Color(0xFFFFC107),
                      size: 24,
                    ),
                  ),
                  title: Text(
                    nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    "S/. $precio\nCategoría: $categoria\n$descripcion",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: isAdmin
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.blue,
                                size: 20,
                              ),
                              onPressed: () => _showPlatoDialog(
                                context,
                                id: plato.id,
                                data: data,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () => _deletePlato(plato.id, context),
                            ),
                          ],
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.shopping_cart,
                            color: Colors.green,
                            size: 22,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Plato agregado al pedido 🛒"),
                              ),
                            );
                          },
                        ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFFFC107),
              onPressed: () => _showPlatoDialog(context),
              child: const Icon(Icons.add, color: Colors.black, size: 26),
            )
          : null,
    );
  }
}
