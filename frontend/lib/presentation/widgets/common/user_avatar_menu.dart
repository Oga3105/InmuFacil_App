import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/my_properties_provider.dart';
import '../../providers/offers_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/urgency_provider.dart';
import '../../providers/visits_provider.dart';
import '../../screens/info/info_screen.dart';

// ─── Menu item value types ────────────────────────────────────────────────────

sealed class _MenuValue {}

class _NavValue extends _MenuValue {
  _NavValue(this.key);
  final String key;
}

class _UrgentValue extends _MenuValue {
  _UrgentValue(this.action);
  final UrgentAction action;
}

class _LogoutValue extends _MenuValue {}

// ─── Widget ───────────────────────────────────────────────────────────────────

class UserAvatarMenu extends ConsumerWidget {
  const UserAvatarMenu({super.key, this.onTabSelected});

  final void Function(int)? onTabSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;

    // Standard data checks
    final props = ref.watch(myPropertiesProvider).asData?.value;
    final hasProps = props != null && props.isNotEmpty;

    final receivedOpts = ref.watch(receivedOffersProvider).asData?.value;
    final sentOpts = ref.watch(sentOffersProvider).asData?.value;
    final hasOffers =
        (receivedOpts?.isNotEmpty ?? false) || (sentOpts?.isNotEmpty ?? false);

    final visitsState = ref.watch(myVisitsProvider);
    final hasVisits =
        visitsState.value != null && visitsState.value!.isNotEmpty;

    final chatsState = ref.watch(chatListProvider);
    final hasChats =
        chatsState.value != null && chatsState.value!.isNotEmpty;

    // Urgency engine
    final urgentActions = ref.watch(urgencyProvider);
    final hasUrgency = urgentActions.isNotEmpty;

    const urgencyGreen = Color(kUrgencyGreen);
    const actionBlue = Color(kUrgencyBlue);

    // ── Build menu items ─────────────────────────────────────────────────────

    final List<PopupMenuEntry<_MenuValue>> items = [];
    final bool isDark = theme.brightness == Brightness.dark;
    final Color navItemColor = isDark ? Colors.white : actionBlue;

    // 1. Urgent actions — shown at top, styled green
    if (hasUrgency) {
      items.add(
        PopupMenuItem<_MenuValue>(
          enabled: false,
          height: 28,
          child: Text(
            'Requiere tu atencion',
            style: theme.textTheme.labelSmall?.copyWith(
              color: urgencyGreen,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
      );

      for (final action in urgentActions) {
        items.add(
          PopupMenuItem<_MenuValue>(
            value: _UrgentValue(action),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                color: urgencyGreen.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: urgencyGreen.withOpacity(0.25)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded,
                      color: urgencyGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: urgencyGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          action.propertyTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: urgencyGreen.withOpacity(0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: urgencyGreen, size: 12),
                ],
              ),
            ),
          ),
        );
      }

      items.add(const PopupMenuDivider());
    }

    // 2. Standard navigation items
    items.add(
      PopupMenuItem<_MenuValue>(
        value: _NavValue('profile'),
        child: _NavItem(
          icon: Icons.person_outline,
          label: 'Mi Perfil',
          accentColor: navItemColor,
        ),
      ),
    );

    if (hasProps)
      items.add(
        PopupMenuItem<_MenuValue>(
          value: _NavValue('my-properties'),
          child: _NavItem(
            icon: Icons.home_work_outlined,
            label: 'Mis Propiedades',
            accentColor: navItemColor,
          ),
        ),
      );

    if (hasOffers)
      items.add(
        PopupMenuItem<_MenuValue>(
          value: _NavValue('offers'),
          child: _NavItem(
            icon: Icons.handshake_outlined,
            label: 'Mis Ofertas',
            accentColor: navItemColor,
          ),
        ),
      );

    if (hasVisits)
      items.add(
        PopupMenuItem<_MenuValue>(
          value: _NavValue('visits'),
          child: _NavItem(
            icon: Icons.calendar_month_outlined,
            label: 'Mis Visitas',
            accentColor: navItemColor,
          ),
        ),
      );

    if (hasChats)
      items.add(
        PopupMenuItem<_MenuValue>(
          value: _NavValue('messages'),
          child: _NavItem(
            icon: Icons.chat_bubble_outline,
            label: 'Mensajes',
            accentColor: navItemColor,
          ),
        ),
      );

