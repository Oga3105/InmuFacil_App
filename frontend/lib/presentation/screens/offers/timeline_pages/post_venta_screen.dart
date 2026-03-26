import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/file_downloader.dart';
import '../../../../core/utils/file_drop_zone.dart';

import '../../../widgets/common/app_bar_back_button.dart';
import '../../../providers/offers_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/user_avatar_menu.dart';
import '../../../../core/config/env_config.dart';

const _storage = FlutterSecureStorage();

const _kBlue  = Color(0xFF2563EB);
const _kGreen = Color(0xFF16A34A);
const _kBg    = Color(0xFFF8FAFC);
const _kNavy  = Color(0xFF1E3A5F);

/// Possible delivery statuses for a post-sale document.
/// null       = seller has not acted yet
/// "uploading"= upload in progress (local only)
/// "uploaded" = file available for download
/// "in_person"= seller marked as delivered in person / other means
/// "not_applicable" = seller marked supply as not contracted
typedef DocStatus = String?;

/// Pantalla Post-Venta y Suministros.
/// - Vendedor: sube facturas o marca como entregada en mano / no aplica.
/// - Comprador: descarga documentos (solo si subidos) o ve el estado.
class PostVentaScreen extends ConsumerStatefulWidget {
  const PostVentaScreen({super.key, required this.offer});

  final OfferData offer;

  @override
  ConsumerState<PostVentaScreen> createState() => _PostVentaScreenState();
}

class _PostVentaScreenState extends ConsumerState<PostVentaScreen> {
  bool _isInitializing = true;

  // Status per doc_type: null | "uploading" | "uploaded" | "in_person" | "not_applicable"
  final Map<String, DocStatus> _docStatus = {
    'electricity': null,
    'water': null,
    'gas': null,
    'ibi': null,
    'community': null,
  };

  // Backend doc IDs (only when status == "uploaded"), needed for download URL
  final Map<String, int> _docIds = {};

  // Original filenames from the backend (used to preserve extension on download)
  final Map<String, String> _docFilenames = {};

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final resp = await Dio().get(
        '$EnvConfig.apiBaseUrl/post-sale/${widget.offer.id}/status',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (!mounted) return;
      final data = resp.data as Map<String, dynamic>;
      setState(() {
        data.forEach((key, value) {
          if (!_docStatus.containsKey(key)) return;
          final v = value as Map<String, dynamic>? ?? {};
          _docStatus[key] = v['status'] as String?;
          if (v['doc_id'] != null) {
            _docIds[key] = v['doc_id'] as int;
          }
          if (v['filename'] != null) {
            _docFilenames[key] = v['filename'] as String;
          }
        });
      });
    } catch (_) {
      // Gate not met or network error — silently ignore
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _uploadDocument(String docType) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    await _uploadBytes(docType, bytes, picked.name);
  }

