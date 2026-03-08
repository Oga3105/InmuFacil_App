import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../../widgets/common/app_bar_back_button.dart';
import '../../../providers/offers_provider.dart';
import '../../../providers/auth_provider.dart';

const String _kApiBase = 'http://localhost:8000/api/v1';
const _storage = FlutterSecureStorage();

const _kBlue  = Color(0xFF2563EB);
const _kGreen = Color(0xFF16A34A);
const _kBg    = Color(0xFFF8FAFC);

/// Pantalla Post-Venta y Suministros.
/// - Vendedor: sube las 3 ultimas facturas de Luz, Agua, Gas + info de comunidad.
/// - Comprador: descarga los documentos para el cambio de titularidad.
class PostVentaScreen extends ConsumerStatefulWidget {
  const PostVentaScreen({super.key, required this.offer});

  final OfferData offer;

  @override
  ConsumerState<PostVentaScreen> createState() => _PostVentaScreenState();
}

class _PostVentaScreenState extends ConsumerState<PostVentaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Upload states: null = not started, false = uploading, true = done
  final Map<String, bool?> _uploaded = {
    'electricity': null,
    'water': null,
    'gas': null,
    'ibi': null,
    'community': null,
  };


  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final dio = Dio();
      final resp = await dio.get(
        '$_kApiBase/post-sale/${widget.offer.id}/documents',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (mounted) {
        final docs = List<Map<String, dynamic>>.from(resp.data as List);
        setState(() {
          for (final doc in docs) {
            final key = doc['doc_type'] as String?;
            if (key != null && _uploaded.containsKey(key)) {
              _uploaded[key] = true;
            }
          }
        });
      }
    } catch (_) {
      // Gate not met yet (403) or network error — silently ignore for buyer tab
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _uploadDocument(String docType) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _uploaded[docType] = false); // uploading state

    try {
      final token = await _storage.read(key: 'jwt_token');
      final file  = await MultipartFile.fromFile(
        picked.path,
        filename: picked.name,
      );
      final formData = FormData.fromMap({
        'doc_type': docType,
        'file': file,
      });
      final dio = Dio();
      await dio.post(
        '$_kApiBase/post-sale/${widget.offer.id}/documents',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (!mounted) return;
      setState(() => _uploaded[docType] = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Documento "$docType" subido correctamente.'),
          backgroundColor: _kGreen,
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _uploaded[docType] = null);
      final msg = (e.response?.data as Map?)?['detail'] as String? ??
          'Error al subir el documento.';
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: AppBarBackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text(
          'Post-Venta y Suministros',
          style: TextStyle(
              color: Color(0xFF1E3A5F), fontWeight: FontWeight.bold, fontSize: 17),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: _kBlue,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: _kBlue,
          tabs: const [
            Tab(text: 'Vendedor'),
            Tab(text: 'Comprador'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildSellerTab(isSeller),
          _buildBuyerTab(!isSeller),
        ],
      ),
    );
  }

  Widget _buildSellerTab(bool isCurrentUser) {
    final documents = [
      _DocInfo(
        key: 'electricity',
        label: 'Facturas de Luz (ultimas 3)',
        subtitle: 'Incluye el CUPS electrico',
        icon: Icons.bolt_outlined,
        color: Colors.amber,
      ),
      _DocInfo(
        key: 'water',
        label: 'Facturas de Agua (ultimas 3)',
        subtitle: 'Numero de contrato de agua',
        icon: Icons.water_drop_outlined,
        color: Colors.blue,
      ),
      _DocInfo(
        key: 'gas',
        label: 'Facturas de Gas (ultimas 3)',
        subtitle: 'Incluye el CUPS de gas si aplica',
        icon: Icons.local_fire_department_outlined,
        color: Colors.orange,
      ),
      _DocInfo(
        key: 'community',
        label: 'Info de Comunidad',
        subtitle: 'Contacto del administrador y cuota mensual',
        icon: Icons.apartment_outlined,
        color: _kGreen,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _InfoBanner(
          icon: Icons.upload_file_outlined,
          color: _kBlue,
          message: isCurrentUser
              ? 'Sube las facturas para facilitar al comprador el cambio de titularidad de los suministros.'
              : 'El vendedor esta subiendo la documentacion de suministros.',
        ),
        const SizedBox(height: 20),
        ...documents.map((doc) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _UploadCard(
                doc: doc,
                isUploaded: _uploaded[doc.key] == true,
                isUploading: _uploaded[doc.key] == false,
                canUpload: isCurrentUser,
                onUpload: () => _uploadDocument(doc.key),
              ),
            )),
        const SizedBox(height: 8),
        if (isCurrentUser && _uploaded.values.every((v) => v == true))
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kGreen.withOpacity(0.09),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: const [
                Icon(Icons.check_circle, color: _kGreen),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Toda la documentacion ha sido subida. El comprador ya puede descargarla.',
                    style: TextStyle(
                        color: _kGreen, fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBuyerTab(bool isCurrentUser) {
    final transfers = [
      _TransferInfo(
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
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _InfoBanner(
          icon: Icons.download_outlined,
          color: _kGreen,
          message: isCurrentUser
              ? 'Descarga los documentos del vendedor para gestionar el cambio de titularidad de los suministros.'
              : 'Esta seccion es solo para el comprador.',
        ),
        const SizedBox(height: 20),
        ...transfers.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TransferCard(transfer: t, canDownload: isCurrentUser),
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
    required this.icon,
    required this.color,
  });

  final String key;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _TransferInfo {
  const _TransferInfo({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.steps,
  });

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

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.doc,
    required this.isUploaded,
    required this.canUpload,
    required this.onUpload,
    this.isUploading = false,
  });

  final _DocInfo doc;
  final bool isUploaded;
  final bool isUploading;
  final bool canUpload;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUploaded ? _kGreen.withOpacity(0.4) : Colors.grey.shade200,
        ),
      ),
      child: Row(
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
                        color: Color(0xFF1E3A5F))),
                Text(doc.subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isUploaded)
            const Icon(Icons.check_circle, color: _kGreen, size: 24)
          else if (isUploading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue),
            )
          else if (canUpload)
            TextButton(
              onPressed: onUpload,
              style: TextButton.styleFrom(
                foregroundColor: _kBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Subir'),
            )
          else
            Icon(Icons.hourglass_empty, color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }
}

class _TransferCard extends StatefulWidget {
  const _TransferCard({required this.transfer, required this.canDownload});

  final _TransferInfo transfer;
  final bool canDownload;

  @override
  State<_TransferCard> createState() => _TransferCardState();
}

class _TransferCardState extends State<_TransferCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
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
                    child: Icon(widget.transfer.icon,
                        color: widget.transfer.color, size: 22),
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
                                color: Color(0xFF1E3A5F))),
                        Text(widget.transfer.subtitle,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade400,
                  ),
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
                                child: Text(
                                  '${e.key + 1}',
                                  style: const TextStyle(
                                      color: _kBlue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(e.value,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700)),
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (widget.canDownload)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Descargando documento... (requiere que el vendedor lo haya subido)')),
                          );
                        },
                        icon: const Icon(Icons.download_outlined, size: 16),
                        label: const Text('Descargar'),
                        style: TextButton.styleFrom(foregroundColor: _kBlue),
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
