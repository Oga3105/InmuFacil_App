import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:inmufacil_frontend/presentation/providers/not_found_provider.dart';
import 'package:inmufacil_frontend/core/utils/temp_translations.dart';

class NotFoundScreen extends ConsumerWidget {
  final String? uri;

  const NotFoundScreen({super.key, this.uri});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Custom Colors from design
    final primaryColor = const Color(0xFF135BEC);
    final navyCustom = const Color(0xFF0F172A);
    final bgLight = Colors.white;
    final bgDark = const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      body: Stack(
        children: [
          // Background Grid
          Positioned.fill(
            child: CustomPaint(
              painter: BlueprintGridPainter(
                color: primaryColor.withOpacity(0.1),
              ),
            ),
          ),
          
          // Main Scrollable Content
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1024;
              
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header
                        _Header(isDesktop: isDesktop, primaryColor: primaryColor),
                        
                        const SizedBox(height: 60),
                        
                        // Content Body
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 1,
                                child: _TextContent(
                                  primaryColor: primaryColor,
                                  navyCustom: navyCustom,
                                ),
                              ),
                              const SizedBox(width: 80),
                              Expanded(
                                flex: 1,
                                child: _IsometricIllustration(primaryColor: primaryColor),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _IsometricIllustration(primaryColor: primaryColor),
                              const SizedBox(height: 60),
                              _TextContent(
                                primaryColor: primaryColor,
                                navyCustom: navyCustom,
                              ),
                            ],
                          ),
                          
                        const SizedBox(height: 60),
                        
                        // Footer
                        _Footer(isDesktop: isDesktop),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isDesktop;
  final Color primaryColor;

