import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/nasa_power_service.dart';
import '../logic/solar_calculator.dart';
import 'package:flutter_application_1/screens/results_screen.dart';

class QuestionsScreen extends StatefulWidget {
  final String codigoPostal;
  final String localidad;
  final double latitud;
  final double longitud;
  final SolarIrradiationData irradiacionData;

  const QuestionsScreen({
    super.key,
    required this.codigoPostal,
    required this.localidad,
    required this.latitud,
    required this.longitud,
    required this.irradiacionData,
  });

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen>
    with TickerProviderStateMixin {
  int _currentQuestion = 0;

  // Respuestas seleccionadas
  final Set<int> _selectedMonths = {};
  int? _selectedHorario;
  final TextEditingController _consumoController = TextEditingController();
  final FocusNode _consumoFocus = FocusNode();
  double _presupuesto = 100000; // valor default del slider

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  final List<String> _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril',
    'Mayo', 'Junio', 'Julio', 'Agosto',
    'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  final List<Map<String, dynamic>> _horarios = [
    {'icon': Icons.wb_twilight_rounded, 'label': 'Madrugada', 'sub': '12am – 6am'},
    {'icon': Icons.wb_sunny_outlined, 'label': 'Mañana', 'sub': '6am – 12pm'},
    {'icon': Icons.light_mode_rounded, 'label': 'Tarde', 'sub': '12pm – 6pm'},
    {'icon': Icons.nights_stay_rounded, 'label': 'Noche', 'sub': '6pm – 12am'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _consumoController.dispose();
    _consumoFocus.dispose();
    super.dispose();
  }

  void _animateToQuestion(int index) {
    _fadeController.reverse().then((_) {
      setState(() => _currentQuestion = index);
      _fadeController.forward();
    });
  }

  bool get _canContinue {
    if (_currentQuestion == 0) return _selectedMonths.isNotEmpty;
    if (_currentQuestion == 1) return _selectedHorario != null;
    if (_currentQuestion == 2) return _consumoController.text.trim().isNotEmpty;
    if (_currentQuestion == 3) return true; // slider siempre tiene valor
    return false;
  }

  void _onNext() {
    if (!_canContinue) return;
    HapticFeedback.mediumImpact();
    if (_currentQuestion < 3) {
      _animateToQuestion(_currentQuestion + 1);
    } else {
      final horarioIndex = _selectedHorario ?? 2;

      final tiltReal = SolarCalculator.calcularTilt(
        horarioIndex,
        widget.irradiacionData.latitud.abs(),
      );
      final azimutReal = SolarCalculator.calcularAzimut(horarioIndex);

      final gtiCorregido = widget.irradiacionData.gtiMensual.map((ghi) {
        final factor = _factorCorreccion(tiltReal, azimutReal, widget.latitud);
        return ghi * factor;
      }).toList();

      final promedioCorregido =
          gtiCorregido.reduce((a, b) => a + b) / gtiCorregido.length;

      final irradiacionCorregida = SolarIrradiationData(
        ghiMensual: widget.irradiacionData.ghiMensual,
        gtiMensual: gtiCorregido,
        promedioDiarioGTI: promedioCorregido,
        tiltUsado: tiltReal,
        azimutUsado: azimutReal,
        latitud: widget.irradiacionData.latitud,
        longitud: widget.irradiacionData.longitud,
        fuenteReal: widget.irradiacionData.fuenteReal,
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            codigoPostal: widget.codigoPostal,
            localidad: widget.localidad,
            latitud: widget.latitud,
            longitud: widget.longitud,
            irradiacionData: irradiacionCorregida,
            mesesAltoConsumo: _selectedMonths.toList(),
            horarioIndex: horarioIndex,
            consumoAnual: double.tryParse(_consumoController.text) ?? 3600,
            presupuesto: _presupuesto,
          ),
        ),
      );
    }
  }

  /// Factor de corrección GTI según tilt y azimut del usuario.
  double _factorCorreccion(double tilt, double azimut, double latitud) {
    final tiltOptimo = latitud.abs() * 0.87;
    final difTilt = (tilt - tiltOptimo).abs();
    final factorTilt = 1.0 - (difTilt / (tiltOptimo + 1)) * 0.15;
    final difAzimut = (azimut - 180).abs();
    final factorAzimut = 1.0 - (difAzimut / 180) * 0.20;
    return (factorTilt * factorAzimut).clamp(0.75, 1.15);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_currentQuestion > 0) {
                            _animateToQuestion(_currentQuestion - 1);
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundCard,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: AppColors.border, width: 1),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Paso ${_currentQuestion + 2} de 6',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textHint,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                Text(
                                  '${((_currentQuestion + 2) / 6 * 100).toInt()}%',
                                  style: const TextStyle(
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
                                value: (_currentQuestion + 2) / 6,
                                backgroundColor: AppColors.border,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
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

                // Contenido animado
                Expanded(
                  child: AnimatedBuilder(
                    animation: _fadeController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnim.value,
                        child: Transform.translate(
                          offset: Offset(0, _slideAnim.value),
                          child: child,
                        ),
                      );
                    },
                    child: _buildCurrentQuestion(),
                  ),
                ),

                // Botón siguiente
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                  child: _buildNextButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentQuestion() {
    switch (_currentQuestion) {
      case 0:
        return _buildMesesQuestion();
      case 1:
        return _buildHorarioQuestion();
      case 2:
        return _buildConsumoQuestion();
      case 3:
        return _buildPresupuestoQuestion();
      default:
        return const SizedBox();
    }
  }

  // ── PREGUNTA 1: Meses ──────────────────────────────────────────
  Widget _buildMesesQuestion() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          _buildQuestionHeader(
            icon: Icons.calendar_month_rounded,
            title: '¿En qué meses\nconsumes más energía?',
            subtitle: 'Puedes seleccionar varios meses.',
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: _meses.length,
            itemBuilder: (context, i) {
              final selected = _selectedMonths.contains(i);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (selected) {
                      _selectedMonths.remove(i);
                    } else {
                      _selectedMonths.add(i);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.solarOrange.withOpacity(0.15)
                        : AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppColors.solarOrange
                          : AppColors.border,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _meses[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected
                            ? AppColors.solarOrange
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── PREGUNTA 2: Horario ────────────────────────────────────────
  Widget _buildHorarioQuestion() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          _buildQuestionHeader(
            icon: Icons.schedule_rounded,
            title: '¿En qué horario\nconsumes más energía?',
            subtitle: 'Selecciona el horario de mayor uso.',
          ),
          const SizedBox(height: 32),
          ...List.generate(_horarios.length, (i) {
            final selected = _selectedHorario == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedHorario = i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 72,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.solarOrange.withOpacity(0.12)
                        : AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? AppColors.solarOrange
                          : AppColors.border,
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.solarOrange.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.solarOrange.withOpacity(0.2)
                                : AppColors.backgroundInput,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _horarios[i]['icon'] as IconData,
                            color: selected
                                ? AppColors.solarOrange
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _horarios[i]['label'] as String,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? AppColors.solarOrange
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                _horarios[i]['sub'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.solarOrange,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── PREGUNTA 3: Consumo ────────────────────────────────────────
  Widget _buildConsumoQuestion() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          _buildQuestionHeader(
            icon: Icons.bolt_rounded,
            title: 'Consumo anual\nneto (kWh)',
            subtitle:
                'Puedes encontrarlo en tu recibo de luz o en tu portal CFE.',
          ),
          const SizedBox(height: 36),

          // Campo de entrada
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppColors.backgroundInput,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _consumoFocus.hasFocus
                    ? AppColors.solarOrange
                    : AppColors.border,
                width: _consumoFocus.hasFocus ? 2 : 1,
              ),
              boxShadow: _consumoFocus.hasFocus
                  ? [
                      BoxShadow(
                        color: AppColors.solarOrange.withOpacity(0.12),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: TextField(
              controller: _consumoController,
              focusNode: _consumoFocus,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 1,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textHint,
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 20, right: 12, top: 2),
                  child: Icon(
                    Icons.electric_bolt_rounded,
                    color: AppColors.solarOrange,
                    size: 24,
                  ),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 60, minHeight: 0),
                suffixIcon: const Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      'kWh',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 20),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Tarjetas de referencia
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'REFERENCIAS TÍPICAS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHint,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRefRow('Casa pequeña', '1,200 – 2,400 kWh/año'),
                _buildRefRow('Casa mediana', '2,400 – 6,000 kWh/año'),
                _buildRefRow('Casa grande', '6,000 – 14,400 kWh/año'),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRefRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.solarOrange,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── PREGUNTA 4: Presupuesto ────────────────────────────────────
  Widget _buildPresupuestoQuestion() {
    final min = 5000.0;
    final max = 500000.0;

    String _formatMXN(double val) {
      if (val >= 1000000) return '\$${(val / 1000000).toStringAsFixed(1)}M';
      if (val >= 1000) return '\$${(val / 1000).toStringAsFixed(0)}k';
      return '\$${val.toStringAsFixed(0)}';
    }

    // Etiqueta de rango según presupuesto
    String _rangoLabel() {
      if (_presupuesto < 50000) return 'Panel individual o batería básica';
      if (_presupuesto < 100000) return 'Kit solar pequeño (2–4 paneles)';
      if (_presupuesto < 200000) return 'Kit solar mediano (4–8 paneles)';
      if (_presupuesto < 350000) return 'Sistema completo con batería';
      return 'Sistema premium de alta autonomía';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _buildQuestionHeader(
            icon: Icons.account_balance_wallet_rounded,
            title: '¿Cuál es tu\npresupuesto?',
            subtitle: 'Desliza para indicar cuánto puedes invertir.',
          ),
          const SizedBox(height: 48),

          // Monto actual
          Center(
            child: Column(
              children: [
                Text(
                  _formatMXN(_presupuesto),
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    color: AppColors.solarOrange,
                    letterSpacing: -2,
                  ),
                ),
                const Text('MXN',
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textHint,
                        letterSpacing: 2)),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.solarOrange,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.solarOrange,
              overlayColor: AppColors.solarOrange.withValues(alpha: 0.15),
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 14),
              trackHeight: 6,
            ),
            child: Slider(
              value: _presupuesto,
              min: min,
              max: max,
              divisions: 96,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                setState(() => _presupuesto = val);
              },
            ),
          ),

          // Min / Max labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatMXN(min),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint)),
                Text(_formatMXN(max),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Descripción del rango
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_rounded,
                    color: AppColors.solarOrange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _rangoLabel(),
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // ── Header reutilizable ────────────────────────────────────────
  Widget _buildQuestionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                color: AppColors.solarOrange.withOpacity(0.3), width: 1),
          ),
          child: Icon(icon, color: AppColors.solarOrange, size: 26),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -1,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Botón siguiente ────────────────────────────────────────────
  Widget _buildNextButton() {
    final enabled = _canContinue;
    final isLast = _currentQuestion == 3;
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
              ? [
                  BoxShadow(
                    color: AppColors.solarOrange.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLast ? 'Ver resultados' : 'Siguiente',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.white : AppColors.textHint,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isLast ? Icons.solar_power_rounded : Icons.arrow_forward_rounded,
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
      child: CustomPaint(painter: _QuestionsBackgroundPainter()),
    );
  }
}

class _QuestionsBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0A0E1A), Color(0xFF0B1020), Color(0xFF0A0E1A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF5A623).withOpacity(0.05),
          Colors.transparent,
        ],
      ).createShader(
          Rect.fromCircle(center: Offset(0, size.height), radius: size.width));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}