    items.add(const PopupMenuDivider());

    // ── Info & help section ───────────────────────────────────────────────────
    items.add(
      PopupMenuItem<_MenuValue>(
        enabled: false,
        height: 28,
        child: Text(
          'Informacion y ayuda',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.grey[500],
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
    items.add(
      PopupMenuItem<_MenuValue>(
        value: _NavValue('info-what-is'),
        child: _NavItem(
          icon: Icons.info_outline,
          label: 'Que es InmuFácil',
          accentColor: theme.colorScheme.onSurface,
        ),
      ),
    );
    items.add(
      PopupMenuItem<_MenuValue>(
        value: _NavValue('info-buyer-guide'),
        child: _NavItem(
          icon: Icons.shopping_bag_outlined,
          label: 'Guia del Comprador',
          accentColor: const Color(0xFF135BEC),
        ),
      ),
    );
    items.add(
      PopupMenuItem<_MenuValue>(
        value: _NavValue('info-seller-guide'),
        child: _NavItem(
          icon: Icons.sell_outlined,
          label: 'Guia del Vendedor',
          accentColor: const Color(0xFF16A34A),
        ),
      ),
    );
    items.add(
      PopupMenuItem<_MenuValue>(
        value: _NavValue('info-contact'),
        child: _NavItem(
          icon: Icons.support_agent_outlined,
          label: 'Contacto y Ayuda',
          accentColor: theme.colorScheme.onSurface,
        ),
      ),
    );

    items.add(const PopupMenuDivider());
    items.add(
      PopupMenuItem<_MenuValue>(
        value: _LogoutValue(),
        child: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text('Cerrar Sesion',
                style: TextStyle(color: Colors.red, fontSize: 14)),
          ],
        ),
      ),
    );

    // ── Render ───────────────────────────────────────────────────────────────

    return PopupMenuButton<_MenuValue>(
      offset: const Offset(0, 44),
      tooltip: 'Menu de usuario',
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.96),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (_) => items,
      onSelected: (value) async {
        switch (value) {
          case _LogoutValue():
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) {
              context.go('/');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sesion cerrada correctamente')),
              );
            }

          case _UrgentValue(:final action):
            ref.read(searchProvider.notifier).clearError();
            context.push(action.route, extra: action.routeExtra);

          case _NavValue(:final key):
            ref.read(searchProvider.notifier).clearError();
            switch (key) {
              case 'profile':
                onTabSelected != null
                    ? onTabSelected!(0)
                    : context.push('/profile');
              case 'my-properties':
                onTabSelected != null
                    ? onTabSelected!(1)
                    : context.push('/profile?tab=1');
              case 'offers':
                onTabSelected != null
                    ? onTabSelected!(2)
                    : context.push('/profile?tab=2');
              case 'visits':
                onTabSelected != null
                    ? onTabSelected!(3)
                    : context.push('/profile?tab=3');
              case 'messages':
                onTabSelected != null
                    ? onTabSelected!(4)
                    : context.push('/profile?tab=4');
              case 'info-what-is':
                context.push(InfoScreen.routeFor(InfoPageType.whatIsInmufacil));
              case 'info-buyer-guide':
                context.push(InfoScreen.routeFor(InfoPageType.buyerGuide));
              case 'info-seller-guide':
                context.push(InfoScreen.routeFor(InfoPageType.sellerGuide));
              case 'info-contact':
                context.push(InfoScreen.routeFor(InfoPageType.contact));
            }
        }
      },
      child: _AvatarWithDot(
        photoUrl: user?.profilePhotoUrl,
        showDot: hasUrgency,
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _AvatarWithDot extends StatelessWidget {
  const _AvatarWithDot({required this.photoUrl, required this.showDot});

  final String? photoUrl;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final avatar = SizedBox(
      width: 36,
      height: 36,
      child: ClipOval(
        child: photoUrl != null
            ? Image.network(
                '$photoUrl?v=$ts',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _defaultAvatar,
              )
            : _defaultAvatar,
      ),
    );

    if (!showDot) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(kUrgencyGreen),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget get _defaultAvatar => Container(
        color: const Color(kUrgencyBlue),
        child: const Icon(Icons.person, color: Colors.white, size: 20),
      );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: accentColor),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: accentColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
