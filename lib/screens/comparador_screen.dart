import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/product_model.dart';
import '../repositories/solar_repository.dart';
import '../logic/solar_calculator.dart';
import '../logic/recommendation_engine.dart';

class ComparadorScreen extends StatefulWidget {
  final int panelesSugeridos;
  final double consumoAnual;
  final String localidad;
  final double irradiacion;
  final int horarioIndex;
  final double presupuesto;

  const ComparadorScreen({
    super.key,
    this.panelesSugeridos = 6,
    this.consumoAnual = 3600,
    this.localidad = 'Ciudad de México',
    this.irradiacion = 5.8,
    this.horarioIndex = 2,
    this.presupuesto = 100000,
  });

  @override
  State<ComparadorScreen> createState() => _ComparadorScreenState();
}

class _ComparadorScreenState extends State<ComparadorScreen>
    with TickerProviderStateMixin {

  final SolarRepository _repository = SolarRepository();
  late SolarCalculator _calculator;

  int _selectedFilter = 0;
  int? _selectedProductIndex;
  bool _isLoading = true;
  String? _errorMessage;
  List<Product> _productos = [];
  List<Product> _filteredProducts = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  final List<String> _filters = ['Todos', 'Paneles', 'Baterías', 'Paquetes'];

  @override
  void initState() {
    super.initState();
    _calculator = SolarCalculator(
      consumoAnualKWh: widget.consumoAnual,
      irradiacionKWhM2Dia: widget.irradiacion,
      tiltGrados: SolarCalculator.calcularTilt(widget.horarioIndex, widget.irradiacion),
      azimutGrados: SolarCalculator.calcularAzimut(widget.horarioIndex),
      mesesAltoConsumo: const [],
      horarioConsumoIndex: widget.horarioIndex,
    );
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _cargarProductos();
  }

  @override
  void dispose() { _fadeController.dispose(); super.dispose(); }

  Future<void> _cargarProductos() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final all = await _repository.getAllProducts();

      // Motor de recomendación con perfil real del usuario
      final engine = RecommendationEngine(
        consumoAnual: widget.consumoAnual,
        irradiacion: widget.irradiacion,
        presupuesto: widget.presupuesto,
      );

      final scored = engine.rank(all);
      final rankeados = scored.map((s) => s.producto).toList();

      setState(() { _productos = rankeados; _isLoading = false; });
      _applyFilter();
      _fadeController.forward();
    } catch (e) {
      setState(() { _errorMessage = 'Error al cargar productos.'; _isLoading = false; });
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 0) {
        _filteredProducts = _productos;
      } else {
        final cats = [null, ProductCategory.panel, ProductCategory.bateria, ProductCategory.paquete];
        _filteredProducts = _productos.where((p) => p.categoria == cats[_selectedFilter]).toList();
      }
      _selectedProductIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: Container(decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0A0E1A), Color(0xFF0C1220), Color(0xFF0A0E1A)])))),
          SafeArea(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildTopBar(),
              _buildHeader(),
              const SizedBox(height: 16),
              _buildFilters(),
              const SizedBox(height: 16),
              Expanded(child: _buildBody()),
            ]),
          ),
          if (_selectedProductIndex != null) _buildSelectionBar(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return Center(child: CircularProgressIndicator(
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.solarOrange)));
    if (_errorMessage != null) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline_rounded, color: AppColors.textHint, size: 48),
      const SizedBox(height: 12),
      Text(_errorMessage!, style: const TextStyle(color: AppColors.textSecondary)),
      const SizedBox(height: 16),
      GestureDetector(onTap: _cargarProductos, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(color: AppColors.solarOrange, borderRadius: BorderRadius.circular(12)),
        child: const Text('Reintentar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
    ]));
    return FadeTransition(opacity: _fadeAnim, child: _buildProductList());
  }

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Row(children: [
      GestureDetector(onTap: () => Navigator.of(context).pop(),
        child: Container(width: 42, height: 42,
          decoration: BoxDecoration(color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary, size: 16))),
      const SizedBox(width: 16),
      const Text('Comparador de productos',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const Spacer(),
      GestureDetector(onTap: _cargarProductos,
        child: Container(width: 42, height: 42,
          decoration: BoxDecoration(color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 18))),
    ]),
  );

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded, color: AppColors.solarOrange, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(
          'Consumo: ${widget.consumoAnual.toStringAsFixed(0)} kWh/año · ${widget.panelesSugeridos} paneles sugeridos · ${widget.localidad}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5))),
      ])),
  );

  Widget _buildFilters() => SizedBox(height: 40, child: ListView.builder(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    itemCount: _filters.length,
    itemBuilder: (context, i) {
      final sel = _selectedFilter == i;
      return Padding(padding: const EdgeInsets.only(right: 10),
        child: GestureDetector(onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedFilter = i); _applyFilter(); },
          child: AnimatedContainer(duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? AppColors.solarOrange : AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? AppColors.solarOrange : AppColors.border)),
            child: Text(_filters[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
              color: sel ? Colors.white : AppColors.textSecondary)))));
    }));

  Widget _buildProductList() {
    if (_filteredProducts.isEmpty) return const Center(
      child: Text('No hay productos en esta categoría.', style: TextStyle(color: AppColors.textSecondary)));
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20, 0, 20, _selectedProductIndex != null ? 110 : 20),
      itemCount: _filteredProducts.length,
      itemBuilder: (ctx, i) => _buildProductCard(_filteredProducts[i], i));
  }

  Widget _buildProductCard(Product p, int index) {
    final isSelected = _selectedProductIndex == index;
    final roi = _calculator.retornoInversion(p.precio);
    final roiLabel = roi.isInfinite ? 'N/A' : '${roi.toStringAsFixed(1)} años';
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedProductIndex = isSelected ? null : index); },
      child: AnimatedContainer(duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.solarOrange.withOpacity(0.08) : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.solarOrange : AppColors.border, width: isSelected ? 2 : 1),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.solarOrange.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 4))] : []),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.solarOrange.withOpacity(0.2) : AppColors.backgroundInput,
                borderRadius: BorderRadius.circular(12)),
              child: Icon(_categoryIcon(p.categoria),
                color: isSelected ? AppColors.solarOrange : AppColors.textSecondary, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(p.nombre, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.solarOrange : AppColors.textPrimary))),
                if (p.esRecomendado) ...[const SizedBox(width: 6), Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.solarOrange.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                  child: const Text('★ Top', style: TextStyle(fontSize: 10, color: AppColors.solarOrange, fontWeight: FontWeight.w700)))],
                if (p.etiqueta != null && !p.esRecomendado) ...[const SizedBox(width: 6), Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(6)),
                  child: Text(p.etiqueta!, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)))],
              ]),
              Text(p.descripcion, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('\$${_formatPrice(p.precio.toInt())}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.solarOrange : AppColors.textPrimary)),
              const Text('MXN', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
            ]),
          ]),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Row(children: [
            if (p.cantidadPaneles != null) _buildSpec(Icons.solar_power_rounded, '${p.cantidadPaneles} paneles'),
            if (p.potenciaKW != null) _buildSpec(Icons.flash_on_rounded, '${p.potenciaKW!.toStringAsFixed(1)} kW'),
            if (p.capacidadKWh != null) _buildSpec(Icons.battery_charging_full_rounded, '${p.capacidadKWh!.toStringAsFixed(0)} kWh'),
            _buildSpec(Icons.savings_rounded, '\$${_formatPrice(p.ahorroAnualEstimado.toInt())}/año'),
            _buildSpec(Icons.replay_rounded, 'ROI $roiLabel'),
          ]),
        ])));
  }

  Widget _buildSpec(IconData icon, String label) => Expanded(child: Row(children: [
    Icon(icon, size: 12, color: AppColors.textHint), const SizedBox(width: 4),
    Flexible(child: Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
  ]));

  Widget _buildSelectionBar() {
    final p = _filteredProducts[_selectedProductIndex!];
    final roi = _calculator.retornoInversion(p.precio);
    final roiStr = roi.isInfinite ? 'N/A' : '${roi.toStringAsFixed(1)} años';
    return Positioned(bottom: 0, left: 0, right: 0,
      child: Container(padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(color: AppColors.backgroundCard,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, -4))]),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Text('\$${_formatPrice(p.precio.toInt())} MXN · ROI $roiStr',
              style: const TextStyle(fontSize: 12, color: AppColors.solarOrange)),
          ])),
          GestureDetector(
            onTap: () { HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${p.nombre} agregado a tu cotización'),
                backgroundColor: AppColors.solarOrange, behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
            },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.solarOrange, AppColors.solarGlow],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.solarOrange.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))]),
              child: const Text('Cotizar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)))),
        ])));
  }

  IconData _categoryIcon(ProductCategory cat) {
    switch (cat) {
      case ProductCategory.panel: return Icons.solar_power_rounded;
      case ProductCategory.bateria: return Icons.battery_charging_full_rounded;
      case ProductCategory.paquete: return Icons.home_rounded;
    }
  }

  String _formatPrice(int price) {
    final s = price.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write(',');
      result.write(s[i]);
    }
    return result.toString();
  }
}