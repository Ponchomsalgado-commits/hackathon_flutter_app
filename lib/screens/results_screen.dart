import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
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
    _radiacionSolar = widget.irradiacionData.promedioDiarioGTI;
    _localidad = widget.localidad;
    _tilt = widget.irradiacionData.tiltUsado;
    _azimut = SolarCalculator.calcularAzimut(widget.horarioIndex);

    const potenciaPanelKW = 0.4;      // 400W por panel
    const eficienciaSistema = 0.78;   // pérdidas inversor, temperatura, cables

    // Paneles necesarios para cubrir consumo anual
    _panelesSugeridos = (widget.consumoAnual /
            (_radiacionSolar * 365 * potenciaPanelKW * eficienciaSistema))
        .ceilToDouble();

    // Generación real con esos paneles
    final generacionAnual = _panelesSugeridos *
        potenciaPanelKW *
        _radiacionSolar *
        365 *
        eficienciaSistema;

    // Consumo residual (lo que sigue pagando a la CFE)
    _consumoEsperado =
        (widget.consumoAnual - generacionAnual).clamp(0, widget.consumoAnual);

    // Ahorro real en kWh
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
                          const SizedBox(height: 16),
                          _buildRecomendacionCard(),
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
    // ── Tarifa CFE ──────────────────────────────────────────────────
    // TODO: reemplazar con tabla real de tarifas por zona/DAC
    const tarifaCFE = 2.50; // MXN por kWh (tarifa doméstica promedio)

    final generacionAnual = _panelesSugeridos * 0.4 * _radiacionSolar * 365 * 0.78;
    final ahorroKWh = _ahorroEstimado.clamp(0, widget.consumoAnual);
    final ahorroMXN = ahorroKWh * tarifaCFE;
    final porcentaje = (ahorroKWh / widget.consumoAnual * 100).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.solarOrange.withValues(alpha: 0.15),
            AppColors.solarOrange.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.solarOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(children: [
            const Icon(Icons.wb_sunny_rounded,
                color: AppColors.solarOrange, size: 18),
            const SizedBox(width: 8),
            const Text('GENERACIÓN SOLAR ESTIMADA',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.solarOrange,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
          ]),

          const SizedBox(height: 16),

          // Número grande — generación anual
          AnimatedBuilder(
            animation: _countAnim,
            builder: (context, _) {
              final val = (generacionAnual * _countAnim.value)
                  .toStringAsFixed(0);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(val,
                      style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -2)),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10, left: 6),
                    child: Text('kWh/año',
                        style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary)),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 6),
          Text('Producción estimada con ${_panelesSugeridos.toInt()} paneles de 400W',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textHint)),

          const SizedBox(height: 20),

          // 3 stats: kWh · MXN · %
          Row(children: [
            _buildMiniStat(
              icon: Icons.bolt_rounded,
              label: 'Ahorro kWh/año',
              value: '${ahorroKWh.toStringAsFixed(0)} kWh',
            ),
            const SizedBox(width: 10),
            _buildMiniStat(
              icon: Icons.attach_money_rounded,
              label: 'Ahorro MXN/año',
              value: '\$${(ahorroMXN / 1000).toStringAsFixed(1)}k',
              sublabel: 'Tarifa \$${tarifaCFE.toStringAsFixed(2)}/kWh',
            ),
            const SizedBox(width: 10),
            _buildMiniStat(
              icon: Icons.pie_chart_rounded,
              label: 'Reducción factura',
              value: '${porcentaje.toStringAsFixed(0)}%',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String label,
    required String value,
    String? sublabel,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundInput,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.solarOrange, size: 16),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textHint, height: 1.3)),
            if (sublabel != null) ...[
              const SizedBox(height: 2),
              Text(sublabel,
                  style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.solarOrange,
                      height: 1.2)),
            ],
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

  Widget _buildRecomendacionCard() {
    // Porcentaje de cobertura solar
    final cobertura = (_ahorroEstimado / widget.consumoAnual * 100).clamp(0, 100);

    // Ahorro económico estimado (tarifa CFE promedio $2.50/kWh)
    final ahorroMXN = _ahorroEstimado * 2.50;

    // ROI estimado
    final roiAnios = widget.presupuesto > 0
        ? (widget.presupuesto / ahorroMXN).clamp(0, 30)
        : 0.0;

    // Horario label
    final horarioLabels = ['Madrugada', 'Mañana', 'Tarde', 'Noche'];
    final horarioLabel = horarioLabels[widget.horarioIndex.clamp(0, 3)];

    // Tipo de sistema según presupuesto y paneles
    String _tipoSistema() {
      if (_panelesSugeridos <= 3) return 'Sistema básico residencial';
      if (_panelesSugeridos <= 6) return 'Sistema mediano residencial';
      if (_panelesSugeridos <= 12) return 'Sistema completo con batería';
      return 'Sistema industrial / premium';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.solarOrange.withValues(alpha: 0.12),
            AppColors.solarOrange.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.solarOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded,
                color: AppColors.solarOrange, size: 18),
            const SizedBox(width: 8),
            const Text('TU PERFIL SOLAR',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.solarOrange,
                    letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 16),

          // Tipo de sistema
          Text(_tipoSistema(),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(
            'Orientado al $horarioLabel · Tilt ${_tilt.toStringAsFixed(0)}° · Azimut ${_azimut.toStringAsFixed(0)}°',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),

          const SizedBox(height: 20),

          // Stats clave
          Row(children: [
            _buildRecoStat(
              '${cobertura.toStringAsFixed(0)}%',
              'Cobertura solar',
              Icons.wb_sunny_rounded,
            ),
            const SizedBox(width: 12),
            _buildRecoStat(
              '\$${(ahorroMXN / 1000).toStringAsFixed(1)}k',
              'Ahorro/año MXN',
              Icons.savings_rounded,
            ),
            const SizedBox(width: 12),
            _buildRecoStat(
              '${roiAnios.toStringAsFixed(1)} años',
              'Retorno inversión',
              Icons.trending_up_rounded,
            ),
          ]),

          const SizedBox(height: 16),

          // Mensaje personalizado
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.lightbulb_rounded,
                  color: AppColors.solarOrange, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cobertura >= 80
                      ? 'Excelente potencial. Con ${_panelesSugeridos.toInt()} paneles cubres el ${cobertura.toStringAsFixed(0)}% de tu consumo.'
                      : cobertura >= 50
                          ? 'Buen potencial. Puedes reducir tu factura a la mitad con ${_panelesSugeridos.toInt()} paneles.'
                          : 'Con ${_panelesSugeridos.toInt()} paneles reduces significativamente tu dependencia de la CFE.',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoStat(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Icon(icon, color: AppColors.solarOrange, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textHint, height: 1.3)),
        ]),
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