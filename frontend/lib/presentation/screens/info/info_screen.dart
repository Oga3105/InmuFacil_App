import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kBlue  = Color(0xFF2563EB);
const _kGreen = Color(0xFF16A34A);
const _kBg    = Color(0xFFF8FAFC);
const _kNavy  = Color(0xFF1E3A5F);

// ============================================================================
// Generic Info Screen — receives page type as enum
// ============================================================================

enum InfoPageType {
  whatIsInmufacil,
  howItWorks,
  buyerGuide,
  sellerGuide,
  contact,
  faq,
  privacy,
  terms,
  legalNotice,
}

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key, required this.pageType});

  final InfoPageType pageType;

  static String routeFor(InfoPageType type) {
    const map = {
      InfoPageType.whatIsInmufacil: '/info/what-is',
      InfoPageType.howItWorks: '/info/how-it-works',
      InfoPageType.buyerGuide: '/info/buyer-guide',
      InfoPageType.sellerGuide: '/info/seller-guide',
      InfoPageType.contact: '/info/contact',
      InfoPageType.faq: '/info/faq',
      InfoPageType.privacy: '/info/privacy',
      InfoPageType.terms: '/info/terms',
      InfoPageType.legalNotice: '/info/legal',
    };
    return map[type]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
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
                      style: TextStyle(color: Color(0xFF2563EB)),
                    ),
                    TextSpan(
                      text: 'Facil',
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
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
        actions: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
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
          const SizedBox(width: 12),
          const UserAvatarMenu(),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildContent(context),
    );
  }


  Widget _buildContent(BuildContext context) {
    switch (pageType) {
      case InfoPageType.whatIsInmufacil:
        return _WhatIsScreen();
      case InfoPageType.howItWorks:
        return _HowItWorksScreen();
      case InfoPageType.buyerGuide:
        return _BuyerGuideScreen();
      case InfoPageType.sellerGuide:
        return _SellerGuideScreen();
      case InfoPageType.contact:
        return _ContactScreen();
      case InfoPageType.faq:
        return _FaqScreen();
      case InfoPageType.privacy:
        return const _LegalTextScreen(
          title: 'Politica de Privacidad',
          sections: _privacySections,
          heroIcon: Icons.privacy_tip_outlined,
          heroColor: _kBlue,
        );
      case InfoPageType.terms:
        return const _LegalTextScreen(
          title: 'Terminos y Condiciones de Uso',
          sections: _termsSections,
          heroIcon: Icons.description_outlined,
          heroColor: _kNavy,
        );
      case InfoPageType.legalNotice:
        return const _LegalTextScreen(
          title: 'Aviso Legal',
          sections: _legalNoticeSections,
          heroIcon: Icons.gavel_outlined,
          heroColor: _kGreen,
        );
    }
  }
}

// ============================================================================
// What is InmuFacil
// ============================================================================

class _WhatIsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const features = [
      ('Sin intermediarios', 'Conectamos directamente a compradores y vendedores particulares, eliminando las comisiones de las agencias.', Icons.handshake_outlined),
      ('Proceso guiado', 'Desde la visita hasta la firma notarial, te acompanamos en cada paso con herramientas legales y financieras.', Icons.route_outlined),
      ('Seguridad juridica', 'Verificacion de identidad KYC, Contrato de Arras digital y notaria integrada.', Icons.security_outlined),
      ('Solvencia consciente', 'Cuestionario financiero para que compradores conozcan su situacion real antes de ofertar.', Icons.assessment_outlined),
      ('Transparencia total', 'Historial de ofertas y negociacion completamente visible para ambas partes.', Icons.visibility_outlined),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Hero
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kNavy, _kBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.home_work_outlined, color: Colors.white, size: 52),
              const SizedBox(height: 16),
              const Text(
                'InmuFacil',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'La plataforma P2P de compraventa inmobiliaria sin comisiones de agencia.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Por que InmuFacil?',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: _kNavy),
        ),
        const SizedBox(height: 16),
        ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _FeatureCard(icon: f.$3, title: f.$1, body: f.$2),
            )),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kGreen.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kGreen.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Text(
                '0 EUR en comisiones de agencia',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kGreen),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'El ahorro medio en una operacion de 250.000 EUR es de 7.500 EUR (3% agencia)',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: _kGreen.withOpacity(0.8),
                    height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// How it Works
// ============================================================================

