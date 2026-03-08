/// Categorías de producto disponibles en el sistema.
enum ProductCategory { panel, bateria, paquete }

/// Modelo universal de producto solar.
/// Todos los proveedores se normalizan a esta clase.
class Product {
  final String id;
  final String proveedorId;
  final ProductCategory categoria;
  final String nombre;
  final String descripcion;
  final double precio;

  // Especificaciones técnicas
  final double? potenciaKW;       // kW pico (paneles y paquetes)
  final double? capacidadKWh;     // kWh almacenables (baterías y paquetes)
  final int? cantidadPaneles;     // Número de paneles incluidos

  // Rendimiento
  final double ahorroAnualEstimado; // kWh/año ahorrados estimados
  final int garantiaAnios;

  // Presentación
  final String? etiqueta;         // "Más popular", "Recomendado", etc.
  final bool esRecomendado;       // Calculado por SolarCalculator

  const Product({
    required this.id,
    required this.proveedorId,
    required this.categoria,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    this.potenciaKW,
    this.capacidadKWh,
    this.cantidadPaneles,
    required this.ahorroAnualEstimado,
    required this.garantiaAnios,
    this.etiqueta,
    this.esRecomendado = false,
  });

  /// Crea una copia del producto con campos modificados.
  Product copyWith({
    String? id,
    String? proveedorId,
    ProductCategory? categoria,
    String? nombre,
    String? descripcion,
    double? precio,
    double? potenciaKW,
    double? capacidadKWh,
    int? cantidadPaneles,
    double? ahorroAnualEstimado,
    int? garantiaAnios,
    String? etiqueta,
    bool? esRecomendado,
  }) {
    return Product(
      id: id ?? this.id,
      proveedorId: proveedorId ?? this.proveedorId,
      categoria: categoria ?? this.categoria,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      potenciaKW: potenciaKW ?? this.potenciaKW,
      capacidadKWh: capacidadKWh ?? this.capacidadKWh,
      cantidadPaneles: cantidadPaneles ?? this.cantidadPaneles,
      ahorroAnualEstimado: ahorroAnualEstimado ?? this.ahorroAnualEstimado,
      garantiaAnios: garantiaAnios ?? this.garantiaAnios,
      etiqueta: etiqueta ?? this.etiqueta,
      esRecomendado: esRecomendado ?? this.esRecomendado,
    );
  }

  /// Convierte el producto a un mapa JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'proveedorId': proveedorId,
    'categoria': categoria.name,
    'nombre': nombre,
    'descripcion': descripcion,
    'precio': precio,
    'potenciaKW': potenciaKW,
    'capacidadKWh': capacidadKWh,
    'cantidadPaneles': cantidadPaneles,
    'ahorroAnualEstimado': ahorroAnualEstimado,
    'garantiaAnios': garantiaAnios,
    'etiqueta': etiqueta,
    'esRecomendado': esRecomendado,
  };

  /// Construye un Product desde un mapa JSON normalizado.
  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    proveedorId: json['proveedorId'] as String,
    categoria: ProductCategory.values.firstWhere(
      (e) => e.name == json['categoria'],
      orElse: () => ProductCategory.panel,
    ),
    nombre: json['nombre'] as String,
    descripcion: json['descripcion'] as String? ?? '',
    precio: (json['precio'] as num).toDouble(),
    potenciaKW: (json['potenciaKW'] as num?)?.toDouble(),
    capacidadKWh: (json['capacidadKWh'] as num?)?.toDouble(),
    cantidadPaneles: json['cantidadPaneles'] as int?,
    ahorroAnualEstimado: (json['ahorroAnualEstimado'] as num).toDouble(),
    garantiaAnios: json['garantiaAnios'] as int,
    etiqueta: json['etiqueta'] as String?,
    esRecomendado: json['esRecomendado'] as bool? ?? false,
  );

  @override
  String toString() => 'Product($id | $nombre | \$$precio)';
}


/// Modelo del proveedor solar.
class Provider {
  final String id;
  final String nombre;
  final String? whatsapp;
  final String? email;
  final String? sitioWeb;
  final String? logoUrl;
  final String? apiUrl;
  final String? apiKey;
  final bool activo;

  const Provider({
    required this.id,
    required this.nombre,
    this.whatsapp,
    this.email,
    this.sitioWeb,
    this.logoUrl,
    this.apiUrl,
    this.apiKey,
    this.activo = true,
  });


  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'apiUrl': apiUrl,
    'activo': activo,
  };
}


/// Modelo del cálculo del usuario. Se guarda en DB local.
class UserCalculation {
  final String id;
  final DateTime fecha;
  final double consumoActualKWh;
  final String codigoPostal;
  final String localidad;
  final double irradiacionKWhM2Dia;
  final double tiltGrados;
  final double azimutGrados;
  final List<int> mesesAltoConsumo;
  final int horarioConsumoIndex;
  final List<String>? productosSeleccionados; // IDs de productos cotizados

  const UserCalculation({
    required this.id,
    required this.fecha,
    required this.consumoActualKWh,
    required this.codigoPostal,
    required this.localidad,
    required this.irradiacionKWhM2Dia,
    required this.tiltGrados,
    required this.azimutGrados,
    required this.mesesAltoConsumo,
    required this.horarioConsumoIndex,
    this.productosSeleccionados,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fecha': fecha.toIso8601String(),
    'consumoActualKWh': consumoActualKWh,
    'codigoPostal': codigoPostal,
    'localidad': localidad,
    'irradiacionKWhM2Dia': irradiacionKWhM2Dia,
    'tiltGrados': tiltGrados,
    'azimutGrados': azimutGrados,
    'mesesAltoConsumo': mesesAltoConsumo,
    'horarioConsumoIndex': horarioConsumoIndex,
    'productosSeleccionados': productosSeleccionados,
  };

  factory UserCalculation.fromJson(Map<String, dynamic> json) => UserCalculation(
    id: json['id'] as String,
    fecha: DateTime.parse(json['fecha'] as String),
    consumoActualKWh: (json['consumoActualKWh'] as num).toDouble(),
    codigoPostal: json['codigoPostal'] as String,
    localidad: json['localidad'] as String,
    irradiacionKWhM2Dia: (json['irradiacionKWhM2Dia'] as num).toDouble(),
    tiltGrados: (json['tiltGrados'] as num).toDouble(),
    azimutGrados: (json['azimutGrados'] as num).toDouble(),
    mesesAltoConsumo: List<int>.from(json['mesesAltoConsumo'] as List),
    horarioConsumoIndex: json['horarioConsumoIndex'] as int,
    productosSeleccionados: json['productosSeleccionados'] != null
        ? List<String>.from(json['productosSeleccionados'] as List)
        : null,
  );
}