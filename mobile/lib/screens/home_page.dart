import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/estacion.dart';
import 'login_screen.dart';
import 'add_estacion.dart'; // Importamos la pantalla que creaste antes

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Instanciamos tu servicio de API para usarlo en la lista
  final ApiService _apiService = ApiService();

  // Función para recargar la lista cuando volvemos de agregar una estación
  void _refrescarLista() {
    setState(() {});
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
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      
      // FutureBuilder se encarga de llamar a fetchEstaciones() y construir la interfaz
      body: FutureBuilder<List<Estacion>>(
        future: _apiService.fetchEstaciones(),
        builder: (context, snapshot) {
          
          // ESTADO 1: Cargando (Muestra un círculo de progreso)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ESTADO 2: Error (Muestra qué falló)
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }

          // ESTADO 3: Vacío (No hay estaciones en la base de datos)
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Aún no hay estaciones registradas.\n¡Agrega una nueva!',
                textAlign: TextAlign.center,
              ),
            );
          }

          // ESTADO 4: Éxito (Construye la lista con los datos)
          final estaciones = snapshot.data!;
          return ListView.builder(
            itemCount: estaciones.length,
            itemBuilder: (context, index) {
              final estacion = estaciones[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.sensors, color: Colors.blue),
                  // Asegúrate de que tu modelo 'estacion.dart' tenga 'nombre' y 'ubicacion'
                  title: Text(estacion.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(estacion.ubicacion),
                ),
              );
            },
          );
        },
      ),

      // Botón flotante para ir a la pantalla de agregar
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navegamos a AddEstacionScreen y esperamos a que el usuario vuelva
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEstacionScreen()),
          );
          
          // Si el resultado es true (la estación se guardó), recargamos la lista
          if (resultado == true) {
            _refrescarLista();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}