import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class RegistryLinkWidget extends StatelessWidget {
  const RegistryLinkWidget({
    super.key,
    required this.propertyAddress,
    this.cadastralRef,
  });

  final String propertyAddress;
  final String? cadastralRef;

  static const String _registradoresUrl =
      'https://www.registradores.org/servicios-al-ciudadano/registro-de-la-propiedad/';

  Future<void> _openRegistradores(BuildContext context) async {
    final uri = Uri.parse(_registradoresUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el enlace'),
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referencia copiada al portapapeles'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.account_balance_outlined,
                  color: const Color(0xFF2563EB),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Registro de la Propiedad',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Info text
            Text(
              'Verifica la titularidad y cargas de este inmueble en el Registro de la Propiedad',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            // Main CTA button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openRegistradores(context),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Consultar en Registradores.org'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            // Direct search section
            Text(
              'Busqueda directa',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            // Cadastral ref row (only if provided)
            if (cadastralRef != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Referencia catastral',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cadastralRef!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _copyToClipboard(context, cadastralRef!),
                      icon: const Icon(Icons.copy_outlined, size: 20),
                      tooltip: 'Copiar referencia catastral',
                      color: const Color(0xFF2563EB),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Pre-search steps info card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Pasos para consultar',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _StepItem(
                    number: '1',
                    text: "Pulse 'Consultar en Registradores.org'",
                  ),
                  const SizedBox(height: 4),
                  _StepItem(
                    number: '2',
                    text: 'Seleccione su comunidad autonoma',
                  ),
                  const SizedBox(height: 4),
                  _StepItem(
                    number: '3',
                    text: 'Introduzca la referencia catastral',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.number,
    required this.text,
  });

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFF59E0B),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
