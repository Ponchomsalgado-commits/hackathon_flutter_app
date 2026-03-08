import '../models/product_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER REPOSITORY
// Misma tubería doble que SolarRepository pero para proveedores.
// Tubería A: API externa (cuando el proveedor tenga endpoint)
// Tubería B: Lista local manual (datos de prueba / sin API)
// ─────────────────────────────────────────────────────────────────────────────

class ProviderRepository {
  // Cache en memoria
  List<Provider>? _cached;

  /// Devuelve todos los proveedores activos.
  Future<List<Provider>> getAll({bool forceRefresh = false}) async {
    if (_cached != null && !forceRefresh) return _cached!;

    final local = _localProviders();
    // Aquí puedes hacer: final api = await _fetchFromApi();
    // y combinar: [...local, ...api]

    _cached = local.where((p) => p.activo).toList();
    return _cached!;
  }

  /// Busca un proveedor por su ID.
  Future<Provider?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearCache() => _cached = null;

  // ── TUBERÍA B: Proveedores locales (edita aquí manualmente) ───────────────

  List<Provider> _localProviders() => [
    const Provider(
      id: 'tecnoligente',
      nombre: 'Tecnoligente',
      whatsapp: '5215512345678',
      email: 'ventas@tecnoligente.com',
      sitioWeb: 'https://tecnoligente.com',
      logoUrl: null,
      activo: true,
    ),
    const Provider(
      id: 'proveedor_a',
      nombre: 'SunPower México',
      whatsapp: '5215598765432',
      email: 'contacto@sunpowermexico.com',
      sitioWeb: 'https://sunpowermexico.com',
      logoUrl: null,
      activo: true,
    ),
    const Provider(
      id: 'proveedor_b',
      nombre: 'Enercity Solar',
      whatsapp: '5215511112222',
      email: 'info@enercitysolar.mx',
      sitioWeb: 'https://enercitysolar.mx',
      logoUrl: null,
      activo: true,
    ),
    const Provider(
      id: 'proveedor_c',
      nombre: 'Solaris Pro',
      whatsapp: '5215533334444',
      email: 'ventas@solarispro.mx',
      sitioWeb: 'https://solarispro.mx',
      logoUrl: null,
      activo: true,
    ),
  ];

  // ── TUBERÍA A: API externa (descomentar cuando esté disponible) ───────────
  // Future<List<Provider>> _fetchFromApi() async {
  //   final response = await http.get(Uri.parse('https://api.tuservidor.com/providers'));
  //   final list = json.decode(response.body) as List;
  //   return list.map((p) => Provider(
  //     id: p['id'],
  //     nombre: p['name'],
  //     whatsapp: p['whatsapp'],
  //     email: p['email'],
  //     sitioWeb: p['website'],
  //   )).toList();
  // }
}