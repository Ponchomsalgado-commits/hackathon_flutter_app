// ─────────────────────────────────────────────────────────────────────────────
// GEOCODING SERVICE
// Convierte un código postal mexicano en latitud y longitud.
// Por ahora usa tabla interna. Cuando tengas API Key de Google,
// descomenta el bloque HTTP al final del archivo.
// ─────────────────────────────────────────────────────────────────────────────

class GeocodingService {
  /// Convierte un código postal mexicano en coordenadas.
  Future<GeoLocation> getLocation(String codigoPostal) async {
    return _fallbackLocation(codigoPostal);
  }

  /// Tabla interna por código postal mexicano.
  GeoLocation _fallbackLocation(String codigoPostal) {
    final cp = int.tryParse(codigoPostal) ?? 6600;

    // CDMX y área metropolitana
    if (cp >= 1000 && cp <= 16999) {
      return GeoLocation(latitud: 19.4326, longitud: -99.1332,
          localidad: 'Ciudad de México', codigoPostal: codigoPostal);
    }
    // Estado de México
    if (cp >= 50000 && cp <= 57999) {
      return GeoLocation(latitud: 19.2965, longitud: -99.6568,
          localidad: 'Toluca', codigoPostal: codigoPostal);
    }
    // Jalisco / Guadalajara
    if (cp >= 44000 && cp <= 45999) {
      return GeoLocation(latitud: 20.6597, longitud: -103.3496,
          localidad: 'Guadalajara', codigoPostal: codigoPostal);
    }
    // Nuevo León / Monterrey
    if (cp >= 64000 && cp <= 67999) {
      return GeoLocation(latitud: 25.6866, longitud: -100.3161,
          localidad: 'Monterrey', codigoPostal: codigoPostal);
    }
    // Baja California / Tijuana
    if (cp >= 22000 && cp <= 22999) {
      return GeoLocation(latitud: 32.5149, longitud: -117.0382,
          localidad: 'Tijuana', codigoPostal: codigoPostal);
    }
    // Baja California / Mexicali
    if (cp >= 21000 && cp <= 21999) {
      return GeoLocation(latitud: 32.6245, longitud: -115.4523,
          localidad: 'Mexicali', codigoPostal: codigoPostal);
    }
    // Sonora / Hermosillo
    if (cp >= 83000 && cp <= 83999) {
      return GeoLocation(latitud: 29.0729, longitud: -110.9559,
          localidad: 'Hermosillo', codigoPostal: codigoPostal);
    }
    // Chihuahua
    if (cp >= 31000 && cp <= 31999) {
      return GeoLocation(latitud: 28.6329, longitud: -106.0691,
          localidad: 'Chihuahua', codigoPostal: codigoPostal);
    }
    // Coahuila / Saltillo
    if (cp >= 25000 && cp <= 25999) {
      return GeoLocation(latitud: 25.4232, longitud: -100.9963,
          localidad: 'Saltillo', codigoPostal: codigoPostal);
    }
    // Tamaulipas / Reynosa
    if (cp >= 88500 && cp <= 88799) {
      return GeoLocation(latitud: 26.0921, longitud: -98.2775,
          localidad: 'Reynosa', codigoPostal: codigoPostal);
    }
    // Tamaulipas / Matamoros
    if (cp >= 87000 && cp <= 87499) {
      return GeoLocation(latitud: 25.8691, longitud: -97.5026,
          localidad: 'Matamoros', codigoPostal: codigoPostal);
    }
    // Sinaloa / Culiacán
    if (cp >= 80000 && cp <= 80999) {
      return GeoLocation(latitud: 24.8049, longitud: -107.3940,
          localidad: 'Culiacán', codigoPostal: codigoPostal);
    }
    // Veracruz
    if (cp >= 91000 && cp <= 91999) {
      return GeoLocation(latitud: 19.1738, longitud: -96.1342,
          localidad: 'Veracruz', codigoPostal: codigoPostal);
    }
    // Puebla
    if (cp >= 72000 && cp <= 72999) {
      return GeoLocation(latitud: 19.0414, longitud: -98.2063,
          localidad: 'Puebla', codigoPostal: codigoPostal);
    }
    // Oaxaca
    if (cp >= 68000 && cp <= 68999) {
      return GeoLocation(latitud: 17.0732, longitud: -96.7266,
          localidad: 'Oaxaca', codigoPostal: codigoPostal);
    }
    // Yucatán / Mérida
    if (cp >= 97000 && cp <= 97999) {
      return GeoLocation(latitud: 20.9674, longitud: -89.6237,
          localidad: 'Mérida', codigoPostal: codigoPostal);
    }
    // Quintana Roo / Cancún
    if (cp >= 77500 && cp <= 77999) {
      return GeoLocation(latitud: 21.1743, longitud: -86.8466,
          localidad: 'Cancún', codigoPostal: codigoPostal);
    }
    // Guerrero / Acapulco
    if (cp >= 39000 && cp <= 39999) {
      return GeoLocation(latitud: 16.8531, longitud: -99.8237,
          localidad: 'Acapulco', codigoPostal: codigoPostal);
    }
    // Aguascalientes
    if (cp >= 20000 && cp <= 20999) {
      return GeoLocation(latitud: 21.8853, longitud: -102.2916,
          localidad: 'Aguascalientes', codigoPostal: codigoPostal);
    }
    // Querétaro
    if (cp >= 76000 && cp <= 76999) {
      return GeoLocation(latitud: 20.5888, longitud: -100.3899,
          localidad: 'Querétaro', codigoPostal: codigoPostal);
    }
    // San Luis Potosí
    if (cp >= 78000 && cp <= 78999) {
      return GeoLocation(latitud: 22.1565, longitud: -100.9855,
          localidad: 'San Luis Potosí', codigoPostal: codigoPostal);
    }
    // Default: CDMX
    return GeoLocation(latitud: 19.4326, longitud: -99.1332,
        localidad: 'México', codigoPostal: codigoPostal);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS
// ─────────────────────────────────────────────────────────────────────────────

class GeoLocation {
  final double latitud;
  final double longitud;
  final String localidad;
  final String codigoPostal;

  const GeoLocation({
    required this.latitud,
    required this.longitud,
    required this.localidad,
    required this.codigoPostal,
  });

  @override
  String toString() =>
      'GeoLocation($localidad: $latitud, $longitud)';
}

class GeocodingException implements Exception {
  final String message;
  const GeocodingException(this.message);
  @override
  String toString() => 'GeocodingException: $message';
}