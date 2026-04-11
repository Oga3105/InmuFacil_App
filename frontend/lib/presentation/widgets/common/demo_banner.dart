import 'package:flutter/material.dart';

/// Franja de aviso de entorno de demostración.
/// Usar como [PreferredSize] en AppBar.bottom o como widget inline.
class DemoBanner extends StatelessWidget implements PreferredSizeWidget {
  const DemoBanner({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(44.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFEF3C7), // amber-100
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.science_outlined, size: 14, color: Color(0xFF92400E)),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'Entorno de demostración — Los inmuebles son ficticios y no representan ofertas reales.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF92400E),
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge compacto "DEMO" para superponer en tarjetas de propiedad.
class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B), // amber-400
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: const Text(
        'DEMO',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
