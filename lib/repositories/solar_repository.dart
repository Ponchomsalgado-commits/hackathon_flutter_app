import '../models/product_model.dart';
import '../datasources/solar_datasources.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SOLAR REPOSITORY
// Orquesta todos los datasources, normaliza los datos y los entrega
// a la UI como List<Product> — sin importar el origen.
// ─────────────────────────────────────────────────────────────────────────────

class SolarRepository {
  // Lista de todos los proveedores registrados.
  // Para agregar un proveedor nuevo, solo añádelo aquí.
  final List<SolarDataSource> _dataSources = [
    ProviderADataSource(),
    ProviderBDataSource(),
    ProviderCDataSource(),
  ];

  // Cache en memoria para no repetir llamadas innecesarias.
  List<Product>? _cachedProducts;

  /// Obtiene todos los productos de todos los proveedores.
  /// Si ya están en caché, los devuelve sin llamar a las APIs.
  Future<List<Product>> getAllProducts({bool forceRefresh = false}) async {
    if (_cachedProducts != null && !forceRefresh) {
      return _cachedProducts!;
    }

    final List<Product> allProducts = [];

    // Llama a todos los proveedores en paralelo
    final futures = _dataSources.map((source) => _fetchAndNormalize(source));
    final results = await Future.wait(futures, eagerError: false);

    for (final productList in results) {
      allProducts.addAll(productList);
    }

    _cachedProducts = allProducts;
    return allProducts;
  }

  /// Obtiene productos filtrados por categoría.
  Future<List<Product>> getByCategory(ProductCategory category) async {
    final all = await getAllProducts();
    return all.where((p) => p.categoria == category).toList();
  }

  /// Obtiene productos de un proveedor específico.
  Future<List<Product>> getByProvider(String proveedorId) async {
    final all = await getAllProducts();
    return all.where((p) => p.proveedorId == proveedorId).toList();
  }

  /// Limpia el caché (útil al cambiar filtros o refrescar).
  void clearCache() => _cachedProducts = null;

  // ── FETCH + NORMALIZE ────────────────────────────────────────────────────

  /// Llama a un datasource y normaliza sus productos.
  /// Si falla, devuelve lista vacía (no rompe la app).
  Future<List<Product>> _fetchAndNormalize(SolarDataSource source) async {
    try {
      final rawList = await source.fetchRawProducts();
      return rawList
          .map((raw) => _normalize(raw, source.proveedorId))
          .whereType<Product>() // filtra nulos si el mapper falla
          .toList();
    } catch (e) {
      // Log del error sin romper el flujo
      print('[Repository] Error en ${source.nombre}: $e');
      return [];
    }
  }

  /// Mapper universal: detecta el formato y convierte a Product.
  Product? _normalize(Map<String, dynamic> raw, String proveedorId) {
    try {
      switch (proveedorId) {
        case 'proveedor_a':
          return _mapProviderA(raw);
        case 'proveedor_b':
          return _mapProviderB(raw);
        case 'proveedor_c':
          return _mapProviderC(raw);
        default:
          return null;
      }
    } catch (e) {
      print('[Repository] Error normalizando producto de $proveedorId: $e');
      return null;
    }
  }

  // ── MAPPERS INDIVIDUALES ─────────────────────────────────────────────────

  /// Mapper para Proveedor A (SunPower México)
  Product _mapProviderA(Map<String, dynamic> raw) {
    return Product(
      id: raw['product_id'] as String? ?? '',
      proveedorId: 'proveedor_a',
      categoria: _parseCategoryA(raw['type'] as String? ?? 'panel'),
      nombre: raw['title'] as String? ?? 'Sin nombre',
      descripcion: raw['description'] as String? ?? '',
      precio: (raw['cost'] as num?)?.toDouble() ?? 0,
      potenciaKW: (raw['power_kw'] as num?)?.toDouble(),
      capacidadKWh: (raw['battery_kwh'] as num?)?.toDouble(),
      cantidadPaneles: raw['num_panels'] as int?,
      ahorroAnualEstimado: (raw['yearly_savings'] as num?)?.toDouble() ?? 0,
      garantiaAnios: raw['warranty_years'] as int? ?? 0,
      etiqueta: raw['badge'] as String?,
    );
  }

  ProductCategory _parseCategoryA(String type) {
    switch (type) {
      case 'panel': return ProductCategory.panel;
      case 'battery': return ProductCategory.bateria;
      case 'package': return ProductCategory.paquete;
      default: return ProductCategory.panel;
    }
  }

  /// Mapper para Proveedor B (Enercity Solar)
  /// Nota: este proveedor usa "watt_peak" en Watts, lo convertimos a kW.
  Product _mapProviderB(Map<String, dynamic> raw) {
    final wattPeak = raw['watt_peak'] as num?;
    final potenciaKW = wattPeak != null ? wattPeak / 1000.0 : null;
    final storagekwh = raw['storage_kwh'] as num?;

    ProductCategory categoria;
    if (storagekwh != null && potenciaKW == null) {
      categoria = ProductCategory.bateria;
    } else if ((raw['panel_count'] as int? ?? 0) > 1) {
      categoria = ProductCategory.paquete;
    } else {
      categoria = ProductCategory.panel;
    }

    return Product(
      id: raw['item_id'] as String? ?? '',
      proveedorId: 'proveedor_b',
      categoria: categoria,
      nombre: raw['item_name'] as String? ?? 'Sin nombre',
      descripcion: raw['item_desc'] as String? ?? '',
      precio: (raw['price_mxn'] as num?)?.toDouble() ?? 0,
      potenciaKW: potenciaKW,
      capacidadKWh: storagekwh?.toDouble(),
      cantidadPaneles: raw['panel_count'] as int?,
      ahorroAnualEstimado: (raw['annual_save'] as num?)?.toDouble() ?? 0,
      garantiaAnios: raw['guarantee'] as int? ?? 0,
      etiqueta: raw['label'] as String?,
    );
  }

  /// Mapper para Proveedor C (Solaris Pro)
  /// Nota: este proveedor anida las specs bajo una clave 'specs' y 'roi'.
  Product _mapProviderC(Map<String, dynamic> raw) {
    final specs = raw['specs'] as Map<String, dynamic>? ?? {};
    final roi = raw['roi'] as Map<String, dynamic>? ?? {};
    final storagekwh = specs['kwh_storage'] as num?;
    final potenciaKW = (specs['kw'] as num?)?.toDouble();

    ProductCategory categoria;
    if (storagekwh != null && potenciaKW == null) {
      categoria = ProductCategory.bateria;
    } else if ((specs['panels'] as int? ?? 0) > 1) {
      categoria = ProductCategory.paquete;
    } else {
      categoria = ProductCategory.panel;
    }

    return Product(
      id: raw['uid'] as String? ?? '',
      proveedorId: 'proveedor_c',
      categoria: categoria,
      nombre: raw['name'] as String? ?? 'Sin nombre',
      descripcion: raw['summary'] as String? ?? '',
      precio: (raw['mxn_price'] as num?)?.toDouble() ?? 0,
      potenciaKW: potenciaKW,
      capacidadKWh: storagekwh?.toDouble(),
      cantidadPaneles: specs['panels'] as int?,
      ahorroAnualEstimado: (roi['yearly_kwh_saved'] as num?)?.toDouble() ?? 0,
      garantiaAnios: roi['warranty'] as int? ?? 0,
      etiqueta: raw['tag'] as String?,
    );
  }
}