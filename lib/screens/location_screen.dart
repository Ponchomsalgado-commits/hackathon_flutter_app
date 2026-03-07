import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
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

  void _simulateLocation() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _locationLoading = true;
      _usingLocation = false;
      _postalController.clear();
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _locationLoading = false;
        _usingLocation = true;
        _postalController.text = '06600'; // CDMX simulado
      });
      HapticFeedback.lightImpact();
    }
  }

  bool get _canContinue =>
      _postalController.text.trim().length >= 4 || _usingLocation;

  void _onNext() {
    if (!_canContinue) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuestionsScreen(),
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
                            onTap: _locationLoading ? null : _simulateLocation,
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
                    child: _buildNextButton(),
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
    final enabled = _canContinue;
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
          border: enabled
              ? null
              : Border.all(color: AppColors.border, width: 1),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.solarOrange.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Siguiente',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.white : AppColors.textHint,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_rounded,
              color: enabled ? Colors.white : AppColors.textHint,
              size: 20,
            ),
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
