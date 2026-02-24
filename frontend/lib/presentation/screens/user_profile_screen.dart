import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inmufacil_frontend/presentation/providers/auth_provider.dart';
import 'package:inmufacil_frontend/presentation/providers/search_provider.dart';
import 'package:inmufacil_frontend/presentation/widgets/map/property_floating_card.dart'; // Using the updated card
import '../../domain/entities/user.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  
  // [NEW] Password Change State
  bool _isChangingPassword = false;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // [NEW] Editing State
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
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
       // address/location not yet in User entity — controller keeps its own state
    }

    final isVerified = user.dniStatus == 'verified';

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
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          tabs: const [
                             Tab(child: Row(children: [Icon(Icons.person, size: 20), SizedBox(width: 8), Text('Mi Perfil')])),
                             Tab(child: Row(children: [Icon(Icons.home_work, size: 20), SizedBox(width: 8), Text('Mis Propiedades')])),
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
                      return _tabController.index == 0 
                        ? _buildProfileTab(user, isVerified)
                        : _buildPropertiesTab();
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
                      TextSpan(text: 'Inmu', style: TextStyle(color: Color(0xFF2563EB))),
                      TextSpan(text: 'Fácil', style: TextStyle(color: Color(0xFF16A34A))),
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
          TextButton.icon(
             onPressed: () => context.go('/'),
             icon: const Icon(Icons.home_outlined, size: 20, color: Colors.black54),
             label: const Text('Inicio', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.grey), onPressed: () {}),
          const SizedBox(width: 8),
          
          // [UPDATED] Profile Menu with Logout
          PopupMenuButton<String>(
            offset: const Offset(0, 40),
            tooltip: 'Menú de usuario',
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
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
                    context.go('/'); // Redirect to Home
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sesión cerrada correctamente')),
                    );
                }
              }
            },
            child: const CircleAvatar(
               radius: 16,
               backgroundColor: Color(0xFF2563EB), // Official Blue
               child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 24),
        ],
      );
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
                   BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                 ],
              ),
              child: const Center(
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
            ),
            if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
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
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                   // Dynamic User Type
                  _buildHeaderBadge(user.userType == 'agent' ? 'Agente Inmobiliario' : 'Propietario Particular', Colors.blue.shade50, Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      // Mock Date for now as User entity might need createdAt parsing
                      Text('Miembro desde 2024', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  if (isVerified)
                     Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text('Verificado', style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
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
         if (!isVerified) _buildVerificationBanner(),
         
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
          const Text('Información Personal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 24),
          
          // [UPDATED] ReadOnly logic based on _isEditing
          Row(
            children: [
              Expanded(child: _buildTextField('Nombre Completo', _nameController, !_isEditing)),
              const SizedBox(width: 24),
              Expanded(child: _buildTextField('Teléfono', _phoneController, !_isEditing)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildTextField('Ubicación', _locationController, !_isEditing)),
              const SizedBox(width: 24),
              Expanded(child: _buildTextField('Correo Electrónico (No editable)', TextEditingController(text: user.email), true)),
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
                           // ... revert location
                         });
                       }, 
                       style: OutlinedButton.styleFrom(
                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                         side: const BorderSide(color: Colors.red), // Red border
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                       ),
                       child: const Text('Cancelar', style: TextStyle(color: Colors.red)), // Red text
                     ),
                   ),

                ElevatedButton(
                  onPressed: () async {
                    if (_isEditing) {
                       // TODO: updateProfile will be implemented when backend endpoint is ready
                       // For now, just exit edit mode and show a coming-soon notice
                       setState(() { _isEditing = false; });
                       if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(
                             content: Row(children: [Icon(Icons.info_outline, color: Colors.white), SizedBox(width: 8), Text('Guardado localmente — sincronización próximamente')]),
                             backgroundColor: Color(0xFF2563EB),
                             behavior: SnackBarBehavior.floating,
                           ),
                         );
                       }
                    } else {
                       // Enable Edit Mode
                       setState(() {
                         _isEditing = true;
                       });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEditing ? const Color(0xFF16A34A) : const Color(0xFF0F172A), 
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: ref.watch(authProvider).isLoading && _isEditing 
                     ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                     : Text(
                        _isEditing ? 'Guardar Datos' : 'Editar Perfil',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
          const Text('Seguridad y Privacidad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 24),
          
          // [UPDATED] Password Change Section
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: _isChangingPassword 
                ? _buildChangePasswordForm()
                : Row(
                  children: [
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          const Text('Contraseña', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Actualiza tu contraseña periódicamente para mayor seguridad.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                       ],
                     ),
                     const Spacer(),
                     OutlinedButton(
                       onPressed: (){
                         setState(() {
                           _isChangingPassword = true;
                         });
                       }, 
                       style: OutlinedButton.styleFrom(
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                       ),
                       child: const Text('Cambiar Contraseña', style: TextStyle(color: Colors.black87)),
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
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       const Text('Suspender Cuenta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange)),
                       const SizedBox(height: 4),
                       Text('Tu perfil no será visible públicamente.', style: TextStyle(color: Colors.orange.shade300, fontSize: 12)),
                       const SizedBox(height: 12),
                       SizedBox(
                         width: double.infinity,
                         child: OutlinedButton(
                           onPressed: () async {
                              // Toggle suspension via API
                              final newStatus = !isSuspended; // If currently suspended, we want to reactivate (active=true) which corresponds to isSuspended=false. 
                              // Wait, isSuspended = !isActive.
                              // If isSuspended is true -> isActive is false. Reactivate -> isActive = true.
                              // If isSuspended is false -> isActive is true. Suspend -> isActive = false.
                              
                               // TODO: Account suspension via backend when endpoint is ready
                               if (context.mounted) {
                                 ScaffoldMessenger.of(context).showSnackBar(
                                   const SnackBar(content: Text('Función de suspensión próximamente disponible')),
                                 );
                               }
                           },
                           style: OutlinedButton.styleFrom(
                             side: const BorderSide(color: Colors.orange),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                           ),
                           child: Text(isSuspended ? 'Reactivar' : 'Suspender', style: const TextStyle(color: Colors.orange)),
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
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       const Text('Eliminar Cuenta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
                       const SizedBox(height: 4),
                       Text('Esta acción es irreversible.', style: TextStyle(color: Colors.red.shade300, fontSize: 12)),
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
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // 12px radius
                           ),
                           child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
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

  Widget _buildPromoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB), // Official Blue
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('¿Vendes tu casa?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Publicala gratis ahora y llega a miles de compradores verificados en nuestra red P2P segura.', 
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2563EB), size: 18),
              label: const Text('Publicar Nueva Propiedad', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Tab 2: Grid of Properties
  Widget _buildPropertiesTab() {
    // Mock Data logic...
    final allProperties = ref.watch(filteredByMapPropertiesProvider);
    final myProperties = allProperties.take(2).toList(); 

    if (myProperties.isEmpty) {
      return _buildEmptyStateCard(small: false);
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
                 Text('Tus Propiedades', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                 SizedBox(height: 4),
                 Text('Gestiona tus anuncios publicados y su estado.', style: TextStyle(color: Colors.grey, fontSize: 13)),
               ],
             ),
             // Sort Dropdown mockup
             Row(
               children: [
                 Text('Ordenar por: ', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                 const Text('Más recientes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                 const Icon(Icons.expand_more, size: 16),
               ],
             ),
           ],
         ),
         const SizedBox(height: 24),
         
         // GRID
         GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 350,
              mainAxisExtent: 380, // Height of card
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
            ),
            itemCount: myProperties.length + 1, // +1 for "Add New" placeholder
            itemBuilder: (context, index) {
              
              // Last Item: "Add New" Placeholder
              if (index == myProperties.length) {
                return _buildAddPropertyPlaceholder();
              }
              
              final p = myProperties[index];
              
              return PropertyFloatingCard(
                property: p,
                onTap: () {},
                width: double.infinity,
              );
            },
         ),
      ],
    );
  }

  Widget _buildAddPropertyPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid, width: 2), // Dashed borders need custom painter usually, solid is fine for MVP or use CustomPaint
      ),
      child: InkWell(
        onTap: () {}, // Publicar
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
              child: const Icon(Icons.add_home_outlined, size: 32, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            const Text('¿Tienes otra propiedad?', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
            const Text('Publicar otro anuncio', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
          ],
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
             decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
             child: const Icon(Icons.home, size: 32, color: Colors.grey),
           ),
           const SizedBox(height: 16),
           const Text('No tienes propiedades activas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
           const SizedBox(height: 8),
           const Text('"Empieza hoy mismo tu proceso de venta directa sin intermediarios."', 
             textAlign: TextAlign.center,
             style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),),
           const SizedBox(height: 16),
           TextButton(
             onPressed: (){}, 
             child: const Text('Ver mis borradores', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
           ),
         ],
       ),
    );
  }

  Widget _buildChangePasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cambiar Contraseña', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
        const SizedBox(height: 16),
        
        // Current Password
        _buildTextField('Contraseña Actual', _currentPasswordController, false, isPassword: true),
        const SizedBox(height: 16),
        
        // New Password
        Row(
          children: [
            Expanded(child: _buildTextField('Nueva Contraseña', _newPasswordController, false, isPassword: true)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Confirmar Nueva Contraseña', _confirmPasswordController, false, isPassword: true)),
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
                  _currentPasswordController.clear();
                  _newPasswordController.clear();
                  _confirmPasswordController.clear();
                });
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                // Mock Validation
                if (_newPasswordController.text != _confirmPasswordController.text) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Las contraseñas no coinciden'), backgroundColor: Colors.red));
                   return;
                }
                // Mock Success
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña actualizada correctamente'), backgroundColor: Colors.green));
                setState(() {
                  _isChangingPassword = false;
                  _currentPasswordController.clear();
                  _newPasswordController.clear();
                  _confirmPasswordController.clear();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Actualizar Contraseña', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool readOnly, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          obscureText: isPassword,
          style: TextStyle(color: readOnly ? Colors.grey.shade500 : Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
            prefixIcon: readOnly ? null : null, 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield, color: Color(0xFF2563EB)),
          const SizedBox(width: 16),
          const Expanded(
            child: Text('Verifica tu identidad para mayor seguridad y destacar tus anuncios.', style: TextStyle(color: Color(0xFF1E293B))),
          ),
          TextButton(
            onPressed: () => context.push('/verify-identity'),
            child: const Text('Verificar Ahora', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
