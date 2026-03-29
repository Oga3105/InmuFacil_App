import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/env_config.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

const _kNavy = Color(0xFF0F172A);
const _kPurple = Color(0xFF7C3AED);
const _kGreen = Color(0xFF16A34A);
const _kSlate = Color(0xFF64748B);
const _kBg = Color(0xFFF8FAFC);

// ─── Data model ───────────────────────────────────────────────────────────────

class _ConsentEntry {
  const _ConsentEntry({
    required this.id,
    required this.actionType,
    required this.actionLabel,
    required this.dataCategories,
    required this.purpose,
    required this.aiProvider,
    required this.consentTextVersion,
    required this.consentedAt,
    this.ipAddress,
    this.propertyId,
  });

  final int id;
  final String actionType;
  final String actionLabel;
  final List<String> dataCategories;
  final String purpose;
  final String aiProvider;
  final String consentTextVersion;
  final DateTime consentedAt;
  final String? ipAddress;
  final String? propertyId;

  factory _ConsentEntry.fromJson(Map<String, dynamic> json) {
    final raw = json['data_categories'];
    List<String> cats;
    if (raw is List) {
      cats = raw.map((e) => e.toString()).toList();
    } else if (raw is String) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        cats = decoded.map((e) => e.toString()).toList();
      } catch (_) {
        cats = raw
            .replaceAll('[', '')
            .replaceAll(']', '')
            .replaceAll('"', '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    } else {
      cats = const [];
    }
    return _ConsentEntry(
      id: json['id'] as int,
      actionType: json['action_type'] as String,
      actionLabel: json['action_label'] as String,
      dataCategories: cats,
      purpose: json['purpose'] as String,
      aiProvider: json['ai_provider'] as String,
      consentTextVersion:
          (json['consent_text_version'] as String?) ?? 'v1.0',
      consentedAt:
          DateTime.parse(json['consented_at'] as String).toLocal(),
      ipAddress: json['ip_address'] as String?,
      propertyId: json['property_id'] as String?,
    );
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final _aiConsentHistoryProvider =
    FutureProvider.autoDispose<List<_ConsentEntry>>((ref) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'auth_token');
  if (token == null) return [];

  final dio = Dio(BaseOptions(
    baseUrl: EnvConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  final response = await dio.get(
    '/ai-consent/me',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  final list = response.data as List<dynamic>;
  return list
      .map((e) => _ConsentEntry.fromJson(e as Map<String, dynamic>))
      .toList()
    ..sort((a, b) => b.consentedAt.compareTo(a.consentedAt));
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class AiConsentHistoryScreen extends ConsumerWidget {
  const AiConsentHistoryScreen({super.key});

  static const routePath = '/ai-consent-history';
  static const routeName = 'ai-consent-history';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_aiConsentHistoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context),
      body: historyAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kPurple)),
        error: (err, _) => _ErrorState(message: err.toString()),
        data: (entries) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _PageHeader(count: entries.length)),
            if (entries.isEmpty)
              const SliverFillRemaining(child: _EmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ConsentCard(entry: entries[index]),
                    ),
                    childCount: entries.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AppBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: GestureDetector(
        onTap: () => context.go('/'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo_inmufacil.png', height: 32),
            const SizedBox(width: 8),
            const Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                children: [
                  TextSpan(
                    text: 'Inmu',
                    style: TextStyle(color: Color(0xFF135BEC)),
                  ),
                  TextSpan(
                    text: 'Fácil',
                    style: TextStyle(color: Color(0xFF16A34A)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
      ),
      actions: [
        if (MediaQuery.sizeOf(context).width >= 650)
        GestureDetector(
          onTap: () => context.go('/'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF135BEC),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF135BEC).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_rounded, size: 18, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Inicio',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 12),
            UserAvatarMenu(),
            SizedBox(width: 16),
          ],
        ),
      ],
    );
  }
}

// ─── Page header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Framed header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kPurple.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kPurple.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.privacy_tip_outlined, color: _kPurple, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Historial de Consentimientos IA',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kPurple),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Registro de consentimientos explícitos para el tratamiento de datos por IA (Art. 15 RGPD).',
                        style: TextStyle(fontSize: 13, color: _kPurple.withOpacity(0.85)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Count badge
          Text(
            count == 0
                ? 'Sin registros todavía'
                : '$count consentimiento${count != 1 ? 's' : ''} registrado${count != 1 ? 's' : ''}',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          // GDPR info panel
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: Color(0xFF92400E)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Base jurídica: Art. 6.1.a RGPD / Art. 7 LOPDGDD. '
                    'Derecho de acceso: Art. 15 RGPD.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Consent Card (expandable) ────────────────────────────────────────────────

class _ConsentCard extends StatefulWidget {
  const _ConsentCard({required this.entry});
  final _ConsentEntry entry;

  @override
  State<_ConsentCard> createState() => _ConsentCardState();
}

class _ConsentCardState extends State<_ConsentCard> {
  bool _expanded = false;

  static IconData _iconForType(String type) {
    switch (type) {
      case 'property_description':
        return Icons.auto_awesome;
      case 'kyc_identity_verification':
        return Icons.verified_user_outlined;
      default:
        return Icons.smart_toy_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final dateLabel =
        DateFormat('d MMM yyyy · HH:mm', 'es').format(e.consentedAt);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // Always-visible row
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_iconForType(e.actionType),
                          color: _kPurple, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.actionLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.schedule_outlined,
                                  size: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(width: 3),
                              Text(
                                dateLabel,
                                style: TextStyle(
                                    fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _kGreen.withValues(alpha: 0.25)),
                      ),
                      child: const Text(
                        'ACEPTADO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _kGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: _kSlate,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),

            // Expandable detail
            if (_expanded) ...[
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(
                      icon: Icons.smart_toy_outlined,
                      label: 'Proveedor de IA',
                      value: e.aiProvider,
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      icon: Icons.flag_outlined,
                      label: 'Finalidad',
                      value: e.purpose,
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      icon: Icons.upload_outlined,
                      label: 'Datos enviados al proveedor',
                      value: e.dataCategories.map((c) => '• $c').join('\n'),
                    ),
                    if (e.propertyId != null) ...[
                      const SizedBox(height: 10),
                      _DetailRow(
                        icon: Icons.home_outlined,
                        label: 'Inmueble de referencia',
                        value: 'ID: ${e.propertyId}',
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _kBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          _MetaChip(
                              icon: Icons.tag, text: 'Registro #${e.id}'),
                          _MetaChip(
                              icon: Icons.verified_outlined,
                              text: 'Version ${e.consentTextVersion}'),
                          if (e.ipAddress != null)
                            _MetaChip(
                                icon: Icons.router_outlined,
                                text: 'IP: ${e.ipAddress}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: _kSlate),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: _kSlate,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: _kNavy,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: _kSlate),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(fontSize: 10, color: _kSlate)),
      ],
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFEDE9FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_outlined,
                  color: _kPurple, size: 38),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sin registros de consentimiento',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _kNavy,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Cuando uses funciones de IA (descripción de inmueble, '
              'verificación de identidad…) y otorgues tu consentimiento, '
              'los registros aparecerán aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _kSlate, height: 1.6),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.home_outlined, size: 16),
              label: const Text('Volver al inicio'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPurple,
                side: const BorderSide(color: Color(0xFFDDD6FE)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                color: Color(0xFFDC2626), size: 44),
            const SizedBox(height: 16),
            const Text(
              'No se pudo cargar el historial',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _kNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _kSlate),
            ),
          ],
        ),
      ),
    );
  }
}
