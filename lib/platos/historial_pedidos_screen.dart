import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../login_screen.dart';

class HistorialPedidosScreen extends StatefulWidget {
  const HistorialPedidosScreen({super.key});

  @override
  State<HistorialPedidosScreen> createState() => _HistorialPedidosScreenState();
}

class _HistorialPedidosScreenState extends State<HistorialPedidosScreen> {
  final FirebaseService service = FirebaseService();

  /// FORMATEAR FECHA SIN IMPORTAR EL FORMATO
  String formatearFecha(dynamic fecha) {
    try {
      if (fecha is Timestamp) {
        // Firestore UTC → convertir a Perú (UTC-5)
        DateTime utc = fecha.toDate().toUtc();
        DateTime peru = utc.subtract(const Duration(hours: 5));
        return DateFormat('dd/MM/yyyy hh:mm a').format(peru);
      }

      if (fecha is String) {
        return fecha; // si ya viene en texto, lo dejamos igual
      }

      return "Fecha desconocida";
    } catch (_) {
      return "Fecha desconocida";
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // ❌ Si no hay usuario → pedir login
    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFC107),
          foregroundColor: Colors.black,
          title: const Text("Mis pedidos"),
          centerTitle: true,
        ),
        body: Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFFC107)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LoginScreen()),
            ),
            child: const Text(
              "Iniciar sesión",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ),
      );
    }

    // ✅ Usuario logueado
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: Colors.black,
        title: const Text("Mis pedidos"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.obtenerPedidosPorUsuario(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC107)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No tienes pedidos aún.",
                style: TextStyle(color: Colors.white70, fontSize: 17),
              ),
            );
          }

          // ---------------------------------------------
          // 🔥 ORDENAR MANUALMENTE POR FECHA DESCENDENTE
          // ---------------------------------------------
          final pedidos = snapshot.data!.docs.toList();

          pedidos.sort((a, b) {
            final fechaA = a["fecha"] ?? Timestamp.now();
            final fechaB = b["fecha"] ?? Timestamp.now();
            return fechaB.compareTo(fechaA); // más reciente primero
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final datos = pedidos[index].data() as Map<String, dynamic>;

              final estado = datos["estado"] ?? "Pendiente";
              final total = (datos["total"] ?? 0).toDouble();
              final fecha = formatearFecha(datos["fecha"]);
              final platos = (datos["platos"] as List?) ?? [];

              Color estadoColor = Colors.orangeAccent;
              if (estado == "Entregado") estadoColor = Colors.greenAccent;
              if (estado == "Cancelado") estadoColor = Colors.redAccent;

              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Fecha: $fecha",
                        style: const TextStyle(color: Colors.white70),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Estado: $estado",
                            style: TextStyle(
                              color: estadoColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Total: S/ ${total.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Color(0xFFFFC107),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const Divider(color: Colors.white24, height: 20),

                      const Text(
                        "Platos:",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 6),

                      ...platos.map((p) {
                        final nombre = p["nombre"] ?? "Plato";
                        final cantidad = p["cantidad"] ?? 1;
                        final subtotal = (p["subtotal"] ?? 0)
                            .toDouble()
                            .toStringAsFixed(2);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "$nombre (x$cantidad)",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                "S/ $subtotal",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