  const _Header({required this.isDesktop, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        Icon(Icons.hexagon_outlined, color: primaryColor, size: 40),
        const SizedBox(width: 12),
        Text(
          'app.name'.tr(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
        ),
        if (isDesktop) ...[
          Container(
            height: 32,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            color: Theme.of(context).dividerColor,
          ),
          Text(
             'home.tagline_part1'.tr(),
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'home.tagline_part2'.tr(),
            style: TextStyle(
              fontSize: 18,
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}

class _TextContent extends ConsumerStatefulWidget {

  final Color primaryColor;
  final Color navyCustom;

  const _TextContent({required this.primaryColor, required this.navyCustom});

  @override
  ConsumerState<_TextContent> createState() => _TextContentState();
}

class _TextContentState extends ConsumerState<_TextContent> {
  final _emailController = TextEditingController();
  bool _isValid = false;
  // Standard email regex ensuring @ and .
  final _emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _validate(String value) {
    setState(() {
      _isValid = _emailRegex.hasMatch(value.trim());
    });
  }

  Future<void> _submit() async {
    if (_isValid) {
      // Dismiss keyboard
      FocusScope.of(context).unfocus();
      
      await ref.read(notFoundProvider.notifier).submitInterest(_emailController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(notFoundProvider);
    final isLoading = state is AsyncLoading;

    // Listen for state changes to show Side Effects (SnackBars)
    ref.listen(notFoundProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
           _emailController.clear();
           setState(() => _isValid = false);
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('not_found.notify_me_success'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        },
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error.toString()}'), // Should use i18n
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          '404',
          style: TextStyle(
            fontSize: 120,
            fontWeight: FontWeight.w900,
            height: 0.8,
            color: isDark ? Colors.white.withOpacity(0.1) : widget.navyCustom.withOpacity(0.1),
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.1,
              fontSize: 40,
            ),
            children: [
              TextSpan(text: 'not_found.building_future_part1'.tr()),
              TextSpan(
                text: 'not_found.building_future_part2'.tr(),
                style: TextStyle(color: widget.primaryColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'not_found.description'.tr(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 18,
            color: Theme.of(context).textTheme.bodyMedium?.color,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        
        // Form
        Text(
          'not_found.notify_me_label'.tr(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: TextField(
                  controller: _emailController,
                  onChanged: _validate,
                  enabled: !isLoading, // Disable when loading
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'not_found.email_placeholder'.tr(),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isValid && !isLoading ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  disabledForegroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading 
                    ? SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(
                          strokeWidth: 2, 
                          color: Colors.white
                        )
                      )
                    : Text(
                        'not_found.notify_button'.tr(), 
                        style: TextStyle(fontWeight: FontWeight.bold)
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.security, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              'not_found.security_text'.tr(),
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}

class _IsometricIllustration extends StatelessWidget {
  final Color primaryColor;

  const _IsometricIllustration({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    // HTML reference: <div class="relative w-full max-w-[420px] aspect-square">
    return SizedBox(
      width: 420,
      height: 420, // aspect-square
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Background Dashed Box (Rotated)
          // HTML: absolute inset-0 bg-primary/5 border-2 border-dashed border-primary/30 rounded-xl transform rotate-3 scale-95
          Transform.rotate(
            angle: 3 * math.pi / 180, // rotate-3
            child: Transform.scale(
              scale: 0.95, // scale-95
              child: Container(
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12), // rounded-xl
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3),
                    width: 2,
                   // Note: Flutter standard border doesn't support dashed natively without package/custom painter.
                   // Using solid for now to keep it simple, or we could add a CustomPainter.
                   // User asked for "exact", so let's stick to dimensions first.
                  ),
                ),
                child: CustomPaint(
                   painter: _DashedBorderPainter(
                      color: primaryColor.withOpacity(0.3),
                      strokeWidth: 2,
                      radius: 12,
                   ),
                ),
              ),
            ),
          ),
          
          // 2. Isometric Group
          // HTML: absolute inset-0 flex items-center justify-center construction-isometric
          // construction-isometric: transform: perspective(1000px) rotateX(10deg) rotateY(-5deg);
          Center(
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective(1000px) -> 1/1000 = 0.001
                ..rotateX(10 * math.pi / 180) // rotateX(10deg)
                ..rotateY(-5 * math.pi / 180), // rotateY(-5deg)
              child: SizedBox(
                // HTML: w-64 h-64 (256px)
                width: 256,
                height: 256,
                child: Stack(
                  clipBehavior: Clip.none, // Allow elements to overflow (bubbles, cards)
                  children: [
                    // 2.1 Base Block
                    // HTML: absolute bottom-0 left-0 w-full h-1/2 bg-white border-2 border-slate-200 rounded-sm shadow-xl
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 128, // h-1/2 of 256
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4), // rounded-sm
                          border: Border.all(color: Colors.grey.shade200, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1), // shadow-xl approx
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // 2.2 Middle Block
                    // HTML: absolute bottom-1/2 left-0 w-2/3 h-1/3 bg-slate-50 border-2 border-slate-200 rounded-sm
                    Positioned(
                      bottom: 128, // bottom-1/2 starts at 50%
                      left: 0,
                      width: 170.6, // w-2/3 of 256
                      height: 85.3, // h-1/3 of 256
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade200, width: 2),
                        ),
                      ),
                    ),
                    
                    // 2.3 Top Transparent Block (Blueprint)
                    // HTML: top-4 left-1/4 w-3/4 h-1/2 bg-primary/10 border-2 border-dashed border-primary rounded-sm overflow-hidden
                    Positioned(
                      top: 16, // top-4
                      left: 64, // left-1/4
                      width: 192, // w-3/4
                      height: 128, // h-1/2
                      child: Container(
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          // Border handled by painter for dashed effect if possible, or just solid
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                               child: CustomPaint(
                                 painter: _DashedBorderPainter(color: primaryColor, strokeWidth: 2, radius: 4),
                               ),
                            ),
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.5,
                                child: CustomPaint(
                                  painter: BlueprintGridPainter(
                                    color: primaryColor.withOpacity(1.0), // Opacity handled by parent
                                    spacing: 30, // 30px from CSS background-size
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // 2.4 Shield Bubble
                    // HTML: -top-10 -right-10 size-32 bg-primary/10 backdrop-blur-sm rounded-full ... shield-glow
                    Positioned(
                      top: -40, // -top-10 (10 * 4px)
                      right: -40, // -right-10
                      width: 128, // size-32
                      height: 128,
                      child: Container(
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryColor.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4),
                              blurRadius: 20, // shield-glow
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        // Note: BackdropFilter for blur requires Clip, which might clip circle shadows
                        // skipping blur for simplicity/performance in Flutter web
                        child: Icon(
                          Icons.security, // Closest to shield_lock
                          size: 60, // text-6xl approx
                          color: primaryColor,
                        ),
                      ),
                    ),
                    
                    // 2.5 Verified User Card
                    // HTML: -left-12 top-1/2 bg-white p-3 rounded-lg shadow-2xl border border-slate-100
                    Positioned(
                      left: -48, // -left-12
                      top: 128, // top-1/2
                      child: Container(
                        padding: const EdgeInsets.all(12), // p-3
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8), // rounded-lg
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [
                            BoxShadow(
                               color: Colors.black.withOpacity(0.2), // shadow-2xl
                               blurRadius: 25,
                               offset: const Offset(0, 10), // approx 2xl
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Verified Icon
                            Container(
                              width: 32, // size-8
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.verified_user, size: 18, color: Colors.green),
                            ),
                            const SizedBox(width: 12), // gap-3
                            // Placeholders
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 64, // w-16
                                  height: 8, // h-2
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 40, // w-10
                                  height: 6, // h-1.5
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // 2.6 Code Tag
                    // HTML: -bottom-6 left-1/2 -translate-x-1/2 w-48 ... text-[10px]
                    Positioned(
                       bottom: -24, // -bottom-6
                       left: 0, 
                       right: 0,
                       child: Center(
                         child: Container(
                           width: 192, // w-48
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               Text('[', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 10, fontFamily: 'monospace')),
                               Expanded(
                                 child: Container(
                                   margin: const EdgeInsets.symmetric(horizontal: 8),
                                   height: 1, 
                                   color: primaryColor.withOpacity(0.3)
                                 ),
                               ),
                               Text('SECURE_LAYER_V2', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 10, fontFamily: 'monospace')),
                               Expanded(
                                 child: Container(
                                   margin: const EdgeInsets.symmetric(horizontal: 8),
                                   height: 1, 
                                   color: primaryColor.withOpacity(0.3)
                                 ),
                               ),
                               Text(']', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 10, fontFamily: 'monospace')),
                             ],
                           ),
                         ),
                       ),
                    ),
                    
                    // 2.7 Dots
                    // HTML: top-10 right-10 size-2 bg-primary animate-pulse
                    Positioned(
                      top: 40, // top-10
                      right: 40, // right-10
                      child: Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                     // HTML: bottom-20 left-0 size-1.5 bg-primary/40
                    Positioned(
                      bottom: 80, // bottom-20
                      left: 0,
                      child: Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
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

// Helper for dashed borders since Flutter doesn't have them built-in natively
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashGap;
  final double dashLength;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2,
    this.radius = 0,
    this.dashGap = 4,
    this.dashLength = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height), 
      Radius.circular(radius)
    );
    
    final Path path = Path()..addRRect(rrect);
    
    // Simple dash implementation
    final Path dashedPath = Path();
    for (ui.PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        dashedPath.addPath(
          pathMetric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + dashGap;
      }
    }
    
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}

class _Footer extends StatelessWidget {
  final bool isDesktop;

  const _Footer({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FooterItem(icon: Icons.construction, text: 'not_found.secure_infrastructure'.tr()),
                  const SizedBox(width: 24),
                  _FooterItem(icon: Icons.hub, text: 'not_found.direct_architecture'.tr()),
                ],
              ),
              if (!isDesktop) const SizedBox(height: 16),
              Text(
                '© ${DateTime.now().year} ${'not_found.copyright_text'.tr()}',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FooterItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FooterItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

class BlueprintGridPainter extends CustomPainter {
  final Color color;
  final double spacing;

  BlueprintGridPainter({required this.color, this.spacing = 30.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BlueprintGridPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.spacing != spacing;
  }
}
