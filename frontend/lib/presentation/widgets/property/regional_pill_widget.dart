import 'package:flutter/material.dart';
import '../../../core/utils/ccaa_utils.dart';

class RegionalPillWidget extends StatelessWidget {
  const RegionalPillWidget({
    super.key,
    required this.postalCode,
  });

  final String postalCode;

  @override
  Widget build(BuildContext context) {
    final ccaa = ccaaFromPostalCode(postalCode);
    if (ccaa == ComunidadAutonoma.desconocida) return const SizedBox.shrink();

    final requiresCedula = ccaaRequiereCedula(ccaa);
    final name = ccaaDisplayName[ccaa] ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF135BEC).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_city_outlined,
            size: 14,
            color: Color(0xFF135BEC),
          ),
          const SizedBox(width: 6),
          Text(
            requiresCedula
                ? 'Requisito regional detectado para $name'
                : 'Inmueble en $name',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E40AF),
            ),
          ),
          if (requiresCedula) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Cedula requerida',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