class _HowItWorksScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const steps = [
      _Step(
        number: '1',
        title: 'Publica tu propiedad',
        body: 'Crea tu anuncio con fotos, descripcion y precio. Sube el Certificado Energetico (CEE) para poder recibir ofertas.',
        icon: Icons.add_home_outlined,
        color: _kBlue,
      ),
      _Step(
        number: '2',
        title: 'Recibe visitas',
        body: 'Los compradores solicitan visitas. Tu gestionas tus ventanas horarias y confirms las citas que te interesen.',
        icon: Icons.calendar_month_outlined,
        color: _kGreen,
      ),
      _Step(
        number: '3',
        title: 'Gestiona ofertas',
        body: 'Los compradores hacen ofertas con su Pasaporte de Solvencia adjunto. Acepta, rechaza o contraoferta directamente.',
        icon: Icons.payments_outlined,
        color: Colors.purple,
      ),
      _Step(
        number: '4',
        title: 'Firma el Contrato de Arras',
        body: 'La entrevista guiada genera el borrador del contrato de arras. Ambas partes lo firman digitalmente.',
        icon: Icons.draw_outlined,
        color: Colors.orange,
      ),
      _Step(
        number: '5',
        title: 'Tasacion e hipoteca',
        body: 'Si el comprador necesita hipoteca, coordinas la visita del tasador. El banco aprueba el prestamo.',
        icon: Icons.assessment_outlined,
        color: _kBlue,
      ),
      _Step(
        number: '6',
        title: 'Notaria y escrituras',
        body: 'Se firma la compraventa ante notario. InmuFacil te muestra el checklist de documentos necesarios.',
        icon: Icons.account_balance_outlined,
        color: _kGreen,
      ),
      _Step(
        number: '7',
        title: 'Entrega de llaves',
        body: 'Confirma la entrega. El comprador recibe los documentos para el cambio de titularidad de suministros.',
        icon: Icons.vpn_key_outlined,
        color: Colors.amber,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'El proceso completo',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: _kNavy),
        ),
        const SizedBox(height: 8),
        Text(
          'De la publicacion a las llaves, todo en una plataforma.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        ...steps.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _StepCard(step: e.value, isLast: e.key == steps.length - 1),
            )),
      ],
    );
  }
}

// ============================================================================
// Buyer Guide
// ============================================================================

class _BuyerGuideScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const sections = [
      _GuideSection(
        icon: Icons.search_outlined,
        color: _kBlue,
        title: 'Busca tu propiedad ideal',
        items: [
          'Usa los filtros de precio, superficie, habitaciones y ubicacion',
          'Guarda tus favoritos para comparar despues',
          'Activa alertas para recibir nuevos anuncios que coincidan con tu busqueda',
        ],
      ),
      _GuideSection(
        icon: Icons.assessment_outlined,
        color: Colors.purple,
        title: 'Completa tu Pasaporte de Solvencia',
        items: [
          'Responde honestamente al cuestionario financiero',
          'Conoce tu ratio de endeudamiento real (maximo recomendado 35%)',
          'Tu nivel de solvencia (Bronce/Plata/Oro) se muestra al vendedor de forma anonimizada',
          'Caduca a los 90 dias para mantener la informacion actualizada',
        ],
      ),
      _GuideSection(
        icon: Icons.payments_outlined,
        color: _kGreen,
        title: 'Haz tu oferta',
        items: [
          'Las ofertas son formales y quedan registradas',
          'Puedes incluir condiciones (sujeto a hipoteca, libre de cargas, etc.)',
          'El vendedor puede aceptar, rechazar o contraofertarte',
          'Un chat privado se abre automaticamente cuando la oferta es aceptada',
        ],
      ),
      _GuideSection(
        icon: Icons.euro_outlined,
        color: Colors.orange,
        title: 'Costes que debes prever',
        items: [
          'ITP (segunda mano): 6-10% segun comunidad autonoma',
          'IVA (obra nueva): 10%',
          'Notaria: 600-1.200 EUR aprox.',
          'Registro de la Propiedad: 400-700 EUR aprox.',
          'Gestoria: 300-600 EUR aprox.',
          'Total estimado: 10-15% sobre el precio de compra',
        ],
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kBlue.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBlue.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_outline, color: _kBlue, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Guia del Comprador',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _kBlue)),
                    SizedBox(height: 4),
                    Text(
                      'Todo lo que necesitas saber para comprar sin agencias.',
                      style: TextStyle(fontSize: 13, color: _kBlue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...sections.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _GuideSectionCard(section: s),
            )),
      ],
    );
  }
}

// ============================================================================
// Seller Guide
// ============================================================================

