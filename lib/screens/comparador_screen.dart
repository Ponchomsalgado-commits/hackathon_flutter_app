import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class ComparadorScreen extends StatefulWidget {
  final int panelesSugeridos;
  final double consumoAnual;
  final String localidad;

  const ComparadorScreen({
    super.key,
    this.panelesSugeridos = 6,
    this.consumoAnual = 3600,
    this.localidad = 'Ciudad de México',
  });

  @override
  State<ComparadorScreen> createState() => _ComparadorScreenState();
}

class _ComparadorScreenState extends State<ComparadorScreen>
    with TickerProviderStateMixin {
  int _selectedFilter = 0; // 0=Todos, 1=Paneles, 2=Baterías, 3=Paquetes
  int? _selectedProduct;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  final List<String> _filters = ['Todos', 'Paneles', 'Baterías', 'Paquetes'];

  final List<Map<String, dynamic>> _productos = [
    {
      'tipo': 'Paquete',
      'nombre': 'Solar Starter',
      'descripcion': 'Ideal para hogares pequeños',
      'paneles': 4,
      'bateria': '5 kWh',
      'precio': 85000,
      'ahorro_anual': 12000,
      'garantia': '10 años',
      'tag': 'Más popular',
      'tagColor': AppColors.solarOrange,
      'icon': Icons.home_rounded,
      'potencia': '1.6 kW',
    },
    {
      'tipo': 'Paquete',
      'nombre': 'Solar Plus',
      'descripcion': 'Para consumo medio-alto',
      'paneles': 8,
      'bateria': '10 kWh',
      'precio': 155000,
      'ahorro_anual': 22000,
      'garantia': '15 años',
      'tag': 'Recomendado',
      'tagColor': const Color(0xFF4FC3F7),
      'icon': Icons.house_rounded,
      'potencia': '3.2 kW',
    },
    {
      'tipo': 'Paquete',
      'nombre': 'Solar Pro',
      'descripcion': 'Máxima independencia energética',
      'paneles': 12,
      'bateria': '20 kWh',
      'precio': 240000,
      'ahorro_anual': 35000,
      'garantia': '25 años',
      'tag': 'Premium',
      'tagColor': const Color(0xFFFFD700),
      'icon': Icons.apartment_rounded,
      'potencia': '4.8 kW',
    },
    {
      'tipo': 'Panel',
      'nombre': 'Panel Monocristalino 400W',
      'descripcion': 'Alta eficiencia 21.5%',
      'paneles': 1,
      'bateria': null,
      'precio': 8500,
      'ahorro_anual': 2800,
      'garantia': '25 años',
      'tag': null,
      'tagColor': null,
      'icon': Icons.solar_power_rounded,
      'potencia': '400 W',
    },
    {
      'tipo': 'Panel',
      'nombre': 'Panel Bifacial 450W',
      'descripcion': 'Captación frontal y trasera',
      'paneles': 1,
      'bateria': null,
      'precio': 11200,
      'ahorro_anual': 3400,
      'garantia': '30 años',
      'tag': 'Alta eficiencia',
      'tagColor': const Color(0xFF81C784),
      'icon': Icons.solar_power_rounded,
      'potencia': '450 W',
    },
    {
      'tipo': 'Batería',
      'nombre': 'Batería LiFePO4 5kWh',
      'descripcion': 'Ciclo de vida > 6000 cargas',
      'paneles': null,
      'bateria': '5 kWh',
      'precio': 32000,
      'ahorro_anual': 4500,
      'garantia': '10 años',
      'tag': null,
      'tagColor': null,
      'icon': Icons.battery_charging_full_rounded,
      'potencia': null,
    },
    {
      'tipo': 'Batería',
      'nombre': 'Batería LiFePO4 10kWh',
      'descripcion': 'Autonomía nocturna completa',
      'paneles': null,
      'bateria': '10 kWh',
      'precio': 58000,
      'ahorro_anual': 8500,
      'garantia': '12 años',
      'tag': 'Más autonomía',
      'tagColor': const Color(0xFF4FC3F7),
      'icon': Icons.battery_charging_full_rounded,
      'potencia': null,
    },
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    if (_selectedFilter == 0) return _productos;
    final tipo = _filters[_selectedFilter];
    // Remove 's' to match tipo field: Paneles->Panel, Baterías->Batería, Paquetes->Paquete
    final tipoSingular = tipo == 'Paneles'
        ? 'Panel'
        : tipo == 'Baterías'
            ? 'Batería'
            : 'Paquete';
    return _productos.where((p) => p['tipo'] == tipoSingular).toList();
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
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
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(),
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildFilters(),
                  const SizedBox(height: 16),
                  Expanded(child: _buildProductList()),
                ],
              ),
            ),
          ),
          // Bottom sheet de producto seleccionado
          if (_selectedProduct != null) _buildSelectionBar(),
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
          const Text('Comparador de productos',
              style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              )),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: AppColors.solarOrange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Basado en tu consumo de ${widget.consumoAnual.toStringAsFixed(0)} kWh/año, '
                'te recomendamos ${widget.panelesSugeridos} paneles en ${widget.localidad}.',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (context, i) {
          final selected = _selectedFilter == i;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedFilter = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.solarOrange
                      : AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.solarOrange : AppColors.border,
                  ),
                ),
                child: Text(
                  _filters[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductList() {
    final products = _filteredProducts;
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, _selectedProduct != null ? 100 : 20),
      itemCount: products.length,
      itemBuilder: (context, i) => _buildProductCard(products[i], i),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p, int index) {
    final globalIndex = _productos.indexOf(p);
    final isSelected = _selectedProduct == globalIndex;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedProduct = isSelected ? null : globalIndex;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.solarOrange.withOpacity(0.08)
              : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.solarOrange : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: AppColors.solarOrange.withOpacity(0.15),
                  blurRadius: 16, offset: const Offset(0, 4),
                )]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.solarOrange.withOpacity(0.2)
                        : AppColors.backgroundInput,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(p['icon'] as IconData,
                      color: isSelected
                          ? AppColors.solarOrange
                          : AppColors.textSecondary,
                      size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(p['nombre'] as String,
                              style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.solarOrange
                                    : AppColors.textPrimary,
                              )),
                          if (p['tag'] != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (p['tagColor'] as Color).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(p['tag'] as String,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: p['tagColor'] as Color,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                          ],
                        ],
                      ),
                      Text(p['descripcion'] as String,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textHint)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${_formatPrice(p['precio'] as int)}',
                      style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.solarOrange
                            : AppColors.textPrimary,
                      ),
                    ),
                    const Text('MXN',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textHint)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 14),
            // Specs row
            Row(
              children: [
                if (p['paneles'] != null)
                  _buildSpec(Icons.solar_power_rounded,
                      '${p['paneles']} panel${p['paneles'] == 1 ? '' : 'es'}'),
                if (p['potencia'] != null)
                  _buildSpec(Icons.flash_on_rounded, p['potencia'] as String),
                if (p['bateria'] != null)
                  _buildSpec(Icons.battery_charging_full_rounded,
                      p['bateria'] as String),
                _buildSpec(Icons.savings_rounded,
                    '\$${_formatPrice(p['ahorro_anual'] as int)}/año'),
                _buildSpec(Icons.verified_rounded, p['garantia'] as String),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpec(IconData icon, String label) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textHint),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar() {
    final p = _productos[_selectedProduct!];
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20, offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['nombre'] as String,
                      style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      )),
                  Text('\$${_formatPrice(p['precio'] as int)} MXN',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.solarOrange)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${p['nombre']} agregado a tu cotización'),
                    backgroundColor: AppColors.solarOrange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.solarOrange, AppColors.solarGlow],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.solarOrange.withOpacity(0.35),
                      blurRadius: 12, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text('Cotizar',
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: Colors.white,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 1000) {
      final parts = price.toString().split('');
      final result = StringBuffer();
      for (int i = 0; i < parts.length; i++) {
        if (i > 0 && (parts.length - i) % 3 == 0) result.write(',');
        result.write(parts[i]);
      }
      return result.toString();
    }
    return price.toString();
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E1A), Color(0xFF0C1220), Color(0xFF0A0E1A)],
          ),
        ),
      ),
    );
  }
}
