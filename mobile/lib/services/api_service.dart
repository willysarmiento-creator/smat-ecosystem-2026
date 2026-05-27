import 'dart:convert';
import 'package:flutter/foundation.dart'; // Importante para usar kIsWeb
import 'package:http/http.dart' as http;
import '../models/estacion.dart';
import 'auth_service.dart';

class ApiService {
  // 10.0.2.2 es el alias del localhost de la PC para emuladores Android
  final String baseUrl = "http://127.0.0.1:8000";

  Future<List<Estacion>> fetchEstaciones() async {
    try {
      // 1. Obtenemos el token guardado del usuario que inició sesión
      final token = await AuthService().getToken(); 
      
      // 2. Enviamos el token en los headers de la petición GET
      final response = await http.get(
        Uri.parse('$baseUrl/estaciones/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Estacion.fromJson(data)).toList();
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('No se pudo conectar con SMAT. ¿Está el servidor activo?');
    }
  }

  Future<bool> crearEstacion(String nombre, String ubicacion) async {
    final token = await AuthService().getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/estaciones/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'nombre': nombre, 'ubicacion': ubicacion}),
    );
    return response.statusCode == 200;
  }

  // Eliminar una estación
  Future<bool> eliminarEstacion(int id) async {
    final token = await AuthService().getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/estaciones/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  // Actualizar una estación existente
  Future<bool> editarEstacion(int id, String nombre, String ubicacion) async {
    final token = await AuthService().getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/estaciones/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'nombre': nombre, 'ubicacion': ubicacion}),
    );
    return response.statusCode == 200;
  }
}
