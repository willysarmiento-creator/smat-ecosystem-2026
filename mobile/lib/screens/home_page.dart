import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/estacion.dart';
import 'login_screen.dart';
import 'add_estacion.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  late Future<List<Estacion>> _estacionesFuture;

  @override
  void initState() {
    super.initState();
    _refrescarDatos();
  }

  void _refrescarDatos() {
    setState(() {
      _estacionesFuture = _apiService.fetchEstaciones();
    });
  }

  void _mostrarDialogoEdicion(Estacion estacion) {
    final nombreCtrl = TextEditingController(text: estacion.nombre);
    final ubicacionCtrl = TextEditingController(text: estacion.ubicacion);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Estación"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre")),
            TextField(controller: ubicacionCtrl, decoration: const InputDecoration(labelText: "Ubicación")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              bool ok = await _apiService.editarEstacion(estacion.id, nombreCtrl.text, ubicacionCtrl.text);
              
              if (!context.mounted) return;

              if (ok) {
                Navigator.pop(context);
                _refrescarDatos();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Estación actualizada con éxito")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Error al actualizar la estación")),
                );
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
      appBar: AppBar(
        title: const Text('Estaciones SMAT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refrescarDatos();
          await _estacionesFuture; 
        },
        child: FutureBuilder<List<Estacion>>(
          future: _estacionesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 300),
                  Center(child: Text('No hay estaciones registradas.')),
                ],
              );
            }

            final estaciones = snapshot.data!;
            return ListView.builder(
              itemCount: estaciones.length,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final estacion = estaciones[index];

                final colorAlerta = estacion.ultimaLectura < 50 ? Colors.green : Colors.red;

                return Dismissible(
                  key: Key(estacion.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) async {
                    bool ok = await _apiService.eliminarEstacion(estacion.id);
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("${estacion.nombre} eliminada")),
                      );
                    }
                    _refrescarDatos();
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      leading: Icon(Icons.sensors, color: colorAlerta),
                      title: Text(estacion.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(estacion.ubicacion),
                      onTap: () => _mostrarDialogoEdicion(estacion),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEstacionScreen()),
          );
          if (resultado == true) {
            _refrescarDatos();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}