import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // para vibración

class PedidosAdminScreen extends StatefulWidget {
  const PedidosAdminScreen({super.key});

  @override
  State<PedidosAdminScreen> createState() => _PedidosAdminScreenState();
}

class _PedidosAdminScreenState extends State<PedidosAdminScreen> {
  List<String> _idsPrevios = []; // detectar pedidos nuevos

  // =====================================================
  // 🔥 POPUP DE INFORMACIÓN DEL CLIENTE
  // =====================================================
  void _mostrarDatosCliente(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Datos del Cliente",
                style: TextStyle(
                  color: Color(0xFFFFC107),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              _item("Correo", data["clienteEmail"]),
              _item("Teléfono", data["telefono"]),
              _item("Dirección", data["direccion"]),
              _item("Referencia", data["referencia"]),
              _item("Método de Pago", data["metodoPago"]),
              _item("Total", "S/ ${data["total"]}"),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  child: const Text(
                    "Cerrar",
                    style: TextStyle(color: Color(0xFFFFC107)),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              (value == null || value.toString().trim().isEmpty)
                  ? "—"
                  : value.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Pedidos Realizados",
          style: TextStyle(
            color: Color(0xFFFFC107),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("pedidos")
            .orderBy("fecha", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC107)),
            );
          }

          final pedidos = snapshot.data!.docs;

          // ================================================================
          // 🔥 DETECTAR PEDIDO NUEVO = VIBRACIÓN + SNACKBAR
          // ================================================================
          final idsActuales = pedidos.map((p) => p.id).toList();

          if (_idsPrevios.isNotEmpty &&
              idsActuales.length > _idsPrevios.length) {
            HapticFeedback.mediumImpact();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Nuevo pedido recibido",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  backgroundColor: Color(0xFFFFC107),
                  duration: Duration(seconds: 2),
                ),
              );
            });
          }

          _idsPrevios = idsActuales;
          // ================================================================

          if (pedidos.isEmpty) {
            return const Center(
              child: Text(
                "No hay pedidos aún 🍔",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: pedidos.length,
            itemBuilder: (_, i) {
              final pedido = pedidos[i];
              final data = pedido.data() as Map<String, dynamic>;

              final clienteEmail = data["clienteEmail"] ?? "Desconocido";
              final estado = data["estado"] ?? "Pendiente";
              final fecha = (data["fecha"] as Timestamp).toDate();

              final platos = List<Map<String, dynamic>>.from(data["platos"]);

              return Card(
                color: Colors.white.withOpacity(0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===================================================
                      // EMAIL + ESTADO + BOTÓN CLIENTE
                      // ===================================================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            clienteEmail,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.person,
                                  color: Color(0xFFFFC107),
                                ),
                                onPressed: () => _mostrarDatosCliente(data),
                              ),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: estado == "Pendiente"
                                      ? Colors.orange
                                      : Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  estado,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // FECHA Y HORA
                      Text(
                        "Fecha: ${fecha.day.toString().padLeft(2, '0')}/"
                        "${fecha.month.toString().padLeft(2, '0')}/"
                        "${fecha.year}  "
                        "${fecha.hour.toString().padLeft(2, '0')}:"
                        "${fecha.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),

                      const Divider(color: Colors.white24, height: 22),

                      // LISTA DE PLATOS
                      Column(
                        children: platos.map((p) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "${p["cantidad"]}x ${p["nombre"]}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Text(
                                  "S/ ${p["subtotal"].toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    color: Color(0xFFFFC107),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 12),

                      const Divider(color: Colors.white24),

                      // MARCAR COMO ENTREGADO
                      if (estado == "Pendiente")
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFC107),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Marcar como ENTREGADO",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection("pedidos")
                                  .doc(pedido.id)
                                  .update({"estado": "Entregado"});
                            },
                          ),
                        ),
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
