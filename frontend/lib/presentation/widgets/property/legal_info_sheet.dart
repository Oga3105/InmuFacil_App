import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/config/env_config.dart';
import '../../providers/search_provider.dart';

// ---------------------------------------------------------------------------
// Provider: fetches the legal guide content from the backend
// ---------------------------------------------------------------------------

final _legalGuideProvider =
    FutureProvider.autoDispose.family<_LegalGuideData, _LegalGuideArgs>(
  (ref, args) async {
    final apiClient = ref.watch(apiClientProvider);
    final response = await apiClient.client.post(
      '/ai/legal-guide',
      data: {
        'ccaa': args.ccaa,
        'guide_type': args.guideType,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return _LegalGuideData(
      content: data['content'] as String? ?? '',
      disclaimer: data['disclaimer'] as String? ?? '',
    );
  },
);

// ---------------------------------------------------------------------------
// Internal data classes
// ---------------------------------------------------------------------------

class _LegalGuideArgs {
  const _LegalGuideArgs({required this.ccaa, required this.guideType});
  final String ccaa;
  final String guideType;

  @override
  bool operator ==(Object other) =>
      other is _LegalGuideArgs &&
      other.ccaa == ccaa &&
      other.guideType == guideType;

  @override
  int get hashCode => Object.hash(ccaa, guideType);
}

class _LegalGuideData {
  const _LegalGuideData({required this.content, required this.disclaimer});
  final String content;
  final String disclaimer;
}

// ---------------------------------------------------------------------------
// LegalInfoSheet
// ---------------------------------------------------------------------------

class LegalInfoSheet extends ConsumerWidget {
  const LegalInfoSheet({
    super.key,
    required this.ccaa,
    required this.guideType,
    required this.guideTitle,
  });

  final String ccaa;
  final String guideType;
  final String guideTitle;

  // Static helper to open the sheet
  static Future<void> show(
    BuildContext context, {
    required String ccaa,
    required String guideType,
    required String title,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LegalInfoSheet(
        ccaa: ccaa,
        guideType: guideType,
        guideTitle: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = _LegalGuideArgs(ccaa: ccaa, guideType: guideType);
    final guideAsync = ref.watch(_legalGuideProvider(args));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHandle(),
              _buildHeader(context, ref, args),
              const Divider(height: 1),
              Expanded(
                child: guideAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (_, __) => _buildErrorState(
                    context,
                    ref,
                    args,
                  ),
                  data: (guide) => _buildContent(
                    context,
                    scrollController,
                    guide,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    _LegalGuideArgs args,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              guideTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'legal.close_tooltip'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    _LegalGuideArgs args,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'legal.error_loading_guide'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(_legalGuideProvider(args)),
              child: Text('legal.retry_btn'.tr()),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildContent(
    BuildContext context,
    ScrollController scrollController,
    _LegalGuideData guide,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          guide.content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
              ),
        ),
        const SizedBox(height: 24),
        Text(
          guide.disclaimer,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
        ),
      ],
    );
  }
}