class _SellerGuideScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const sections = [
      _GuideSection(
        icon: Icons.add_home_outlined,
        color: _kGreen,
        title: 'Publica tu propiedad',
        items: [
          'Completa todos los campos del asistente de publicacion',
          'Sube al menos 5 fotos de calidad (recomendadas 10+)',
          'El Certificado Energetico (CEE) es obligatorio para recibir ofertas',
          'Configura tus ventanas horarias de visitas',
        ],
      ),
      _GuideSection(
        icon: Icons.verified_user_outlined,
        color: _kBlue,
        title: 'Gestiona la solvencia',
        items: [
          'Revisa el Pasaporte de Solvencia del comprador antes de aceptar',
          'El nivel Oro indica maxima solvencia (pago al contado o hipoteca aprobada)',
          'Solo tu puedes ver este pasaporte y es completamente anonimizado',
          'Debes aceptar la solvencia para que el proceso avance',
        ],
      ),
      _GuideSection(
        icon: Icons.description_outlined,
        color: Colors.purple,
        title: 'Documentacion necesaria',
        items: [
          'Escritura de propiedad',
          'Ultimo recibo IBI pagado',
          'Certificado de no deber a la comunidad',
          'Certificado Energetico (CEE) — obligatorio',
          'Nota simple del Registro (no mas de 3 meses)',
          'Si hay hipoteca: certificado de saldo pendiente',
        ],
      ),
      _GuideSection(
        icon: Icons.euro_outlined,
        color: Colors.orange,
        title: 'Costes del vendedor',
        items: [
          'Plusvalia municipal: variable segun ayuntamiento y anos de tenencia',
          'IRPF por ganancia patrimonial: 19-28% sobre la ganancia',
          'Cancelacion registral de hipoteca (si aplica): 400-800 EUR',
          'Notaria: parte proporcional (normalmente asumida por el comprador)',
        ],
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kGreen.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kGreen.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.home_outlined, color: _kGreen, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Guia del Vendedor',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _kGreen)),
                    SizedBox(height: 4),
                    Text(
                      'Vende tu propiedad sin pagar comisiones de agencia.',
                      style: TextStyle(fontSize: 13, color: _kGreen),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...sections.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _GuideSectionCard(section: s),
            )),
      ],
    );
  }
}

// ============================================================================
// Contact
// ============================================================================

class _ContactScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Estamos para ayudarte',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: _kNavy),
        ),
        const SizedBox(height: 8),
        Text(
          'Selecciona el canal que mejor te convenga.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        _ContactOption(
          icon: Icons.email_outlined,
          color: _kBlue,
          title: 'Correo electronico',
          subtitle: 'soporte@inmufacil.es',
          actionLabel: 'Enviar email',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _ContactOption(
          icon: Icons.chat_bubble_outline,
          color: _kGreen,
          title: 'Chat en la aplicacion',
          subtitle: 'Respuesta en menos de 24 horas',
          actionLabel: 'Abrir chat',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _ContactOption(
          icon: Icons.help_outline,
          color: Colors.purple,
          title: 'Centro de ayuda',
          subtitle: 'Consulta nuestras guias y tutoriales',
          actionLabel: 'Ver ayuda',
          onTap: () => context.push(InfoScreen.routeFor(InfoPageType.faq)),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Informacion legal',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14, color: _kNavy)),
              const SizedBox(height: 12),
              _LegalLink(label: 'Politica de Privacidad',
                  route: InfoScreen.routeFor(InfoPageType.privacy)),
              _LegalLink(label: 'Terminos de Uso',
                  route: InfoScreen.routeFor(InfoPageType.terms)),
              _LegalLink(label: 'Aviso Legal',
                  route: InfoScreen.routeFor(InfoPageType.legalNotice)),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.route});

  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.chevron_right, color: _kBlue, size: 18),
            Text(label,
                style: const TextStyle(
                    color: _kBlue, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// FAQ
// ============================================================================

class _FaqScreen extends StatelessWidget {
  static const _faqs = [
    _FaqItem(
      q: 'Es gratuito usar InmuFacil?',
      a: 'Si, publicar propiedades y enviar ofertas es completamente gratuito. '
          'Algunas funcionalidades premium como servicios de tasacion o asesoria legal pueden tener coste.',
    ),
    _FaqItem(
      q: 'Necesito un agente inmobiliario?',
      a: 'No. InmuFacil esta disenado para conectar directamente a compradores y vendedores. '
          'La plataforma guia el proceso con herramientas legales y financieras integradas.',
    ),
    _FaqItem(
      q: 'Es obligatorio el Certificado Energetico (CEE)?',
      a: 'Si. La ley espanola obliga a disponer del CEE para vender una propiedad. '
          'Ademas, InmuFacil bloquea la recepcion de ofertas hasta que el CEE este subido.',
    ),
    _FaqItem(
      q: 'Que es el Pasaporte de Solvencia?',
      a: 'Es un cuestionario financiero que el comprador completa voluntariamente. '
          'Ayuda al vendedor a valorar la solidez financiera del comprador antes de aceptar una oferta. '
          'Los datos son anonimizados y caduca a los 90 dias.',
    ),
    _FaqItem(
      q: 'El Contrato de Arras generado es legal?',
      a: 'El contrato generado por InmuFacil es un borrador orientativo. '
          'Recomendamos que sea revisado por un abogado antes de la firma. '
          'InmuFacil no presta servicios juridicos.',
    ),
    _FaqItem(
      q: 'Como se verifican los usuarios?',
      a: 'InmuFacil usa un proceso KYC (Know Your Customer) con verificacion de DNI/NIE '
          'mediante fotografia y reconocimiento de documentos. Los usuarios verificados '
          'tienen mayor credibilidad en la plataforma.',
    ),
    _FaqItem(
      q: 'Que ocurre si una de las partes se echa atras?',
      a: 'Segun las condiciones del Contrato de Arras: si el comprador desiste, '
          'pierde las arras entregadas. Si el vendedor desiste, debe devolver el doble de las arras.',
    ),
    _FaqItem(
      q: 'InmuFacil guarda mis datos?',
      a: 'Tus datos se tratan conforme al RGPD. Puedes ejercer tu derecho al olvido '
          'solicitando la eliminacion de tu cuenta. Los documentos sensibles se cifran en reposo.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Preguntas frecuentes',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kNavy),
        ),
        const SizedBox(height: 20),
        ..._faqs.map((faq) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FaqCard(faq: faq),
            )),
      ],
    );
  }
}

