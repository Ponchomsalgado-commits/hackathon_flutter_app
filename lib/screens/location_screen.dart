import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../services/geocoding_service.dart';
import '../services/nasa_power_service.dart';
import '../logic/solar_calculator.dart';
import 'package:flutter_application_1/screens/questions_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _postalController = TextEditingController();
  final FocusNode _postalFocus = FocusNode();
  bool _isInputFocused = false;
  bool _usingLocation = false;
  bool _locationLoading = false;
  bool _nasaLoading = false;
  String? _nasaError;
  double? _gpsLatitud;
  double? _gpsLongitud;

  late AnimationController _fadeController;
  late Animation<double> _headerFade;
  late Animation<double> _cardFade;
  late Animation<double> _buttonFade;

  @override
  void initState() {
    super.initState();

    _postalFocus.addListener(() {
      setState(() => _isInputFocused = _postalFocus.hasFocus);
    });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _cardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.3, 0.75, curve: Curves.easeOut),
      ),
    );

    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _postalController.dispose();
    _postalFocus.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    HapticFeedback.mediumImpact();
    setState(() { _locationLoading = true; _usingLocation = false; });

    try {
      // 1. Verificar si el servicio de ubicación está habilitado
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Activa el GPS de tu dispositivo e intenta de nuevo.');
        return;
      }

      // 2. Verificar y solicitar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Permiso de ubicación denegado.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showLocationError('Permiso denegado permanentemente. Actívalo en Configuración.');
        return;
      }

      // 3. Obtener posición GPS real
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      // 4. Convertir lat/lng a CP aproximado usando tabla inversa
      final cpAproximado = _latLngToCP(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _locationLoading = false;
          _usingLocation = true;
          _postalController.text = cpAproximado;
          // Guardar coordenadas reales para usarlas en _onNext
          _gpsLatitud = position.latitude;
          _gpsLongitud = position.longitude;
        });
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showLocationError('No se pudo obtener la ubicación. Ingresa tu CP manualmente.');
    }
  }

  void _showLocationError(String msg) {
    if (!mounted) return;
    setState(() => _locationLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  /// Convierte lat/lng a código postal aproximado por zona de México
  String _latLngToCP(double lat, double lng) {
    // Norte (Baja California, Sonora, Chihuahua)
    if (lat >= 28) {
      if (lng <= -114) return '21000'; // Mexicali/Tijuana
      if (lng <= -109) return '83000'; // Hermosillo
      return '31000'; // Chihuahua
    }
    // Noreste (Coahuila, Nuevo León, Tamaulipas)
    if (lat >= 24 && lng >= -102) return '64000'; // Monterrey
    // Occidente (Jalisco, Colima, Nayarit)
    if (lat >= 19 && lat < 22 && lng <= -102) return '44100'; // Guadalajara
    // Centro (CDMX, Estado de México, Morelos)
    if (lat >= 18 && lat < 20 && lng >= -100 && lng <= -98) return '06600'; // CDMX
    // Sur (Oaxaca, Chiapas, Guerrero)
    if (lat < 18) return '68000'; // Oaxaca
    // Sureste (Yucatán, Quintana Roo)
    if (lng >= -92) return '97000'; // Mérida
    // Default
    return '06600';
  }

  bool get _canContinue =>
      _postalController.text.trim().length >= 4 || _usingLocation;

  Future<void> _onNext() async {
    if (!_canContinue || _nasaLoading) return;
    HapticFeedback.mediumImpact();

    final cp = _postalController.text.trim();
    setState(() { _nasaLoading = true; _nasaError = null; });

    // Si usó GPS, tenemos lat/lng exactos — si no, usar tabla por CP
    late double latitud;
    late double longitud;
    late String localidad;

    if (_usingLocation && _gpsLatitud != null && _gpsLongitud != null) {
      // Coordenadas GPS reales — máxima precisión para NASA POWER
      latitud = _gpsLatitud!;
      longitud = _gpsLongitud!;
      localidad = 'Tu ubicación';
    } else {
      // Tabla interna por CP
      final geo = await GeocodingService().getLocation(cp);
      latitud = geo.latitud;
      longitud = geo.longitud;
      localidad = geo.localidad;
    }

    // lat/lng → irradiación (NASA POWER o fallback histórico)
    final nasa = await NasaPowerService().getIrradiation(
      latitud: latitud,
      longitud: longitud,
      tilt: SolarCalculator.calcularTilt(2, latitud.abs()),
      azimut: 180,
    );

    if (!mounted) return;
    setState(() => _nasaLoading = false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuestionsScreen(
          codigoPostal: cp,
          localidad: localidad,
          latitud: latitud,
          longitud: longitud,
          irradiacionData: nasa,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Fondo estático
          _buildBackground(),

          SafeArea(
            child: Column(
              children: [
                // Top bar con botón de regreso y progreso
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      // Botón atrás
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.border, width: 1),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Barra de progreso
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Paso 1 de 4',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textHint,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                Text(
                                  '25%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.solarOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: 0.25,
                                backgroundColor: AppColors.border,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.solarOrange),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenido scrollable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),

                        // Ícono de ubicación animado
                        FadeTransition(
                          opacity: _headerFade,
                          child: _buildLocationIcon(),
                        ),

                        const SizedBox(height: 28),

                        // Pregunta principal
                        FadeTransition(
                          opacity: _headerFade,
                          child: AnimatedBuilder(
                            animation: _fadeController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                    0,
                                    20 *
                                        (1 -
                                            Curves.easeOut.transform(
                                                _headerFade.value))),
                                child: child,
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '¿Dónde instalará',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w300,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -1,
                                    height: 1.15,
                                  ),
                                ),
                                Text(
                                  'los paneles solares?',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -1,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Necesitamos tu ubicación para calcular\nla irradiación solar y el potencial de ahorro.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Campo de código postal
                        FadeTransition(
                          opacity: _cardFade,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CÓDIGO POSTAL',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textHint,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundInput,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _isInputFocused
                                        ? AppColors.borderActive
                                        : _usingLocation
                                            ? AppColors.solarOrange
                                                .withOpacity(0.5)
                                            : AppColors.border,
                                    width: _isInputFocused ? 2 : 1,
                                  ),
                                  boxShadow: _isInputFocused
                                      ? [
                                          BoxShadow(
                                            color: AppColors.solarOrange
                                                .withOpacity(0.12),
                                            blurRadius: 16,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: TextField(
                                  controller: _postalController,
                                  focusNode: _postalFocus,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(5),
                                  ],
                                  onChanged: (_) => setState(() {}),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    letterSpacing: 4,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Ej. 06600',
                                    hintStyle: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textHint,
                                      letterSpacing: 2,
                                    ),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 18, right: 12),
                                      child: Icon(
                                        Icons.location_on_rounded,
                                        color: _isInputFocused
                                            ? AppColors.solarOrange
                                            : _usingLocation
                                                ? AppColors.solarOrange
                                                : AppColors.textHint,
                                        size: 22,
                                      ),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(
                                        minWidth: 56, minHeight: 0),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 18),
                                    suffixIcon: _postalController
                                            .text.isNotEmpty
                                        ? GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _postalController.clear();
                                                _usingLocation = false;
                                              });
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 16),
                                              child: Icon(
                                                Icons.close_rounded,
                                                color: AppColors.textHint,
                                                size: 18,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),

                              // Badge de ubicación detectada
                              if (_usingLocation)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.solarOrange,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Ubicación detectada automáticamente',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.solarOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Divisor "o"
                        FadeTransition(
                          opacity: _cardFade,
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                    height: 1,
                                    color: AppColors.border),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'ó',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                    height: 1,
                                    color: AppColors.border),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Botón "Usar mi ubicación"
                        FadeTransition(
                          opacity: _cardFade,
                          child: GestureDetector(
                            onTap: _locationLoading ? null : _useMyLocation,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: double.infinity,
                              height: 58,
                              decoration: BoxDecoration(
                                color: _usingLocation
                                    ? AppColors.solarOrange.withOpacity(0.12)
                                    : AppColors.backgroundCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _usingLocation
                                      ? AppColors.solarOrange.withOpacity(0.5)
                                      : AppColors.border,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_locationLoading)
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                AppColors.solarOrange),
                                      ),
                                    )
                                  else
                                    Icon(
                                      _usingLocation
                                          ? Icons.my_location_rounded
                                          : Icons.gps_fixed_rounded,
                                      color: _usingLocation
                                          ? AppColors.solarOrange
                                          : AppColors.textSecondary,
                                      size: 20,
                                    ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _locationLoading
                                        ? 'Detectando ubicación...'
                                        : _usingLocation
                                            ? 'Usando mi ubicación'
                                            : 'Usar mi ubicación',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: _usingLocation
                                          ? AppColors.solarOrange
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),

                // Botón Siguiente fijo abajo
                FadeTransition(
                  opacity: _buttonFade,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                    child: Column(
                      children: [
                        if (_nasaError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Colors.redAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_nasaError!,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.redAccent))),
                            ]),
                          ),
                        _buildNextButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.solarOrange.withOpacity(0.2),
            AppColors.solarOrange.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.solarOrange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: const Icon(
        Icons.solar_power_rounded,
        color: AppColors.solarOrange,
        size: 26,
      ),
    );
  }

  Widget _buildNextButton() {
    final enabled = _canContinue && !_nasaLoading;
    return GestureDetector(
      onTap: enabled ? _onNext : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [AppColors.solarOrange, AppColors.solarGlow],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: enabled ? null : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: enabled ? null : Border.all(color: AppColors.border, width: 1),
          boxShadow: enabled
              ? [BoxShadow(color: AppColors.solarOrange.withOpacity(0.35),
                  blurRadius: 18, offset: const Offset(0, 6))]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_nasaLoading) ...[
              const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
              const SizedBox(width: 12),
              const Text('Calculando irradiación...',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ] else ...[
              Text('Siguiente',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                      color: enabled ? Colors.white : AppColors.textHint,
                      letterSpacing: 0.3)),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded,
                  color: enabled ? Colors.white : AppColors.textHint, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _LocationBackgroundPainter(),
      ),
    );
  }
}

class _LocationBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0A0E1A),
          Color(0xFF0B1020),
          Color(0xFF0A0E1A),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Acento de luz en la esquina superior derecha
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF5A623).withOpacity(0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width, 0), radius: size.width * 0.6));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);

    // Líneas de cuadrícula muy sutiles
    final gridPaint = Paint()
      ..color = const Color(0xFFF5A623).withOpacity(0.025)
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}