import '../models/product_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// INTERFAZ BASE
// Cada proveedor implementa esta interfaz. Si un proveedor cambia su API,
// solo tocas su archivo, sin afectar el resto de la app.
// ─────────────────────────────────────────────────────────────────────────────

abstract class SolarDataSource {
  /// ID único del proveedor (ej: "proveedor_a")
  String get proveedorId;

  /// Nombre legible del proveedor (ej: "SunPower México")
  String get nombre;

  /// Obtiene la lista de productos RAW del proveedor.
  /// Lanza una excepción si la API falla.
  Future<List<Map<String, dynamic>>> fetchRawProducts();
}


// ─────────────────────────────────────────────────────────────────────────────
// PROVEEDOR A — Datos simulados (reemplazar con HTTP real)
// ─────────────────────────────────────────────────────────────────────────────

class ProviderADataSource implements SolarDataSource {
  @override
  String get proveedorId => 'proveedor_a';

  @override
  String get nombre => 'SunPower México';

  @override
  Future<List<Map<String, dynamic>>> fetchRawProducts() async {
    // Simula latencia de red
    await Future.delayed(const Duration(milliseconds: 400));

    // En producción: usar http.get(Uri.parse(apiUrl), headers: {'Authorization': apiKey})
    // y hacer json.decode(response.body)
    return [
      {
        'product_id': 'spa_001',
        'type': 'panel',
        'title': 'Panel Monocristalino 400W',
        'description': 'Alta eficiencia 21.5%',
        'cost': 8500.0,
        'power_kw': 0.4,
        'battery_kwh': null,
        'num_panels': 1,
        'yearly_savings': 2800.0,
        'warranty_years': 25,
        'badge': null,
      },
      {
        'product_id': 'spa_002',
        'type': 'package',
        'title': 'Solar Starter Pack',
        'description': 'Ideal para hogares pequeños',
        'cost': 85000.0,
        'power_kw': 1.6,
        'battery_kwh': 5.0,
        'num_panels': 4,
        'yearly_savings': 12000.0,
        'warranty_years': 10,
        'badge': 'Más popular',
      },
    ];
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// PROVEEDOR B — Formato JSON diferente al A (demostración de normalización)
// ─────────────────────────────────────────────────────────────────────────────

class ProviderBDataSource implements SolarDataSource {
  @override
  String get proveedorId => 'proveedor_b';

  @override
  String get nombre => 'Enercity Solar';

  @override
  Future<List<Map<String, dynamic>>> fetchRawProducts() async {
    await Future.delayed(const Duration(milliseconds: 600));

    // Este proveedor usa claves distintas: "item_name", "watt_peak", "price_mxn"
    return [
      {
        'item_id': 'spb_001',
        'item_name': 'Panel Bifacial 450W',
        'item_desc': 'Captación frontal y trasera',
        'price_mxn': 11200.0,
        'watt_peak': 450,          // en Watts, no kW
        'storage_kwh': null,
        'panel_count': 1,
        'annual_save': 3400.0,
        'guarantee': 30,
        'label': 'Alta eficiencia',
      },
      {
        'item_id': 'spb_002',
        'item_name': 'Batería LiFePO4 10kWh',
        'item_desc': 'Autonomía nocturna completa',
        'price_mxn': 58000.0,
        'watt_peak': null,
        'storage_kwh': 10.0,
        'panel_count': null,
        'annual_save': 8500.0,
        'guarantee': 12,
        'label': 'Más autonomía',
      },
      {
        'item_id': 'spb_003',
        'item_name': 'Paquete Solar Plus',
        'item_desc': 'Para consumo medio-alto',
        'price_mxn': 155000.0,
        'watt_peak': 3200,
        'storage_kwh': 10.0,
        'panel_count': 8,
        'annual_save': 22000.0,
        'guarantee': 15,
        'label': 'Recomendado',
      },
    ];
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// PROVEEDOR C — Estructura con "specs" anidados
// ─────────────────────────────────────────────────────────────────────────────

class ProviderCDataSource implements SolarDataSource {
  @override
  String get proveedorId => 'proveedor_c';

  @override
  String get nombre => 'Solaris Pro';

  @override
  Future<List<Map<String, dynamic>>> fetchRawProducts() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      {
        'uid': 'spc_001',
        'name': 'Solar Pro Bundle',
        'summary': 'Máxima independencia energética',
        'mxn_price': 240000.0,
        'specs': {
          'kw': 4.8,
          'kwh_storage': 20.0,
          'panels': 12,
        },
        'roi': {
          'yearly_kwh_saved': 35000.0,
          'warranty': 25,
        },
        'tag': 'Premium',
      },
      {
        'uid': 'spc_002',
        'name': 'Batería LiFePO4 5kWh',
        'summary': 'Ciclo de vida > 6000 cargas',
        'mxn_price': 32000.0,
        'specs': {
          'kw': null,
          'kwh_storage': 5.0,
          'panels': null,
        },
        'roi': {
          'yearly_kwh_saved': 4500.0,
          'warranty': 10,
        },
        'tag': null,
      },
    ];
  }
}