class _FaqCard extends StatefulWidget {
  const _FaqCard({required this.faq});

  final _FaqItem faq;

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _expanded ? _kBlue.withOpacity(0.3) : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.faq.q,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: _expanded ? _kBlue : _kNavy)),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: _expanded ? _kBlue : Colors.grey.shade400,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                Text(widget.faq.a,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem({required this.q, required this.a});
  final String q;
  final String a;
}

// ============================================================================
// Legal text screens (Privacy, Terms, Legal Notice)
// ============================================================================

class _LegalSection {
  const _LegalSection({
    required this.title,
    required this.body,
    this.icon = Icons.article_outlined,
    this.highlight = false,
  });
  final String title;
  final String body;
  final IconData icon;
  /// Highlight = true renders the section with a coloured border (for AI/biometrics)
  final bool highlight;
}

class _LegalTextScreen extends StatelessWidget {
  const _LegalTextScreen({
    required this.title,
    required this.sections,
    this.heroIcon = Icons.description_outlined,
    this.heroColor = _kBlue,
  });

  final String title;
  final List<_LegalSection> sections;
  final IconData heroIcon;
  final Color heroColor;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Hero header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: heroColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: heroColor.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: heroColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(heroIcon, color: heroColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: heroColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ultima actualizacion: Marzo 2026 · Version 1.0',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Cifrado AES-256-GCM · RGPD · ISO 27001',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...sections.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LegalSectionTile(
                  index: e.key + 1,
                  section: e.value,
                ),
              ),
            ),
        const SizedBox(height: 20),
        // Footer note
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline,
                  size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Para cualquier consulta legal contacta con nosotros en legal@inmufacil.es',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegalSectionTile extends StatefulWidget {
  const _LegalSectionTile({required this.index, required this.section});
  final int index;
  final _LegalSection section;

  @override
  State<_LegalSectionTile> createState() => _LegalSectionTileState();
}

class _LegalSectionTileState extends State<_LegalSectionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.section;
    final borderColor = s.highlight
        ? _kBlue.withValues(alpha: 0.35)
        : (_expanded ? _kBlue.withValues(alpha: 0.25) : Colors.grey.shade200);
    final bgColor =
        s.highlight ? _kBlue.withValues(alpha: 0.04) : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _expanded
                          ? _kBlue.withValues(alpha: 0.12)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${widget.index}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color:
                              _expanded ? _kBlue : Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(s.icon,
                      size: 17,
                      color: _expanded ? _kBlue : Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _expanded ? _kBlue : _kNavy,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: _expanded ? _kBlue : Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  s.body,
                  style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade700,
                      height: 1.65),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Privacy Policy Sections ────────────────────────────────────────────────

