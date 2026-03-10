import '../models/product_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RECOMMENDATION ENGINE
// Ordena productos por score según el perfil del usuario.
//
// SCORE (0.0 → 1.0):
//   40% → Cobertura del consumo anual
//   35% → Ajuste al presupuesto
//   25% → Potencia del panel (W)
// ─────────────────────────────────────────────────────────────────────────────

class RecommendationEngine {
  final double consumoAnual;      // kWh/año del usuario
  final double irradiacion;       // kWh/m²/día (NASA POWER)
  final double presupuesto;       // MXN disponibles

  const RecommendationEngine({
    required this.consumoAnual,
    required this.irradiacion,
    required this.presupuesto,
  });

  /// Ordena los productos de mayor a menor score y asigna etiquetas.
  List<ScoredProduct> rank(List<Product> productos) {
    if (productos.isEmpty) return [];

    // 1. Calcular potencia máxima disponible (para normalizar)
    final maxPotenciaKW = productos
        .map((p) => _potenciaTotal(p))
        .reduce((a, b) => a > b ? a : b);

    // 2. Calcular score de cada producto
    final scored = productos.map((p) {
      final score = _calcularScore(p, maxPotenciaKW);
      return ScoredProduct(producto: p, score: score);
    }).toList();

    // 3. Ordenar de mayor a menor score
    scored.sort((a, b) => b.score.compareTo(a.score));

    // 4. Asignar etiquetas únicas al top 3
    final result = <ScoredProduct>[];
    for (int i = 0; i < scored.length; i++) {
      String? etiqueta;
      if (i == 0) etiqueta = '⭐ Top recomendado';
      else if (i == 1) etiqueta = '⚡ Mejor potencia';
      else if (i == 2) etiqueta = '💰 Mejor precio';

      result.add(ScoredProduct(
        producto: scored[i].producto.copyWith(
          etiqueta: etiqueta,
          esRecomendado: i < 3,
        ),
        score: scored[i].score,
        etiqueta: etiqueta,
      ));
    }

    return result;
  }

  // ── Score individual ────────────────────────────────────────────────────

  double _calcularScore(Product p, double maxPotenciaKW) {
    final scorCobertura = _scoreCobertura(p);      // 40%
    final scorePresupuesto = _scorePresupuesto(p); // 35%
    final scorePotencia = _scorePotencia(p, maxPotenciaKW); // 25%

    return (scorCobertura * 0.40) +
           (scorePresupuesto * 0.35) +
           (scorePotencia * 0.25);
  }

  /// Qué % del consumo anual cubre este producto (0.0 → 1.0)
  double _scoreCobertura(Product p) {
    final generacion = _generacionAnual(p);
    if (generacion <= 0) return 0;
    // Penaliza si genera MUY por encima del consumo (sobredimensionado)
    final ratio = generacion / consumoAnual;
    if (ratio >= 1.0) return 1.0 - ((ratio - 1.0) * 0.1).clamp(0, 0.3);
    return ratio.clamp(0, 1);
  }

  /// Qué tan bien encaja el precio en el presupuesto (0.0 → 1.0)
  double _scorePresupuesto(Product p) {
    if (p.precio <= 0) return 0;
    if (p.precio > presupuesto) {
      // Fuera de presupuesto — penaliza proporcionalmente
      final exceso = (p.precio - presupuesto) / presupuesto;
      return (1.0 - exceso).clamp(0, 0.5);
    }
    // Dentro del presupuesto — premia los que aprovechan bien el budget
    final uso = p.precio / presupuesto;
    // Óptimo entre 60% y 90% del presupuesto
    if (uso >= 0.6 && uso <= 0.9) return 1.0;
    if (uso < 0.6) return 0.6 + (uso / 0.6) * 0.4;
    return 1.0 - ((uso - 0.9) / 0.1) * 0.2;
  }

  /// Potencia total normalizada contra el máximo disponible (0.0 → 1.0)
  double _scorePotencia(Product p, double maxPotenciaKW) {
    if (maxPotenciaKW <= 0) return 0;
    return (_potenciaTotal(p) / maxPotenciaKW).clamp(0, 1);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Generación anual estimada del producto (kWh/año)
  double _generacionAnual(Product p) {
    final potencia = _potenciaTotal(p);
    if (potencia <= 0) return 0;
    return potencia * irradiacion * 365 * 0.78;
  }

  /// Potencia total del producto en kW
  double _potenciaTotal(Product p) {
    if (p.potenciaKW != null && p.cantidadPaneles != null) {
      return p.potenciaKW! * p.cantidadPaneles!;
    }
    if (p.potenciaKW != null) return p.potenciaKW!;
    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCORED PRODUCT — producto con su score calculado
// ─────────────────────────────────────────────────────────────────────────────

class ScoredProduct {
  final Product producto;
  final double score;           // 0.0 → 1.0
  final String? etiqueta;       // Solo top 3

  const ScoredProduct({
    required this.producto,
    required this.score,
    this.etiqueta,
  });

  /// Score como porcentaje legible (ej: "87%")
  String get scoreLabel => '${(score * 100).toStringAsFixed(0)}%';

  /// Cobertura estimada del consumo
  double coberturaEstimada(double consumoAnual, double irradiacion) {
    final potencia = _potenciaTotal();
    if (potencia <= 0 || consumoAnual <= 0) return 0;
    final generacion = potencia * irradiacion * 365 * 0.78;
    return (generacion / consumoAnual * 100).clamp(0, 100);
  }

  double _potenciaTotal() {
    if (producto.potenciaKW != null && producto.cantidadPaneles != null) {
      return producto.potenciaKW! * producto.cantidadPaneles!;
    }
    return producto.potenciaKW ?? 0;
  }
}
