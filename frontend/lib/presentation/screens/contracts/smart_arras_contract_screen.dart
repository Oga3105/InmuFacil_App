import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/currency_input_formatter.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';

// ---------------------------------------------------------------------------
// SmartArrasContractScreen
// ---------------------------------------------------------------------------

class SmartArrasContractScreen extends ConsumerStatefulWidget {
  const SmartArrasContractScreen({
    super.key,
    required this.propertyId,
    required this.buyerId,
    required this.sellerId,
    required this.salePrice,
    required this.propertyAddress,
  });

  final String propertyId;
  final String buyerId;
  final String sellerId;
  final int salePrice;
  final String propertyAddress;

  @override
  ConsumerState<SmartArrasContractScreen> createState() =>
      _SmartArrasContractScreenState();
}

class _SmartArrasContractScreenState
    extends ConsumerState<SmartArrasContractScreen> {
  late int _arrasAmount;
  DateTime? _signatureDeadline;
  bool _needsMortgage = false;
  final List<String> _furnitureItems = [];

  // Validation errors
  String? _arrasError;
  String? _deadlineError;

  // Furniture input controller
  final TextEditingController _furnitureController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default arras = 10% of sale price
    _arrasAmount = (widget.salePrice * 0.10).round();
  }

  @override
  void dispose() {
    _furnitureController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  bool _validate() {
    bool valid = true;
    setState(() {
      _arrasError = null;
      _deadlineError = null;

      if (_arrasAmount >= widget.salePrice) {
        _arrasError =
            'arras_contract.error_arras_exceeds_price'.tr();
        valid = false;
      }

      if (_signatureDeadline == null ||
          !_signatureDeadline!.isAfter(DateTime.now())) {
        _deadlineError = 'arras_contract.error_deadline_future'.tr();
        valid = false;
      }
    });
    return valid;
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        _signatureDeadline = picked;
        _deadlineError = null;
      });
    }
  }

  void _onGenerateContract() {
    if (!_validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('arras_contract.generated_snackbar'.tr()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addFurnitureItem() {
    final text = _furnitureController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _furnitureItems.add(text);
      _furnitureController.clear();
    });
  }

  void _removeFurnitureItem(int index) {
    setState(() {
      _furnitureItems.removeAt(index);
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppBarBackButton(
            onPressed: () => context.pop(),
          ),
        ),
        title: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.go('/'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo_inmufacil.png', height: 28),
                const SizedBox(width: 8),
                const Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(text: 'Inmu', style: TextStyle(color: Color(0xFF135BEC))),
                      TextSpan(text: 'Fácil', style: TextStyle(color: Color(0xFF16A34A))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (MediaQuery.sizeOf(context).width >= 650)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/'),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF135BEC),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF135BEC).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 5),
                    Text('transaction.home_btn'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),


              ),
            ),
          ),
          const SizedBox(width: 8),
          const UserAvatarMenu(),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // KYC Warning placeholder
            _KycWarningBanner(),

            const SizedBox(height: 16),

            // Arras amount field
            _SectionLabel(label: 'arras_contract.section_arras_amount'.tr()),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: CurrencyInputFormatter.format(_arrasAmount),
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixText: 'EUR',
                errorText: _arrasError,
                helperText:
                    '${'arras_contract.sale_price_label'.tr()}: ${CurrencyInputFormatter.format(widget.salePrice)} EUR',
              ),
              onChanged: (val) {
                final parsed = CurrencyInputFormatter.parse(val);
                if (parsed != null) {
                  setState(() {
                    _arrasAmount = parsed;
                    _arrasError = null;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // Signature deadline picker
            _SectionLabel(
                label: 'arras_contract.section_deadline'.tr()),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDeadline,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  errorText: _deadlineError,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _signatureDeadline != null
                      ? DateFormat('dd/MM/yyyy').format(_signatureDeadline!)
                      : 'arras_contract.select_date'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _signatureDeadline != null
                        ? null
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Mortgage clause toggle
            SwitchListTile(
              value: _needsMortgage,
              onChanged: (v) => setState(() => _needsMortgage = v),
              title: Text('arras_contract.needs_mortgage'.tr()),
              subtitle: Text(
                'arras_contract.needs_mortgage_subtitle'.tr(),
                style:
                    theme.textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 8),

            // Furniture items
            _SectionLabel(label: 'arras_contract.section_furniture'.tr()),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _furnitureController,
                    decoration: InputDecoration(
                      hintText: 'arras_contract.furniture_hint'.tr(),
                      border: const OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) => _addFurnitureItem(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addFurnitureItem,
                  child: Text('arras_contract.add_item'.tr()),
                ),
              ],
            ),
            if (_furnitureItems.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _furnitureItems.asMap().entries.map((entry) {
                  return Chip(
                    label: Text(entry.value),
                    onDeleted: () => _removeFurnitureItem(entry.key),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),

            // A4 preview card
            SmartContractPreview(
              buyerId: widget.buyerId,
              sellerId: widget.sellerId,
              propertyAddress: widget.propertyAddress,
              salePrice: widget.salePrice,
              arrasAmount: _arrasAmount,
              signatureDeadline: _signatureDeadline,
              needsMortgage: _needsMortgage,
              furnitureItems: _furnitureItems,
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('arras_contract.btn_edit'.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onGenerateContract,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF135BEC),
                      foregroundColor: Colors.white,
                    ),
                    child: Text('arras_contract.btn_generate'.tr()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// KYC Warning Banner
// ---------------------------------------------------------------------------

class _KycWarningBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.40),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: Color(0xFFF59E0B),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'arras_contract.kyc_warning'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFF59E0B),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label helper
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// SmartContractPreview — A4-style notarial preview card
// ---------------------------------------------------------------------------

class SmartContractPreview extends StatelessWidget {
  const SmartContractPreview({
    super.key,
    required this.buyerId,
    required this.sellerId,
    required this.propertyAddress,
    required this.salePrice,
    required this.arrasAmount,
    required this.signatureDeadline,
    required this.needsMortgage,
    required this.furnitureItems,
  });

  final String buyerId;
  final String sellerId;
  final String propertyAddress;
  final int salePrice;
  final int arrasAmount;
  final DateTime? signatureDeadline;
  final bool needsMortgage;
  final List<String> furnitureItems;

  static const Color _blue = Color(0xFF135BEC);
  static const Color _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deadlineText = signatureDeadline != null
        ? DateFormat('dd/MM/yyyy').format(signatureDeadline!)
        : 'arras_contract.preview_pending_date'.tr();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Document title
          Center(
            child: Text(
              'arras_contract.preview_title'.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),


          const SizedBox(height: 4),
          Center(
            child: Text(
              'arras_contract.preview_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),

          // REUNIDOS
          _PreviewSection(
            label: 'arras_contract.preview_section_reunidos'.tr(),
            labelColor: _blue,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PreviewRow(
                  title: 'arras_contract.preview_buyer'.tr(),
                  value: buyerId,
                  validated: true,
                ),
                const SizedBox(height: 4),
                _PreviewRow(
                  title: 'arras_contract.preview_seller'.tr(),
                  value: sellerId,
                  validated: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // OBJETO
          _PreviewSection(
            label: 'arras_contract.preview_section_objeto'.tr(),
            labelColor: _blue,

            child: _PreviewRow(
              title: 'arras_contract.preview_address'.tr(),
              value: propertyAddress,
              validated: propertyAddress.isNotEmpty,
            ),
          ),

          const SizedBox(height: 14),

          // PRECIO DE COMPRAVENTA
          _PreviewSection(
            label: 'arras_contract.preview_section_precio'.tr(),
            labelColor: _blue,

            child: _PreviewRow(
              title: 'arras_contract.preview_sale_price'.tr(),
              value:
                  '${CurrencyInputFormatter.format(salePrice)} EUR',
              validated: salePrice > 0,
            ),
          ),

          const SizedBox(height: 14),

          // ARRAS (10%)
          _PreviewSection(
            label: 'arras_contract.preview_section_arras'.tr(),
            labelColor: _blue,

            child: _PreviewRow(
              title: 'arras_contract.preview_arras'.tr(),
              value:
                  '${CurrencyInputFormatter.format(arrasAmount)} EUR',
              validated: arrasAmount > 0 && arrasAmount < salePrice,
            ),
          ),

          const SizedBox(height: 14),

          // PLAZO DE ESCRITURACION
          _PreviewSection(
            label: 'arras_contract.preview_section_plazo'.tr(),
            labelColor: _blue,

            child: _PreviewRow(
              title: 'arras_contract.preview_deadline'.tr(),
              value: deadlineText,
              validated: signatureDeadline != null &&
                  signatureDeadline!.isAfter(DateTime.now()),
            ),
          ),

          // CLAUSULA DE DESISTIMIENTO (mortgage)
          if (needsMortgage) ...[
            const SizedBox(height: 14),
            _PreviewSection(
              label: 'arras_contract.preview_section_desistimiento'.tr(),
              labelColor: _green,

              child: Text(
                'arras_contract.preview_mortgage_clause'.tr(),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],

          // INVENTARIO (furniture)
          if (furnitureItems.isNotEmpty) ...[
            const SizedBox(height: 14),
            _PreviewSection(
              label: 'arras_contract.preview_section_inventario'.tr(),
              labelColor: _blue,

              child: Text(
                furnitureItems.join(', '),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),

          // Legal reference
          Center(
            child: Text(
              'arras_contract.preview_legal_ref'.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Digital signature notice
          Center(
            child: Text(
              'arras_contract.preview_signature_notice'.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preview section header
// ---------------------------------------------------------------------------

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({
    required this.label,
    required this.labelColor,
    required this.child,
  });

  final String label;
  final Color labelColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: labelColor,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Preview row (label + value with optional validated highlight)
// ---------------------------------------------------------------------------

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.title,
    required this.value,
    this.validated = false,
  });

  final String title;
  final String value;
  final bool validated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: validated
                  ? const Color(0xFF16A34A)
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
