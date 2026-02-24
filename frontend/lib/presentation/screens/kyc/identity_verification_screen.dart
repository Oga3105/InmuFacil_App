import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/verification_provider.dart';
import '../../widgets/common/premium_button.dart';
import 'widgets/document_upload_card.dart';

class IdentityVerificationScreen extends ConsumerWidget {
  const IdentityVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verificationProvider);
    final notifier = ref.read(verificationProvider.notifier);

    // PageController is not strictly needed if we just switch content based on index,
    // but PageView gives nice transitions. We use logic to switch page.
    final PageController pageController =
        PageController(initialPage: state.currentStepIndex);

    // Sync PageController if state changes externally (e.g. back button logic)
    // In a real build() we shouldn't trigger side effects, but for simple wizard steps it's often easier
    // to build the view based on state directly. Let's use an AnimatedSwitcher or direct PageView.
    // To keep it simple and robust:
    if (pageController.hasClients &&
        pageController.page?.round() != state.currentStepIndex) {
      pageController.animateToPage(
        state.currentStepIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Verifica tu Identidad',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (state.currentStepIndex > 0) {
              notifier.prevStep();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Trust Badge Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.blue[50],
            child: Row(
              children: [
                 Icon(Icons.lock_outline, color: Colors.blue[800], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Transferencia Segura (TLS) y Privacidad RGPD. Tus datos no son visibles públicamente.',
                    style: TextStyle(color: Colors.blue[900], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // Progress Indicator
          LinearProgressIndicator(
            value: (state.currentStepIndex + 1) / 4,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),

          Expanded(
            child: PageView(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe
              children: [
                _buildStep1DocumentType(notifier),
                _buildStep2Scan(context, state, notifier),
                _buildStep3Selfie(context, state, notifier),
                _buildStep4Review(context, state, notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1DocumentType(VerificationNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona tu documento',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Necesitamos validar tu identidad legal para activar tu cuenta.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          _buildOptionCard('D.N.I Espa\u00f1ol', Icons.credit_card,
              () => notifier.setDocumentType(DocumentType.dni),),
          const SizedBox(height: 16),
          _buildOptionCard('N.I.E / Residencia', Icons.badge_outlined,
              () => notifier.setDocumentType(DocumentType.nie),),
          const SizedBox(height: 16),
          _buildOptionCard('Pasaporte', Icons.menu_book,
              () => notifier.setDocumentType(DocumentType.pasaporte),),
        ],
      ),
    );
  }

  Widget _buildOptionCard(String text, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue[600], size: 28),
            const SizedBox(width: 16),
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Scan(BuildContext context, VerificationState state,
      VerificationNotifier notifier,) {
    bool canProceed = state.frontImage != null && state.backImage != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escanea tu documento',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aseg\u00farate de que la imagen sea clara y legible.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          DocumentUploadCard(
            title: 'Frente del Documento',
            onTap: notifier.pickFrontImage,
            imageFile: state.frontImage,
            status: state.frontStatus,
          ),
          const SizedBox(height: 16),
          DocumentUploadCard(
            title: 'Reverso del Documento',
            onTap: notifier.pickBackImage,
            imageFile: state.backImage,
            status: state.backStatus,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: PremiumButton(
              label: 'Continuar',
              color: canProceed ? Colors.blue : Colors.grey,
              onPressed: canProceed ? notifier.nextStep : () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Selfie(BuildContext context, VerificationState state,
      VerificationNotifier notifier,) {
    bool canProceed = state.selfieImage != null;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Prueba de Vida',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toma una selfie para asegurar que eres t\u00fa.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 48),
          GestureDetector(
            onTap: notifier.pickSelfie,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
                border: Border.all(
                    color: state.selfieImage != null
                        ? Colors.green
                        : Colors.blue[200]!,
                    width: 4,),
                image: state.selfieImage != null
                    ? DecorationImage(
                        image: FileImage(state.selfieImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: state.selfieImage == null
                  ? Icon(Icons.face, size: 80, color: Colors.blue[300])
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: notifier.pickSelfie,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Abrir C\u00e1mara Frontal'),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: PremiumButton(
              label: 'Revisar y Enviar',
              color: canProceed ? Colors.blue : Colors.grey,
              onPressed: canProceed ? notifier.nextStep : () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Review(BuildContext context, VerificationState state,
      VerificationNotifier notifier,) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Icon(Icons.shield_outlined, size: 64, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'Listo para verificar',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tus documentos se enviar\u00e1n de forma segura a nuestros servidores para su validaci\u00f3n manual.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const Spacer(),
          if (state.isLoading)
            const CircularProgressIndicator()
          else
            SizedBox(
              width: double.infinity,
              child: PremiumButton(
                label: 'Enviar Verificación',
                color: Colors.blue,
                onPressed: () async {
                   bool success = await notifier.submitVerification();
                   if (success) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Documentos enviados correctamente')),
                     );
                     context.pop(); // GoRouter pop
                   }
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
