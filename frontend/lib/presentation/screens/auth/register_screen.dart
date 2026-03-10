import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../info/info_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // FocusNodes para navegar entre campos con Enter / Tab
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isTermsAccepted = false;

  // Colors for the new design (Same as Login)
  final Color _tealBrandColor = const Color(0xFF2D5C5A); // "Greenish" teal
  final Color _glowBlueColor = const Color(0xFF2563EB);

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
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
    // Garantizar al menos uno de cada categoría
    final List<String> chars = [
      uppercase[rng.nextInt(uppercase.length)],
      lowercase[rng.nextInt(lowercase.length)],
      digits[rng.nextInt(digits.length)],
      symbols[rng.nextInt(symbols.length)],
    ];
    // Rellenar los 12 caracteres restantes aleatoriamente
    for (int i = 0; i < 12; i++) {
      chars.add(allChars[rng.nextInt(allChars.length)]);
    }
    // Mezclar para evitar patrones predecibles
    chars.shuffle(rng);
    final password = chars.join();

    setState(() {
      _passwordController.text = password;
      _confirmPasswordController.text = password;
      _isPasswordVisible = true;
      _isConfirmPasswordVisible = true;
    });
  }

  Future<void> _handleRegister() async {
    if (!_isTermsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar los Términos y Condiciones'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).register(
        _emailController.text,
        _passwordController.text,
        _fullNameController.text,
      );
      
      if (success && mounted) {
        // Redirect to Login or Home? 
        // Plan says: Redirect to Login (or Auto-login). 
        // Let's redirect to Login for now to be safe, asking user to login.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta creada con éxito. Por favor inicia sesión.'), backgroundColor: Colors.green),
        );
        context.go('/login');
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

  Widget _buildTrustBadgeSimple({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String title,
  }) {
    return Container( // Reuse same as Login
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
                  color: Colors.grey[400], 
                  letterSpacing: 1.2, 
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.grey[700], 
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  // Custom Euro Strikethrough Icon
  Widget _buildEuroOffIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(Icons.euro_symbol, color: Colors.white, size: 24),
        Transform.rotate(
          angle: -0.785398, // -45 degrees in radians
          child: Container(
            width: 30,
            height: 2,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 900;

    // Split Layout Components
    
    // 1. Branding Panel (Right Side on Desktop - Redesigned)
    Widget brandingPanel = Container(
      color: const Color(0xFF1E3A8A), // Dark Navy Blue background
      child: Stack(
        children: [
          // Background Overlay (Gradient)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1E3A8A).withOpacity(0.8),
                  const Color(0xFF111827).withOpacity(0.95),
                ],
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Logo Image + Text (clickable → Home)
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
                        const Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Inmu',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF2563EB),
                                  letterSpacing: -1.0,
                                ),
                              ),
                              TextSpan(
                                text: 'Fácil',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF16A34A),
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
                const SizedBox(height: 24),
                
                // Headline
                const Text(
                  'Seguridad Garantizada entre Particulares',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                
                const SizedBox(height: 48),

                // Features Row (only 2 features now)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFeatureItem(Icons.verified_user_outlined, 'P2P VERIFICADO'),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _buildEuroOffIcon(),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'SIN COMISIONES',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Footer (only copyright, no links)
                Text(
                  '© 2026 INMUFÁCIL SECURE-TECH',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // 2. Form Panel (Left Side on Desktop)
    Widget formPanel = Container(
      color: const Color(0xFFF5F5F7), // Light gray background
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                 elevation: 2,
                 shadowColor: Colors.black.withOpacity(0.05),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                 color: Colors.white,
                 child: Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                   child: Form(
                   key: _formKey,
                   child: Column(
                     mainAxisSize: MainAxisSize.min,
                     crossAxisAlignment: CrossAxisAlignment.stretch, // Left alignment comes from text alignment
                     children: [
                       // Branding for Mobile
                       if (!isDesktop) ...[
                         Center(
                           child: MouseRegion(
                             cursor: SystemMouseCursors.click,
                             child: GestureDetector(
                               onTap: () => context.go('/'),
                               child: Column(
                                 children: [
                                     Icon(Icons.star, color: _glowBlueColor, size: 32),
                                    const SizedBox(height: 8),
                                   Text('InmuFácil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _tealBrandColor)),
                                 ],
                               ),
                             ),
                           ),
                         ),
                         const SizedBox(height: 24),
                       ],

                       // Header (Left Aligned)
                       Text(
                         'Crea tu cuenta',
                         textAlign: TextAlign.left,
                         style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                           color: const Color(0xFF1E293B),
                           fontWeight: FontWeight.bold,
                           fontSize: 22,
                         ),
                       ),
                       const SizedBox(height: 6),
                       Text(
                         'Únete a la red P2P más segura del sector inmobiliario.',
                         textAlign: TextAlign.left,
                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                           color: const Color(0xFF64748B),
                           fontSize: 12,
                           height: 1.3,
                         ),
                       ),
                       const SizedBox(height: 20),

                       // Name Field
                       const Text(
                         'Nombre completo',
                         style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                       ),
                       const SizedBox(height: 6),
                       TextFormField(
                         controller: _fullNameController,
                         textInputAction: TextInputAction.next,
                         onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocusNode),
                         style: const TextStyle(fontSize: 13),
                         decoration: _buildInputDecoration('Ej: Juan Pérez'),
                         validator: (value) => (value == null || value.length < 3) ? 'Mínimo 3 caracteres' : null,
                       ),
                       const SizedBox(height: 14),

                       // Email Field
                       const Text(
                         'Correo electrónico',
                         style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                       ),
                       const SizedBox(height: 6),
                       TextFormField(
                         controller: _emailController,
                         focusNode: _emailFocusNode,
                         textInputAction: TextInputAction.next,
                         onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocusNode),
                          style: const TextStyle(fontSize: 13),
                         decoration: _buildInputDecoration('nombre@ejemplo.com'),
                         validator: (value) {
                           if (value == null || value.isEmpty) return 'Requerido';
                           final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                           if (!emailRegex.hasMatch(value)) return 'Ingresa un correo válido';
                           return null;
                           },
                       ),
                       const SizedBox(height: 14),

                       // Password Field
                       const Text(
                         'Contraseña',
                         style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                       ),
                       const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_confirmPasswordFocusNode),
                          style: const TextStyle(fontSize: 13),
                          decoration: _buildInputDecoration('Mínimo 8 caracteres').copyWith(
                            suffixIcon: SizedBox(
                              width: 80,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Tooltip(
                                    message: 'Generar contraseña segura',
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.auto_fix_high,
                                        color: Color(0xFF2563EB),
                                        size: 18,
                                      ),
                                      onPressed: _generateSecurePassword,
                                      splashRadius: 18,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      color: Colors.grey[400],
                                      size: 18,
                                    ),
                                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                    splashRadius: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          validator: (value) => (value == null || value.length < 8) ? 'Mínimo 8 caracteres' : null,
                        ),
                       const SizedBox(height: 14),

                       // Confirm Password Field
                       const Text(
                         'Confirmar contraseña',
                         style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                       ),
                       const SizedBox(height: 6),
                       TextFormField(
                         controller: _confirmPasswordController,
                         focusNode: _confirmPasswordFocusNode,
                         obscureText: !_isConfirmPasswordVisible,
                         textInputAction: TextInputAction.done,
                         onFieldSubmitted: (_) => _handleRegister(),
                          style: const TextStyle(fontSize: 13),
                         decoration: _buildInputDecoration('Repite tu contraseña').copyWith(
                           suffixIcon: IconButton(
                             icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey[400], size: 18),
                             onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                           ),
                         ),
                         validator: (value) {
                           if (value != _passwordController.text) return 'Las contraseñas no coinciden';
                           return null;
                         },
                       ),
                       const SizedBox(height: 16),

                       // Terms Checkbox
                       Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           SizedBox(
                             width: 20,
                             height: 20,
                             child: Checkbox(
                               value: _isTermsAccepted,
                               onChanged: (v) => setState(() => _isTermsAccepted = v!),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                               activeColor: _glowBlueColor,
                               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                             ),
                           ),
                           const SizedBox(width: 8),
                           Expanded(
                             child: Text.rich(
                               TextSpan(
                                 text: 'Acepto los ',
                                 style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                 children: [
                                   TextSpan(
                                     text: 'Terminos y Condiciones',
                                     style: TextStyle(
                                       color: _glowBlueColor,
                                       fontWeight: FontWeight.w600,
                                       decoration: TextDecoration.underline,
                                     ),
                                     recognizer: TapGestureRecognizer()
                                       ..onTap = () => context.push(
                                             InfoScreen.routeFor(
                                                 InfoPageType.terms),
                                           ),
                                   ),
                                   const TextSpan(text: ' y la '),
                                   TextSpan(
                                     text: 'Politica de Privacidad',
                                     style: TextStyle(
                                       color: _glowBlueColor,
                                       fontWeight: FontWeight.w600,
                                       decoration: TextDecoration.underline,
                                     ),
                                     recognizer: TapGestureRecognizer()
                                       ..onTap = () => context.push(
                                             InfoScreen.routeFor(
                                                 InfoPageType.privacy),
                                           ),
                                   ),
                                 ],
                               ),
                             ),
                           ),
                         ],
                       ),

                       const SizedBox(height: 20),

                       // Register Button
                       Consumer(
                          builder: (context, ref, child) {
                            final isLoading = ref.watch(authProvider).isLoading;
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _glowBlueColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: isLoading 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text(
                                      'Crear Cuenta',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                              ),
                            );
                          },
                       ),
                       
                       const SizedBox(height: 16),
                       
                       // Login Link
                       Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Text('¿Ya tienes cuenta? ', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: InkWell(
                                onTap: () => context.go('/login'),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Text(
                                    'Inicia sesión',
                                    style: TextStyle(color: _glowBlueColor, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
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
          ],
        ),
      ),
    ),
    );


    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Light gray background
      body: Row(
        children: [
          // ON DESKTOP: Form on Left (flex 1), Branding on Right (flex 1)
          
          // LEFT SIDE - Form
          Expanded(
            flex: 1,
            child: formPanel,
          ),

          // RIGHT SIDE - Branding
          if (isDesktop)
            Expanded(
              flex: 1,
              child: brandingPanel,
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _glowBlueColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