  Future<void> _uploadBytes(String docType, Uint8List bytes, String filename) async {
    setState(() => _docStatus[docType] = 'uploading');
    try {
      final token = await _storage.read(key: 'auth_token');
      final file = MultipartFile.fromBytes(bytes, filename: filename);
      final formData = FormData.fromMap({'doc_type': docType, 'file': file});
      final resp = await Dio().post(
        '$EnvConfig.apiBaseUrl/post-sale/${widget.offer.id}/documents',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (!mounted) return;
      final docId = (resp.data as Map<String, dynamic>)['id'] as int?;
      setState(() {
        _docStatus[docType] = 'uploaded';
        if (docId != null) _docIds[docType] = docId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento subido correctamente.'), backgroundColor: _kGreen),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _docStatus[docType] = null);
      final msg = (e.response?.data as Map?)?['detail'] as String? ?? 'Error al subir.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
      );
    }
  }

  Future<void> _flagDocument(String docType, String flag) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      await Dio().post(
        '$EnvConfig.apiBaseUrl/post-sale/${widget.offer.id}/flag',
        data: {'doc_type': docType, 'flag': flag},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (!mounted) return;
      setState(() => _docStatus[docType] = flag);
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = (e.response?.data as Map?)?['detail'] as String? ?? 'Error al guardar.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final isSeller = currentUser?.id != widget.offer.buyerId;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppBarBackButton(onPressed: () => Navigator.of(context).pop()),
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
                    TextSpan(text: 'Inmu', style: TextStyle(color: Color(0xFF2563EB))),
                    TextSpan(text: 'Fácil', style: TextStyle(color: Color(0xFF16A34A))),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
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
                  Text('Inicio',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final isAuthenticated = ref.watch(authProvider).isAuthenticated;
              if (!isAuthenticated) return const SizedBox.shrink();
              return const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 12),
                  UserAvatarMenu(),
                  SizedBox(width: 16),
                ],
              );
            },
          ),
        ],
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : isSeller
              ? _buildSellerTab(true)
              : _buildBuyerTab(),
    );
  }

  Widget _buildSellerTab(bool isCurrentUser) {
    final documents = [
      _DocInfo(key: 'electricity', label: 'Facturas de Luz (ultimas 3)',
          subtitle: 'Incluye el CUPS electrico',
          noApplicaLabel: 'Sin suministro electrico',
          icon: Icons.bolt_outlined, color: Colors.amber),
      _DocInfo(key: 'water', label: 'Facturas de Agua (ultimas 3)',
          subtitle: 'Numero de contrato de agua',
          noApplicaLabel: 'Sin suministro de agua',
          icon: Icons.water_drop_outlined, color: Colors.blue),
      _DocInfo(key: 'gas', label: 'Facturas de Gas (ultimas 3)',
          subtitle: 'Incluye el CUPS de gas si aplica',
          noApplicaLabel: 'Vivienda sin gas contratado',
          icon: Icons.local_fire_department_outlined, color: Colors.orange),
      _DocInfo(key: 'ibi', label: 'Ultimo recibo del IBI',
          subtitle: 'Impuesto de Bienes Inmuebles',
          noApplicaLabel: 'Exento de IBI (raro, justificar)',
          icon: Icons.account_balance_outlined, color: Colors.purple),
      _DocInfo(key: 'community', label: 'Info de Comunidad',
          subtitle: 'Contacto del administrador y cuota mensual',
          noApplicaLabel: 'Sin comunidad de propietarios',
          icon: Icons.apartment_outlined, color: _kGreen),
    ];

    final allDone = _docStatus.values.every((s) => s != null && s != 'uploading');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _InfoBanner(
          icon: Icons.upload_file_outlined,
          color: _kBlue,
          message: 'Sube las facturas o indica como se entrega cada documento al comprador.',
        ),
        const SizedBox(height: 20),
        ...documents.map((doc) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SellerDocCard(
            doc: doc,
            status: _docStatus[doc.key],
            isCurrentUser: true,
            onUpload: () => _uploadDocument(doc.key),
            onDropBytes: (bytes, name) => _uploadBytes(doc.key, bytes, name),
            onFlag: (flag) => _flagDocument(doc.key, flag),
            onReset: () => setState(() {
              _docStatus[doc.key] = null;
              _docIds.remove(doc.key);
            }),
          ),
        )),
        if (allDone) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: _kGreen),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Toda la documentacion ha sido gestionada. El comprador puede consultar el estado.',
                    style: TextStyle(
                        color: _kGreen, fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBuyerTab() {
    final transfers = [
      _TransferInfo(
        key: 'electricity',
        label: 'Cambio de titular — Electricidad',
        subtitle: 'Con el CUPS del vendedor, llama a tu comercializadora',
        icon: Icons.bolt_outlined,
        color: Colors.amber,
        steps: [
          'Descarga la ultima factura con el CUPS',
          'Contacta con tu comercializadora electrica',
          'Solicita el cambio de titularidad con el CUPS',
          'El proceso suele tardar 5-10 dias habiles',
        ],
      ),
      _TransferInfo(
        key: 'water',
        label: 'Cambio de titular — Agua',
        subtitle: 'Contacta con la empresa municipal de agua',
        icon: Icons.water_drop_outlined,
        color: Colors.blue,
        steps: [
          'Descarga la factura de agua con numero de contrato',
          'Acude a las oficinas de la empresa de agua',
          'Presenta DNI y escrituras de compra',
          'El cambio es inmediato con cita previa',
        ],
      ),
      _TransferInfo(
        key: 'gas',
        label: 'Cambio de titular — Gas',
        subtitle: 'Solo si la vivienda tiene suministro de gas',
        icon: Icons.local_fire_department_outlined,
        color: Colors.orange,
        steps: [
          'Descarga la factura de gas con el CUPS',
          'Llama a tu comercializadora de gas',
          'Solicita cambio de titularidad',
          'Pueden requerir inspeccion de la instalacion',
        ],
      ),
      _TransferInfo(
        key: 'ibi',
        label: 'IBI — Cambio de titular',
        subtitle: 'Impuesto de Bienes Inmuebles municipal',
        icon: Icons.account_balance_outlined,
        color: Colors.purple,
        steps: [
          'Descarga el ultimo recibo del IBI',
          'Acude al ayuntamiento o sede electronica',
          'Solicita el cambio de titular con escrituras y DNI',
          'La modificacion aplica al ejercicio siguiente',
        ],
      ),
      _TransferInfo(
        key: 'community',
        label: 'Comunidad de Propietarios',
        subtitle: 'Contacto del administrador y cuota',
        icon: Icons.apartment_outlined,
        color: const Color(0xFF16A34A),
        steps: [
          'Consulta los datos del administrador de fincas',
          'Notifica el cambio de propietario por escrito',
          'Facilita tu domiciliacion bancaria para la cuota',
          'Solicita el certificado de deudas al dia',
        ],
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _InfoBanner(
          icon: Icons.download_outlined,
          color: _kGreen,
          message: 'Descarga los documentos disponibles para gestionar el cambio de titularidad.',
        ),
        const SizedBox(height: 20),
        ...transfers.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _BuyerTransferCard(
            transfer: t,
            docStatus: _docStatus[t.key],
            docId: _docIds[t.key],
            docFilename: _docFilenames[t.key],
            offerId: widget.offer.id,
            canInteract: true,
            onFlag: (flag) => _flagDocument(t.key, flag),
            onReset: () => setState(() {
              _docStatus[t.key] = null;
              _docIds.remove(t.key);
              _docFilenames.remove(t.key);
            }),
          ),
        )),
      ],
    );
  }
}

