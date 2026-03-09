import '../models/product_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SOLAR CALCULATOR
// Motor de cálculo central. Recibe los datos del usuario y la lista de
// productos del repositorio, y devuelve resultados listos para la UI.
// ─────────────────────────────────────────────────────────────────────────────

class SolarCalculator {

  // ── CONSTANTES DEL SISTEMA ────────────────────────────────────────────────
  static const double _eficienciaSistema = 0.78;  // 78% eficiencia instalación
  static const double _potenciaPanelKW   = 0.40;  // Panel estándar 400W
  static const int    _diasAnio          = 365;

  // ── ENTRADA: Datos del usuario ────────────────────────────────────────────

  final double consumoAnualKWh;
  final double irradiacionKWhM2Dia;  // Varía según código postal
  final double tiltGrados;
  final double azimutGrados;
  final List<int> mesesAltoConsumo;
  final int horarioConsumoIndex;

  SolarCalculator({
    required this.consumoAnualKWh,
    required this.irradiacionKWhM2Dia,
    required this.tiltGrados,
    required this.azimutGrados,
    required this.mesesAltoConsumo,
    required this.horarioConsumoIndex,
  });

  // ── CÁLCULOS PRINCIPALES ─────────────────────────────────────────────────

  /// Número de paneles de 400W necesarios para cubrir el consumo anual.
  int get panelesSugeridos {
    final generacionPorPanel = _potenciaPanelKW * irradiacionKWhM2Dia
        * _diasAnio * _eficienciaSistema;
    return (consumoAnualKWh / generacionPorPanel).ceil();
  }

  /// Generación anual total estimada con [numPaneles] paneles.
  double generacionAnual(int numPaneles) {
    return numPaneles * _potenciaPanelKW * irradiacionKWhM2Dia
        * _diasAnio * _eficienciaSistema;
  }

  /// Consumo residual esperado (lo que seguirás pagando a la CFE).
  double get consumoResidualKWh {
    final gen = generacionAnual(panelesSugeridos);
    return (consumoAnualKWh - gen).clamp(0.0, consumoAnualKWh);
  }

  /// Ahorro anual estimado en kWh.
  double get ahorroAnualKWh => consumoAnualKWh - consumoResidualKWh;

  /// Porcentaje de cobertura solar (0.0 – 1.0).
  double get porcentajeCobertura =>
      (ahorroAnualKWh / consumoAnualKWh).clamp(0.0, 1.0);

  /// Factor de ajuste por horario de consumo.
  /// Si consumes de tarde (alta irradiación) el sistema es más eficiente.
  double get factorHorario {
    switch (horarioConsumoIndex) {
      case 0: return 0.85; // Madrugada — necesitas batería
      case 1: return 0.95; // Mañana
      case 2: return 1.05; // Tarde — mayor irradiación coincide con consumo
      case 3: return 0.80; // Noche — dependes de batería o red
      default: return 1.0;
    }
  }

  /// Retorno de inversión en años dado el precio del producto.
  /// Usa precio promedio de kWh CFE = $2.50 MXN.
  double retornoInversion(double precioProducto, {double preciokWhCFE = 2.50}) {
    final ahorroAnualMXN = ahorroAnualKWh * preciokWhCFE * factorHorario;
    if (ahorroAnualMXN <= 0) return double.infinity;
    return precioProducto / ahorroAnualMXN;
  }

  // ── FILTRADO Y RECOMENDACIÓN DE PRODUCTOS ────────────────────────────────

  /// Recibe la lista completa de productos y devuelve los recomendados,
  /// ordenados por mejor relación cobertura/precio.
  List<Product> recomendar(List<Product> productos) {
    final scored = productos.map((p) {
      final score = _calcularScore(p);
      return _ScoredProduct(p, score);
    }).toList();

    // Ordenar de mayor a menor score
    scored.sort((a, b) => b.score.compareTo(a.score));

    // Marcar los top 3 como recomendados
    final recomendados = scored.take(3).map((sp) {
      return sp.product.copyWith(esRecomendado: true);
    }).toList();

    final resto = scored.skip(3).map((sp) => sp.product).toList();

    return [...recomendados, ...resto];
  }

  /// Filtra solo los productos que cubren al menos [coberturaMinimaKWh].
  List<Product> filtrarPorCobertura(
    List<Product> productos, {
    double coberturaMinimaKWh = 0,
  }) {
    return productos.where((p) {
      if (p.potenciaKW == null) return true; // Baterías pasan siempre
      final genAnual = (p.potenciaKW! / _potenciaPanelKW) *
          generacionAnual(1) *
          (p.cantidadPaneles ?? 1);
      return genAnual >= coberturaMinimaKWh;
    }).toList();
  }

