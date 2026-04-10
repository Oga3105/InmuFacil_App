import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:easy_localization/easy_localization.dart';
import '../../../../core/services/ai_consent_service.dart';
import '../../../../domain/entities/property_type.dart';
import '../../../providers/property_form_provider.dart';
import '../../../providers/search_provider.dart'; // for locationServiceProvider
import '../../../widgets/ai/ai_consent_dialog.dart';

class PropertyStep1TypeLocation extends ConsumerStatefulWidget {
  const PropertyStep1TypeLocation({super.key});

  @override
  ConsumerState<PropertyStep1TypeLocation> createState() =>
      _PropertyStep1TypeLocationState();
}

class _PropertyStep1TypeLocationState
    extends ConsumerState<PropertyStep1TypeLocation> {
  // Controllers
  late final TextEditingController _streetController;
  late final TextEditingController _streetNumberController;
  late final TextEditingController _floorController;
  late final TextEditingController _cityController;
  late final TextEditingController _provinceController;
  late final TextEditingController _postalCodeController;
  late final MapController _mapController;

  // FocusNodes — required to detect whether the user is typing in a field
  // before we overwrite it with reverse-geocoded data from the state.
  final _streetFocus       = FocusNode();
  final _streetNumberFocus = FocusNode();
  final _floorFocus        = FocusNode();
  final _cityFocus         = FocusNode();
  final _provinceFocus     = FocusNode();
  final _postalCodeFocus   = FocusNode();

  Timer? _debounce;
  bool _locating = false;

  static const _defaultCenter = LatLng(40.4168, -3.7038);

  static final _selectableTypes =
      PropertyType.values.where((t) => t != PropertyType.all).toList();

  @override
  void initState() {
    super.initState();
    final s = ref.read(propertyFormProvider);
    _streetController       = TextEditingController(text: s.streetText);
    _streetNumberController = TextEditingController(text: s.streetNumberText);
    _floorController        = TextEditingController(text: s.floorText);
    _cityController         = TextEditingController(text: s.cityText);
    _provinceController     = TextEditingController(text: s.provinceText);
    _postalCodeController   = TextEditingController(text: s.postalCodeText);
    _mapController          = MapController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _streetController.dispose();
    _streetNumberController.dispose();
    _floorController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    _streetFocus.dispose();
    _streetNumberFocus.dispose();
    _floorFocus.dispose();
    _cityFocus.dispose();
    _provinceFocus.dispose();
    _postalCodeFocus.dispose();
    super.dispose();
  }

  void _sync(TextEditingController ctrl, FocusNode focus, String value) {
    if (!focus.hasFocus && ctrl.text != value) {
      ctrl.text = value;
    }
  }

  void _onAddressFieldChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 900), () {
      ref.read(propertyFormProvider.notifier).geocodeAddress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s        = ref.watch(propertyFormProvider);
    final notifier = ref.read(propertyFormProvider.notifier);

    _sync(_streetController,       _streetFocus,       s.streetText);
    _sync(_streetNumberController, _streetNumberFocus, s.streetNumberText);
    _sync(_floorController,        _floorFocus,        s.floorText);
    _sync(_cityController,         _cityFocus,         s.cityText);
    _sync(_provinceController,     _provinceFocus,     s.provinceText);
    _sync(_postalCodeController,   _postalCodeFocus,   s.postalCodeText);

    final center = s.selectedLocation ?? _defaultCenter;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        if (isDesktop) {
          return _buildDesktopLayout(context, s, notifier, center);
        }
        return _buildMobileLayout(context, s, notifier, center);
      },
    );
  }

  // ── Desktop: 50 / 50 split ───────────────────────────────────────────────

  Widget _buildDesktopLayout(
    BuildContext context,
    PropertyFormState s,
    PropertyFormNotifier notifier,
    LatLng center,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildLeftPanel(s, notifier),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _buildMap(s, notifier, center),
        ),
      ],
    );
  }

  // ── Mobile: vertical ─────────────────────────────────────────────────────

  Widget _buildMobileLayout(
    BuildContext context,
    PropertyFormState s,
    PropertyFormNotifier notifier,
    LatLng center,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTypeCard(s, notifier),
          const SizedBox(height: 16),
          _buildLocationCard(s, notifier),
          const SizedBox(height: 16),
          Text('property_wizard.map_label'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 260,
              child: _buildMap(s, notifier, center),
            ),
          ),
          if (s.step1Error != null) ...[
            const SizedBox(height: 12),
            _Banner(
              color: const Color(0xFFFEE2E2),
              borderColor: const Color(0xFFF87171),
              iconColor: const Color(0xFFDC2626),
              icon: Icons.error_outline,
              text: s.step1Error!,
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Left panel (desktop) ──────────────────────────────────────────────────

  Widget _buildLeftPanel(PropertyFormState s, PropertyFormNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeCard(s, notifier),
        const SizedBox(height: 16),
        _buildLocationCard(s, notifier),
        if (s.step1Error != null) ...[
          const SizedBox(height: 12),
          _Banner(
            color: Theme.of(context).colorScheme.errorContainer,
            borderColor: Theme.of(context).colorScheme.error,
            iconColor: Theme.of(context).colorScheme.error,
            icon: Icons.error_outline,
            text: s.step1Error!,
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  // ── "Información Básica" card ─────────────────────────────────────────────

  Widget _buildTypeCard(PropertyFormState s, PropertyFormNotifier notifier) {
    return _SectionCard(
      icon: Icons.info_outline_rounded,
      title: 'property_wizard.info_basic_card'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('property_wizard.type_label'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectableTypes.map((type) {
              final selected = s.selectedType == type;
              return ChoiceChip(
                label: Text(type.translationKey.tr(),
                    style: const TextStyle(fontSize: 13)),
                selected: selected,
                onSelected: (_) => notifier.selectType(type),
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  fontSize: 13,
                  color: selected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── "Ubicación" card ──────────────────────────────────────────────────────

  Widget _buildLocationCard(PropertyFormState s, PropertyFormNotifier notifier) {
    return _SectionCard(
      icon: Icons.location_on_outlined,
      title: 'property_wizard.location_card'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._buildAddressFields(s, notifier),
          const SizedBox(height: 16),
          ..._buildGpsSection(s),
          const SizedBox(height: 12),
          _buildHideLocationToggle(s, notifier),
          const SizedBox(height: 8),
          _buildAiComfortConsentToggle(s, notifier),
        ],
      ),
    );
  }

  // ── Dirección estructurada ────────────────────────────────────────────────

  InputDecoration _inputDec(String hint, {IconData? icon}) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: icon != null ? Icon(icon, size: 18) : null,
      );

  List<Widget> _buildAddressFields(
      PropertyFormState s, PropertyFormNotifier notifier) {
    final cursorColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF1E293B);
    return [
      Text('property_wizard.address_label'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      const SizedBox(height: 8),
      // Calle
      TextField(
        controller: _streetController,
        focusNode: _streetFocus,
        cursorColor: cursorColor,
        decoration: _inputDec('property_wizard.street_hint'.tr(), icon: Icons.add_road_outlined),
        onChanged: (v) {
          notifier.setStreet(v);
          _onAddressFieldChanged();
        },
      ),
      const SizedBox(height: 10),
      // Número | Piso
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _streetNumberController,
              focusNode: _streetNumberFocus,
              cursorColor: cursorColor,
              decoration: _inputDec('property_wizard.number_hint'.tr()),
              onChanged: (v) {
                notifier.setStreetNumber(v);
                _onAddressFieldChanged();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _floorController,
                  focusNode: _floorFocus,
                  cursorColor: cursorColor,
                  maxLength: 15,
                  decoration: _inputDec('property_wizard.floor_hint'.tr()).copyWith(
                    hintText: 'property_wizard.floor_hint'.tr(),
                    counterText: '',
                  ),
                  onChanged: notifier.setFloor,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.visibility_outlined,
                        size: 13, color: Colors.blue.shade400),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'property_wizard.floor_visibility'.tr(),
                        style: TextStyle(
                            fontSize: 11, color: Colors.blue.shade400),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      // Ciudad
      TextField(
        controller: _cityController,
        focusNode: _cityFocus,
        cursorColor: cursorColor,
        decoration: _inputDec('property_wizard.city_hint'.tr(), icon: Icons.location_city_outlined),
        onChanged: (v) {
          notifier.setCity(v);
          _onAddressFieldChanged();
        },
      ),
      const SizedBox(height: 10),
      // Provincia | CP
      Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _provinceController,
              focusNode: _provinceFocus,
              cursorColor: cursorColor,
              decoration: _inputDec('property_wizard.province_hint'.tr()),
              onChanged: (v) {
                notifier.setProvince(v);
                _onAddressFieldChanged();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _postalCodeController,
              focusNode: _postalCodeFocus,
              cursorColor: cursorColor,
              decoration: _inputDec('property_wizard.postal_code_hint'.tr()),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                notifier.setPostalCode(v);
                _onAddressFieldChanged();
              },
            ),
          ),
        ],
      ),
    ];
  }

  // ── GPS section ───────────────────────────────────────────────────────────

  List<Widget> _buildGpsSection(PropertyFormState s) {
    return [
      Text('property_wizard.gps_title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      const SizedBox(height: 4),
      Text(
        'property_wizard.gps_subtitle'.tr(),
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            if (s.isGeocodingAddress)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                s.selectedLocation != null
                    ? Icons.gps_fixed
                    : Icons.gps_not_fixed,
                size: 16,
                color: s.selectedLocation != null
                    ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s.isGeocodingAddress
                    ? 'property_wizard.gps_searching'.tr()
                    : s.selectedLocation != null
                        ? '${s.selectedLocation!.latitude.toStringAsFixed(5)}, '
                            '${s.selectedLocation!.longitude.toStringAsFixed(5)}'
                        : 'property_wizard.gps_no_coords'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  color: s.selectedLocation != null && !s.isGeocodingAddress
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // ── Toggle ubicación aproximada ───────────────────────────────────────────

  Widget _buildHideLocationToggle(
      PropertyFormState s, PropertyFormNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          'property_wizard.hide_location_title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          s.hideExactLocation
              ? 'property_wizard.hide_location_on'.tr()
              : 'property_wizard.hide_location_off'.tr(),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        secondary: Icon(
          s.hideExactLocation
              ? Icons.location_off_outlined
              : Icons.location_on_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        value: s.hideExactLocation,
        onChanged: (_) => notifier.toggleHideExactLocation(),
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  // ── Toggle consentimiento IA ──────────────────────────────────────────────

  Widget _buildAiComfortConsentToggle(
      PropertyFormState s, PropertyFormNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          'property_wizard.ai_comfort_title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          s.aiComfortConsent
              ? 'property_wizard.ai_comfort_on'.tr()
              : 'property_wizard.ai_comfort_off'.tr(),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        secondary: Icon(
          Icons.self_improvement_rounded,
          color: s.aiComfortConsent
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade400,
        ),
        value: s.aiComfortConsent,
        onChanged: (newValue) async {
          if (newValue) {
            // Show GDPR consent dialog before enabling
            final accepted = await AiConsentDialog.show(
              context: context,
              config: AiConsentConfig.aiComfortReport,
            );
            if (accepted) {
              notifier.toggleAiComfortConsent();
            }
          } else {
            // Disable without requiring dialog
            notifier.toggleAiComfortConsent();
          }
        },
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  // ── Map ───────────────────────────────────────────────────────────────────

  Widget _buildMap(
    PropertyFormState s,
    PropertyFormNotifier notifier,
    LatLng center,
  ) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: s.selectedLocation != null ? 15 : 12,
            onTap: (_, latLng) => notifier.setLocation(latLng),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.inmufacil.frontend',
            ),
            if (s.selectedLocation != null)
              MarkerLayer(markers: [
                Marker(
                  point: s.selectedLocation!,
                  width: 40,
                  height: 40,
                  child: Icon(Icons.location_pin,
                      color: Theme.of(context).colorScheme.primary, size: 40),
                ),
              ]),
          ],
        ),
        // ── Mi ubicación button ────────────────────────────────────────
        Positioned(
          right: 12,
          bottom: 12,
          child: SizedBox(
            width: 40,
            height: 40,
            child: FloatingActionButton(
              heroTag: 'step1_my_location',
              onPressed: _locating ? null : _goToMyLocation,
              tooltip: 'Mi ubicación',
              elevation: 2,
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: _locating
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : const Icon(Icons.my_location, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _goToMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final locationService = ref.read(locationServiceProvider);
      final result = await locationService.getCurrentLocation();
      if (!mounted) return;
      _mapController.move(result.location, 15.0);
      // Also update the pin to the detected location
      ref.read(propertyFormProvider.notifier).setLocation(result.location);
      if (result.isFallback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo obtener tu ubicación. Mostrando España.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }
} // end _PropertyStep1TypeLocationState

// ─── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─── Reusable banner ─────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.borderColor,
    required this.iconColor,
    required this.icon,
    required this.text,
  });

  final Color color;
  final Color borderColor;
  final Color iconColor;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 12, color: iconColor)),
            ),
          ],
        ),
      );
}