// ── Data classes ───────────────────────────────────────────────────────────────

class _DocInfo {
  const _DocInfo({
    required this.key,
    required this.label,
    required this.subtitle,
    required this.noApplicaLabel,
    required this.icon,
    required this.color,
  });

  final String key;
  final String label;
  final String subtitle;
  final String noApplicaLabel;
  final IconData icon;
  final Color color;
}

class _TransferInfo {
  const _TransferInfo({
    required this.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.steps,
  });

  final String key;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> steps;
}

// ── Widgets ────────────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.color, required this.message});

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(color: color.withOpacity(0.9), fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

/// Seller-side card with tri-state actions: upload / in_person / not_applicable.
class _SellerDocCard extends StatelessWidget {
  const _SellerDocCard({
    required this.doc,
    required this.status,
    required this.isCurrentUser,
    required this.onUpload,
    required this.onDropBytes,
    required this.onFlag,
    this.onReset,
  });

  final _DocInfo doc;
  final DocStatus status;
  final bool isCurrentUser;
  final VoidCallback onUpload;
  final FileDropCallback onDropBytes;
  final ValueChanged<String> onFlag;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: doc.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(doc.icon, color: doc.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: _kNavy)),
                    Text(doc.subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              _statusIcon,
            ],
          ),
          // Action area
          if (isCurrentUser) ...[
            const SizedBox(height: 12),
            _buildActionArea(context),
          ],
        ],
      ),
    );
  }

  Color get _borderColor {
    switch (status) {
      case 'uploaded':
        return _kGreen.withOpacity(0.4);
      case 'in_person':
        return _kBlue.withOpacity(0.3);
      case 'not_applicable':
        return Colors.grey.shade300;
      default:
        return Colors.grey.shade200;
    }
  }

  Widget get _statusIcon {
    switch (status) {
      case 'uploaded':
        return const Icon(Icons.check_circle, color: _kGreen, size: 24);
      case 'uploading':
        return const SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue));
      case 'in_person':
        return Icon(Icons.handshake_outlined, color: _kBlue, size: 22);
      case 'not_applicable':
        return Icon(Icons.block_outlined, color: Colors.grey.shade400, size: 22);
      default:
        return Icon(Icons.hourglass_empty, color: Colors.grey.shade400, size: 20);
    }
  }

  Widget _buildActionArea(BuildContext context) {
    if (status == 'uploading') {
      return const Text('Subiendo...', style: TextStyle(fontSize: 12, color: _kBlue));
    }

    if (status == 'uploaded') {
      return _StatusChip(
        icon: Icons.check_circle_outline,
        label: 'Archivo subido',
        color: _kGreen,
        onReset: onReset,
      );
    }

    if (status == 'in_person') {
      return _StatusChip(
        icon: Icons.handshake_outlined,
        label: 'Entregada en mano o por otro medio',
        color: _kBlue,
        onReset: onReset,
      );
    }

    if (status == 'not_applicable') {
      return _StatusChip(
        icon: Icons.block_outlined,
        label: doc.noApplicaLabel,
        color: Colors.grey.shade600,
        onReset: onReset,
      );
    }

    // status == null — show three action buttons + drag-and-drop zone
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _ActionButton(
              icon: Icons.upload_file_outlined,
              label: 'Subir archivo',
              color: _kBlue,
              onTap: onUpload,
            ),
            _ActionButton(
              icon: Icons.handshake_outlined,
              label: 'Entregada en mano',
              color: _kGreen,
              onTap: () => onFlag('in_person'),
            ),
            _ActionButton(
              icon: Icons.block_outlined,
              label: 'No aplica',
              color: Colors.grey.shade600,
              onTap: () => onFlag('not_applicable'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FileDropZone(onDrop: onDropBytes),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onReset,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
        ),
        if (onReset != null)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onReset,
              child: Icon(Icons.edit_outlined, size: 16, color: Colors.grey.shade400),
            ),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

/// Buyer-side expandable card with gated download and optional flag actions.
class _BuyerTransferCard extends StatefulWidget {
  const _BuyerTransferCard({
    required this.transfer,
    required this.docStatus,
    required this.docId,
    required this.offerId,
    required this.canInteract,
    this.docFilename,
    this.onFlag,
    this.onReset,
  });

  final _TransferInfo transfer;
  final DocStatus docStatus;
  final int? docId;
  final String? docFilename;
  final String offerId;
  final bool canInteract;
  final ValueChanged<String>? onFlag;
  final VoidCallback? onReset;

  @override
  State<_BuyerTransferCard> createState() => _BuyerTransferCardState();
}

class _BuyerTransferCardState extends State<_BuyerTransferCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final statusBadge = _buildStatusBadge();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.transfer.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.transfer.icon, color: widget.transfer.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.transfer.label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: _kNavy)),
                        Text(widget.transfer.subtitle,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        if (statusBadge != null) ...[
                          const SizedBox(height: 4),
                          statusBadge,
                        ],
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 8),
                  ...widget.transfer.steps.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _kBlue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Text('${e.key + 1}',
                                style: const TextStyle(
                                    color: _kBlue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(e.value,
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildDownloadArea(context),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget? _buildStatusBadge() {
    switch (widget.docStatus) {
      case 'uploaded':
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle, color: _kGreen, size: 13),
          const SizedBox(width: 4),
          Text('Documento disponible',
              style: TextStyle(fontSize: 11, color: _kGreen, fontWeight: FontWeight.w500)),
        ]);
      case 'in_person':
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.handshake_outlined, color: _kBlue, size: 13),
          const SizedBox(width: 4),
          Text('Entregado en mano por el vendedor',
              style: TextStyle(fontSize: 11, color: _kBlue, fontWeight: FontWeight.w500)),
        ]);
      case 'not_applicable':
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.block_outlined, color: Colors.grey.shade500, size: 13),
          const SizedBox(width: 4),
          Text('No aplica para esta vivienda',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ]);
      default:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.hourglass_empty, color: Colors.orange.shade400, size: 13),
          const SizedBox(width: 4),
          Text('Pendiente del vendedor',
              style: TextStyle(fontSize: 11, color: Colors.orange.shade600)),
        ]);
    }
  }

  bool _isDownloading = false;

  Future<void> _triggerDownload(BuildContext context) async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    try {
      final token = await _storage.read(key: 'auth_token');
      final url =
          '$EnvConfig.apiBaseUrl/post-sale/${widget.offerId}/documents/${widget.docId}/download';

      final response = await Dio().get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final bytes = Uint8List.fromList(response.data ?? []);
      final filename = widget.docFilename ?? 'documento_${widget.transfer.key}';
      await downloadBytes(bytes, filename);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Documento descargado correctamente.'),
          backgroundColor: _kGreen,
          duration: Duration(seconds: 3),
        ),
      );
    } on DioException catch (e) {
      if (!context.mounted) return;
      final msg = (e.response?.data as Map?)?['detail'] as String? ??
          'Error al descargar el documento.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Widget _buildDownloadArea(BuildContext context) {
    final canDownload = widget.canInteract &&
        widget.docStatus == 'uploaded' &&
        widget.docId != null;

    // Non-file delivery flagged — show chip + optional reset (no download needed)
    if (widget.docStatus == 'in_person') {
      return _StatusChip(
        icon: Icons.handshake_outlined,
        label: 'Entregado en mano o por otro medio',
        color: _kBlue,
        onReset: widget.canInteract ? widget.onReset : null,
      );
    }

    if (widget.docStatus == 'not_applicable') {
      return _StatusChip(
        icon: Icons.block_outlined,
        label: 'No aplica para esta vivienda',
        color: Colors.grey.shade600,
        onReset: widget.canInteract ? widget.onReset : null,
      );
    }

    // Build the download row (enabled only when uploaded)
    final downloadRow = Align(
      alignment: Alignment.centerRight,
      child: _isDownloading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue),
            )
          : TextButton.icon(
              onPressed: canDownload ? () => _triggerDownload(context) : null,
              icon: Icon(Icons.download_outlined, size: 16,
                  color: canDownload ? _kBlue : Colors.grey.shade400),
              label: Text(
                'Descargar',
                style: TextStyle(
                    color: canDownload ? _kBlue : Colors.grey.shade400,
                    fontSize: 13),
              ),
              style: TextButton.styleFrom(
                foregroundColor: canDownload ? _kBlue : Colors.grey.shade400,
                disabledForegroundColor: Colors.grey.shade400,
              ),
            ),
    );

    // Pending (null) + buyer can flag → show flag buttons above disabled download
    if (widget.docStatus == null && widget.onFlag != null && widget.canInteract) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _ActionButton(
                icon: Icons.handshake_outlined,
                label: 'Entregado en mano',
                color: _kBlue,
                onTap: () => widget.onFlag!('in_person'),
              ),
              _ActionButton(
                icon: Icons.block_outlined,
                label: 'No aplica',
                color: Colors.grey.shade600,
                onTap: () => widget.onFlag!('not_applicable'),
              ),
            ],
          ),
          downloadRow,
        ],
      );
    }

    // Uploaded or no flag capability → just the download row
    return downloadRow;
  }
}
