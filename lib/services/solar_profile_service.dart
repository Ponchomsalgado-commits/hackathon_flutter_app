import 'geocoding_service.dart';
import 'nasa_power_service.dart';
import '../logic/solar_calculator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SOLAR PROFILE SERVICE
// Orquesta Geocoding + NASA POWER y devuelve un perfil solar completo.
// Este es el "cerebro" que conecta los datos del usuario con las APIs.
// ─────────────────────────────────────────────────────────────────────────────

class SolarProfileService {
  final GeocodingService _geocoding = GeocodingService();
  final NasaPowerService _nasa = NasaPowerService();

  /// Genera el perfil solar completo del usuario.
  /// Llama a Google Geocoding y luego a NASA POWER.
  Future<SolarProfile> buildProfile({
    required String codigoPostal,
    required int horarioIndex,
    required List<int> mesesAltoConsumo,
    required double consumoAnualKWh,
    required double presupuestoMXN,
  }) async {
    // 1. CP → lat/lng
    final geoLocation = await _geocoding.getLocation(codigoPostal);

    // 2. Calcular tilt y azimut óptimos según horario y latitud
    final tilt = SolarCalculator.calcularTilt(horarioIndex, geoLocation.latitud.abs() * 0.9);
    final azimut = SolarCalculator.calcularAzimut(horarioIndex);

    // 3. lat/lng + tilt/azimut → irradiación real (NASA POWER)
    final irradiacion = await _nasa.getIrradiation(
      latitud: geoLocation.latitud,
      longitud: geoLocation.longitud,
      tilt: tilt,
      azimut: azimut,
    );

    // 4. Construir calculadora con datos reales
    final calculator = SolarCalculator(
      consumoAnualKWh: consumoAnualKWh,
      irradiacionKWhM2Dia: irradiacion.promedioDiarioGTI,
      tiltGrados: tilt,
      azimutGrados: azimut,
      mesesAltoConsumo: mesesAltoConsumo,
      horarioConsumoIndex: horarioIndex,
    );

    return SolarProfile(
      codigoPostal: codigoPostal,
      localidad: geoLocation.localidad,
      latitud: geoLocation.latitud,
      longitud: geoLocation.longitud,
      tilt: tilt,
      azimut: azimut,
      irradiacion: irradiacion,
      consumoAnualKWh: consumoAnualKWh,
      presupuestoMXN: presupuestoMXN,
      mesesAltoConsumo: mesesAltoConsumo,
      horarioIndex: horarioIndex,
      calculator: calculator,
      datosNasaReales: irradiacion.fuenteReal,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELO: PERFIL SOLAR COMPLETO DEL USUARIO
// ─────────────────────────────────────────────────────────────────────────────

class SolarProfile {
  final String codigoPostal;
  final String localidad;
  final double latitud;
  final double longitud;
  final double tilt;
  final double azimut;
  final SolarIrradiationData irradiacion;
  final double consumoAnualKWh;
  final double presupuestoMXN;
  final List<int> mesesAltoConsumo;
  final int horarioIndex;
  final SolarCalculator calculator;
  final bool datosNasaReales;

  const SolarProfile({
    required this.codigoPostal,
    required this.localidad,
    required this.latitud,
    required this.longitud,
    required this.tilt,
    required this.azimut,
    required this.irradiacion,
    required this.consumoAnualKWh,
    required this.presupuestoMXN,
    required this.mesesAltoConsumo,
    required this.horarioIndex,
    required this.calculator,
    required this.datosNasaReales,
  });

  // Atajos útiles para la UI
  double get irradiacionPromedio => irradiacion.promedioDiarioGTI;
  int get panelesSugeridos => calculator.panelesSugeridos;
  double get ahorroAnualKWh => calculator.ahorroAnualKWh;
  double get consumoResidualKWh => calculator.consumoResidualKWh;
  double get porcentajeCobertura => calculator.porcentajeCobertura;

  /// Irradiación del mes específico (para la gráfica)
  double gtiDelMes(int mes) => irradiacion.gtiDelMes(mes);

  /// Etiqueta del horario de consumo
  String get horarioLabel {
    const labels = ['Madrugada', 'Mañana', 'Tarde', 'Noche'];
    return labels[horarioIndex.clamp(0, 3)];
  }

  /// Dirección del azimut en texto
  String get azimutLabel {
    if (azimut < 45) return 'Norte';
    if (azimut < 135) return 'Este';
    if (azimut <= 225) return 'Sur';
    if (azimut < 315) return 'Oeste';
    return 'Norte';
  }

  @override
  String toString() =>
      'SolarProfile($localidad | GTI: ${irradiacionPromedio.toStringAsFixed(2)} | '
      'Paneles: $panelesSugeridos | NASA: $datosNasaReales)';
}
