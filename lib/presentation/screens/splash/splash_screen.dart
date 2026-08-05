import 'package:flutter/material.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';
import 'package:trigrid/presentation/widgets/trigrid_board_mark.dart';
import 'package:trigrid/presentation/widgets/trigrid_game_surface.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: TriGridBackdrop(
        child: SafeArea(
          child: Center(
            child: Semantics(
              liveRegion: true,
              label: l10n.appTitle,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TriGridBoardMark(
                    size: 82,
                    semanticsLabel: l10n.boardPreviewLabel,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.appTitle,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 10),
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
