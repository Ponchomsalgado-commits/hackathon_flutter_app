import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/nasa_power_service.dart';
import '../logic/solar_calculator.dart';
import 'comparador_screen.dart';

class ResultsScreen extends StatefulWidget {
  final String codigoPostal;
  final String localidad;
  final double latitud;
  final double longitud;
  final SolarIrradiationData irradiacionData;
  final List<int> mesesAltoConsumo;
  final int horarioIndex;
  final double consumoAnual;
  final double presupuesto;

  const ResultsScreen({
    super.key,
    this.codigoPostal = '06600',
    this.localidad = 'Ciudad de México',
    this.latitud = 19.4326,
    this.longitud = -99.1332,
    SolarIrradiationData? irradiacionData,
    this.mesesAltoConsumo = const [5, 6, 7],
    this.horarioIndex = 2,
    this.consumoAnual = 3600,
    this.presupuesto = 100000,
  }) : irradiacionData = irradiacionData ??
            const SolarIrradiationData(
              ghiMensual: [4.5, 5.2, 6.0, 6.8, 6.5, 5.8, 5.5, 5.6, 5.2, 5.0, 4.6, 4.2],
              gtiMensual: [4.5, 5.2, 6.0, 6.8, 6.5, 5.8, 5.5, 5.6, 5.2, 5.0, 4.6, 4.2],
              promedioDiarioGTI: 5.8,
              tiltUsado: 25,
              azimutUsado: 180,
              latitud: 19.4326,
              longitud: -99.1332,
              fuenteReal: false,
            );

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _countController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _countAnim;

  late double _radiacionSolar;
  late double _tilt;
  late double _azimut;
  late double _panelesSugeridos;
  late String _localidad;

  @override
  void initState() {
    super.initState();
    _calcularDatos();

    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _countController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _countAnim = CurvedAnimation(parent: _countController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _calcularDatos() {
    _radiacionSolar = widget.irradiacionData.promedioDiarioGTI;
    _localidad = widget.localidad;
    _tilt = widget.irradiacionData.tiltUsado;
    _azimut = SolarCalculator.calcularAzimut(widget.horarioIndex);
    const potenciaPanelKW = 0.4;
    const eficienciaSistema = 0.78;
    _panelesSugeridos = (widget.consumoAnual /
            (_radiacionSolar * 365 * potenciaPanelKW * eficienciaSistema))
        .ceilToDouble();
  }

  String get _azimutLabel {
    if (_azimut == 135) return 'Sur-Este';
    if (_azimut == 225) return 'Sur-Oeste';
    return 'Sur';
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
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: AnimatedBuilder(
                      animation: _slideAnim,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _slideAnim.value),
                        child: child,
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            _buildHeader(),
                            const SizedBox(height: 32),
                            _buildConsumoAnual(),
                            const SizedBox(height: 20),
                            _buildPerfilCards(),
                            const SizedBox(height: 40),
                          ],
                        ),
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
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Paso 6 de 6',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                  const Text('100%',
                      style: TextStyle(fontSize: 12,
                          color: AppColors.solarOrange,
                          fontWeight: FontWeight.w600)),
                ]),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.solarOrange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.solarOrange, size: 14),
            const SizedBox(width: 6),
            const Text('Análisis completado',
                style: TextStyle(fontSize: 12,
                    color: AppColors.solarOrange,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('Tu perfil',
            style: TextStyle(fontSize: 38, fontWeight: FontWeight.w300,
                color: AppColors.textPrimary, letterSpacing: -1, height: 1.1)),
        const Text('solar',
            style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary, letterSpacing: -1, height: 1.1)),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.location_on_rounded,
              color: AppColors.textHint, size: 14),
          const SizedBox(width: 4),
          Text(_localidad,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ]),
      ],
    );
  }

  Widget _buildConsumoAnual() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.solarOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.bolt_rounded,
                color: AppColors.solarOrange, size: 24),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Consumo anual registrado',
                style: TextStyle(fontSize: 12, color: AppColors.textHint)),
            const SizedBox(height: 4),
            AnimatedBuilder(
              animation: _countAnim,
              builder: (context, _) {
                final val = (widget.consumoAnual * _countAnim.value)
                    .toStringAsFixed(0);
                return Text('$val kWh/año',
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5));
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildPerfilCards() {
    return Column(
      children: [
        _buildPerfilCard(
          icon: Icons.wb_sunny_rounded,
          label: 'Radiación solar en su zona',
          value: _radiacionSolar.toStringAsFixed(1),
          unit: 'kWh/m²/día',
          color: AppColors.solarOrange,
        ),
        const SizedBox(height: 12),
        _buildPerfilCard(
          icon: Icons.rotate_90_degrees_ccw_rounded,
          label: 'Tilt recomendado',
          value: '${_tilt.toStringAsFixed(0)}°',
          unit: 'inclinación',
          color: const Color(0xFF4FC3F7),
        ),
        const SizedBox(height: 12),
        _buildPerfilCard(
          icon: Icons.explore_rounded,
          label: 'Azimut recomendado',
          value: '${_azimut.toStringAsFixed(0)}°',
          unit: _azimutLabel,
          color: const Color(0xFF81C784),
        )
      ],
    );
  }

  Widget _buildPerfilCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary)),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5)),
            Text(unit,
                style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
          ]),
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
                irradiacion: _radiacionSolar,
                horarioIndex: widget.horarioIndex,
                presupuesto: widget.presupuesto,
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
                color: AppColors.solarOrange.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.compare_arrows_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Comparar productos y paquetes',
                  style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w600, color: Colors.white)),
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

class _ResultsBackgroundPainter extends CustomPainter {
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
          const Color(0xFFF5A623).withValues(alpha: 0.07),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width, 0), radius: size.width * 0.7));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);

    final gridPaint = Paint()
      ..color = const Color(0xFFF5A623).withValues(alpha: 0.025)
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