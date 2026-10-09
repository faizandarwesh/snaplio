import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/screenshot_repository.dart';
import '../../domain/models.dart';

/// A one-tap action derived from an extracted entity.
class EntityAction {
  const EntityAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.run,
    this.detail,
  });

  final String label;
  final String? detail;
  final IconData icon;
  final Color color;

  /// Returns a confirmation message to show (e.g. "Copied"), or null.
  final Future<String?> Function() run;
}

const _blue = Color(0xFF6B9EF2);
const _teal = Color(0xFF4DBDB3);
const _green = Color(0xFF25D366);
const _violet = Color(0xFF9B87F5);
const _amber = Color(0xFFE8A951);
const _coral = Color(0xFFEE7B6E);
const _slate = Color(0xFF8D9AB0);

Future<String?> _open(Uri uri) async {
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  return ok ? null : 'No app found to open this';
}

Future<String?> _copy(String text, String what) async {
  await Clipboard.setData(ClipboardData(text: text));
  return '$what copied';
}

/// [onOpenLink] records the link as opened (weekly recap: "unread links").
List<EntityAction> actionsFor(List<EntityRow> entities, {void Function(EntityRow link)? onOpenLink}) {
  final byType = <EntityType, List<EntityRow>>{};
  for (final e in entities) {
    final t = EntityType.fromName(e.type);
    if (t != null) byType.putIfAbsent(t, () => []).add(e);
  }
  final out = <EntityAction>[];

  for (final e in byType[EntityType.otp] ?? const <EntityRow>[]) {
    out.add(EntityAction(label: 'Copy OTP', detail: e.displayValue, icon: Icons.password_rounded, color: _violet, run: () => _copy(e.value, 'OTP')));
  }
  for (final e in (byType[EntityType.url] ?? const <EntityRow>[]).take(3)) {
    out.add(EntityAction(
      label: 'Open link',
      detail: e.displayValue,
      icon: Icons.open_in_new_rounded,
      color: _blue,
      run: () async {
        final uri = Uri.tryParse(e.value);
        if (uri == null) return 'Invalid link';
        onOpenLink?.call(e);
        return _open(uri);
      },
    ));
  }
  for (final e in (byType[EntityType.phone] ?? const <EntityRow>[]).take(2)) {
    out.add(EntityAction(label: 'Call', detail: e.displayValue, icon: Icons.call_rounded, color: _teal, run: () => _open(Uri(scheme: 'tel', path: e.value))));
    final digits = e.value.replaceAll(RegExp(r'\D'), '');
    out.add(EntityAction(
      label: 'WhatsApp',
      detail: e.displayValue,
      icon: Icons.chat_rounded,
      color: _green,
      run: () => _open(Uri.parse('https://wa.me/$digits')),
    ));
  }
  for (final e in (byType[EntityType.email] ?? const <EntityRow>[]).take(2)) {
    out.add(EntityAction(label: 'Email', detail: e.displayValue, icon: Icons.mail_outline_rounded, color: _amber, run: () => _open(Uri(scheme: 'mailto', path: e.value))));
  }
  for (final e in (byType[EntityType.address] ?? const <EntityRow>[]).take(1)) {
    out.add(EntityAction(
      label: 'Open in Maps',
      detail: e.displayValue,
      icon: Icons.map_outlined,
      color: _coral,
      run: () async {
        final geo = Uri.parse('geo:0,0?q=${Uri.encodeComponent(e.value)}');
        if (await canLaunchUrl(geo)) return _open(geo);
        return _open(Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': e.value}));
      },
    ));
  }
  for (final e in (byType[EntityType.amount] ?? const <EntityRow>[]).take(2)) {
    out.add(EntityAction(label: 'Copy amount', detail: e.displayValue, icon: Icons.payments_outlined, color: const Color(0xFF5BBF8A), run: () => _copy(e.displayValue, 'Amount')));
  }
  for (final e in (byType[EntityType.tracking] ?? const <EntityRow>[]).take(1)) {
    out.add(EntityAction(label: 'Copy tracking #', detail: e.displayValue, icon: Icons.local_shipping_outlined, color: _slate, run: () => _copy(e.value, 'Tracking number')));
  }
  return out;
}
