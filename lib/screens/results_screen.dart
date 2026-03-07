import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import 'comparador_screen.dart';

class ResultsScreen extends StatefulWidget {
  final String codigoPostal;
  final List<int> mesesAltoConsumo;
  final int horarioIndex;
  final double consumoAnual;

  const ResultsScreen({
    super.key,
    this.codigoPostal = '06600',
    this.mesesAltoConsumo = const [5, 6, 7],
    this.horarioIndex = 2,
    this.consumoAnual = 3600,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _countController;
  late AnimationController _sunController;

  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _countAnim;
  late Animation<double> _sunRotation;

  // Datos calculados
  late double _radiacionSolar;
  late double _tilt;
  late double _azimut;
  late double _consumoEsperado;
  late double _ahorroEstimado;
  late double _panelesSugeridos;
  late String _localidad;

  final List<String> _horarioLabels = ['Madrugada', 'Mañana', 'Tarde', 'Noche'];
  final List<String> _meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];

  @override
  void initState() {
    super.initState();
    _calcularDatos();

    _sunController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _sunRotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _sunController, curve: Curves.linear),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    _countAnim = CurvedAnimation(parent: _countController, curve: Curves.easeOut);
  }

  void _calcularDatos() {
    // Radiación solar estimada por código postal (México)
    final cp = int.tryParse(widget.codigoPostal) ?? 6600;
    if (cp < 20000) {
      _radiacionSolar = 5.8; // CDMX / Centro
      _localidad = 'Ciudad de México';
    } else if (cp < 45000) {
      _radiacionSolar = 6.2; // Occidente / Jalisco
      _localidad = 'Occidente de México';
    } else if (cp < 65000) {
      _radiacionSolar = 6.8; // Norte / Monterrey
      _localidad = 'Norte de México';
    } else if (cp < 80000) {
      _radiacionSolar = 7.1; // Noroeste / Sonora
      _localidad = 'Noroeste de México';
    } else {
      _radiacionSolar = 5.5; // Sur / Sureste
      _localidad = 'Sur de México';
    }

    // Tilt y Azimut según horario de consumo
    // 0=Madrugada, 1=Mañana, 2=Tarde, 3=Noche
    switch (widget.horarioIndex) {
      case 0: // Madrugada — no aplica captación directa
        _tilt = 20;
        _azimut = 180; // Sur puro, máxima captación general
        break;
      case 1: // Mañana — orientar al Este
        _tilt = 25;
        _azimut = 135; // Sur-Este
        break;
      case 2: // Tarde — orientar al Oeste
        _tilt = 28;
        _azimut = 225; // Sur-Oeste
        break;
      case 3: // Noche — maximizar captación diurna
        _tilt = 22;
        _azimut = 180; // Sur puro
        break;
      default:
        _tilt = 25;
        _azimut = 180;
    }

    // Consumo esperado con paneles solares (reducción estimada)
    final eficienciaSistema = 0.78;
    final horasPico = _radiacionSolar;
    _panelesSugeridos = (widget.consumoAnual / (horasPico * 365 * 0.4 * eficienciaSistema)).ceilToDouble();
    final generacionAnual = _panelesSugeridos * 0.4 * horasPico * 365 * eficienciaSistema;
    _consumoEsperado = (widget.consumoAnual - generacionAnual).clamp(0, widget.consumoAnual);
    _ahorroEstimado = widget.consumoAnual - _consumoEsperado;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _countController.dispose();
    _sunController.dispose();
    super.dispose();
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
                _buildTopBar(),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _fadeController,
                    builder: (context, child) => Opacity(
                      opacity: _fadeAnim.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnim.value),
                        child: child,
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildHeader(),
                          const SizedBox(height: 28),
                          _buildConsumoCard(),
                          const SizedBox(height: 16),
                          _buildSolarGrid(),
                          const SizedBox(height: 16),
                          _buildMesesChart(),
                          const SizedBox(height: 16),
                          _buildPanelesCard(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildComparadorButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textSecondary, size: 16),
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
                    const Text('Paso 5 de 5',
                        style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                    const Text('100%',
                        style: TextStyle(fontSize: 12, color: AppColors.solarOrange,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 1.0,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.solarOrange),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.solarOrange, size: 18),
                  const SizedBox(width: 8),
                  Text('Análisis completado',
                      style: TextStyle(
                        fontSize: 13, color: AppColors.solarOrange,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Tu perfil\nsolar',
                  style: TextStyle(
                    fontSize: 36, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -1.5, height: 1.1,
                  )),
              const SizedBox(height: 6),
              Text(_localidad,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary)),
            ],
          ),
        ),
        // Sol animado pequeño
        AnimatedBuilder(
          animation: _sunRotation,
          builder: (context, child) => SizedBox(
            width: 72, height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppColors.solarOrange.withOpacity(0.15),
                      Colors.transparent,
                    ]),
                  ),
                ),
                Transform.rotate(
                  angle: _sunRotation.value,
                  child: CustomPaint(
                    size: const Size(60, 60),
                    painter: _MiniSunRaysPainter(),
                  ),
                ),
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(colors: [
                      AppColors.solarAmber, AppColors.solarGlow,
                    ]),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.solarOrange.withOpacity(0.5),
                        blurRadius: 12, spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsumoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.solarOrange.withOpacity(0.15),
            AppColors.solarOrange.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.solarOrange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.solarOrange, size: 18),
              const SizedBox(width: 8),
              const Text('CONSUMO ESPERADO AÑO SIGUIENTE',
                  style: TextStyle(fontSize: 11, color: AppColors.solarOrange,
                      fontWeight: FontWeight.w600, letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedBuilder(
                animation: _countAnim,
                builder: (context, _) {
                  final val = (_consumoEsperado * _countAnim.value).toStringAsFixed(0);
                  return Text(val,
                      style: const TextStyle(
                        fontSize: 52, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary, letterSpacing: -2,
                      ));
                },
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 10, left: 6),
                child: Text('kWh/año',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniStat('Consumo actual',
                  '${widget.consumoAnual.toStringAsFixed(0)} kWh'),
              const SizedBox(width: 16),
              _buildMiniStat('Ahorro estimado',
                  '${_ahorroEstimado.toStringAsFixed(0)} kWh'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundInput,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSolarGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.wb_sunny_rounded,
            label: 'Radiación solar',
            value: '${_radiacionSolar.toStringAsFixed(1)}',
            unit: 'kWh/m²/día',
            color: AppColors.solarAmber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.rotate_90_degrees_ccw_rounded,
            label: 'Tilt recomendado',
            value: '${_tilt.toStringAsFixed(0)}°',
            unit: 'inclinación',
            color: const Color(0xFF4FC3F7),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.explore_rounded,
            label: 'Azimut',
            value: '${_azimut.toStringAsFixed(0)}°',
            unit: _azimutLabel(_azimut),
            color: const Color(0xFF81C784),
          ),
        ),
      ],
    );
  }

  String _azimutLabel(double az) {
    if (az == 180) return 'Sur';
    if (az > 180 && az <= 225) return 'Sur-Oeste';
    if (az >= 135 && az < 180) return 'Sur-Este';
    return 'Sur';
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700,
                color: color, letterSpacing: -0.5,
              )),
          Text(unit,
              style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMesesChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MESES DE ALTO CONSUMO',
              style: TextStyle(fontSize: 11, color: AppColors.textHint,
                  fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Row(
            children: List.generate(12, (i) {
              final isHigh = widget.mesesAltoConsumo.contains(i);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 400 + i * 50),
                        height: isHigh ? 48 : 24,
                        decoration: BoxDecoration(
                          gradient: isHigh
                              ? const LinearGradient(
                                  colors: [AppColors.solarAmber, AppColors.solarGlow],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                )
                              : null,
                          color: isHigh ? null : AppColors.backgroundInput,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: isHigh
                              ? [BoxShadow(
                                  color: AppColors.solarOrange.withOpacity(0.3),
                                  blurRadius: 6,
                                )]
                              : [],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(_meses[i],
                          style: TextStyle(
                            fontSize: 8,
                            color: isHigh
                                ? AppColors.solarOrange
                                : AppColors.textHint,
                            fontWeight: isHigh
                                ? FontWeight.w600
                                : FontWeight.w400,
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppColors.solarOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.solar_power_rounded,
                color: AppColors.solarOrange, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Paneles sugeridos',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Text('${_panelesSugeridos.toInt()} paneles (400W c/u)',
                    style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                Text('Para cubrir tu consumo en ${_localidad}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textHint)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparadorButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ComparadorScreen(
                panelesSugeridos: _panelesSugeridos.toInt(),
                consumoAnual: widget.consumoAnual,
                localidad: _localidad,
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.solarOrange, AppColors.solarGlow],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.solarOrange.withOpacity(0.4),
                blurRadius: 20, offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.compare_arrows_rounded, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text('Comparar productos y paquetes',
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: Colors.white, letterSpacing: 0.2,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: CustomPaint(painter: _ResultsBackgroundPainter()),
    );
  }
}

class _MiniSunRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = AppColors.solarAmber.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 2 * math.pi) / 8;
      canvas.drawLine(
        Offset(center.dx + 18 * math.cos(angle), center.dy + 18 * math.sin(angle)),
        Offset(center.dx + 26 * math.cos(angle), center.dy + 26 * math.sin(angle)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ResultsBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0A0E1A), Color(0xFF0C1220), Color(0xFF0A0E1A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final glow = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFFF5A623).withOpacity(0.07),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.8, size.height * 0.1),
          radius: size.width * 0.7));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
