import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product_model.dart';
import '../repositories/provider_repository.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COTIZAR BOTTOM SHEET
// Se muestra al presionar "Cotizar" en el comparador.
// Contiene: info del producto, perfil solar del usuario y contacto del proveedor.
// ─────────────────────────────────────────────────────────────────────────────

class CotizarBottomSheet extends StatefulWidget {
  final Product producto;
  final double consumoAnual;
  final String localidad;
  final double irradiacion;
  final double tilt;
  final double azimut;
  final String codigoPostal;

  const CotizarBottomSheet({
    super.key,
    required this.producto,
    required this.consumoAnual,
    required this.localidad,
    this.irradiacion = 5.8,
    this.tilt = 25,
    this.azimut = 180,
    this.codigoPostal = '—',
  });

  /// Muestra el bottom sheet desde cualquier pantalla.
  static Future<void> show(
    BuildContext context, {
    required Product producto,
    required double consumoAnual,
    required String localidad,
    double irradiacion = 5.8,
    double tilt = 25,
    double azimut = 180,
    String codigoPostal = '—',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CotizarBottomSheet(
        producto: producto,
        consumoAnual: consumoAnual,
        localidad: localidad,
        irradiacion: irradiacion,
        tilt: tilt,
        azimut: azimut,
        codigoPostal: codigoPostal,
      ),
    );
  }

  @override
  State<CotizarBottomSheet> createState() => _CotizarBottomSheetState();
}

class _CotizarBottomSheetState extends State<CotizarBottomSheet> {
  final ProviderRepository _providerRepo = ProviderRepository();
  Provider? _proveedor;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProvider();
  }

  Future<void> _loadProvider() async {
    final p = await _providerRepo.getById(widget.producto.proveedorId);
    setState(() { _proveedor = p; _loading = false; });
  }

  // Texto resumen para compartir por WhatsApp / copiar
  String get _resumenTexto {
    final p = widget.producto;
    final prov = _proveedor;
    return '''☀️ *Solar Match 2026 — Mi perfil solar*

📦 *Producto de interés:*
${p.nombre}
💰 \$${_fmt(p.precio.toInt())} MXN
${p.potenciaKW != null ? '⚡ ${p.potenciaKW!.toStringAsFixed(1)} kW' : ''}${p.capacidadKWh != null ? ' · 🔋 ${p.capacidadKWh!.toStringAsFixed(0)} kWh' : ''}
🛡️ Garantía: ${p.garantiaAnios} años

📊 *Mi consumo:*
📍 ${widget.localidad} · CP ${widget.codigoPostal}
⚡ ${widget.consumoAnual.toStringAsFixed(0)} kWh/año
☀️ Radiación: ${widget.irradiacion.toStringAsFixed(1)} kWh/m²/día
📐 Tilt: ${widget.tilt.toStringAsFixed(0)}° · Azimut: ${widget.azimut.toStringAsFixed(0)}°

${prov != null ? '📞 *Contacto ${prov.nombre}:*\n${prov.whatsapp != null ? "WhatsApp: wa.me/${prov.whatsapp}" : ""}\n${prov.email ?? ""}' : ''}''';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header producto
                  _buildProductHeader(),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),

                  // Perfil solar del usuario
                  _buildPerfilSolar(),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),

                  // Contacto proveedor
                  _loading
                      ? const Center(child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.solarOrange)))
                      : _buildContacto(),

                  const SizedBox(height: 20),

                  // Botón copiar resumen
                  _buildCopyButton(),

                  const SizedBox(height: 12),

                  // Nota captura de pantalla
                  Center(
                    child: Text(
                      '📸 Toma una captura para tener esta info a la mano',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductHeader() {
    final p = widget.producto;
    return Row(
      children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: AppColors.solarOrange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.solar_power_rounded,
              color: AppColors.solarOrange, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.nombre,
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
              Text(_proveedor?.nombre ?? p.proveedorId,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('\$${_fmt(p.precio.toInt())}',
                style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: AppColors.solarOrange,
                )),
            const Text('MXN',
                style: TextStyle(fontSize: 11, color: AppColors.textHint)),
          ],
        ),
      ],
    );
  }

  Widget _buildPerfilSolar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TU PERFIL SOLAR',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: AppColors.textHint, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildInfoRow(Icons.location_on_rounded,
            '${widget.localidad} · CP ${widget.codigoPostal}'),
        _buildInfoRow(Icons.bolt_rounded,
            '${widget.consumoAnual.toStringAsFixed(0)} kWh/año'),
        _buildInfoRow(Icons.wb_sunny_rounded,
            '${widget.irradiacion.toStringAsFixed(1)} kWh/m²/día de radiación'),
        _buildInfoRow(Icons.rotate_90_degrees_ccw_rounded,
            'Tilt ${widget.tilt.toStringAsFixed(0)}° · Azimut ${widget.azimut.toStringAsFixed(0)}°'),
      ],
    );
  }

  Widget _buildContacto() {
    final prov = _proveedor;
    if (prov == null) {
      return const Text('Proveedor no encontrado.',
          style: TextStyle(color: AppColors.textHint));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CONTACTAR A ${prov.nombre.toUpperCase()}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: AppColors.textHint, letterSpacing: 1.2)),
        const SizedBox(height: 12),

        if (prov.whatsapp != null)
          _buildContactButton(
            icon: Icons.chat_rounded,
            label: 'WhatsApp',
            sublabel: '+${prov.whatsapp}',
            color: const Color(0xFF25D366),
            onTap: () => _copyToClipboard('wa.me/${prov.whatsapp}'),
          ),

        if (prov.email != null)
          _buildContactButton(
            icon: Icons.email_rounded,
            label: 'Email',
            sublabel: prov.email!,
            color: AppColors.accentBlue,
            onTap: () => _copyToClipboard(prov.email!),
          ),

        if (prov.sitioWeb != null)
          _buildContactButton(
            icon: Icons.language_rounded,
            label: 'Sitio web',
            sublabel: prov.sitioWeb!,
            color: AppColors.solarOrange,
            onTap: () => _copyToClipboard(prov.sitioWeb!),
          ),
      ],
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.backgroundInput,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(sublabel,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.copy_rounded, color: AppColors.textHint, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyButton() {
    return GestureDetector(
      onTap: () => _copyToClipboard(_resumenTexto),
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.solarOrange, AppColors.solarGlow],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.solarOrange.withOpacity(0.3),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.copy_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Copiar resumen completo',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.solarOrange),
          const SizedBox(width: 10),
          Expanded(child: Text(text,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('¡Copiado al portapapeles!'),
        backgroundColor: AppColors.solarOrange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _fmt(int price) {
    final s = price.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write(',');
      result.write(s[i]);
    }
    return result.toString();
  }
}