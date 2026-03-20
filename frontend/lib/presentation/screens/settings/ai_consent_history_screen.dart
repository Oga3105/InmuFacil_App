import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:inmufacil_frontend/presentation/providers/auth_provider.dart';
import 'package:intl/intl.dart';

import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

class _ConsentEntry {
  const _ConsentEntry({
    required this.id,
    required this.actionType,
    required this.actionLabel,
    required this.dataCategories,
    required this.purpose,
    required this.aiProvider,
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
  final DateTime consentedAt;
  final String? ipAddress;
  final String? propertyId;

  factory _ConsentEntry.fromJson(Map<String, dynamic> json) {
    final raw = json['data_categories'];
    final List<String> cats;
    if (raw is List) {
      cats = raw.map((e) => e.toString()).toList();
    } else if (raw is String) {
      // stored as JSON string: '["a","b"]'
      cats = raw
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
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
      consentedAt: DateTime.parse(json['consented_at'] as String).toLocal(),
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
    baseUrl: kApiBaseUrl,
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
      .toList();
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class AiConsentHistoryScreen extends ConsumerWidget {
  const AiConsentHistoryScreen({super.key});

  static const routePath = '/ai-consent-history';
  static const routeName = 'ai-consent-history';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final historyAsync = ref.watch(_aiConsentHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: AppBarBackButton(onPressed: () => context.pop()),
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_inmufacil.png',
              height: 28,
              errorBuilder: (_, __, ___) => const SizedBox(width: 28),
            ),
            const SizedBox(width: 8),
            const Text(
              'InmuFácil',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text(
              'Inicio',
              style: TextStyle(color: Color(0xFF2563EB), fontSize: 13),
            ),
          ),
          if (authState.isAuthenticated)
            const UserAvatarMenu(),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(message: err.toString()),
        data: (entries) => entries.isEmpty
            ? const _EmptyState()
            : _ConsentList(entries: entries),
      ),
    );
  }
}

// ─── List ─────────────────────────────────────────────────────────────────────

class _ConsentList extends StatelessWidget {
  const _ConsentList({required this.entries});
  final List<_ConsentEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.privacy_tip_outlined,
                      color: Color(0xFF7C3AED),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Historial de Consentimientos IA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${entries.length} registro${entries.length != 1 ? 's' : ''} de consentimiento. '
                'Base juridica: Art. 6.1.a RGPD / Art. 7 LOPDGDD.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _ConsentCard(entry: entries[index]),
          ),
        ),
      ],
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _ConsentCard extends StatelessWidget {
  const _ConsentCard({required this.entry});
  final _ConsentEntry entry;

  static const _purple = Color(0xFF7C3AED);
  static const _green = Color(0xFF16A34A);

  IconData _iconForActionType(String type) {
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
    final dateLabel = DateFormat('d MMM yyyy, HH:mm', 'es').format(entry.consentedAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: icon + label + badge
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_iconForActionType(entry.actionType),
                    color: _purple, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.actionLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _green.withValues(alpha: 0.2)),
                ),
                child: const Text(
                  'ACEPTADO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _green,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Date
          _InfoLine(
            icon: Icons.schedule_outlined,
            label: 'Fecha',
            value: dateLabel,
          ),
          const SizedBox(height: 6),

          // Provider
          _InfoLine(
            icon: Icons.smart_toy_outlined,
            label: 'Proveedor IA',
            value: entry.aiProvider,
          ),
          const SizedBox(height: 6),

          // Purpose
          _InfoLine(
            icon: Icons.flag_outlined,
            label: 'Finalidad',
            value: entry.purpose,
          ),
          const SizedBox(height: 6),

          // Data categories
          _InfoLine(
            icon: Icons.upload_outlined,
            label: 'Datos enviados',
            value: entry.dataCategories.map((c) => '• $c').join('\n'),
          ),

          // Property ref (optional)
          if (entry.propertyId != null) ...[
            const SizedBox(height: 6),
            _InfoLine(
              icon: Icons.home_outlined,
              label: 'Inmueble',
              value: 'ID: ${entry.propertyId}',
            ),
          ],

          // IP (optional)
          if (entry.ipAddress != null) ...[
            const SizedBox(height: 6),
            _InfoLine(
              icon: Icons.router_outlined,
              label: 'IP de sesion',
              value: entry.ipAddress!,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
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
        Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF334155),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Empty / Error states ─────────────────────────────────────────────────────

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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Color(0xFF7C3AED),
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin registros de consentimiento',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aqui apareceran los consentimientos que hayas otorgado para el uso de IA en la plataforma.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 40),
            const SizedBox(height: 12),
            const Text(
              'No se pudo cargar el historial',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
