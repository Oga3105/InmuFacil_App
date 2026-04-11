import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/google_sign_in_button.dart';


class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _isPasswordVisible = false;

  // Colors for the new design
  final Color _tealBrandColor = const Color(0xFF2D5C5A); // "Greenish" teal
  final Color _glowBlueColor = const Color(0xFF2563EB);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      // Trigger real login
      final success = await ref.read(authProvider.notifier).login(
        _emailController.text,
        _passwordController.text,
      );
      
      if (success && mounted) {
        context.go('/');
      } else {
        final error = ref.read(authProvider).errorMessage;
        if (error != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    }
  }


  
  Widget _buildTrustBadgeSimple(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state for errors/loading state
    ref.listen(authProvider, (previous, next) {
      if (next.errorMessage != null && !next.isLoading) {
        // Optional: clear error after showing? 
      }
    });

    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 900;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        children: [
          // LEFT SIDE - Branding (Desktop Only)
         // Left side - Image/Branding with Blur and Home Content
        if (isDesktop)
          Expanded(
            flex: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Background Color
                Container(color: _tealBrandColor),

                // 2. Blurred/Faded Background Text
                Positioned.fill(
                  child: ImageFiltered(
                    // Apply blur to create the "difuminado" effect
                    imageFilter: ui.ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Top Text (Behind/Above Card)
                          Text(
                            'Sin intermediarios.\n0% comisiones.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit', // Assuming generic sans if not avail, but aiming for style
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                              color: Colors.white.withOpacity(0.1), // Very faded
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Compra y vende sin comisiones.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          const SizedBox(height: 300), // Space for the card
                          Text(
                            'De la búsqueda a la notaría\nen pasos seguros.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Elimina la incertidumbre.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Central Raised Card (Reduced Size)
                Center(
                  child: Container(
                    width: 380, // Fixed width to keep it compact
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48), // Reduced padding
                    decoration: BoxDecoration(
                      color: _tealBrandColor, 
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(8, 8),
                          blurRadius: 24,
                          spreadRadius: -4,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          offset: const Offset(-4, -4),
                          blurRadius: 16,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => context.go('/'),
                            child: Column(
                              children: [
                                Image.asset(
                                  'assets/images/logo_inmufacil.png',
                                  height: 70,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 16),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Inmu',
                                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                          color: const Color(0xFF2563EB),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 32,
                                          letterSpacing: -1.0,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Fácil',
                                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                          color: const Color(0xFF16A34A),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 32,
                                          letterSpacing: -1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 32,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Text(
                          'Inmuebles fácil entre particulares',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),


          // RIGHT SIDE - Login Form
          Expanded(
            flex: 1,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Card(
                         elevation: 8,
                         shadowColor: Colors.black.withOpacity(0.08),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                         color: Theme.of(context).colorScheme.surfaceContainerLowest,
                         child: Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                           child: Form(
                             key: _formKey,
                             child: Column(
                               mainAxisSize: MainAxisSize.min,
                               crossAxisAlignment: CrossAxisAlignment.stretch,
                               children: [
                                 // Branding for Mobile (since left panel is hidden)
                                 if (!isDesktop) ...[
                                   Center(
                                     child: MouseRegion(
                                       cursor: SystemMouseCursors.click,
                                       child: GestureDetector(
                                         onTap: () => context.go('/'),
                                         child: Column(
                                           children: [
                                             Image.asset(
                                               'assets/images/logo_inmufacil.png',
                                               height: 40,
                                               fit: BoxFit.contain,
                                             ),
                                             const SizedBox(height: 6),
                                             Text('InmuFácil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _tealBrandColor)),
                                           ],
                                         ),
                                       ),
                                     ),
                                   ),
                                   const SizedBox(height: 20),
                                 ],

                                 // Header
                                 Text(
                                   'Bienvenido de nuevo',
                                   textAlign: TextAlign.center,
                                   style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                     color: Theme.of(context).colorScheme.onSurface,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                                 const SizedBox(height: 6),
                                 Text(
                                   'Accede a tu panel seguro de InmuFácil.',
                                   textAlign: TextAlign.center,
                                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                     color: Theme.of(context).colorScheme.onSurfaceVariant,
                                   ),
                                 ),
                                 const SizedBox(height: 16),

                                 // Google button FIRST
                                 const GoogleSignInButton(),
                                 const SizedBox(height: 14),

                                 // Divisor "o"
                                 Row(
                                   children: [
                                     Expanded(child: Divider(color: Colors.grey[300])),
                                     Padding(
                                       padding: const EdgeInsets.symmetric(horizontal: 12),
                                       child: Text(
                                         'auth.or_separator'.tr(),
                                         style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                       ),
                                     ),
                                     Expanded(child: Divider(color: Colors.grey[300])),
                                   ],
                                 ),
                                 const SizedBox(height: 14),

                                 // Email Field
                                 Text(
                                   'CORREO ELECTRÓNICO',
                                   style: TextStyle(
                                     fontSize: 11,
                                     fontWeight: FontWeight.bold,
                                     letterSpacing: 1.2,
                                     color: Theme.of(context).colorScheme.onSurfaceVariant,
                                   ),
                                 ),
                                 const SizedBox(height: 6),
                                 TextFormField(
                                   controller: _emailController,
                                   textInputAction: TextInputAction.next,
                                   onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocusNode),
                                   decoration: InputDecoration(
                                     hintText: 'ejemplo@correo.com',
                                     hintStyle: TextStyle(color: Colors.grey[400]),
                                     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                     border: OutlineInputBorder(
                                       borderRadius: BorderRadius.circular(12),
                                       borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                                     ),
                                     enabledBorder: OutlineInputBorder(
                                       borderRadius: BorderRadius.circular(12),
                                       borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                                     ),
                                     focusedBorder: OutlineInputBorder(
                                       borderRadius: BorderRadius.circular(12),
                                       borderSide: BorderSide(color: _glowBlueColor, width: 2),
                                     ),
                                     filled: true,
                                     fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                                   ),
                                   validator: (value) {
                                     if (value == null || value.isEmpty) {
                                       return 'Por favor ingresa tu correo';
                                     }
                                     final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                     if (!emailRegex.hasMatch(value)) {
                                       return 'Ingresa un correo válido';
                                     }
                                     return null;
                                   },
                                 ),
                                 const SizedBox(height: 16),

                                 // Password Field
                                 Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                   children: [
                                     Text(
                                       'CONTRASEÑA',
                                       style: TextStyle(
                                         fontSize: 11,
                                         fontWeight: FontWeight.bold,
                                         letterSpacing: 1.2,
                                         color: Theme.of(context).colorScheme.onSurfaceVariant,
                                       ),
                                     ),
                                     TextButton(
                                       onPressed: () {
                                         final email = _emailController.text.trim();
                                         context.push('/forgot-password', extra: email.isNotEmpty ? email : null);
                                       },
                                       style: TextButton.styleFrom(
                                         padding: EdgeInsets.zero,
                                         minimumSize: Size.zero,
                                         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                       ),
                                       child: Text(
                                         '¿Olvidaste tu contraseña?',
                                         style: TextStyle(
                                           color: _glowBlueColor,
                                           fontWeight: FontWeight.w600,
                                           fontSize: 13,
                                         ),
                                       ),
                                     ),
                                   ],
                                 ),
                                 const SizedBox(height: 6),
                                 TextFormField(
                                   controller: _passwordController,
                                   focusNode: _passwordFocusNode,
                                   obscureText: !_isPasswordVisible,
                                   textInputAction: TextInputAction.done,
                                   onFieldSubmitted: (_) => _handleLogin(),
                                   decoration: InputDecoration(
                                     hintText: '••••••••',
                                     hintStyle: TextStyle(color: Colors.grey[400]),
                                     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                     suffixIcon: IconButton(
                                       icon: Icon(
                                         _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                         color: Colors.grey[400],
                                         size: 20,
                                       ),
                                       onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                     ),
                                     border: OutlineInputBorder(
                                       borderRadius: BorderRadius.circular(12),
                                       borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                                     ),
                                     enabledBorder: OutlineInputBorder(
                                       borderRadius: BorderRadius.circular(12),
                                       borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                                     ),
                                     focusedBorder: OutlineInputBorder(
                                       borderRadius: BorderRadius.circular(12),
                                       borderSide: BorderSide(color: _glowBlueColor, width: 2),
                                     ),
                                     filled: true,
                                     fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                                   ),
                                   validator: (value) {
                                     if (value == null || value.isEmpty) {
                                       return 'Por favor ingresa tu contraseña';
                                     }
                                     return null;
                                   },
                                 ),

                                 const SizedBox(height: 20),

                                 // Login Button (Premium Glow Style)
                                 Consumer(
                                    builder: (context, ref, child) {
                                      final isLoading = ref.watch(authProvider).isLoading;
                                      return Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _glowBlueColor.withOpacity(0.3),
                                              blurRadius: 20,
                                              spreadRadius: 0,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: isLoading ? null : _handleLogin,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _glowBlueColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: isLoading
                                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : const Text(
                                                'Entrar',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                        ),
                                      );
                                    },
                                 ),

                                 const SizedBox(height: 10),

                                 // Link: Continuar sin cuenta
                                 Center(
                                   child: TextButton(
                                     onPressed: () => context.go('/'),
                                     style: TextButton.styleFrom(
                                       foregroundColor: Colors.grey[500],
                                       padding: EdgeInsets.zero,
                                       minimumSize: Size.zero,
                                       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                     ),
                                     child: const Text(
                                       'Continuar sin registrarse →',
                                       style: TextStyle(fontSize: 12),
                                     ),
                                   ),
                                 ),

                                 const SizedBox(height: 8),

                                 // Register Link
                                 Row(
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   children: [
                                     Text(
                                       '¿No tienes cuenta?',
                                       style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                     ),
                                     TextButton(
                                       onPressed: () => context.go('/register'),
                                       style: TextButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                           borderRadius: BorderRadius.circular(12),
                                         ),
                                       ),
                                       child: Text(
                                         'Regístrate',
                                         style: TextStyle(
                                           color: _glowBlueColor,
                                           fontWeight: FontWeight.bold,
                                         ),
                                       ),
                                     ),
                                   ],
                                 ),
                               ],
                             ),
                           ),
                         ),
                      ),
                    ),

                    // Trust Badges (Desktop only)
                    if (isDesktop) ...[
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildTrustBadgeSimple(
                             context,
                             icon: Icons.shield,
                             iconColor: const Color(0xFF16A34A),
                             bgColor: const Color(0xFFDCFCE7),
                             label: 'GARANTÍA INMUFÁCIL',
                             title: 'Tu venta tranquila',
                           ),
                           _buildTrustBadgeSimple(
                             context,
                             icon: Icons.lock,
                             iconColor: const Color(0xFF2563EB),
                             bgColor: const Color(0xFFDBEAFE),
                             label: 'P2P VERIFICADO',
                             title: 'Tu compra segura',
                           ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
