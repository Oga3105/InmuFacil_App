import 'package:flutter/material.dart';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:inmufacil_frontend/core/utils/temp_translations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inmufacil_frontend/presentation/providers/auth_provider.dart';
import 'package:inmufacil_frontend/presentation/providers/chat_provider.dart';
import 'package:inmufacil_frontend/presentation/providers/my_properties_provider.dart';
import 'package:inmufacil_frontend/presentation/providers/offers_provider.dart';
import 'package:inmufacil_frontend/presentation/providers/solvency_provider.dart';
import 'package:inmufacil_frontend/presentation/providers/visits_provider.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/user.dart';
import '../widgets/common/app_bar_back_button.dart';
import '../widgets/common/user_avatar_menu.dart';
import '../widgets/visits/visit_cancel_dialog.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // [NEW] Password Change State
  bool _isChangingPassword = false;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // [NEW] Password visibility state (matching register screen)
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // [NEW] Editing State
  bool _isEditing = false;

  // [NEW] Photo upload state
  bool _isUploadingPhoto = false;

  // Properties tab sort and filter state
  String _propertiesSortBy = 'newest';
  String _propertiesStatusFilter = 'all';

  // Offers tab sort state
  String _offersSortBy = 'newest';

  // Visits tab sort state
  String _visitsSortBy = 'soonest';

  // Messages tab sort state
  String _messagesSortBy = 'newest';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 5, initialIndex: widget.initialTabIndex, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      // Refresh visits data when Visitas tab (index 3) becomes active
      if (_tabController.index == 3) {
        ref.invalidate(sentOffersProvider);
        ref.invalidate(receivedOffersProvider);
        ref.invalidate(myVisitsProvider);
        ref.invalidate(chatVisitsProvider);
      }
      // Refresh chat list when Messages tab (index 4) becomes active
      if (_tabController.index == 4) {
        ref.invalidate(chatListProvider);
      }
    });
    // If starting on a tab that needs fresh data, refresh immediately
    if (widget.initialTabIndex == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(sentOffersProvider);
        ref.invalidate(receivedOffersProvider);
        ref.invalidate(myVisitsProvider);
        ref.invalidate(chatVisitsProvider);
      });
    }
    if (widget.initialTabIndex == 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(chatListProvider);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Fallback
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Init/Sync Controllers only if NOT editing
    if (!_isEditing) {
      final name = user.name ?? '';
      if (_nameController.text != name) _nameController.text = name;

      final phone = user.phone ?? '';
      if (_phoneController.text != phone) _phoneController.text = phone;
    }

    final isVerified = user.dniStatus?.toLowerCase() == 'validado';

    // Layout
    // Header -> Tabs -> Content
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // background-light
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Profile Card (Full Width Container)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(top: 24, bottom: 0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildProfileHeader(user, isVerified),
                      ),
                      const SizedBox(height: 24),
                      // Tabs aligned left
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelColor: const Color(0xFF2563EB),
                          unselectedLabelColor: Colors.grey.shade500,
                          indicatorColor: const Color(0xFF2563EB),
                          indicatorWeight: 3,
                          dividerColor: Colors.transparent,
                          labelStyle: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                          tabs: [
                            const Tab(
                                child: Row(children: [
                              Icon(Icons.person, size: 20),
                              SizedBox(width: 8),
                              Text('Mi Perfil')
                            ])),
                            const Tab(
                                child: Row(children: [
                              Icon(Icons.home_work, size: 20),
                              SizedBox(width: 8),
                              Text('Mis Propiedades')
                            ])),
                            const Tab(
                                child: Row(children: [
                              Icon(Icons.handshake_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Mis Ofertas')
                            ])),
                            const Tab(
                                child: Row(children: [
                              Icon(Icons.calendar_month_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Visitas')
                            ])),
                            Tab(
                              child: Row(
                                children: [
                                  const Icon(Icons.chat_bubble_outline,
                                      size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Mensajes'),
                                  const SizedBox(width: 6),
                                  Consumer(
                                    builder: (ctx, r, _) {
                                      final total = r
                                              .watch(chatListProvider)
                                              .asData
                                              ?.value
                                              .fold(
                                                  0,
                                                  (sum, c) =>
                                                      sum + c.unreadCount) ??
                                          0;
                                      if (total == 0)
                                        return const SizedBox.shrink();
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '$total',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tab Content Area
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      if (_tabController.index == 0)
                        return _buildProfileTab(user, isVerified);
                      if (_tabController.index == 1)
                        return _buildPropertiesTab();
                      if (_tabController.index == 2) return _buildOffersTab();
                      if (_tabController.index == 3) return _buildVisitsTab();
                      return _buildMessagesTab();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AppBarBackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      title: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
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
                        style: TextStyle(color: Color(0xFF2563EB))),
                    TextSpan(
                        text: 'Fácil',
                        style: TextStyle(color: Color(0xFF16A34A))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
      ),
      actions: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.25),
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
        ),
        const SizedBox(width: 16),
        IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.grey),
            onPressed: () {}),
        const SizedBox(width: 8),

        // [UPDATED] Profile Menu with Logout
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            final activeTab = _tabController.index;
            return UserAvatarMenu(
              onTabSelected: (index) {
                if (index != activeTab) {
                  _tabController.animateTo(index);
                }
              },
            );
          },
        ),
        const SizedBox(width: 24),
      ],
    );
  }

  /// Opens the browser file picker and uploads the selected image as profile photo.
  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (image == null) return;

    setState(() => _isUploadingPhoto = true);

    final result =
        await ref.read(authProvider.notifier).uploadProfilePhoto(image);

    if (mounted) {
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success'] == true
              ? '✅ Foto de perfil actualizada'
              : '❌ ${result['error'] ?? 'Error al subir la foto'}'),
          backgroundColor: result['success'] == true
              ? const Color(0xFF16A34A)
              : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _deleteProfilePhoto() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar foto de perfil'),
        content: const Text(
            '¿Estás seguro de que quieres eliminar tu foto de perfil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isUploadingPhoto = true);
    final result = await ref.read(authProvider.notifier).deleteProfilePhoto();
    if (mounted) {
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success'] == true
              ? 'Foto de perfil eliminada'
              : result['error'] ?? 'Error al eliminar la foto'),
          backgroundColor: result['success'] == true
              ? const Color(0xFF16A34A)
              : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // Header matching the image
  Widget _buildProfileHeader(User user, bool isVerified) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar
        Stack(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB), // Official Blue
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: ClipOval(
                child: user.profilePhotoUrl != null
                    ? Image.network(
                        '${user.profilePhotoUrl}?v=${DateTime.now().millisecondsSinceEpoch}',
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person,
                            size: 40, color: Colors.white),
                      )
                    : const Icon(Icons.person, size: 40, color: Colors.white),
              ),
            ),
            // Camera button — always visible
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _isUploadingPhoto
                      ? const Padding(
                          padding: EdgeInsets.all(5),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 14),
                ),
              ),
            ),
            // Delete photo button — only visible when user has a photo
            if (user.profilePhotoUrl != null)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploadingPhoto ? null : _deleteProfilePhoto,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 12),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 24),

        // Name & Badges
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name ?? 'Usuario InmuFácil',
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  // Dynamic User Type
                  _buildHeaderBadge(
                      user.userType == 'agent'
                          ? 'Agente Inmobiliario'
                          : 'Propietario Particular',
                      Colors.blue.shade50,
                      Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                          'Miembro desde ${user.createdAt?.year.toString() ?? '—'}',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  if (isVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.green.shade400, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified,
                              size: 15, color: Colors.green.shade600),
                          const SizedBox(width: 5),
                          Text(
                            'VERIFICADO',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(text,
          style:
              TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  // Two Column Layout for Profile Tab
  Widget _buildProfileTab(User user, bool isVerified) {
    // Check if Desktop (Simplified check)
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Verification Banner if needed (Preserved)
        if (!isVerified) _buildVerificationBanner(user.dniStatus),

        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column (Forms)
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildPersonalInfoCard(user),
                    const SizedBox(height: 24),
                    _buildSecurityCard(user),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right Column (Sidebar)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  children: [
                    _buildSolvencyCard(),
                    const SizedBox(height: 10),
                    _buildTrustDashboardButton(),
                    const SizedBox(height: 24),
                    _buildPromoCard(),
                    const SizedBox(height: 24),
                    _buildEmptyStateCard(small: true),
                  ],
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              _buildPersonalInfoCard(user),
              const SizedBox(height: 24),
              _buildSecurityCard(user),
              const SizedBox(height: 24),
              _buildSolvencyCard(),
              const SizedBox(height: 10),
              _buildTrustDashboardButton(),
              const SizedBox(height: 24),
              _buildPromoCard(),
              const SizedBox(height: 24),
              _buildEmptyStateCard(small: true),
            ],
          ),
      ],
    );
  }

  Widget _buildPersonalInfoCard(User user) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Información Personal',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 24),

          // [UPDATED] ReadOnly logic based on _isEditing
          Row(
            children: [
              Expanded(
                  child: _buildTextField(
                      'Nombre Completo', _nameController, !_isEditing)),
              const SizedBox(width: 24),
              Expanded(
                  child: _buildTextField(
                      'Teléfono', _phoneController, !_isEditing)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: _buildTextField('Correo Electrónico (No editable)',
                      TextEditingController(text: user.email), true)),
              const SizedBox(width: 24),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),

          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          // Revert changes
                          _nameController.text = user.name ?? '';
                          _phoneController.text = user.phone ?? '';
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        side: const BorderSide(color: Colors.red), // Red border
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancelar',
                          style: TextStyle(color: Colors.red)), // Red text
                    ),
                  ),
                ElevatedButton(
                  onPressed: () async {
                    if (_isEditing) {
                      final result =
                          await ref.read(authProvider.notifier).updateProfile(
                                fullName: _nameController.text.trim(),
                                phone: _phoneController.text.trim(),
                              );
                      setState(() {
                        _isEditing = false;
                      });
                      if (context.mounted) {
                        final success = result['success'] == true;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Datos guardados correctamente'
                                : (result['error'] ?? 'Error')),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } else {
                      setState(() {
                        _isEditing = true;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEditing
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: ref.watch(authProvider).isLoading && _isEditing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          _isEditing ? 'Guardar Datos' : 'Editar Perfil',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(User user) {
    // isSuspended = NOT isActive  (user.isActive == false means suspended)
    final bool isSuspended = !(user.isActive ?? true);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Seguridad y Privacidad',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 24),

          // [UPDATED] Password Change Section
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8)),
              child: _isChangingPassword
                  ? _buildChangePasswordForm()
                  : Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Contraseña',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(
                                'Actualiza tu contraseña periódicamente para mayor seguridad.',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isChangingPassword = true;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cambiar Contraseña',
                              style: TextStyle(color: Colors.black87)),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // [UPDATED] Suspension + Deletion Row
          Row(
            children: [
              // 50% Suspension
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Suspender Cuenta',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.orange)),
                      const SizedBox(height: 4),
                      Text('Tu perfil no será visible públicamente.',
                          style: TextStyle(
                              color: Colors.orange.shade300, fontSize: 12)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            // TODO: Account suspension via backend when endpoint is ready
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Función de suspensión próximamente disponible')),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.orange),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(isSuspended ? 'Reactivar' : 'Suspender',
                              style: const TextStyle(color: Colors.orange)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 50% Deletion
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Eliminar Cuenta',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.red)),
                      const SizedBox(height: 4),
                      Text('Esta acción es irreversible.',
                          style: TextStyle(
                              color: Colors.red.shade300, fontSize: 12)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Dialog logic...
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)), // 12px radius
                          ),
                          child: const Text('Eliminar',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSolvencyCard() {
    final passportAsync = ref.watch(mySolvencyProvider);

    return passportAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (passport) {
        final hasPassport = passport != null;
        final level = passport?.solvencyLevel ?? '';
        Color gradStart;
        Color gradEnd;
        String levelLabel;
        IconData levelIcon;

        switch (level) {
          case 'gold':
            gradStart = const Color(0xFFB8860B);
            gradEnd = const Color(0xFF996515);
            levelLabel = 'Oro';
            levelIcon = Icons.emoji_events_rounded;
            break;
          case 'silver':
            gradStart = const Color(0xFF64748B);
            gradEnd = const Color(0xFF475569);
            levelLabel = 'Plata';
            levelIcon = Icons.shield_rounded;
            break;
          case 'bronze':
          default:
            gradStart = const Color(0xFFCD7F32);
            gradEnd = const Color(0xFFAB6A2A);
            levelLabel = 'Bronce';
            levelIcon = Icons.shield_outlined;
        }

        if (!hasPassport) {
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.push('/solvency/wizard'),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5F).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E3A5F).withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shield_outlined, color: Color(0xFF1E3A5F), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Pasaporte de Solvencia',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F), fontSize: 13),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2563EB),
                                  borderRadius: BorderRadius.all(Radius.circular(4)),
                                ),
                                child: const Text('Solo compradores', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Completa el asistente para mostrar tu nivel de cualificacion',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF1E3A5F), size: 20),
                  ],
                ),
              ),
            ),
          );
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.push('/solvency/passport'),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gradStart, gradEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: gradStart.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Icon(levelIcon, color: Colors.white, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PASAPORTE DE SOLVENCIA',
                          style: TextStyle(color: Colors.white70, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Nivel $levelLabel',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrustDashboardButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => context.push('/trust-dashboard'),
        icon: const Icon(Icons.workspace_premium_outlined, size: 16),
        label: const Text('Ver nivel de confianza'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1E3A5F),
          side: const BorderSide(color: Color(0xFFCBD5E1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildPromoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB), // Official Blue
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('¿Vendes tu casa?',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          const Text(
            'Publicala gratis ahora y llega a miles de compradores verificados en nuestra red P2P segura.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/property/create'),
              icon: const Icon(Icons.add_circle_outline,
                  color: Color(0xFF2563EB), size: 18),
              label: const Text('Publicar Nueva Propiedad',
                  style: TextStyle(
                      color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tab 2: Grid of Properties
  Widget _buildPropertiesTab() {
    final myPropertiesAsync = ref.watch(myPropertiesProvider);

    return myPropertiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) =>
          Center(child: Text('Error al cargar propiedades: $err')),
      data: (allProperties) {
        // Apply status filter
        var myProperties = _propertiesStatusFilter == 'all'
            ? allProperties
            : allProperties
                .where((p) => p.status == _propertiesStatusFilter)
                .toList();

        // Apply sort
        myProperties = List.from(myProperties);
        switch (_propertiesSortBy) {
          case 'price_asc':
            myProperties.sort((a, b) => a.price.compareTo(b.price));
            break;
          case 'price_desc':
            myProperties.sort((a, b) => b.price.compareTo(a.price));
            break;
          case 'newest':
          default:
            break;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tus Propiedades',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A))),
                    SizedBox(height: 4),
                    Text('Gestiona tus anuncios y su estado.',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
                _SortButton<String>(
                  value: _propertiesSortBy,
                  options: const {
                    'newest': 'Más recientes',
                    'oldest': 'Más antiguas',
                    'price_asc': 'Precio: menor a mayor',
                    'price_desc': 'Precio: mayor a menor',
                  },
                  onChanged: (v) => setState(() => _propertiesSortBy = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Status filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'Todas'),
                  const SizedBox(width: 8),
                  _buildFilterChip('published', 'Publicadas'),
                  const SizedBox(width: 8),
                  _buildFilterChip('draft', 'Borradores'),
                  const SizedBox(width: 8),
                  _buildFilterChip('unpublished', 'No publicadas'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (myProperties.isEmpty)
              _buildEmptyStateCard(small: false)
            else
              Column(
                children: [
                  ...myProperties.map((p) => _buildPropertyListRow(p)),
                  const SizedBox(height: 8),
                  _buildAddPropertyBanner(),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _propertiesStatusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _propertiesStatusFilter = value),
      selectedColor: const Color(0xFF2563EB).withOpacity(0.15),
      checkmarkColor: const Color(0xFF2563EB),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  // ---- Property list row (nueva vista lista) ----

  Widget _buildPropertyListRow(Property p) {
    final status = p.status ?? 'published';
    final imageUrl = (p.images.isNotEmpty) ? p.images.first : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      width: 80,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                    )
                  : _thumbPlaceholder(),
            ),
            const SizedBox(width: 14),
            // Title + status + location
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          p.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusPill(status: status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          p.address.isNotEmpty
                              ? p.address
                              : p.location.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Price + views
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_formatPrice(p.price)}\u20AC',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_outlined,
                        size: 13, color: Color(0xFF94A3B8)),
                    SizedBox(width: 3),
                    Text(
                      '— vistas',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Gestionar button
            _GestionarMenu(
              property: p,
              onView: () => context.push('/property/${p.id}'),
              onOffers: () => context.push('/property/${p.id}/offers'),
              onEdit: () => context.push('/property/${p.id}/edit'),
              onDeactivate: () async {
                final target =
                    status == 'published' ? 'unpublished' : 'published';
                await ref
                    .read(myPropertiesProvider.notifier)
                    .updateStatus(p.id, target);
              },
              onDelete: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    title: const Text('Eliminar propiedad'),
                    content: const Text(
                        'Esta accion no se puede deshacer. La propiedad sera eliminada permanentemente.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref
                      .read(myPropertiesProvider.notifier)
                      .deleteProperty(p.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
        width: 80,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.home_outlined, color: Colors.grey.shade400, size: 28),
      );

  String _formatPrice(double price) {
    final s = price.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Widget _buildAddPropertyBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => context.push('/property/create'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Icon(Icons.home_work_outlined,
                      size: 36, color: Colors.grey.shade400),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 12, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '\u00BFTienes otra propiedad?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Publicar otro anuncio ahora',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard({required bool small}) {
    return Container(
      padding: EdgeInsets.all(small ? 24 : 48),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.grey.shade100, shape: BoxShape.circle),
            child: const Icon(Icons.home, size: 32, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text('No tienes propiedades activas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            '"Empieza hoy mismo tu proceso de venta directa sin intermediarios."',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push('/property/create'),
            icon: const Icon(Icons.add_home_outlined, size: 18),
            label: const Text('Publicar propiedad'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ver mis borradores',
                style: TextStyle(
                    color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Genera una contraseña segura de 16 caracteres usando CSPRNG (Random.secure).
  /// Garantiza al menos 1 mayúscula, 1 minúscula, 1 dígito y 1 símbolo especial.
  void _generateSecurePassword() {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const digits = '0123456789';
    const symbols = '!@#\$%^&*';
    const allChars = uppercase + lowercase + digits + symbols;

    final rng = Random.secure();
    final List<String> chars = [
      uppercase[rng.nextInt(uppercase.length)],
      lowercase[rng.nextInt(lowercase.length)],
      digits[rng.nextInt(digits.length)],
      symbols[rng.nextInt(symbols.length)],
    ];
    for (int i = 0; i < 12; i++) {
      chars.add(allChars[rng.nextInt(allChars.length)]);
    }
    chars.shuffle(rng);
    final password = chars.join();

    setState(() {
      _newPasswordController.text = password;
      _confirmPasswordController.text = password;
      _isNewPasswordVisible = true;
      _isConfirmPasswordVisible = true;
    });
  }

  /// Maps backend error detail to a user-friendly, translated message.
  String _mapPasswordError(String? backendError) {
    if (backendError == null) return 'profile.password_change_error'.tr();
    if (backendError.contains('incorrecta') ||
        backendError.contains('incorrect')) {
      return 'profile.password_current_incorrect'.tr();
    }
    if (backendError.contains('credentials') ||
        backendError.contains('validate') ||
        backendError.contains('Unauthorized')) {
      return 'profile.password_session_expired'.tr();
    }
    return 'profile.password_change_error'.tr();
  }

  Widget _buildChangePasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('profile.change_password'.tr(),
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF0F172A))),
        const SizedBox(height: 16),

        // Current Password (with visibility toggle)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('profile.current_password'.tr(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF334155))),
            const SizedBox(height: 8),
            TextFormField(
              controller: _currentPasswordController,
              obscureText: !_isCurrentPasswordVisible,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFF2563EB), width: 2)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: IconButton(
                  icon: Icon(
                      _isCurrentPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey[400],
                      size: 18),
                  onPressed: () => setState(() =>
                      _isCurrentPasswordVisible = !_isCurrentPasswordVisible),
                  splashRadius: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // New Password + Confirm Password (matching register screen style)
        Row(
          children: [
            // New Password with auto-generate + visibility
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('profile.new_password'.tr(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF334155))),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: !_isNewPasswordVisible,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Mínimo 8 caracteres',
                      hintStyle:
                          TextStyle(color: Colors.grey[400], fontSize: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFF2563EB), width: 2)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      suffixIcon: SizedBox(
                        width: 80,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Tooltip(
                              message: 'profile.generate_password'.tr(),
                              child: IconButton(
                                icon: const Icon(Icons.auto_fix_high,
                                    color: Color(0xFF2563EB), size: 18),
                                onPressed: _generateSecurePassword,
                                splashRadius: 18,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                  _isNewPasswordVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey[400],
                                  size: 18),
                              onPressed: () => setState(() =>
                                  _isNewPasswordVisible =
                                      !_isNewPasswordVisible),
                              splashRadius: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Confirm Password with visibility toggle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('profile.confirm_password'.tr(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF334155))),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Repite tu contraseña',
                      hintStyle:
                          TextStyle(color: Colors.grey[400], fontSize: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFF2563EB), width: 2)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey[400],
                            size: 18),
                        onPressed: () => setState(() =>
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible),
                        splashRadius: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _isChangingPassword = false;
                  _isCurrentPasswordVisible = false;
                  _isNewPasswordVisible = false;
                  _isConfirmPasswordVisible = false;
                  _currentPasswordController.clear();
                  _newPasswordController.clear();
                  _confirmPasswordController.clear();
                });
              },
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('common.cancel'.tr(),
                  style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () async {
                // Validation: passwords must match
                if (_newPasswordController.text !=
                    _confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('profile.password_mismatch'.tr()),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ));
                  return;
                }
                // Validation: current password required
                if (_currentPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('profile.password_current_required'.tr()),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ));
                  return;
                }
                // Validation: min length 8
                if (_newPasswordController.text.length < 8) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('profile.password_min_length'.tr()),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ));
                  return;
                }
                final result =
                    await ref.read(authProvider.notifier).changePassword(
                          _currentPasswordController.text,
                          _newPasswordController.text,
                        );
                if (!context.mounted) return;
                final success = result['success'] == true;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'profile.password_change_success'.tr()
                        : _mapPasswordError(result['error'] as String?)),
                    backgroundColor: success ? Colors.green : Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                if (success) {
                  setState(() {
                    _isChangingPassword = false;
                    _isCurrentPasswordVisible = false;
                    _isNewPasswordVisible = false;
                    _isConfirmPasswordVisible = false;
                    _currentPasswordController.clear();
                    _newPasswordController.clear();
                    _confirmPasswordController.clear();
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('profile.update_password'.tr(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, bool readOnly,
      {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF334155))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          obscureText: isPassword,
          style: TextStyle(
              color: readOnly ? Colors.grey.shade500 : Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
            prefixIcon: readOnly ? null : null,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationBanner(String? dniStatus) {
    final Color bgColor;
    final Color borderColor;
    final Color iconColor;
    final IconData icon;
    final String message;
    final String buttonLabel;
    final String destination;

    if (dniStatus?.toLowerCase() == 'pendiente') {
      bgColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade200;
      iconColor = Colors.orange.shade700;
      icon = Icons.hourglass_top;
      message =
          'Tu verificación está en curso. Te notificaremos cuando esté lista.';
      buttonLabel = 'Ver Estado';
      destination = '/verification-status';
    } else if (dniStatus?.toLowerCase() == 'rechazado') {
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade200;
      iconColor = Colors.red.shade700;
      icon = Icons.cancel_outlined;
      message = 'Tu verificación fue rechazada. Puedes volver a intentarlo.';
      buttonLabel = 'Reintentar';
      destination = '/verify-identity';
    } else {
      bgColor = Colors.blue.shade50;
      borderColor = Colors.blue.shade100;
      iconColor = const Color(0xFF2563EB);
      icon = Icons.shield;
      message =
          'Verifica tu identidad para mayor seguridad y destacar tus anuncios.';
      buttonLabel = 'Verificar Ahora';
      destination = '/verify-identity';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 16),
          Expanded(
            child:
                Text(message, style: const TextStyle(color: Color(0xFF1E293B))),
          ),
          OutlinedButton(
            onPressed: () => context.push(destination),
            style: OutlinedButton.styleFrom(
              foregroundColor: iconColor,
              side: BorderSide(color: borderColor, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(buttonLabel,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mis Ofertas Tab
  // ---------------------------------------------------------------------------

  Widget _buildOffersTab() {
    final sentOffers =
        ref.watch(sentOffersProvider).asData?.value ?? <OfferData>[];
    final receivedOffers =
        ref.watch(receivedOffersProvider).asData?.value ?? <OfferData>[];

    final allOffers = <({OfferData offer, String direction})>[
      ...sentOffers.map((o) => (offer: o, direction: 'Enviada')),
      ...receivedOffers.map((o) => (offer: o, direction: 'Recibida')),
    ];

    // Apply sort
    switch (_offersSortBy) {
      case 'oldest':
        allOffers.sort((a, b) => (a.offer.createdAt ?? DateTime(0)).compareTo(b.offer.createdAt ?? DateTime(0)));
        break;
      case 'amount_asc':
        allOffers.sort((a, b) => a.offer.amount.compareTo(b.offer.amount));
        break;
      case 'amount_desc':
        allOffers.sort((a, b) => b.offer.amount.compareTo(a.offer.amount));
        break;
      case 'newest':
      default:
        allOffers.sort((a, b) => (b.offer.createdAt ?? DateTime(0)).compareTo(a.offer.createdAt ?? DateTime(0)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis Ofertas',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 4),
                Text(
                  'Ofertas enviadas y recibidas.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            _SortButton<String>(
              value: _offersSortBy,
              options: const {
                'newest': 'Más recientes',
                'oldest': 'Más antiguas',
                'amount_asc': 'Importe: menor a mayor',
                'amount_desc': 'Importe: mayor a menor',
              },
              onChanged: (v) => setState(() => _offersSortBy = v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (allOffers.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No hay ofertas todavia.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
            ),
          )
        else
          Column(
            children: allOffers
                .map((e) => _buildOfferRow(e.offer, direction: e.direction))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildOfferRow(OfferData offer, {String? direction}) {
    final statusLabel = _offerStatusLabel(offer.status);
    final statusColor = _offerStatusColor(offer.status);
    final title = offer.propertyTitle ?? 'Propiedad';
    final amount = offer.amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    final directionColor = direction == 'Enviada'
        ? const Color(0xFF2563EB)
        : const Color(0xFF16A34A);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (direction != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: directionColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          direction,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: directionColor),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$amount EUR',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ProfileChatButton(offer: offer),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => context.pushNamed(
              'offer-timeline',
              pathParameters: {'offerId': offer.id},
              extra: offer,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              side: const BorderSide(color: Color(0xFF2563EB)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            child: const Text('Seguimiento'),
          ),
        ],
      ),
    );
  }

  String _offerStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pendiente';
      case 'accepted':
        return 'Aceptada';
      case 'counter_offer':
      case 'countered':
        return 'Contraoferta';
      case 'signing_pending':
        return 'En firma';
      case 'signed':
        return 'Firmada';
      case 'completed':
        return 'Completada';
      case 'rejected':
        return 'Rechazada';
      case 'withdrawn':
        return 'Retirada';
      default:
        return status;
    }
  }

  Color _offerStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const Color(0xFF16A34A);
      case 'counter_offer':
      case 'countered':
        return const Color(0xFFD97706);
      case 'signing_pending':
        return const Color(0xFF2563EB);
      case 'signed':
        return const Color(0xFF2563EB);
      case 'completed':
        return const Color(0xFF16A34A);
      case 'rejected':
        return Colors.red;
      case 'withdrawn':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  // ── Visitas tab ─────────────────────────────────────────────────────────────

  Widget _buildVisitsTab() {
    const kNavy = Color(0xFF1E3A5F);
    const kNavyLight = Color(0xFFEEF3FA);
    final currentUserId = ref.watch(authProvider).user?.id;
    final sentAsync = ref.watch(sentOffersProvider);
    final receivedAsync = ref.watch(receivedOffersProvider);
    final agendaAsync = ref.watch(myVisitsProvider);
    final chatVisitsAsync = ref.watch(chatVisitsProvider);

    final isLoading = sentAsync.isLoading || receivedAsync.isLoading ||
        agendaAsync.isLoading || chatVisitsAsync.isLoading;
    final hasError = sentAsync.hasError || receivedAsync.hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis Visitas',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 4),
                Text(
                  'Visitas programadas como comprador o vendedor.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
            _SortButton<String>(
              value: _visitsSortBy,
              options: const {
                'soonest': 'Más próximas',
                'latest': 'Más lejanas',
                'status': 'Por estado',
              },
              onChanged: (v) => setState(() => _visitsSortBy = v),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (isLoading)
          const Center(
              heightFactor: 5, child: CircularProgressIndicator(color: kNavy))
        else if (hasError)
          Center(
            heightFactor: 5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 40, color: Color(0xFF64748B)),
                const SizedBox(height: 12),
                const Text('Error al cargar visitas',
                    style: TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    ref.invalidate(sentOffersProvider);
                    ref.invalidate(receivedOffersProvider);
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          )
        else
          Builder(
            builder: (context) {
              final sent = sentAsync.value ?? [];
              final received = receivedAsync.value ?? [];
              final seen = <String>{};

              // Source 1: visits derived from chat action messages (visit_request / visit_accepted)
              final offerVisits = [...sent, ...received]
                  .where((o) =>
                      (o.visitStatus != null &&
                          ['requested', 'approved', 'completed']
                              .contains(o.visitStatus)) ||
                      (o.confirmedVisitDate != null &&
                          o.confirmedVisitDate!.isNotEmpty) ||
                      (o.requestedVisitDate != null &&
                          o.requestedVisitDate!.isNotEmpty))
                  .where((o) => seen.add(o.id))
                  .map((o) {
                final isConfirmed =
                    o.visitStatus == 'approved' || o.visitStatus == 'completed';
                final dateStr = isConfirmed
                    ? o.confirmedVisitDate
                    : (o.requestedVisitDate ?? o.confirmedVisitDate);
                final dt = _parseVisitDate(dateStr) ?? DateTime.now();
                final role = o.buyerId == currentUserId ? 'buyer' : 'seller';
                final status = o.visitStatus ?? 'requested';
                return MyVisit(
                  id: 'offer_${o.id}',
                  propertyTitle: o.propertyTitle ?? 'Propiedad',
                  propertyId: o.propertyId,
                  startTime: dt,
                  status: status,
                  role: role,
                );
              }).toList();

              // Source 2: direct chat-action visit scan (/visits/chat — most reliable)
              final chatVisits = chatVisitsAsync.value ?? [];

              // Source 3: visits from the booking system (/visits/agenda)
              final agendaVisits = agendaAsync.value ?? [];

              // Merge, deduplicate (chat-action first — highest reliability)
              final seenIds = <String>{};
              var visits = [
                ...chatVisits.where((v) => seenIds.add(v.id)),
                ...offerVisits.where((v) => seenIds.add(v.id)),
                ...agendaVisits.where((v) => seenIds.add(v.id)),
              ];
              switch (_visitsSortBy) {
                case 'latest':
                  visits.sort((a, b) => b.startTime.compareTo(a.startTime));
                  break;
                case 'status':
                  visits.sort((a, b) => a.status.compareTo(b.status));
                  break;
                case 'soonest':
                default:
                  visits.sort((a, b) => a.startTime.compareTo(b.startTime));
              }

              if (visits.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: kNavyLight,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: const Icon(
                            Icons.calendar_month_outlined,
                            size: 32,
                            color: kNavy,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Sin visitas programadas',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Las visitas que reserves o aceptes aparecerán aquí.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: visits.map((v) => _buildVisitTile(v)).toList(),
              );
            },
          ),
      ],
    );
  }

  /// Parses a visit date string.
  /// Handles "d/M/yyyy HH:mm" (chat action format) and ISO 8601.
  DateTime? _parseVisitDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    // Try ISO 8601 first (from booking system or API)
    final iso = DateTime.tryParse(dateStr);
    if (iso != null) return iso.toLocal();
    // Fallback: "d/M/yyyy HH:mm" (from chat date picker)
    try {
      final parts = dateStr.split(' ');
      final dateParts = parts[0].split('/');
      final timeParts = parts.length > 1 ? parts[1].split(':') : ['0', '0'];
      return DateTime(
        int.parse(dateParts[2]),
        int.parse(dateParts[1]),
        int.parse(dateParts[0]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildVisitTile(MyVisit v) {
    const kNavy = Color(0xFF1E3A5F);
    final isUpcoming = v.startTime.isAfter(DateTime.now());
    final statusColor = _visitStatusColor(v.status);
    final statusLabel = _visitStatusLabel(v.status);
    final roleLabel = v.role == 'buyer' ? 'Comprador' : 'Vendedor';
    final roleColor =
        v.role == 'buyer' ? const Color(0xFF2563EB) : const Color(0xFF16A34A);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isUpcoming
                ? kNavy.withValues(alpha: 0.2)
                : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date block
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isUpcoming ? kNavy : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${v.startTime.day}',
                  style: TextStyle(
                    color: isUpcoming ? Colors.white : Colors.grey.shade500,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _monthAbbr(v.startTime.month),
                  style: TextStyle(
                    color: isUpcoming ? Colors.white70 : Colors.grey.shade400,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        v.propertyTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        roleLabel,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: roleColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      '${v.startTime.hour.toString().padLeft(2, '0')}:${v.startTime.minute.toString().padLeft(2, '0')} · ${v.startTime.day}/${v.startTime.month}/${v.startTime.year}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                if (v.notes != null && v.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    v.notes!,
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Actions Menu
          if (isUpcoming && v.status != 'cancelled' && v.status != 'rejected')
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'reschedule',
                  child: Row(children: [
                    Icon(Icons.edit_calendar, size: 20, color: Color(0xFF2563EB)),
                    SizedBox(width: 8),
                    Text('Reprogramar'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(children: [
                    Icon(Icons.event_busy, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Anular', style: TextStyle(color: Colors.red)),
                  ]),
                ),
              ],
              onSelected: (action) async {
                if (action == 'reschedule') {
                  if (v.id.startsWith('chat_')) {
                    final parts = v.id.split('_');
                    if (parts.length > 1) {
                       context.push('/chat/${parts[1]}');
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Para reprogramar una visita de agenda, anula esta visita y pide una nueva fecha desde la ficha del inmueble.'),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                } else if (action == 'cancel') {
                  final reason = await showDialog<String>(
                    context: context,
                    builder: (_) => const VisitCancelDialog(),
                  );
                  if (reason == null) return;

                  if (v.id.startsWith('chat_')) {
                    // Navigate to chat detail screen to handle cancellation where the logic is
                     final parts = v.id.split('_');
                    if (parts.length > 1) {
                       context.push('/chat/${parts[1]}');
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor, anula la visita desde esta pantalla de chat.')),
                      );
                    }
                  } else {
                     final success = await ref.read(cancelVisitProvider(v.id).future);
                     if (success && mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Visita anulada correctamente.')),
                       );
                       ref.invalidate(myVisitsProvider);
                       ref.read(slotsProvider(v.propertyId)); // trigger refresh of slots if applicable
                     } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Error al anular la visita.')),
                       );
                     }
                  }
                }
              },
            ),
        ],
      ),
    );
  }

  String _visitStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return 'Pendiente';
      case 'approved':
        return 'Confirmada';
      case 'rejected':
        return 'Rechazada';
      case 'cancelled':
        return 'Cancelada';
      case 'completed':
        return 'Completada';
      case 'no_show':
        return 'No presentado';
      default:
        return status;
    }
  }

  Color _visitStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF16A34A);
      case 'requested':
        return const Color(0xFFD97706);
      case 'cancelled':
        return const Color(0xFF64748B);
      case 'rejected':
        return Colors.red;
      case 'completed':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _monthAbbr(int month) {
    const months = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC'
    ];
    return months[month - 1];
  }

  // ── Mensajes tab ────────────────────────────────────────────────────────────

  Widget _buildMessagesTab() {
    final chatAsync = ref.watch(chatListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mensajes',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 4),
                Text(
                  'Tus conversaciones activas con compradores y vendedores.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            _SortButton<String>(
              value: _messagesSortBy,
              options: const {
                'newest': 'Más recientes',
                'oldest': 'Más antiguas',
                'unread': 'No leídos primero',
              },
              onChanged: (v) => setState(() => _messagesSortBy = v),
            ),
          ],
        ),
        const SizedBox(height: 16),

        chatAsync.when(
          loading: () => const Center(
            heightFactor: 5,
            child: CircularProgressIndicator(color: Color(0xFF1E3A5F)),
          ),
          error: (err, _) => Center(
            heightFactor: 5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 40, color: Color(0xFF64748B)),
                const SizedBox(height: 12),
                Text('Error: $err',
                    style: TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.invalidate(chatListProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
          data: (conversations) {
            // chatListProvider already filters out offers with no messages.
            // Show everything it returns.
            var withMessages = conversations
                .where((c) => c.lastMessage.isNotEmpty || c.unreadCount > 0)
                .toList();
            switch (_messagesSortBy) {
              case 'oldest':
                // oldest first — treat empty/epoch timestamp as oldest
                withMessages.sort((a, b) => a.offerId.compareTo(b.offerId));
                break;
              case 'unread':
                withMessages.sort((a, b) => b.unreadCount.compareTo(a.unreadCount));
                break;
              case 'newest':
              default:
                withMessages.sort((a, b) => b.offerId.compareTo(a.offerId));
            }

            if (withMessages.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 48),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF3FA),
                        borderRadius: BorderRadius.circular(36),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 36,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Sin conversaciones activas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cuando haya mensajes en una oferta, aparecerán aquí.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF94A3B8), height: 1.5),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children:
                  withMessages.map((conv) => _buildChatTile(conv)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildChatTile(ChatConversation conv) {
    final hasUnread = conv.unreadCount > 0;
    const kNavy = Color(0xFF1E3A5F);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              hasUnread ? kNavy.withValues(alpha: 0.3) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/chat/${conv.offerId}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: kNavy,
                    backgroundImage:
                        (conv.otherUserPhotoUrl?.isNotEmpty ?? false)
                            ? NetworkImage(conv.otherUserPhotoUrl!)
                            : null,
                    child: (conv.otherUserPhotoUrl?.isNotEmpty ?? false)
                        ? null
                        : const Icon(Icons.person_rounded,
                            size: 28, color: Colors.white),
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                conv.otherUserName,
                                style: TextStyle(
                                  fontWeight: hasUnread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  fontSize: 14,
                                  color: const Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                conv.propertyTitle,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatChatDate(conv.lastDate),
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    hasUnread ? kNavy : const Color(0xFF94A3B8),
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            if (hasUnread) ...[
                              const SizedBox(height: 4),
                              Container(
                                constraints: const BoxConstraints(
                                    minWidth: 18, minHeight: 18),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: kNavy,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text(
                                  conv.unreadCount > 99
                                      ? '99+'
                                      : '${conv.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (conv.lastMessage.isNotEmpty)
                      Text(
                        conv.lastMessage,
                        style: TextStyle(
                          fontSize: 13,
                          color: hasUnread
                              ? const Color(0xFF334155)
                              : const Color(0xFF94A3B8),
                          fontWeight:
                              hasUnread ? FontWeight.w500 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: hasUnread ? kNavy : Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatChatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'AYER';
    } else if (diff.inDays < 7) {
      const days = ['LUN', 'MAR', 'MIE', 'JUE', 'VIE', 'SAB', 'DOM'];
      return days[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}';
    }
  }
}

// ---------------------------------------------------------------------------
// _ProfileChatButton — comprador abre chat con vendedor desde sus ofertas
// ---------------------------------------------------------------------------

class _ProfileChatButton extends ConsumerStatefulWidget {
  const _ProfileChatButton({required this.offer});
  final OfferData offer;

  @override
  ConsumerState<_ProfileChatButton> createState() => _ProfileChatButtonState();
}

class _ProfileChatButtonState extends ConsumerState<_ProfileChatButton> {
  bool _loading = false;

  static const _activeStatuses = {
    'pending',
    'counter_offer',
    'countered',
    'accepted',
    'signing_pending',
    'signed',
  };

  bool get _isActive =>
      _activeStatuses.contains(widget.offer.status.toLowerCase());

  Future<void> _onPressed() async {
    if (!_isActive) return;
    setState(() => _loading = true);
    try {
      await ref.read(sentOffersProvider.notifier).enableChat(widget.offer.id);
    } catch (_) {
      // already enabled
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (mounted) context.push('/chat/${widget.offer.id}');
  }

  @override
  Widget build(BuildContext context) {
    if (!_isActive) return const SizedBox.shrink();
    return OutlinedButton.icon(
      onPressed: _loading ? null : _onPressed,
      icon: _loading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chat_bubble_outline, size: 16),
      label: const Text('Chat'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2563EB),
        side: const BorderSide(color: Color(0xFF2563EB)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status Pill
// ---------------------------------------------------------------------------

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (cfg['color'] as Color).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        cfg['label'] as String,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: cfg['color'] as Color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Map<String, dynamic> _cfg(String s) {
    switch (s) {
      case 'published':
        return {'label': 'ACTIVO', 'color': const Color(0xFF16A34A)};
      case 'draft':
        return {'label': 'BORRADOR', 'color': const Color(0xFFF59E0B)};
      case 'unpublished':
        return {'label': 'EN REVISION', 'color': const Color(0xFF6366F1)};
      default:
        return {'label': 'ACTIVO', 'color': const Color(0xFF16A34A)};
    }
  }
}

// ---------------------------------------------------------------------------
// Gestionar Menu
// ---------------------------------------------------------------------------

class _GestionarMenu extends StatelessWidget {
  const _GestionarMenu({
    required this.property,
    required this.onView,
    required this.onOffers,
    required this.onEdit,
    required this.onDeactivate,
    required this.onDelete,
  });

  final Property property;
  final VoidCallback onView;
  final VoidCallback onOffers;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback onDelete;

  bool get _isActive => (property.status ?? 'published') == 'published';

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'view':
            onView();
            break;
          case 'offers':
            onOffers();
            break;
          case 'edit':
            onEdit();
            break;
          case 'deactivate':
            onDeactivate();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 8,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: const [
              Icon(Icons.house_outlined, size: 18, color: Color(0xFF475569)),
              SizedBox(width: 12),
              Text('Ver Propiedad',
                  style: TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'offers',
          child: Row(
            children: const [
              Icon(Icons.handshake_outlined,
                  size: 18, color: Color(0xFF475569)),
              SizedBox(width: 12),
              Text('Ver Ofertas',
                  style: TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: const [
              Icon(Icons.edit_outlined, size: 18, color: Color(0xFF475569)),
              SizedBox(width: 12),
              Text('Editar',
                  style: TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'deactivate',
          child: Row(
            children: [
              Icon(
                _isActive
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: const Color(0xFF475569),
              ),
              const SizedBox(width: 12),
              Text(
                _isActive ? 'Desactivar' : 'Activar',
                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: const [
              Icon(Icons.delete_outline_rounded,
                  size: 18, color: Color(0xFFDC2626)),
              SizedBox(width: 12),
              Text('Eliminar',
                  style: TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.settings, size: 16, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Gestionar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sort button used by all profile tabs
// ─────────────────────────────────────────────────────────────────────────────

class _SortButton<T> extends StatelessWidget {
  const _SortButton({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: onChanged,
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (_) => options.entries
          .map(
            (e) => PopupMenuItem<T>(
              value: e.key,
              child: Row(
                children: [
                  Icon(
                    Icons.check,
                    size: 15,
                    color: e.key == value
                        ? const Color(0xFF1E3A5F)
                        : Colors.transparent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          e.key == value ? FontWeight.w700 : FontWeight.normal,
                      color: e.key == value
                          ? const Color(0xFF1E3A5F)
                          : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, size: 14, color: Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              options[value] ?? '',
              style:
                  const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more,
                size: 14, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }
}
