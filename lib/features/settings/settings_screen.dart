import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/shell.dart';
import '../../core/design/tokens.dart';
import '../../core/haptics.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_mark.dart';
import '../../services/gallery_service.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>((ref) => PackageInfo.fromPlatform());

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmRescan(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-scan all screenshots?'),
        content: const Text('SnapLio will read every screenshot again. Favorites and categories you changed by hand are kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Re-scan')),
        ],
      ),
    );
    if (ok == true) {
      Haptics.medium();
      ref.read(scanServiceProvider).rescanAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Re-scan started — progress shows on Home')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final stats = ref.watch(libraryStatsProvider).value;
    final access = ref.watch(galleryAccessProvider).value;
    final version = ref.watch(_packageInfoProvider).value;
    final topPad = MediaQuery.paddingOf(context).top;
    final c = context.colors;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(Space.screen, topPad + Space.lg, Space.screen, navBarClearance(context)),
        children: [
          Text('Settings', style: context.text.displaySmall),
          const SizedBox(height: Space.lg),
          _Group(title: 'Appearance', children: [
            Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: Brand.violet.withValues(alpha: 0.2),
                    selectedForegroundColor: context.isDark ? Colors.white : Brand.violet,
                    side: BorderSide(color: c.border),
                    minimumSize: const Size(0, 48),
                  ),
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto_rounded)),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_rounded)),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_rounded)),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) {
                    Haptics.selection();
                    ref.read(settingsProvider.notifier).setThemeMode(s.first);
                  },
                ),
              ),
            ),
          ]),
          _Group(title: 'Library', children: [
            _Tile(
              icon: Icons.refresh_rounded,
              title: 'Re-scan all screenshots',
              subtitle: stats == null ? null : '${formatCount(stats.total)} screenshots · ${formatBytes(stats.bytes)}',
              onTap: () => _confirmRescan(context, ref),
            ),
            _Tile(
              icon: Icons.folder_open_rounded,
              title: 'Manage folders',
              subtitle: settings.excludedAlbumIds.isEmpty ? 'All screenshot folders included' : '${settings.excludedAlbumIds.length} excluded',
              onTap: () => context.push(Routes.folders),
            ),
            if (access == GalleryAccess.limited)
              _Tile(
                icon: Icons.visibility_outlined,
                title: 'Allow access to all screenshots',
                subtitle: 'SnapLio can only see some right now',
                onTap: () async {
                  await ref.read(galleryServiceProvider).presentLimitedPicker();
                  final a = await ref.read(galleryAccessProvider.notifier).refresh();
                  if (a.canRead) ref.read(scanServiceProvider).scan();
                },
              ),
          ]),
          _Group(title: 'Privacy', children: [
            Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: c.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.lock_rounded, color: c.success, size: 20),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Everything stays on your device', style: context.text.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          'Everything is processed on your device. Nothing is uploaded. No account, no analytics, no ads.',
                          style: context.text.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]),
          _Group(title: 'About', children: [
            _Tile(
              icon: Icons.star_outline_rounded,
              title: 'Rate SnapLio',
              onTap: () async {
                final id = version?.packageName ?? 'com.snaplio.app';
                final market = Uri.parse('market://details?id=$id');
                if (!await launchUrl(market, mode: LaunchMode.externalApplication)) {
                  await launchUrl(Uri.https('play.google.com', '/store/apps/details', {'id': id}), mode: LaunchMode.externalApplication);
                }
              },
            ),
            _Tile(
              icon: Icons.description_outlined,
              title: 'Open-source licenses',
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'SnapLio',
                applicationVersion: version?.version,
                applicationIcon: const Padding(padding: EdgeInsets.all(12), child: AppMark(size: 56)),
              ),
            ),
            if (kDebugMode)
              _Tile(icon: Icons.bug_report_outlined, title: 'Scan diagnostics', onTap: () => context.push(Routes.debug)),
          ]),
          const SizedBox(height: Space.lg),
          Center(
            child: Column(
              children: [
                const AppMark(size: 40),
                const SizedBox(height: Space.xs),
                Text('SnapLio ${version == null ? '' : 'v${version.version}'}', style: context.text.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: Space.xs),
            child: Text(title.toUpperCase(), style: context.text.labelSmall?.copyWith(letterSpacing: 1.1, color: c.textTertiary)),
          ),
          Material(
            color: c.surface,
            shape: RoundedRectangleBorder(borderRadius: Radii.mdAll, side: BorderSide(color: c.border)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) Divider(indent: 56, color: c.border),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListTile(
      onTap: onTap == null
          ? null
          : () {
              Haptics.light();
              onTap!();
            },
      minTileHeight: 56,
      leading: Icon(icon, color: c.textSecondary),
      title: Text(title, style: context.text.bodyLarge),
      subtitle: subtitle == null ? null : Text(subtitle!, style: context.text.bodySmall),
      trailing: Icon(Icons.chevron_right_rounded, color: c.textTertiary),
    );
  }
}