const _privacySections = [
  _LegalSection(
    title: 'Responsable del tratamiento',
    icon: Icons.business_outlined,
    body:
        'InmuFacil, S.L. (en tramite de constitucion), con domicilio en Sevilla, '
        'Espana. Correo electronico de proteccion de datos: privacidad@inmufacil.es. '
        'InmuFacil actua como Responsable del Tratamiento conforme al Reglamento (UE) '
        '2016/679 (RGPD) y la Ley Organica 3/2018 (LOPDGDD).',
  ),
  _LegalSection(
    title: 'Datos que recopilamos',
    icon: Icons.folder_outlined,
    body:
        'Recopilamos los siguientes datos necesarios para prestar el servicio:\n\n'
        '• Datos identificativos: nombre completo, DNI/NIE, fecha de nacimiento, '
        'nacionalidad, correo electronico y telefono.\n'
        '• Datos de identidad biometrica: fotografia del documento de identidad y '
        'captura de "prueba de vida" (liveness check) para verificacion KYC.\n'
        '• Datos de la propiedad: direccion, titularidad, precio, documentacion '
        'registral (Nota Simple, CEE, IBI).\n'
        '• Datos financieros (voluntarios): cuestionario del Pasaporte de Solvencia '
        'incluyendo metodo de pago, ratio de endeudamiento, ingresos netos mensuales '
        'y ahorros disponibles.\n'
        '• Datos de navegacion: logs de acceso, direccion IP, tipo de dispositivo '
        'y cookies tecnicas.\n\n'
        'Todos los datos sensibles (DNI, biometria, datos financieros) se almacenan '
        'cifrados con AES-256-GCM en reposo y se transmiten bajo HTTPS/TLS 1.3.',
  ),
  _LegalSection(
    title: 'Inteligencia Artificial y Biometria',
    icon: Icons.smart_toy_outlined,
    highlight: true,
    body:
        'InmuFacil utiliza tecnologias de Inteligencia Artificial (IA) y biometria '
        'para los siguientes fines, requiriendo tu consentimiento explicito (Art. 9 RGPD '
        'para datos biometricos y Art. 22 RGPD para decisiones automatizadas):\n\n'
        '1. Verificacion de identidad (Liveness Check / KYC): el sistema de IA '
        'analiza la captura facial del usuario y la compara con el documento de '
        'identidad aportado para confirmar que el usuario es quien dice ser y esta '
        'fisicamente presente (anti-spoofing). Este procesamiento se realiza de forma '
        'puntual durante el registro y no implica almacenamiento continuado de '
        'datos biometricos mas alla del periodo KYC legalmente exigido.\n\n'
        '2. Generacion de borradores de contratos (IA Generativa): la plataforma '
        'emplea modelos de Inteligencia Artificial para redactar borradores del '
        'Contrato de Arras a partir de los datos de la operacion. Estos borradores '
        'son orientativos y no constituyen asesoramiento juridico. La revision y '
        'firma son responsabilidad exclusiva de las partes.\n\n'
        '3. Analisis de solvencia dinamica: los algoritmos de InmuFacil procesan '
        'los datos del Pasaporte de Solvencia para calcular indices de riesgo '
        '(stress_index) y nivel de solvencia (Bronce/Plata/Oro). Este analisis '
        'es informativo y no constituye una evaluacion crediticia con efectos juridicos.\n\n'
        'Tienes derecho a oponerte al tratamiento automatizado y a solicitar '
        'intervencion humana en cualquier decision que te afecte significativamente.',
  ),
  _LegalSection(
    title: 'Compromiso de no comercializacion',
    icon: Icons.block_outlined,
    highlight: true,
    body:
        'InmuFacil NO vende, cede, alquila ni comercializa los datos personales '
        'de sus usuarios a terceros con fines publicitarios o comerciales.\n\n'
        'Los datos unicamente se comparten con:\n'
        '• Proveedores tecnicos imprescindibles (hosting, KYC, firma digital) '
        'vinculados contractualmente como Encargados del Tratamiento bajo '
        'clausulas de confidencialidad RGPD.\n'
        '• La otra parte de la transaccion (comprador/vendedor), exclusivamente '
        'los datos necesarios para formalizar la operacion acordada.\n'
        '• Autoridades competentes cuando exista obligacion legal.\n\n'
        'InmuFacil no utiliza tus datos con fines de publicidad comportamental, '
        'perfilado comercial ni monetizacion de datos. El modelo de negocio de '
        'la plataforma se basa en comisiones por transaccion completada, '
        'no en la explotacion de datos.',
  ),
  _LegalSection(
    title: 'Base juridica del tratamiento',
    icon: Icons.gavel_outlined,
    body:
        '• Ejecucion del contrato (Art. 6.1.b RGPD): registro, gestion de '
        'ofertas, generacion de documentos.\n'
        '• Consentimiento explicito (Art. 6.1.a / Art. 9.2.a RGPD): tratamiento '
        'biometrico (KYC liveness), IA generativa, analisis de solvencia '
        'y comunicaciones comerciales opcionales.\n'
        '• Obligacion legal (Art. 6.1.c RGPD): conservacion de documentos '
        'conforme a Ley 10/2010 de blanqueo de capitales y normativa fiscal.\n'
        '• Interes legitimo (Art. 6.1.f RGPD): prevencion de fraude, seguridad '
        'de la plataforma y mejora del servicio.',
  ),
  _LegalSection(
    title: 'Conservacion de datos',
    icon: Icons.schedule_outlined,
    body:
        '• Datos de cuenta: mientras la cuenta permanezca activa + 5 anos tras '
        'la cancelacion (obligacion fiscal).\n'
        '• Pasaporte de Solvencia: eliminacion automatica a los 90 dias de su creacion.\n'
        '• Datos biometricos KYC: eliminados en un plazo maximo de 6 meses tras '
        'completar la verificacion, salvo obligacion legal que exija mayor plazo.\n'
        '• Datos de la transaccion (Arras, escrituras): 15 anos conforme al '
        'Codigo Civil para contratos de compraventa.\n'
        '• Logs de seguridad: 12 meses.',
  ),
  _LegalSection(
    title: 'Seguridad tecnica',
    icon: Icons.security_outlined,
    body:
        'InmuFacil implementa las siguientes medidas tecnicas y organizativas '
        'conforme al Articulo 32 RGPD e ISO/IEC 27001:\n\n'
        '• Cifrado en reposo: AES-256-GCM para todos los datos sensibles '
        '(PII, biometria, datos financieros).\n'
        '• Cifrado en transito: HTTPS/TLS 1.3 en todas las comunicaciones.\n'
        '• Autenticacion: JWT con rotacion de tokens y expiracion controlada.\n'
        '• Control de acceso: RBAC (Control de Acceso Basado en Roles) que '
        'garantiza que cada usuario accede exclusivamente a sus propios datos.\n'
        '• Auditoria: logs de acceso a datos sensibles con marca temporal '
        'conforme a PCI DSS.\n'
        '• Vigilancia proactiva: defensa activa contra tecnicas MITRE ATT&CK '
        '(fuerza bruta, phishing, inyeccion SQL).',
  ),
  _LegalSection(
    title: 'Tus derechos RGPD',
    icon: Icons.shield_outlined,
    body:
        'Puedes ejercer los siguientes derechos en privacidad@inmufacil.es '
        'adjuntando copia de tu DNI/NIE:\n\n'
        '• Derecho de acceso: conocer que datos tratamos sobre ti.\n'
        '• Derecho de rectificacion: corregir datos inexactos.\n'
        '• Derecho de supresion ("derecho al olvido"): eliminacion tecnica '
        'de todos tus datos personales cuando no exista obligacion legal '
        'de conservacion. InmuFacil garantiza la viabilidad tecnica de '
        'este derecho mediante el borrado seguro de registros cifrados.\n'
        '• Derecho de portabilidad: recibir tus datos en formato estructurado.\n'
        '• Derecho de oposicion y limitacion: especialmente frente a '
        'decisiones automatizadas por IA (Art. 22 RGPD).\n\n'
        'Si no queda satisfecho/a con nuestra respuesta, puedes reclamar '
        'ante la Agencia Espanola de Proteccion de Datos (www.aepd.es).',
  ),
  _LegalSection(
    title: 'Transferencias internacionales',
    icon: Icons.public_outlined,
    body:
        'InmuFacil no realiza transferencias internacionales de datos fuera '
        'del Espacio Economico Europeo (EEE) de forma sistematica. '
        'En caso de que algun proveedor tecnico se localice fuera del EEE, '
        'se aplicaran las Clausulas Contractuales Tipo aprobadas por la '
        'Comision Europea como garantia de nivel de proteccion adecuado.',
  ),
  _LegalSection(
    title: 'Uso de cookies',
    icon: Icons.cookie_outlined,
    body:
        'InmuFacil utiliza unicamente cookies tecnicas estrictamente necesarias '
        'para el funcionamiento de la plataforma (sesion, autenticacion). '
        'No se utilizan cookies de seguimiento publicitario ni de terceros '
        'con fines comerciales. Puedes gestionar las cookies desde la '
        'configuracion de tu navegador.',
  ),
];

