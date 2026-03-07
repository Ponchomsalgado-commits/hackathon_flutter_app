import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'location_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _sunController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  late Animation<double> _sunRotation;
  late Animation<double> _fadeIn;
  late Animation<double> _titleSlide;
  late Animation<double> _subtitleFade;
  late Animation<double> _buttonFade;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    // Sol girando lentamente
    _sunController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _sunRotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _sunController, curve: Curves.linear),
    );

    // Fade general de entrada
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );

    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // Pulso del botón
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _sunController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _navigateToLocation() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
       pageBuilder: (context, animation, secondaryAnimation) =>
     LocationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Fondo con gradiente y rayos de sol
          _buildBackground(),

          // Contenido principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Sol animado
                  FadeTransition(
                    opacity: _fadeIn,
                    child: _buildSunWidget(),
                  ),

                  const SizedBox(height: 48),

                  // Título "Solar Match 2026"
                  AnimatedBuilder(
                    animation: _fadeController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _subtitleFade.value,
                        child: Transform.translate(
                          offset: Offset(0, _titleSlide.value),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Text(
                          'Solar Match',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w200,
                            color: AppColors.textPrimary,
                            letterSpacing: -2,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '2026',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w700,
                            color: AppColors.solarOrange,
                            letterSpacing: -2,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Subtítulo
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: Text(
                      'Encuentra la solución solar\nperfecta para tu hogar',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        height: 1.6,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Botón Iniciar
                  FadeTransition(
                    opacity: _buttonFade,
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulse.value,
                          child: child,
                        );
                      },
                      child: _buildStartButton(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Texto legal pequeño
                  FadeTransition(
                    opacity: _buttonFade,
                    child: Text(
                      'Gratis · Sin compromisos · 2 minutos',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: BackgroundPainter(animation: _sunController),
      ),
    );
  }

  Widget _buildSunWidget() {
    return AnimatedBuilder(
      animation: _sunRotation,
      builder: (context, child) {
        return SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Halo exterior difuso
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.solarOrange.withOpacity(0.15),
                      AppColors.solarOrange.withOpacity(0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.3, 0.65, 1.0],
                  ),
                ),
              ),

              // Rayos girando
              Transform.rotate(
                angle: _sunRotation.value,
                child: CustomPaint(
                  size: const Size(120, 120),
                  painter: SunRaysPainter(),
                ),
              ),

              // Círculo solar principal
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      AppColors.solarAmber,
                      AppColors.solarOrange,
                      AppColors.solarGlow,
                    ],
                    stops: [0.2, 0.65, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.solarOrange.withOpacity(0.6),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: AppColors.solarAmber.withOpacity(0.3),
                      blurRadius: 48,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _navigateToLocation,
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
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Iniciar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// Pintor del fondo
class BackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  BackgroundPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // Gradiente de fondo base
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0A0E1A),
          const Color(0xFF0D1526),
          const Color(0xFF0A0E1A),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Puntos de luz pequeños (estrellas)
    final starPaint = Paint()..color = Colors.white.withOpacity(0.08);
    final positions = [
      Offset(size.width * 0.1, size.height * 0.1),
      Offset(size.width * 0.85, size.height * 0.08),
      Offset(size.width * 0.25, size.height * 0.18),
      Offset(size.width * 0.7, size.height * 0.22),
      Offset(size.width * 0.45, size.height * 0.06),
      Offset(size.width * 0.92, size.height * 0.35),
      Offset(size.width * 0.05, size.height * 0.42),
    ];
    for (final pos in positions) {
      canvas.drawCircle(pos, 1.5, starPaint);
    }

    // Líneas geométricas sutiles en el fondo
    final linePaint = Paint()
      ..color = const Color(0xFFF5A623).withOpacity(0.04)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Grid diagonal
    for (int i = -5; i < 15; i++) {
      final x = i * (size.width / 8);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * 0.5, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) => false;
}

// Pintor de los rayos del sol
class SunRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final innerRadius = 36.0;
    final outerRadius = 56.0;
    final numRays = 12;

    final paint = Paint()
      ..color = AppColors.solarAmber.withOpacity(0.7)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final shortPaint = Paint()
      ..color = AppColors.solarOrange.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < numRays; i++) {
      final angle = (i * 2 * math.pi) / numRays;
      final start = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final end = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );

      if (i % 2 == 0) {
        canvas.drawLine(start, end, paint);
      } else {
        final shortEnd = Offset(
          center.dx + (outerRadius - 8) * math.cos(angle),
          center.dy + (outerRadius - 8) * math.sin(angle),
        );
        canvas.drawLine(start, shortEnd, shortPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}