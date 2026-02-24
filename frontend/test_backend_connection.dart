import 'package:dio/dio.dart';

void main() async {
  print('Diagnóstico de API InmuFácil...');
  
  final dio = Dio(BaseOptions(
    baseUrl: 'http://127.0.0.1:8000',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ),);
  
  try {
    print('Intentando conectar a http://localhost:8000/api/v1/properties ...');
    final response = await dio.get('/api/v1/properties');
    
    print('Respuesta recibida: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final List data = response.data;
      print('Datos recibidos: ${data.length} propiedades');
      if (data.isNotEmpty) {
        print('Ejemplo de propiedad: ${data.first}');
      } else {
        print('⚠️ ALERTA: La lista de propiedades está vacía.');
      }
    } else {
      print('❌ ERROR: Status code no es 200.');
      print('Body: ${response.data}');
    }
  } catch (e) {
    print('❌ ERROR CRÍTICO DE CONEXIÓN: $e');
    if (e is DioException) {
      print('Tipo de error Dio: ${e.type}');
      print('Mensaje: ${e.message}');
      if (e.response != null) {
        print('Respuesta del servidor: ${e.response?.statusCode} - ${e.response?.data}');
      }
    }
  }
}