// ── Terms & Conditions Sections ───────────────────────────────────────────

const _termsSections = [
  _LegalSection(
    title: 'Objeto y naturaleza P2P de InmuFacil',
    icon: Icons.handshake_outlined,
    body:
        'InmuFacil es una plataforma tecnologica P2P (peer-to-peer) de '
        'intermediacion inmobiliaria que conecta directamente a compradores '
        'y vendedores particulares de inmuebles ubicados en Espana.\n\n'
        'InmuFacil NO actua como agente inmobiliario, NO cobra comision '
        'de agencia a ninguna de las partes y NO es parte en la transaccion '
        'de compraventa. Su funcion es proporcionar herramientas tecnologicas, '
        'documentacion orientativa y un entorno seguro para que las partes '
        'negocien y formalicen su operacion de forma autonoma.',
  ),
  _LegalSection(
    title: 'Aceptacion y capacidad legal',
    icon: Icons.verified_outlined,
    body:
        'El uso de la plataforma implica la aceptacion plena de estos Terminos '
        'y Condiciones, la Politica de Privacidad y el Aviso Legal.\n\n'
        'Para registrarse es necesario ser mayor de 18 anos y tener plena '
        'capacidad juridica para contratar. Los menores de 18 anos tienen '
        'prohibido el acceso a la plataforma.',
  ),
  _LegalSection(
    title: 'Proceso por pasos y Timeline de transaccion',
    icon: Icons.timeline_outlined,
    highlight: true,
    body:
        'InmuFacil estructura las transacciones en un Timeline de hitos '
        'secuenciales. Cada avance requiere la aceptacion expresa de ambas '
        'partes:\n\n'
        '1. Publicacion: el vendedor publica la propiedad con CEE obligatorio.\n'
        '2. Oferta: el comprador formaliza una oferta economica vinculada a '
        'su Pasaporte de Solvencia.\n'
        '3. Verificacion de solvencia: el vendedor revisa y acepta o rechaza '
        'el pasaporte del comprador.\n'
        '4. Contrato de Arras: generacion asistida del borrador + firma digital '
        'de ambas partes. Este hito tiene validez contractual conforme al '
        'Articulo 1454 del Codigo Civil espanol.\n'
        '5. Tasacion e hipoteca: coordinacion del proceso bancario.\n'
        '6. Escritura notarial: cierre de la operacion ante notario.\n'
        '7. Entrega de llaves: confirmacion final.\n\n'
        'La aceptacion de estos Terminos implica el consentimiento para '
        'avanzar paso a paso por el Timeline, reconociendo que cada hito '
        'firmado tiene efectos contractuales propios.',
  ),
  _LegalSection(
    title: 'Inteligencia Artificial — Alcance y limitaciones',
    icon: Icons.smart_toy_outlined,
    highlight: true,
    body:
        'InmuFacil incorpora sistemas de Inteligencia Artificial en los '
        'siguientes modulos:\n\n'
        '1. Generacion de borradores del Contrato de Arras: la IA redacta '
        'automaticamente un borrador a partir de los parametros de la '
        'operacion acordados por las partes (precio, condiciones, plazos). '
        'Este borrador es ORIENTATIVO. InmuFacil no presta servicios '
        'juridicos y RECOMIENDA EXPRESAMENTE la revision del documento por '
        'un abogado o notario antes de su firma. La responsabilidad legal '
        'del contrato recae exclusivamente en las partes firmantes.\n\n'
        '2. Analisis de solvencia (IA): el motor de scoring analiza los '
        'datos del Pasaporte de Solvencia para generar indicadores '
        'informativos. Estos indicadores NO tienen la consideracion de '
        'informe crediticio oficial ni sustituyen a la evaluacion de '
        'una entidad financiera.\n\n'
        '3. Verificacion KYC (Inteligencia Artificial + biometria): el '
        'proceso de prueba de vida es ejecutado por sistemas de IA. '
        'InmuFacil se reserva el derecho a realizar una revision manual '
        'adicional ante casos dudosos.',
  ),
  _LegalSection(
    title: 'Obligaciones del vendedor',
    icon: Icons.home_outlined,
    body:
        '• Publicar informacion veraz y actualizada sobre la propiedad.\n'
        '• Aportar el Certificado Energetico (CEE) vigente (obligatorio por Ley).\n'
        '• Disponer de Nota Simple del Registro de la Propiedad no anterior '
        'a 3 meses al inicio de las arras.\n'
        '• Acreditar estar al corriente de pagos: IBI, comunidad de propietarios '
        'y suministros.\n'
        '• Informar de cargas hipotecarias o servidumbres sobre la propiedad.\n'
        '• No publicar la misma propiedad simultaneamente en otras plataformas '
        'una vez firmado el Contrato de Arras.',
  ),
  _LegalSection(
    title: 'Obligaciones del comprador',
    icon: Icons.person_outlined,
    body:
        '• Completar el Pasaporte de Solvencia con informacion veraz.\n'
        '• Realizar la verificacion de identidad KYC para poder hacer ofertas.\n'
        '• Formular ofertas con intension real de compra.\n'
        '• Disponer de los fondos o financiacion necesaria antes de firmar las arras.\n'
        '• En caso de compra conjunta (multi-comprador), el segundo titular '
        'debe completar su propia verificacion de identidad en la plataforma.',
  ),
  _LegalSection(
    title: 'Contrato de Arras — Efectos y responsabilidad',
    icon: Icons.draw_outlined,
    body:
        'El Contrato de Arras generado por InmuFacil es un borrador de arras '
        'penitenciales (Art. 1454 Cc) que incluye:\n\n'
        '• Identificacion de las partes y la propiedad.\n'
        '• Precio final acordado y cantidad de arras a entregar.\n'
        '• Plazo maximo para escritura notarial.\n'
        '• Condiciones resolutivas pactadas (sujeto a hipoteca, etc.).\n\n'
        'IMPORTANTE: si el comprador desiste, pierde las arras entregadas. '
        'Si el vendedor desiste, esta obligado a devolver el doble. '
        'InmuFacil NO asume responsabilidad alguna por el incumplimiento '
        'de ninguna de las partes ni por errores en la informacion '
        'aportada que afecten a la validez del contrato.',
  ),
  _LegalSection(
    title: 'Exencion de responsabilidad',
    icon: Icons.warning_amber_outlined,
    body:
        'InmuFacil no garantiza:\n'
        '• El estado fisico, juridico o urbanistico de las propiedades publicadas.\n'
        '• La veracidad de la informacion aportada por los usuarios.\n'
        '• La disponibilidad continua e ininterrumpida de la plataforma.\n'
        '• Los resultados economicos de ninguna operacion.\n\n'
        'InmuFacil no sera responsable por danos directos, indirectos o '
        'consecuentes derivados del uso de la plataforma, incluyendo '
        'danos derivados de decisiones tomadas en base a los analisis de IA.',
  ),
  _LegalSection(
    title: 'Uso aceptable y suspension de cuentas',
    icon: Icons.block_outlined,
    body:
        'Esta expresamente prohibido:\n'
        '• Publicar propiedades ficticias o con precio inflado artificialmente.\n'
        '• Usar datos de identidad de terceros o documentos falsificados en el KYC.\n'
        '• Realizar ofertas sin intencion real de compra.\n'
        '• Intentar extraer, copiar o redistribuir datos de otros usuarios.\n'
        '• Cualquier uso fraudulento, abusivo o contrario a la normativa.\n\n'
        'InmuFacil se reserva el derecho a suspender o cancelar cuentas '
        'que incumplan estas condiciones, sin perjuicio de las acciones '
        'legales que correspondan.',
  ),
  _LegalSection(
    title: 'Modificacion de terminos y ley aplicable',
    icon: Icons.edit_note_outlined,
    body:
        'InmuFacil puede modificar estos Terminos notificando a los usuarios '
        'con al menos 30 dias de antelacion. El uso continuado de la '
        'plataforma tras la notificacion implica la aceptacion de los '
        'nuevos terminos.\n\n'
        'Estos Terminos se rigen por la legislacion espanola. Para cualquier '
        'controversia, las partes se someten a los Juzgados y Tribunales '
        'de Sevilla, con renuncia a cualquier otro fuero.',
  ),
];

