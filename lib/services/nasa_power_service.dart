import 'dart:convert';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// NASA POWER SERVICE
// Obtiene la irradiación solar real mes a mes para unas coordenadas dadas.
// API completamente GRATUITA y sin API key.
// Documentación: https://power.larc.nasa.gov/api/
// ─────────────────────────────────────────────────────────────────────────────

class NasaPowerService {
  static const String _baseUrl =
      'https://power.larc.nasa.gov/api/temporal/monthly/point';

  // Parámetro: ALLSKY_SFC_SW_DWN = Irradiancia global en superficie (kWh/m²/día)
  static const String _parameter = 'ALLSKY_SFC_SW_DWN';

  /// Obtiene la irradiación solar mensual para las coordenadas dadas.
  /// [tilt] — ángulo de inclinación del panel en grados
  /// [azimut] — orientación del panel en grados (180 = Sur)
  Future<SolarIrradiationData> getIrradiation({
    required double latitud,
    required double longitud,
    required double tilt,
    required double azimut,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl'
        '?parameters=$_parameter'
        '&community=RE'
        '&longitude=${longitud.toStringAsFixed(4)}'
        '&latitude=${latitud.toStringAsFixed(4)}'
        '&start=2020'
        '&end=2023'
        '&format=JSON',
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        // Verificar que la respuesta tenga la estructura esperada
        if (data.containsKey('properties')) {
          return _parseResponse(data, tilt, azimut, latitud, longitud);
        }
      }
      // Si la respuesta no es válida, usar fallback
      return _fallbackData(latitud, longitud, tilt, azimut);
    } catch (e) {
      // CORS, timeout, sin conexión → siempre usar fallback sin romper la app
      print('[NASA POWER] Usando datos históricos para lat=$latitud');
      return _fallbackData(latitud, longitud, tilt, azimut);
    }
  }

  /// Parsea la respuesta de NASA POWER y calcula la GTI.
  SolarIrradiationData _parseResponse(
    Map<String, dynamic> data,
    double tilt,
    double azimut,
    double latitud,
    double longitud,
  ) {
    final properties = data['properties'] as Map<String, dynamic>;
    final parameter = properties['parameter'] as Map<String, dynamic>;
    final rawData = parameter[_parameter] as Map<String, dynamic>;

    // NASA devuelve datos por año-mes: "202001", "202002", etc.
    // Promediamos los 4 años para obtener un valor mensual representativo
    final Map<int, List<double>> porMes = {};
    for (int mes = 1; mes <= 12; mes++) {
      porMes[mes] = [];
    }

    rawData.forEach((key, value) {
      if (key.length == 6) {
        final mes = int.tryParse(key.substring(4, 6));
        final valor = (value as num?)?.toDouble();
        if (mes != null && valor != null && valor > 0) {
          porMes[mes]!.add(valor);
        }
      }
    });

    // Calcular promedio por mes (GHI - Global Horizontal Irradiance)
    final List<double> ghiMensual = List.generate(12, (i) {
      final valores = porMes[i + 1]!;
      if (valores.isEmpty) return 0.0;
      return valores.reduce((a, b) => a + b) / valores.length;
    });

    // Aplicar factor de corrección por tilt y azimut para obtener GTI
    // Factor simplificado basado en ángulo relativo al óptimo
    final gtiMensual = ghiMensual.map((ghi) {
      return ghi * _factorGTI(tilt, azimut, latitud);
    }).toList();

    final promedioDiario =
        gtiMensual.reduce((a, b) => a + b) / gtiMensual.length;

    return SolarIrradiationData(
      ghiMensual: ghiMensual,
      gtiMensual: gtiMensual,
      promedioDiarioGTI: promedioDiario,
      tiltUsado: tilt,
      azimutUsado: azimut,
      latitud: latitud,
      longitud: longitud,
      fuenteReal: true,
    );
  }

  /// Factor de corrección GHI → GTI según tilt y azimut.
  /// Fórmula simplificada para México (latitud ~15°-32°N).
  double _factorGTI(double tilt, double azimut, double latitud) {
    // Tilt óptimo aproximado para México = latitud * 0.87
    final tiltOptimo = latitud.abs() * 0.87;
    final diferenciaTilt = (tilt - tiltOptimo).abs();

    // Penalización por alejarse del tilt óptimo (max 15%)
    final factorTilt = 1.0 - (diferenciaTilt / tiltOptimo) * 0.15;

    // Penalización por azimut (180° = Sur = óptimo en México)
    final diferenciaAzimut = (azimut - 180).abs();
    final factorAzimut = 1.0 - (diferenciaAzimut / 180) * 0.20;

    return (factorTilt * factorAzimut).clamp(0.75, 1.15);
  }

  /// Fallback con datos históricos estimados por latitud.
  SolarIrradiationData _fallbackData(
    double latitud,
    double longitud,
    double tilt,
    double azimut,
  ) {
    // Datos históricos promedio por zona de México (kWh/m²/día)
    List<double> ghi;

    if (latitud >= 28) {
      // Norte (Chihuahua, Sonora, Coahuila)
      ghi = [4.8, 5.6, 6.4, 7.2, 7.5, 7.8, 7.2, 6.9, 6.5, 5.8, 5.0, 4.6];
    } else if (latitud >= 22) {
      // Centro-Norte (Jalisco, CDMX, Puebla)
      ghi = [4.5, 5.2, 6.0, 6.8, 6.5, 5.8, 5.5, 5.6, 5.2, 5.0, 4.6, 4.2];
    } else if (latitud >= 18) {
      // Centro-Sur (Oaxaca, Veracruz, Chiapas)
      ghi = [4.8, 5.4, 6.1, 6.4, 5.8, 5.0, 5.2, 5.3, 4.9, 4.7, 4.5, 4.4];
    } else {
      // Sureste (Yucatán, Quintana Roo)
      ghi = [5.0, 5.6, 6.2, 6.5, 5.9, 5.1, 5.3, 5.4, 5.0, 4.9, 4.7, 4.8];
    }

    final factor = _factorGTI(tilt, azimut, latitud);
    final gti = ghi.map((v) => v * factor).toList();
    final promedio = gti.reduce((a, b) => a + b) / gti.length;

    return SolarIrradiationData(
      ghiMensual: ghi,
      gtiMensual: gti,
      promedioDiarioGTI: promedio,
      tiltUsado: tilt,
      azimutUsado: azimut,
      latitud: latitud,
      longitud: longitud,
      fuenteReal: false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS
// ─────────────────────────────────────────────────────────────────────────────

class SolarIrradiationData {
  /// Irradiación horizontal global por mes (kWh/m²/día)
  final List<double> ghiMensual;

  /// Irradiación global inclinada por mes — ya ajustada por tilt y azimut
  final List<double> gtiMensual;

  /// Promedio diario anual de GTI (las "Horas Sol Pico")
  final double promedioDiarioGTI;

  final double tiltUsado;
  final double azimutUsado;
  final double latitud;
  final double longitud;

  /// true = datos reales de NASA, false = estimación por zona
  final bool fuenteReal;

  const SolarIrradiationData({
    required this.ghiMensual,
    required this.gtiMensual,
    required this.promedioDiarioGTI,
    required this.tiltUsado,
    required this.azimutUsado,
    required this.latitud,
    required this.longitud,
    required this.fuenteReal,
  });

  /// Irradiación del mes específico (1=Enero, 12=Diciembre)
  double gtiDelMes(int mes) => gtiMensual[mes - 1];

  /// Mes con mayor irradiación
  int get mesMayorIrradiacion {
    double max = 0;
    int idx = 0;
    for (int i = 0; i < gtiMensual.length; i++) {
      if (gtiMensual[i] > max) { max = gtiMensual[i]; idx = i; }
    }
    return idx + 1;
  }

  /// Mes con menor irradiación
  int get mesMenorIrradiacion {
    double min = double.infinity;
    int idx = 0;
    for (int i = 0; i < gtiMensual.length; i++) {
      if (gtiMensual[i] < min) { min = gtiMensual[i]; idx = i; }
    }
    return idx + 1;
  }

  @override
  String toString() =>
      'SolarIrradiationData(GTI promedio: ${promedioDiarioGTI.toStringAsFixed(2)} kWh/m²/día, fuente: ${fuenteReal ? "NASA" : "estimado"})';
}

class NasaException implements Exception {
  final String message;
  const NasaException(this.message);
  @override
  String toString() => 'NasaException: $message';
}