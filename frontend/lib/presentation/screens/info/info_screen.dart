import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';
import '../../widgets/contact/contact_email_dialog.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kBlue  = Color(0xFF135BEC);
const _kGreen = Color(0xFF16A34A);
const _kBg    = Color(0xFFF8FAFC);
const _kNavy  = Color(0xFF135BEC);

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.home_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'common.home_btn'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 12),
              const UserAvatarMenu(),
              const SizedBox(width: 16),
            ],
          ),
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
        return _LegalTextScreen(
          title: 'info.legal.privacy.title'.tr(),
          sections: _privacySections,
          heroIcon: Icons.privacy_tip_outlined,
          heroColor: _kBlue,
        );
      case InfoPageType.terms:
        return _LegalTextScreen(
          title: 'info.legal.terms.title'.tr(),
          sections: _termsSections,
          heroIcon: Icons.description_outlined,
          heroColor: _kBlue,
        );
      case InfoPageType.legalNotice:
        return _LegalTextScreen(
          title: 'info.legal.legal_notice.title'.tr(),
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
    final features = [
      ('info.what_is.features.0.title'.tr(), 'info.what_is.features.0.body'.tr(), Icons.handshake_outlined),
      ('info.what_is.features.1.title'.tr(), 'info.what_is.features.1.body'.tr(), Icons.route_outlined),
      ('info.what_is.features.2.title'.tr(), 'info.what_is.features.2.body'.tr(), Icons.security_outlined),
      ('info.what_is.features.3.title'.tr(), 'info.what_is.features.3.body'.tr(), Icons.assessment_outlined),
      ('info.what_is.features.4.title'.tr(), 'info.what_is.features.4.body'.tr(), Icons.visibility_outlined),
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
              Text(
                'info.what_is.hero_title'.tr(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'info.what_is.hero_subtitle'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'info.what_is.title'.tr(),
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
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
            color: _kGreen.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.savings_outlined, color: _kGreen, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'info.what_is.savings_title'.tr(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kGreen),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'info.what_is.savings_body'.tr(),
                style: TextStyle(fontSize: 12, color: _kGreen.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 14),
              // Commission table
              Table(
                border: TableBorder.all(color: _kGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                columnWidths: const {
                  0: FlexColumnWidth(1.4),
                  1: FlexColumnWidth(1.3),
                  2: FlexColumnWidth(1.3),
                },
                children: [
                  // Header
                  TableRow(
                    decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.12)),
                    children: [
                      _tableCell('info.what_is.savings_table.concept'.tr(), bold: true),
                      _tableCell('info.what_is.savings_table.seller'.tr(), bold: true),
                      _tableCell('info.what_is.savings_table.buyer'.tr(), bold: true),
                    ],
                  ),
                  TableRow(children: [
                    _tableCell('info.what_is.savings_table.percentage'.tr()),
                    _tableCell('info.what_is.savings_table.percentage_seller'.tr()),
                    _tableCell('info.what_is.savings_table.percentage_buyer'.tr()),
                  ]),
                  TableRow(children: [
                    _tableCell('info.what_is.savings_table.fixed_min'.tr()),
                    _tableCell('info.what_is.savings_table.fixed_min_seller'.tr()),
                    _tableCell('info.what_is.savings_table.fixed_min_buyer'.tr()),
                  ]),
                  TableRow(children: [
                    _tableCell('info.what_is.savings_table.online_fee'.tr()),
                    _tableCell('info.what_is.savings_table.online_fee_seller'.tr()),
                    _tableCell('info.what_is.savings_table.online_fee_buyer'.tr()),
                  ]),
                  TableRow(children: [
                    _tableCell('info.what_is.savings_table.financial'.tr()),
                    _tableCell('info.what_is.savings_table.financial_seller'.tr()),
                    _tableCell('info.what_is.savings_table.financial_buyer'.tr()),
                  ]),
                ],
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
    final steps = [
      _Step(number: '1', title: 'info.how_it_works.steps.0.title'.tr(), body: 'info.how_it_works.steps.0.body'.tr(), icon: Icons.add_home_outlined),
      _Step(number: '2', title: 'info.how_it_works.steps.1.title'.tr(), body: 'info.how_it_works.steps.1.body'.tr(), icon: Icons.search_outlined),
      _Step(number: '3', title: 'info.how_it_works.steps.2.title'.tr(), body: 'info.how_it_works.steps.2.body'.tr(), icon: Icons.verified_user_outlined),
      _Step(number: '4', title: 'info.how_it_works.steps.3.title'.tr(), body: 'info.how_it_works.steps.3.body'.tr(), icon: Icons.handshake_outlined),
      _Step(number: '5', title: 'info.how_it_works.steps.4.title'.tr(), body: 'info.how_it_works.steps.4.body'.tr(), icon: Icons.draw_outlined),
      _Step(number: '6', title: 'info.how_it_works.steps.5.title'.tr(), body: 'info.how_it_works.steps.5.body'.tr(), icon: Icons.assessment_outlined),
      _Step(number: '7', title: 'info.how_it_works.steps.6.title'.tr(), body: 'info.how_it_works.steps.6.body'.tr(), icon: Icons.account_balance_outlined),
      _Step(number: '8', title: 'info.how_it_works.steps.7.title'.tr(), body: 'info.how_it_works.steps.7.body'.tr(), icon: Icons.vpn_key_outlined),
      _Step(number: '9', title: 'info.how_it_works.steps.8.title'.tr(), body: 'info.how_it_works.steps.8.body'.tr(), icon: Icons.assignment_turned_in_outlined),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kBlue.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBlue.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.route_outlined, color: _kBlue, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'info.how_it_works.title'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kBlue),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'info.how_it_works.subtitle'.tr(),
                      style: const TextStyle(fontSize: 13, color: _kBlue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...steps.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StepCard(step: s),
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
    final sections = [
      _GuideSection(
        icon: Icons.search_outlined,
        color: _kBlue,
        title: 'info.buyer_guide.sections.0.title'.tr(),
        items: [
          'info.buyer_guide.sections.0.items.0'.tr(),
          'info.buyer_guide.sections.0.items.1'.tr(),
          'info.buyer_guide.sections.0.items.2'.tr(),
        ],
      ),
      _GuideSection(
        icon: Icons.assessment_outlined,
        color: Colors.purple,
        title: 'info.buyer_guide.sections.1.title'.tr(),
        items: [
          'info.buyer_guide.sections.1.items.0'.tr(),
          'info.buyer_guide.sections.1.items.1'.tr(),
          'info.buyer_guide.sections.1.items.2'.tr(),
          'info.buyer_guide.sections.1.items.3'.tr(),
        ],
      ),
      _GuideSection(
        icon: Icons.payments_outlined,
        color: _kGreen,
        title: 'info.buyer_guide.sections.2.title'.tr(),
        items: [
          'info.buyer_guide.sections.2.items.0'.tr(),
          'info.buyer_guide.sections.2.items.1'.tr(),
          'info.buyer_guide.sections.2.items.2'.tr(),
          'info.buyer_guide.sections.2.items.3'.tr(),
        ],
      ),
      _GuideSection(
        icon: Icons.euro_outlined,
        color: Colors.orange,
        title: 'info.buyer_guide.sections.3.title'.tr(),
        items: [
          'info.buyer_guide.sections.3.items.0'.tr(),
          'info.buyer_guide.sections.3.items.1'.tr(),
          'info.buyer_guide.sections.3.items.2'.tr(),
          'info.buyer_guide.sections.3.items.3'.tr(),
          'info.buyer_guide.sections.3.items.4'.tr(),
          'info.buyer_guide.sections.3.items.5'.tr(),
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
                  children: [
                    Text('info.buyer_guide.title'.tr(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _kBlue)),
                    const SizedBox(height: 4),
                    Text(
                      'info.buyer_guide.subtitle'.tr(),
                      style: const TextStyle(fontSize: 13, color: _kBlue),
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
    final sections = [
      _GuideSection(
        icon: Icons.add_home_outlined,
        color: _kGreen,
        title: 'info.seller_guide.sections.0.title'.tr(),
        items: [
          'info.seller_guide.sections.0.items.0'.tr(),
          'info.seller_guide.sections.0.items.1'.tr(),
          'info.seller_guide.sections.0.items.2'.tr(),
          'info.seller_guide.sections.0.items.3'.tr(),
        ],
      ),
      _GuideSection(
        icon: Icons.verified_user_outlined,
        color: _kBlue,
        title: 'info.seller_guide.sections.1.title'.tr(),
        items: [
          'info.seller_guide.sections.1.items.0'.tr(),
          'info.seller_guide.sections.1.items.1'.tr(),
          'info.seller_guide.sections.1.items.2'.tr(),
          'info.seller_guide.sections.1.items.3'.tr(),
        ],
      ),
      _GuideSection(
        icon: Icons.description_outlined,
        color: Colors.purple,
        title: 'info.seller_guide.sections.2.title'.tr(),
        items: [
          'info.seller_guide.sections.2.items.0'.tr(),
          'info.seller_guide.sections.2.items.1'.tr(),
          'info.seller_guide.sections.2.items.2'.tr(),
          'info.seller_guide.sections.2.items.3'.tr(),
          'info.seller_guide.sections.2.items.4'.tr(),
          'info.seller_guide.sections.2.items.5'.tr(),
        ],
      ),
      _GuideSection(
        icon: Icons.euro_outlined,
        color: Colors.orange,
        title: 'info.seller_guide.sections.3.title'.tr(),
        items: [
          'info.seller_guide.sections.3.items.0'.tr(),
          'info.seller_guide.sections.3.items.1'.tr(),
          'info.seller_guide.sections.3.items.2'.tr(),
          'info.seller_guide.sections.3.items.3'.tr(),
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
                  children: [
                    Text('info.seller_guide.title'.tr(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _kGreen)),
                    const SizedBox(height: 4),
                    Text(
                      'info.seller_guide.subtitle'.tr(),
                      style: const TextStyle(fontSize: 13, color: _kGreen),
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
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kBlue.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBlue.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.support_agent_outlined, color: _kBlue, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'info.contact.title'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kBlue),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'info.contact.subtitle'.tr(),
                      style: const TextStyle(fontSize: 13, color: _kBlue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _ContactOption(
          icon: Icons.email_outlined,
          color: _kBlue,
          title: 'info.contact.email_title'.tr(),
          subtitle: 'info.contact.email_subtitle'.tr(),
          actionLabel: 'info.contact.email_action'.tr(),
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => const ContactEmailDialog(),
          ),
        ),
        const SizedBox(height: 12),
        _ContactOption(
          icon: Icons.help_outline,
          color: Colors.purple,
          title: 'info.contact.help_title'.tr(),
          subtitle: 'info.contact.help_subtitle'.tr(),
          actionLabel: 'info.contact.help_action'.tr(),
          onTap: () => context.push(InfoScreen.routeFor(InfoPageType.faq)),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('info.contact.legal_info'.tr(),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 12),
              _LegalLink(label: 'info.contact.privacy'.tr(),
                  route: InfoScreen.routeFor(InfoPageType.privacy)),
              _LegalLink(label: 'info.contact.terms'.tr(),
                  route: InfoScreen.routeFor(InfoPageType.terms)),
              _LegalLink(label: 'info.contact.legal_notice'.tr(),
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
  static final _faqs = [
    _FaqItem(
      q: 'info.faq.items.0.q'.tr(),
      a: 'info.faq.items.0.a'.tr(),
    ),
    _FaqItem(
      q: 'info.faq.items.1.q'.tr(),
      a: 'info.faq.items.1.a'.tr(),
    ),
    _FaqItem(
      q: 'info.faq.items.2.q'.tr(),
      a: 'info.faq.items.2.a'.tr(),
    ),
    _FaqItem(
      q: 'info.faq.items.3.q'.tr(),
      a: 'info.faq.items.3.a'.tr(),
    ),
    _FaqItem(
      q: 'info.faq.items.4.q'.tr(),
      a: 'info.faq.items.4.a'.tr(),
    ),
    _FaqItem(
      q: 'info.faq.items.5.q'.tr(),
      a: 'info.faq.items.5.a'.tr(),
    ),
    _FaqItem(
      q: 'info.faq.items.6.q'.tr(),
      a: 'info.faq.items.6.a'.tr(),
    ),
    _FaqItem(
      q: 'info.faq.items.7.q'.tr(),
      a: 'info.faq.items.7.a'.tr(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.quiz_outlined, color: _kBlue, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'info.faq.title'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kBlue),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'info.faq.subtitle'.tr(),
                      style: const TextStyle(fontSize: 13, color: _kBlue),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _expanded ? _kBlue.withOpacity(0.3) : Theme.of(context).colorScheme.outlineVariant,
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
                            color: _expanded ? _kBlue : Theme.of(context).colorScheme.onSurface)),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: _expanded ? _kBlue : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                Text(widget.faq.a,
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      'info.legal.common.updated_at'.tr(),
                      style: TextStyle(
                          fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'info.legal.common.security_badge'.tr(),
                      style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        Builder(
          builder: (context) => Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'info.legal.common.footer_contact'.tr(),
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4),
                  ),
                ),
              ],
            ),
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
        : (_expanded ? _kBlue.withValues(alpha: 0.25) : Theme.of(context).colorScheme.outlineVariant);
    final bgColor =
        s.highlight ? _kBlue.withValues(alpha: 0.04) : Theme.of(context).colorScheme.surfaceContainerLowest;

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
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${widget.index}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color:
                              _expanded ? _kBlue : Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(s.icon,
                      size: 17,
                      color: _expanded ? _kBlue : Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _expanded ? _kBlue : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: _expanded ? _kBlue : Theme.of(context).colorScheme.onSurfaceVariant,
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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

final _privacySections = [
  _LegalSection(
    title: 'info.legal.privacy.sections.0.title'.tr(),
    icon: Icons.business_outlined,
    body: 'info.legal.privacy.sections.0.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.privacy.sections.1.title'.tr(),
    icon: Icons.folder_outlined,
    body: 'info.legal.privacy.sections.1.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.privacy.sections.2.title'.tr(),
    icon: Icons.smart_toy_outlined,
    highlight: true,
    body: 'info.legal.privacy.sections.2.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.privacy.sections.3.title'.tr(),
    icon: Icons.block_outlined,
    highlight: true,
    body: 'info.legal.privacy.sections.3.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.privacy.sections.4.title'.tr(),
    icon: Icons.gavel_outlined,
    body: 'info.legal.privacy.sections.4.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.privacy.sections.5.title'.tr(),
    icon: Icons.schedule_outlined,
    body: 'info.legal.privacy.sections.5.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.privacy.sections.6.title'.tr(),
    icon: Icons.security_outlined,
    body: 'info.legal.privacy.sections.6.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.privacy.sections.7.title'.tr(),
    icon: Icons.shield_outlined,
    body: 'info.legal.privacy.sections.7.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.privacy.sections.8.title'.tr(),
    icon: Icons.public_outlined,
    body: 'info.legal.privacy.sections.8.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.privacy.sections.9.title'.tr(),
    icon: Icons.cookie_outlined,
    body: 'info.legal.privacy.sections.9.body'.tr(),
  ),
];

// ── Terms & Conditions Sections ───────────────────────────────────────────

final _termsSections = [
  _LegalSection(
    title: 'info.legal.terms.sections.0.title'.tr(),
    icon: Icons.handshake_outlined,
    body: 'info.legal.terms.sections.0.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.terms.sections.1.title'.tr(),
    icon: Icons.verified_outlined,
    body: 'info.legal.terms.sections.1.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.terms.sections.2.title'.tr(),
    icon: Icons.timeline_outlined,
    highlight: true,
    body: 'info.legal.terms.sections.2.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.terms.sections.3.title'.tr(),
    icon: Icons.smart_toy_outlined,
    highlight: true,
    body: 'info.legal.terms.sections.3.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.terms.sections.4.title'.tr(),
    icon: Icons.home_outlined,
    body: 'info.legal.terms.sections.4.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.terms.sections.5.title'.tr(),
    icon: Icons.person_outlined,
    body: 'info.legal.terms.sections.5.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.terms.sections.6.title'.tr(),
    icon: Icons.draw_outlined,
    body: 'info.legal.terms.sections.6.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.terms.sections.7.title'.tr(),
    icon: Icons.warning_amber_outlined,
    body: 'info.legal.terms.sections.7.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.terms.sections.8.title'.tr(),
    icon: Icons.block_outlined,
    body: 'info.legal.terms.sections.8.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.terms.sections.9.title'.tr(),
    icon: Icons.edit_note_outlined,
    body: 'info.legal.terms.sections.9.body'.tr(),
  ),
];

// ── Legal Notice Sections ─────────────────────────────────────────────────

final _legalNoticeSections = [
  _LegalSection(
    title: 'info.legal.legal_notice.sections.0.title'.tr(),
    icon: Icons.business_outlined,
    body: 'info.legal.legal_notice.sections.0.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.legal_notice.sections.1.title'.tr(),
    icon: Icons.domain_outlined,
    body: 'info.legal.legal_notice.sections.1.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.legal_notice.sections.2.title'.tr(),
    icon: Icons.gavel_outlined,
    body: 'info.legal.legal_notice.sections.2.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.legal_notice.sections.3.title'.tr(),
    icon: Icons.copyright_outlined,
    body: 'info.legal.legal_notice.sections.3.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.legal_notice.sections.4.title'.tr(),
    icon: Icons.warning_amber_outlined,
    body: 'info.legal.legal_notice.sections.4.body'.tr(),
  ),
  _LegalSection(
    title: 'info.legal.legal_notice.sections.5.title'.tr(),
    icon: Icons.account_balance_outlined,
    body: 'info.legal.legal_notice.sections.5.body'.tr(),
  ),
];

// ============================================================================
// Reusable sub-widgets
// ============================================================================

Widget _tableCell(String text, {bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: _kGreen,
        height: 1.4,
      ),
    ),
  );
}

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
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 4),
                Text(body,
                    style: TextStyle(
                        fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)),
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
  });

  final String number;
  final String title;
  final String body;
  final IconData icon;
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number badge
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              step.number,
              style: const TextStyle(
                color: _kBlue,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(step.icon, color: _kBlue, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        step.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _kBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  step.body,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
                              fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
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
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: color,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(actionLabel, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