// ── Legal Notice Sections ─────────────────────────────────────────────────

const _legalNoticeSections = [
  _LegalSection(
    title: 'Identificacion del titular',
    icon: Icons.business_outlined,
    body:
        'InmuFacil, S.L. — en tramite de constitucion.\n'
        'Domicilio: Sevilla, Espana.\n'
        'Email de contacto: legal@inmufacil.es\n'
        'Responsable de contenidos: equipo InmuFacil.',
  ),
  _LegalSection(
    title: 'Actividad',
    icon: Icons.domain_outlined,
    body:
        'Prestacion de servicios de plataforma tecnologica P2P para la '
        'intermediacion inmobiliaria entre particulares. InmuFacil no ejerce '
        'actividades reservadas a agentes inmobiliarios colegiados ni presta '
        'servicios de intermediacion financiera o de inversion.',
  ),
  _LegalSection(
    title: 'Normativa aplicable',
    icon: Icons.gavel_outlined,
    body:
        'Este sitio se rige por la legislacion espanola, conforme a:\n'
        '• Ley 34/2002, de servicios de la sociedad de la informacion (LSSICE).\n'
        '• Ley Organica 3/2018 (LOPDGDD) y Reglamento (UE) 2016/679 (RGPD).\n'
        '• Ley 29/1994 de Arrendamientos Urbanos (cuando aplique).\n'
        '• Real Decreto 7/2019 de medidas urgentes en materia de vivienda.\n'
        '• Reglamento (UE) 2024/1689 de IA (AI Act) — cumplimiento proactivo.',
  ),
  _LegalSection(
    title: 'Propiedad intelectual',
    icon: Icons.copyright_outlined,
    body:
        'Todos los contenidos, disenos, codigos fuente y marcas de InmuFacil '
        'estan protegidos por derechos de propiedad intelectual e industrial. '
        'Queda prohibida su reproduccion, distribucion o comunicacion publica '
        'sin autorizacion expresa y por escrito de InmuFacil.',
  ),
  _LegalSection(
    title: 'Exencion de responsabilidad',
    icon: Icons.warning_amber_outlined,
    body:
        'InmuFacil no se responsabiliza de los danos derivados del uso de '
        'la plataforma, de la inexactitud de la informacion publicada por '
        'terceros, ni del incumplimiento de obligaciones entre usuarios. '
        'Los enlaces a sitios externos no implican patrocinio ni responsabilidad '
        'sobre su contenido.',
  ),
  _LegalSection(
    title: 'Jurisdiccion',
    icon: Icons.account_balance_outlined,
    body:
        'Para cualquier controversia derivada del uso de esta plataforma, '
        'las partes se someten a los Juzgados y Tribunales de la ciudad '
        'de Sevilla, con renuncia expresa a cualquier otro fuero que '
        'pudiera corresponderles.',
  ),
];

// ============================================================================
// Reusable sub-widgets
// ============================================================================

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _kBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14, color: _kNavy)),
                const SizedBox(height: 4),
                Text(body,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step {
  const _Step({
    required this.number,
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String number;
  final String title;
  final String body;
  final IconData icon;
  final Color color;
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.isLast});

  final _Step step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: step.color,
                shape: BoxShape.circle,
              ),
              child: Text(
                step.number,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _kNavy)),
                const SizedBox(height: 4),
                Text(step.body,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4)),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GuideSection {
  const _GuideSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<String> items;
}

class _GuideSectionCard extends StatelessWidget {
  const _GuideSectionCard({required this.section});

  final _GuideSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(section.icon, color: section.color, size: 20),
              const SizedBox(width: 10),
              Text(section.title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: section.color)),
            ],
          ),
          const SizedBox(height: 12),
          ...section.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: _kGreen, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade700)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ContactOption extends StatelessWidget {
  const _ContactOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _kNavy)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(foregroundColor: color),
            child: Text(actionLabel, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
