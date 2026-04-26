import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/entities/property.dart';

class SharePropertyService {
  SharePropertyService._();

  static String propertyUrl(String propertyId) =>
      'https://inmufacil.app/property/$propertyId';

  static String buildShareText(Property property) {
    final buf = StringBuffer();

    buf.writeln('share.message_intro'.tr());
    buf.writeln();
    buf.writeln(property.title);

    final stats = <String>[];
    if (property.bedrooms > 0) {
      stats.add('${property.bedrooms} ${'share.bedrooms_short'.tr()}');
    }
    if (property.bathrooms > 0) {
      stats.add('${property.bathrooms} ${'share.bathrooms_short'.tr()}');
    }
    if (property.squareMeters > 0) {
      stats.add('${property.squareMeters.toStringAsFixed(0)} m\u00B2');
    }
    if (stats.isNotEmpty) buf.writeln(stats.join(' | '));

    buf.writeln(property.formattedPriceFull);

    if (property.isVerified) {
      buf.writeln();
      buf.writeln('share.verified_seller'.tr());
    }

    if (property.energyCertification != null &&
        property.energyCertification!.toUpperCase() != 'EN_TRAMITE') {
      buf.writeln('share.energy_cert'.tr(namedArgs: {
        'rating': property.energyCertification!.toUpperCase(),
      }));
    }

    buf.writeln();
    buf.writeln(
        '${'share.view_property'.tr()}: ${propertyUrl(property.id)}');

    return buf.toString();
  }

  static Future<void> shareViaWhatsApp(Property property) async {
    final text = buildShareText(property);
    final encoded = Uri.encodeComponent(text);
    final uri = Uri.parse('https://wa.me/?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> shareNative(Property property) async {
    final text = buildShareText(property);
    await Share.share(text, subject: property.title);
  }

  static Future<void> copyLink(Property property) async {
    final url = propertyUrl(property.id);
    await Clipboard.setData(ClipboardData(text: url));
  }
}