  /// Score de un producto basado en:
  /// - Cobertura respecto al consumo del usuario (40%)
  /// - ROI: qué tan rápido se paga solo (30%)
  /// - Garantía (20%)
  /// - Factor horario (10%)
  double _calcularScore(Product p) {
    // 1. Cobertura
    double coberturaScore = 0;
    if (p.potenciaKW != null) {
      final numPaneles = p.cantidadPaneles ?? (p.potenciaKW! / _potenciaPanelKW).round();
      final gen = generacionAnual(numPaneles);
      coberturaScore = (gen / consumoAnualKWh).clamp(0.0, 1.0) * 40;
    } else {
      coberturaScore = 20; // Baterías reciben puntaje medio en cobertura
    }

    // 2. ROI (invertido: menor ROI = mejor)
    final roi = retornoInversion(p.precio);
    final roiScore = roi.isInfinite ? 0.0 : (1 / roi.clamp(1, 30)) * 30;

    // 3. Garantía (25 años = máximo)
    final garantiaScore = (p.garantiaAnios / 25.0).clamp(0.0, 1.0) * 20;

    // 4. Factor horario
    final horarioScore = factorHorario * 10;

    return coberturaScore + roiScore + garantiaScore + horarioScore;
  }

  // ── RADIACÍON SOLAR POR CÓDIGO POSTAL ────────────────────────────────────

  /// Devuelve la irradiación solar estimada según código postal mexicano.
  static SolarLocationData calcularUbicacion(String codigoPostal) {
    final cp = int.tryParse(codigoPostal) ?? 6600;

    if (cp < 20000) {
      return SolarLocationData(
        localidad: 'Ciudad de México',
        irradiacion: 5.8,
        tiltDefault: 22,
        azimutDefault: 180,
      );
    } else if (cp < 30000) {
      return SolarLocationData(
        localidad: 'Veracruz / Oaxaca',
        irradiacion: 5.5,
        tiltDefault: 18,
        azimutDefault: 180,
      );
    } else if (cp < 45000) {
      return SolarLocationData(
        localidad: 'Occidente / Jalisco',
        irradiacion: 6.2,
        tiltDefault: 24,
        azimutDefault: 180,
      );
    } else if (cp < 65000) {
      return SolarLocationData(
        localidad: 'Norte / Nuevo León',
        irradiacion: 6.8,
        tiltDefault: 28,
        azimutDefault: 180,
      );
    } else if (cp < 85000) {
      return SolarLocationData(
        localidad: 'Noroeste / Sonora',
        irradiacion: 7.1,
        tiltDefault: 30,
        azimutDefault: 180,
      );
    } else {
      return SolarLocationData(
        localidad: 'Yucatán / Caribe',
        irradiacion: 5.6,
        tiltDefault: 16,
        azimutDefault: 180,
      );
    }
  }

  /// Ajusta el azimut según el horario de mayor consumo.
  static double calcularAzimut(int horarioIndex) {
    switch (horarioIndex) {
      case 0: return 180.0; // Madrugada → Sur puro
      case 1: return 135.0; // Mañana → Sur-Este
      case 2: return 225.0; // Tarde → Sur-Oeste
      case 3: return 180.0; // Noche → Sur puro (máxima captación diurna)
      default: return 180.0;
    }
  }

  /// Ajusta el tilt según el horario y la latitud de la zona.
  static double calcularTilt(int horarioIndex, double latitud) {
    // Tilt base = latitud × 0.87 (fórmula estándar para México)
    final base = (latitud.abs() * 0.87).clamp(10.0, 35.0);
    switch (horarioIndex) {
      case 2: return base + 3; // Tarde: más inclinado
      case 1: return base - 2; // Mañana: menos inclinado
      default: return base;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS AUXILIARES
// ─────────────────────────────────────────────────────────────────────────────

/// Resultado del cálculo de ubicación solar.
class SolarLocationData {
  final String localidad;
  final double irradiacion;    // kWh/m²/día
  final double tiltDefault;    // Grados de inclinación
  final double azimutDefault;  // Grados de orientación

  const SolarLocationData({
    required this.localidad,
    required this.irradiacion,
    required this.tiltDefault,
    required this.azimutDefault,
  });
}

/// Producto con su puntuación para ordenamiento interno.
class _ScoredProduct {
  final Product product;
  final double score;
  const _ScoredProduct(this.product, this.score);
}