import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

/// Displays the cryptographic seal badge for a signed document.
///
/// Shows verification ID, truncated seal hash, and timestamp.
/// Tapping the hash copies the full value to clipboard.
class QrDocumentSeal extends StatelessWidget {
  const QrDocumentSeal({
    super.key,
    required this.verificationId,
    required this.sealHash,
    required this.timestampUtc,
    this.documentId,
  });

  final String verificationId;
  final String sealHash;
  final String timestampUtc;
  final String? documentId;

  String get _shortHash =>
      sealHash.length >= 16 ? '${sealHash.substring(0, 8)}...${sealHash.substring(sealHash.length - 8)}' : sealHash;

  String get _formattedTimestamp {
    try {
      final dt = DateTime.parse(timestampUtc).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestampUtc;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF16A34A).withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'signature.seal_title'.tr(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF166534),
                      ),
                    ),
                    Text(
                      'signature.seal_subtitle'.tr(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF4B7C5B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xFFBBF7D0), height: 1),
          const SizedBox(height: 12),

          // Seal hash row
          _InfoRow(
            label: 'signature.seal_hash_label'.tr(),
            value: _shortHash,
            onTap: () {
              Clipboard.setData(ClipboardData(text: sealHash));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('signature.hash_copied'.tr()),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF16A34A),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: Icons.copy_rounded,
          ),

          const SizedBox(height: 8),

          // Verification ID
          _InfoRow(
            label: 'signature.verification_id_label'.tr(),
            value: verificationId.length > 18
                ? verificationId.substring(0, 18)
                : verificationId,
          ),

          const SizedBox(height: 8),

          // Timestamp
          _InfoRow(
            label: 'signature.timestamp_label'.tr(),
            value: _formattedTimestamp,
            icon: Icons.access_time_rounded,
          ),

          if (documentId != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              label: 'signature.document_id_label'.tr(),
              value: documentId!,
            ),
          ],

          const SizedBox(height: 12),

          // eIDAS notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'signature.eidas_notice'.tr(),
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF166534),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info row helper
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget valueWidget = Text(
      value,
      style: const TextStyle(
        fontSize: 12,
        fontFamily: 'monospace',
        color: Color(0xFF1E293B),
        fontWeight: FontWeight.w500,
      ),
    );

    if (onTap != null) {
      valueWidget = GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            valueWidget,
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 14, color: const Color(0xFF16A34A)),
            ],
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: valueWidget),
        if (icon != null && onTap == null)
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
      ],
    );
  }
}
