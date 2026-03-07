import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/common/app_bar_back_button.dart';

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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: AppBarBackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text(
          _titleFor(pageType),
          style: const TextStyle(
              color: _kNavy, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: _buildContent(context),
    );
  }

  String _titleFor(InfoPageType type) {
    const map = {
      InfoPageType.whatIsInmufacil: 'Que es InmuFacil?',
      InfoPageType.howItWorks: 'Como funciona',
      InfoPageType.buyerGuide: 'Guia del Comprador',
      InfoPageType.sellerGuide: 'Guia del Vendedor',
      InfoPageType.contact: 'Contacto',
      InfoPageType.faq: 'Preguntas frecuentes',
      InfoPageType.privacy: 'Privacidad',
      InfoPageType.terms: 'Terminos de uso',
      InfoPageType.legalNotice: 'Aviso Legal',
    };
    return map[type] ?? 'Informacion';
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
        return _LegalTextScreen(
          title: 'Politica de Privacidad',
          sections: _privacySections,
        );
      case InfoPageType.terms:
        return _LegalTextScreen(
          title: 'Terminos y Condiciones de Uso',
          sections: _termsSections,
        );
      case InfoPageType.legalNotice:
        return _LegalTextScreen(
          title: 'Aviso Legal',
          sections: _legalNoticeSections,
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

class _LegalTextScreen extends StatelessWidget {
  const _LegalTextScreen({required this.title, required this.sections});

  final String title;
  final List<_LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Ultima actualizacion: Marzo 2026',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        const SizedBox(height: 20),
        ...sections.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e.key + 1}. ${e.value.title}',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _kNavy),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.value.body,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.6),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _LegalSection {
  const _LegalSection({required this.title, required this.body});
  final String title;
  final String body;
}

const _privacySections = [
  _LegalSection(
    title: 'Responsable del tratamiento',
    body: 'InmuFacil, S.L. (en tramite de constitucion), con domicilio en Sevilla, Espana. '
        'Correo electronico de contacto: privacidad@inmufacil.es',
  ),
  _LegalSection(
    title: 'Datos que recopilamos',
    body: 'Datos identificativos (nombre, DNI/NIE, email, telefono), datos de la vivienda, '
        'documentos KYC (cifrados en reposo con AES-256-GCM), informacion financiera declarada '
        'voluntariamente en el Pasaporte de Solvencia.',
  ),
  _LegalSection(
    title: 'Base juridica del tratamiento',
    body: 'Ejecucion del contrato (Art. 6.1.b RGPD): para prestarte el servicio. '
        'Consentimiento (Art. 6.1.a RGPD): para comunicaciones comerciales. '
        'Interes legitimo (Art. 6.1.f RGPD): para prevencion de fraude y seguridad.',
  ),
  _LegalSection(
    title: 'Conservacion de datos',
    body: 'Los datos de cuenta se conservan mientras la cuenta este activa. '
        'El Pasaporte de Solvencia se elimina automaticamente a los 90 dias. '
        'Los documentos KYC se eliminan segun el periodo legalmente exigido.',
  ),
  _LegalSection(
    title: 'Tus derechos',
    body: 'Tienes derecho a acceso, rectificacion, supresion ("derecho al olvido"), '
        'portabilidad, limitacion y oposicion al tratamiento. '
        'Ejercitalos en privacidad@inmufacil.es.',
  ),
  _LegalSection(
    title: 'Seguridad',
    body: 'Aplicamos cifrado AES-256-GCM para datos sensibles, HTTPS en todas las comunicaciones, '
        'autenticacion JWT con rotacion de tokens y logs de auditoria conforme a ISO 27001.',
  ),
];

const _termsSections = [
  _LegalSection(
    title: 'Objeto',
    body: 'InmuFacil es una plataforma P2P de intermediacion inmobiliaria que conecta '
        'directamente a compradores y vendedores de inmuebles en Espana sin intervenir '
        'como agencia inmobiliaria.',
  ),
  _LegalSection(
    title: 'Usuarios',
    body: 'El servicio esta destinado a personas mayores de 18 anos. '
        'Los usuarios son responsables de la veracidad de la informacion publicada. '
        'InmuFacil no verifica ni garantiza el estado fisico o juridico de los inmuebles.',
  ),
  _LegalSection(
    title: 'Publicacion de propiedades',
    body: 'El vendedor es responsable de contar con los documentos legales necesarios '
        '(CEE, Nota Simple actualizada, IBI al corriente) antes de publicar. '
        'InmuFacil puede suspender anuncios que incumplan la normativa vigente.',
  ),
  _LegalSection(
    title: 'Ofertas y contratos',
    body: 'Las ofertas generadas en la plataforma tienen caracter de propuesta no vinculante '
        'hasta la firma del Contrato de Arras. InmuFacil genera borradores orientativos '
        'que deben ser revisados por profesionales juridicos antes de su firma.',
  ),
  _LegalSection(
    title: 'Responsabilidad',
    body: 'InmuFacil no es parte en las transacciones y no asume responsabilidad por '
        'incumplimientos entre usuarios, vicios ocultos o problemas derivados de la transaccion. '
        'La plataforma actua exclusivamente como intermediario tecnologico.',
  ),
  _LegalSection(
    title: 'Propiedad intelectual',
    body: 'Todos los elementos de la plataforma (codigo, diseno, marca) son propiedad de InmuFacil. '
        'Los usuarios ceden a InmuFacil el derecho de uso de las imagenes publicadas '
        'con el fin exclusivo de mostrarlas en la plataforma.',
  ),
];

const _legalNoticeSections = [
  _LegalSection(
    title: 'Identificacion',
    body: 'InmuFacil, S.L. — en tramite de constitucion. '
        'Domicilio: Sevilla, Espana. '
        'Email: legal@inmufacil.es',
  ),
  _LegalSection(
    title: 'Actividad',
    body: 'Prestacion de servicios de plataforma tecnologica P2P para la intermediacion '
        'inmobiliaria entre particulares. No ejerce actividades reservadas a agentes '
        'inmobiliarios ni presta servicios de inversion.',
  ),
  _LegalSection(
    title: 'Normativa aplicable',
    body: 'Este sitio se rige por la legislacion espanola, conforme a la Ley 34/2002 '
        '(LSSICE), la Ley Organica 3/2018 (LOPDGDD), el Reglamento (UE) 2016/679 (RGPD) '
        'y la Ley 29/1994 de Arrendamientos Urbanos (cuando aplique).',
  ),
  _LegalSection(
    title: 'Propiedad intelectual',
    body: 'Todos los contenidos, disenos, codigos fuente y marcas de InmuFacil '
        'estan protegidos por derechos de propiedad intelectual e industrial. '
        'Queda prohibida su reproduccion sin autorizacion expresa.',
  ),
  _LegalSection(
    title: 'Exencion de responsabilidad',
    body: 'InmuFacil no se responsabiliza de los danos derivados del uso de la plataforma, '
        'de la inexactitud de la informacion publicada por terceros, ni del incumplimiento '
        'de obligaciones entre usuarios.',
  ),
  _LegalSection(
    title: 'Jurisdiccion',
    body: 'Para cualquier controversia derivada del uso de esta plataforma, '
        'las partes se someten a los Juzgados y Tribunales de la ciudad de Sevilla, '
        'con renuncia expresa a cualquier otro fuero que pudiera corresponderles.',
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
