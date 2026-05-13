class Estacion {
  final int id;
  final String nombre;
  final String ubicacion;
  final double ultimaLectura; 

  Estacion({
    required this.id,
    required this.nombre,
    required this.ubicacion,
    this.ultimaLectura = 0.0, 
  });

  factory Estacion.fromJson(Map<String, dynamic> json) {
    return Estacion(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      ubicacion: json['ubicacion'] ?? '',
      ultimaLectura: (json['ultima_lectura'] ?? 0).toDouble(),
    );
  }
}