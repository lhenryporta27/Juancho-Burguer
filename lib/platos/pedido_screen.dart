import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login_screen.dart';

class PedidoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;

  const PedidoScreen({super.key, required this.carrito});

  @override
  State<PedidoScreen> createState() => _PedidoScreenState();
}

class _PedidoScreenState extends State<PedidoScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Future.microtask(() {
        _mostrarLoginForzado(
          "Debes iniciar sesión para ver tu carrito o hacer pedidos.",
        );
      });
    }
  }

  void _mostrarLoginForzado(String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "Inicia sesión",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(mensaje, style: const TextStyle(color: Colors.white70)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFFC107)),
            child: const Text(
              "Iniciar Sesión",
              style: TextStyle(color: Colors.black),
            ),
            onPressed: () {
              Navigator.pop(context);
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

  double get total {
    double suma = 0;
    for (var item in widget.carrito) {
      suma += item["precio"] * item["cantidad"];
    }
    return suma;
  }

  Future<void> _confirmarPedido() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _mostrarLoginForzado("Para confirmar tu pedido debes iniciar sesión.");
      return;
    }

    if (widget.carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Tu carrito está vacío 🍔"),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 80, left: 12, right: 12),
        ),
      );
      return;
    }

    // =====================================================================================
    // 📌 FORMULARIO EMERGENTE ANTES DE CONFIRMAR PEDIDO
    // =====================================================================================

    final direccionCtrl = TextEditingController();
    final referenciaCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();

    String metodoPago = ""; // efectivo / yape / tarjeta

    final resultado = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              "Confirmar Pedido",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  // Dirección
                  TextField(
                    controller: direccionCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Dirección completa",
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Referencia
                  TextField(
                    controller: referenciaCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Referencia (opcional)",
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Teléfono
                  TextField(
                    controller: telefonoCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Teléfono",
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Métodos de pago
                  const Text(
                    "Método de pago:",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Column(
                    children: [
                      RadioListTile(
                        value: "Efectivo",
                        groupValue: metodoPago,
                        activeColor: Colors.amber,
                        title: const Text(
                          "Efectivo",
                          style: TextStyle(color: Colors.white),
                        ),
                        onChanged: (value) {
                          setStateDialog(() => metodoPago = value.toString());
                        },
                      ),
                      RadioListTile(
                        value: "Yape",
                        groupValue: metodoPago,
                        activeColor: Colors.amber,
                        title: const Text(
                          "Yape / Plin",
                          style: TextStyle(color: Colors.white),
                        ),
                        onChanged: (value) {
                          setStateDialog(() => metodoPago = value.toString());
                        },
                      ),
                      RadioListTile(
                        value: "Tarjeta",
                        groupValue: metodoPago,
                        activeColor: Colors.amber,
                        title: const Text(
                          "Tarjeta",
                          style: TextStyle(color: Colors.white),
                        ),
                        onChanged: (value) {
                          setStateDialog(() => metodoPago = value.toString());
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text(
                  "Cancelar",
                  style: TextStyle(color: Colors.white70),
                ),
                onPressed: () => Navigator.pop(context, null),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: const Text(
                  "Continuar",
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: () {
                  // VALIDACIONES
                  if (direccionCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("La dirección es obligatoria"),
                      ),
                    );
                    return;
                  }

                  if (telefonoCtrl.text.length < 9) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Número de teléfono inválido"),
                      ),
                    );
                    return;
                  }

                  if (metodoPago.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Selecciona un método de pago"),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context, {
                    "direccion": direccionCtrl.text.trim(),
                    "referencia": referenciaCtrl.text.trim(),
                    "telefono": telefonoCtrl.text.trim(),
                    "metodoPago": metodoPago,
                  });
                },
              ),
            ],
          );
        },
      ),
    );

    // Si el usuario cancela → detener
    if (resultado == null) return;

    // =====================================================================================
    // 📌 GUARDAR PEDIDO EN FIRESTORE
    // =====================================================================================

    try {
      await _db.collection("pedidos").add({
        "clienteEmail": user.email,
        "estado": "Pendiente",
        "fecha": Timestamp.now(),

        // 👉 Datos del formulario
        "direccion": resultado["direccion"],
        "referencia": resultado["referencia"],
        "telefono": resultado["telefono"],
        "metodoPago": resultado["metodoPago"],

        "platos": widget.carrito.map((p) {
          return {
            "nombre": p["nombre"],
            "cantidad": p["cantidad"],
            "precio": p["precio"],
            "subtotal": p["precio"] * p["cantidad"],
            "imagen": p["imagen"],
          };
        }).toList(),

        "total": total,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("✅ Pedido guardado correctamente"),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 80, left: 12, right: 12),
        ),
      );

      setState(() => widget.carrito.clear());
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error al guardar el pedido: $e"),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 80, left: 12, right: 12),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFC107)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Mi pedido 🛒",
          style: TextStyle(color: Color(0xFFFFC107)),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: true,
        child: widget.carrito.isEmpty
            ? const Center(
                child: Text(
                  "Tu carrito está vacío 🍔",
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.carrito.length,
                      itemBuilder: (context, index) {
                        final plato = widget.carrito[index];
                        final imagen = plato["imagen"] ?? "";

                        return Card(
                          color: Colors.white.withOpacity(0.1),
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                // 🔥 Miniatura
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: imagen.isNotEmpty
                                      ? Image.network(
                                          imagen,
                                          width: 65,
                                          height: 65,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.asset(
                                          'lib/assets/burgerjuancho.jpg',
                                          width: 65,
                                          height: 65,
                                          fit: BoxFit.cover,
                                        ),
                                ),

                                const SizedBox(width: 12),

                                // 🔥 Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plato["nombre"],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Cantidad: ${plato["cantidad"]} • S/. ${(plato["precio"] * plato["cantidad"]).toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 🔥 Botón eliminar
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () => widget.carrito.removeAt(index),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // 🔥 BOTÓN SUBIDO + TOTAL
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 55),
                    child: Column(
                      children: [
                        Text(
                          "Total: S/. ${total.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Color(0xFFFFC107),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC107),
                            minimumSize: const Size(double.infinity, 45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _confirmarPedido,
                          icon: const Icon(Icons.check, color: Colors.black),
                          label: const Text(
                            "Confirmar Pedido",
                            style: TextStyle(color: Colors.black, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
