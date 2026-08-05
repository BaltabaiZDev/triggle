import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';
import 'package:trigrid/presentation/screens/lan/lan_host_setup_screen.dart';
import 'package:trigrid/presentation/screens/lan/lan_join_screen.dart';
import 'package:trigrid/services/permissions/lan_permission_service.dart';

class LanMenuScreen extends StatelessWidget {
  const LanMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.lanMenuTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _LanActionCard(
                    icon: Icons.wifi_tethering_rounded,
                    title: l10n.hostRoom,
                    onTap: () => _openLanScreen(
                      context,
                      () => const LanHostSetupScreen(),
                    ),
                  ),
                  const SizedBox(height: 7),
                  _LanActionCard(
                    icon: Icons.wifi_find_rounded,
                    title: l10n.joinRoom,
                    onTap: () =>
                        _openLanScreen(context, () => const LanJoinScreen()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openLanScreen(
    BuildContext context,
    Widget Function() destination,
  ) async {
    final permissions = const LanPermissionService();
    final result = await permissions.ensureAccess();
    if (!context.mounted) {
      return;
    }
    if (result == LanPermissionResult.granted) {
      await Get.to<void>(destination);
      return;
    }
    final l10n = AppLocalizations.of(context);
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.lanPermissionTitle),
        content: Text(l10n.lanPermissionDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          if (result == LanPermissionResult.permanentlyDenied)
            TextButton(
              onPressed: () {
                permissions.openSystemSettings();
                Navigator.pop(context, false);
              },
              child: Text(l10n.openSystemSettings),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.continueAction),
          ),
        ],
      ),
    );
    if (proceed == true && context.mounted) {
      await Get.to<void>(destination);
    }
  }
}

class _LanActionCard extends StatelessWidget {
  const _LanActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
