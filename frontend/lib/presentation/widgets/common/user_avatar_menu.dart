import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/my_properties_provider.dart';
import '../../providers/offers_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/visits_provider.dart';

class UserAvatarMenu extends ConsumerWidget {
  const UserAvatarMenu({super.key, this.onTabSelected});

  final void Function(int)? onTabSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;

    // Data checks
    final props = ref.watch(myPropertiesProvider).asData?.value;
    final hasProps = props != null && props.isNotEmpty;

    final receivedOpts = ref.watch(receivedOffersProvider).asData?.value;
    final sentOpts = ref.watch(sentOffersProvider).asData?.value;
    final hasOffers = (receivedOpts?.isNotEmpty ?? false) || (sentOpts?.isNotEmpty ?? false);

    final visitsState = ref.watch(myVisitsProvider);
    final hasVisits = visitsState.value != null && visitsState.value!.isNotEmpty;
    print("DEBUG: visitsState.isLoading: ${visitsState.isLoading}, hasValue: ${visitsState.hasValue}, length: ${visitsState.value?.length}");

    final chatsState = ref.watch(chatListProvider);
    final hasChats = chatsState.value != null && chatsState.value!.isNotEmpty;
    print("DEBUG: chatsState.isLoading: ${chatsState.isLoading}, hasValue: ${chatsState.hasValue}, length: ${chatsState.value?.length}");

    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      tooltip: 'Menú de usuario',
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 20),
              SizedBox(width: 8),
              Text('Mi Perfil'),
            ],
          ),
        ),
        if (hasProps)
          const PopupMenuItem(
            value: 'my-properties',
            child: Row(
              children: [
                Icon(Icons.home_work_outlined, size: 20),
                SizedBox(width: 8),
                Text('Mis Propiedades'),
              ],
            ),
          ),
        if (hasOffers)
          const PopupMenuItem(
            value: 'offers',
            child: Row(
              children: [
                Icon(Icons.handshake_outlined, size: 20),
                SizedBox(width: 8),
                Text('Mis Ofertas'),
              ],
            ),
          ),
        if (hasVisits)
          const PopupMenuItem(
            value: 'visits',
            child: Row(
              children: [
                Icon(Icons.calendar_month_outlined, size: 20),
                SizedBox(width: 8),
                Text('Mis Visitas'),
              ],
            ),
          ),
        if (hasChats)
          const PopupMenuItem(
            value: 'messages',
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 20),
                SizedBox(width: 8),
                Text('Mensajes'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        if (value == 'logout') {
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) {
            context.go('/');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sesión cerrada correctamente')),
            );
          }
        } else {
          ref.read(searchProvider.notifier).clearError();
          if (value == 'profile') {
            onTabSelected != null ? onTabSelected!(0) : context.push('/profile');
          } else if (value == 'my-properties') {
            onTabSelected != null ? onTabSelected!(1) : context.push('/profile?tab=1');
          } else if (value == 'offers') {
            onTabSelected != null ? onTabSelected!(2) : context.push('/profile?tab=2');
          } else if (value == 'visits') {
            onTabSelected != null ? onTabSelected!(3) : context.push('/profile?tab=3');
          } else if (value == 'messages') {
            onTabSelected != null ? onTabSelected!(4) : context.push('/profile?tab=4');
          }
        }
      },
      child: Builder(builder: (context) {
        final photoUrl = user?.profilePhotoUrl;
        final ts = DateTime.now().millisecondsSinceEpoch;
        return SizedBox(
          width: 36,
          height: 36,
          child: ClipOval(
            child: photoUrl != null
                ? Image.network(
                    '$photoUrl?v=$ts',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF2563EB),
                      child: const Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                  )
                : Container(
                    color: const Color(0xFF2563EB),
                    child: const Icon(Icons.person, color: Colors.white, size: 20),
                  ),
          ),
        );
      }),
    );
  }
}
