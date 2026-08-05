import 'package:flutter/material.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';
import 'package:trigrid/presentation/widgets/trigrid_board_mark.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  TriGridBoardMark(
                    size: 60,
                    semanticsLabel: l10n.boardPreviewLabel,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.appTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(l10n.appVersion('1.0.0')),
                  const SizedBox(height: 4),
                  Text(l10n.aboutOriginalWork, textAlign: TextAlign.center),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.privacyTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 5),
                  Text(l10n.privacyBody),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.thirdPartyLicenses),
              subtitle: Text(l10n.thirdPartyLicensesDescription),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showLicensePage(
                context: context,
                applicationName: l10n.appTitle,
                applicationVersion: '1.0.0',
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(l10n.assetCreditsBody),
            ),
          ],
        ),
      ),
    );
  }
}
