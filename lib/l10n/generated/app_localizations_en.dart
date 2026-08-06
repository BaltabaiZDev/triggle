// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TriGrid';

  @override
  String get appTagline =>
      'A tactile strategy game of lines, links, and captured triangles.';

  @override
  String get boardPreviewLabel => 'A miniature triangular peg board';

  @override
  String get playOnOnePhone => 'Play on one phone';

  @override
  String get mainMenuLocalDescription =>
      'Create a pass-and-play match for two to four players.';

  @override
  String get localGameSetupTitle => 'Local game';

  @override
  String get localGameSetupSubtitle =>
      'Choose the board and pass this device between turns.';

  @override
  String get playerCountLabel => 'Players';

  @override
  String get boardSizeLabel => 'Game board';

  @override
  String get boardSizeSmall => 'Small';

  @override
  String get boardSizeClassic => 'Classic board';

  @override
  String get boardSizeLarge => 'Large';

  @override
  String get boardSizeHuge => 'Huge';

  @override
  String get boardSizeCustom => 'Custom size';

  @override
  String get classicBoardDetails =>
      '37 pegs · 54 triangles · bands: 10 for 2 players, 12 for 3–4';

  @override
  String get scaledBoardDetails =>
      'Band and marker supplies scale automatically with board size and player count.';

  @override
  String customRadiusLabel(int radius) {
    return 'Radius $radius';
  }

  @override
  String get startMatch => 'Start match';

  @override
  String playerDefaultName(int number) {
    return 'Player $number';
  }

  @override
  String get turnLabel => 'Turn';

  @override
  String scoreLabel(int count) {
    return 'Score $count';
  }

  @override
  String bandsRemainingLabel(int count) {
    return '$count bands';
  }

  @override
  String markersRemainingLabel(int count) {
    return '$count markers';
  }

  @override
  String get pauseGame => 'Pause';

  @override
  String get resumeGame => 'Resume';

  @override
  String get restartMatch => 'Restart';

  @override
  String get backToSetup => 'Back to setup';

  @override
  String get moveBoard => 'Move board';

  @override
  String get resetCamera => 'Reset camera';

  @override
  String get showHint => 'Show a legal move';

  @override
  String get chooseStartPeg => 'Tap a peg or drag from one to place a band.';

  @override
  String get chooseEndPeg => 'Choose one of the highlighted ending pegs.';

  @override
  String get hintShown => 'A legal move is highlighted.';

  @override
  String get invalidPlacement =>
      'That band cannot be placed here. Use a highlighted peg.';

  @override
  String get moveGameEnded => 'The match has already ended.';

  @override
  String get moveDuplicateAction => 'That action was already processed.';

  @override
  String get moveStaleRevision => 'The board changed. Try the move again.';

  @override
  String get moveNotPlayersTurn => 'It is another player\'s turn.';

  @override
  String get moveNoBandsRemaining => 'This player has no bands remaining.';

  @override
  String get moveUnknownEndpoint =>
      'Both ends must attach to pegs on the board.';

  @override
  String get moveWrongAxis =>
      'Bands must follow one of the three grid directions.';

  @override
  String get moveWrongLength =>
      'A band must span exactly four consecutive pegs.';

  @override
  String get moveOutsideBoard =>
      'The complete band must stay inside the board.';

  @override
  String get moveDuplicateBand => 'That exact band is already on the board.';

  @override
  String get moveAddsNoEdge => 'This band would not add a new edge.';

  @override
  String get moveNotConnected => 'The band must touch the existing network.';

  @override
  String capturedTriangles(int count) {
    return 'Captured $count triangle(s).';
  }

  @override
  String get gamePaused => 'Game paused';

  @override
  String get gamePausedDescription =>
      'Board input is disabled until you resume.';

  @override
  String get matchResultTitle => 'Match complete';

  @override
  String winnerName(String name) {
    return '$name wins!';
  }

  @override
  String tiedWinners(String names) {
    return 'Tie: $names';
  }

  @override
  String get resultMarkerLimit => 'Marker limit reached';

  @override
  String get resultBandsExhausted => 'All bands were played';

  @override
  String get resultNoLegalMoves => 'No legal moves remain';

  @override
  String get finalScores => 'Final scores';

  @override
  String get settingsTitle => 'Sound & motion';

  @override
  String get musicVolume => 'Music';

  @override
  String get soundEffectsVolume => 'Sound effects';

  @override
  String get ambientVolume => 'Ambience';

  @override
  String get muteAll => 'Mute all audio';

  @override
  String get haptics => 'Haptic feedback';

  @override
  String get reducedMotion => 'Reduce motion';

  @override
  String get reducedMotionDescription =>
      'Use instant transitions and disable camera effects.';

  @override
  String get particles => 'Particles & confetti';

  @override
  String get screenShake => 'Capture shake';

  @override
  String get animationSpeed => 'Animation speed';

  @override
  String get replayMatch => 'Replay match';

  @override
  String get replayingMatch => 'Replaying the accepted moves…';

  @override
  String get seatSetupTitle => 'Players & bots';

  @override
  String get humanPlayer => 'Human player';

  @override
  String get botPlayer => 'Bot player';

  @override
  String get botDifficultyLabel => 'Bot difficulty';

  @override
  String get botPersonalityLabel => 'Bot personality';

  @override
  String botThinkingTime(int milliseconds) {
    return 'Thinking time: $milliseconds ms';
  }

  @override
  String get botDifficultyBeginner => 'Beginner';

  @override
  String get botDifficultyEasy => 'Easy';

  @override
  String get botDifficultyNormal => 'Normal';

  @override
  String get botDifficultyHard => 'Hard';

  @override
  String get botDifficultyExpert => 'Expert';

  @override
  String get botPersonalityAggressive => 'Aggressive';

  @override
  String get botPersonalityDefensive => 'Defensive';

  @override
  String get botPersonalityBalanced => 'Balanced';

  @override
  String get botVsBotDebug => 'Set all seats to bots';

  @override
  String botThinkingPlayer(String name) {
    return '$name is thinking…';
  }

  @override
  String get passDeviceTitle => 'Pass the device';

  @override
  String passDeviceDescription(String name) {
    return 'Hand the device to $name. The board is hidden until they are ready.';
  }

  @override
  String get readyForTurn => 'I’m ready';

  @override
  String connectionLatency(int milliseconds) {
    return 'LAN $milliseconds ms';
  }

  @override
  String get connectionReconnecting => 'Reconnecting…';

  @override
  String get connectionDisconnected => 'Disconnected';

  @override
  String get connectionIncompatible => 'Incompatible version';

  @override
  String get connectionClosed => 'Connection closed';

  @override
  String get networkGamePaused => 'LAN match paused';

  @override
  String networkWaitingFor(String names) {
    return 'Waiting for $names to reconnect.';
  }

  @override
  String get networkPlayerReconnected =>
      'Everyone is connected. The host can resume.';

  @override
  String get networkHostWillDecide =>
      'The host can wait, remove the player, or replace them with a bot.';

  @override
  String get replaceWithBot => 'Replace with bot';

  @override
  String get removePlayer => 'Remove player';

  @override
  String get lanPlay => 'Local network';

  @override
  String get lanDescription =>
      'Play together over the same Wi-Fi or one phone’s hotspot.';

  @override
  String get lanMenuTitle => 'LAN multiplayer';

  @override
  String get hostRoom => 'Create a game';

  @override
  String get joinRoom => 'Join a game';

  @override
  String get hostSetupTitle => 'Create LAN game';

  @override
  String get joinSetupTitle => 'Join LAN game';

  @override
  String get playerNameLabel => 'Player name';

  @override
  String get roomNameLabel => 'Room name';

  @override
  String roomDefaultName(String name) {
    return '$name’s room';
  }

  @override
  String get createRoom => 'Create room';

  @override
  String get discoveredRooms => 'Nearby rooms';

  @override
  String get scanningNetwork => 'Scanning the local network…';

  @override
  String get manualJoin => 'Manual IP';

  @override
  String get hostAddressLabel => 'Host address';

  @override
  String get portLabel => 'Port';

  @override
  String get roomCodeLabel => 'Room code';

  @override
  String get scanQr => 'Scan QR code';

  @override
  String get connectToRoom => 'Connect';

  @override
  String get lanConnectionFailed =>
      'Could not connect to the LAN room. Check the address, code, and Wi-Fi.';

  @override
  String get discoveryUnavailable =>
      'Automatic discovery is unavailable. Manual IP and QR joining still work.';

  @override
  String get qrScannerTitle => 'Scan room QR';

  @override
  String get qrInstruction =>
      'Point the camera at the QR code on the host device.';

  @override
  String get invalidRoomQr => 'That is not a compatible TriGrid room code.';

  @override
  String get lobbyTitle => 'Game lobby';

  @override
  String roomCodeDisplay(String code) {
    return 'Room code: $code';
  }

  @override
  String hostAddressDisplay(String address, int port) {
    return 'Host: $address:$port';
  }

  @override
  String playersConnected(int count) {
    return '$count of 4 seats filled';
  }

  @override
  String get hostBadge => 'Host';

  @override
  String get readyStatus => 'Ready';

  @override
  String get notReadyStatus => 'Not ready';

  @override
  String get connectedStatus => 'Connected';

  @override
  String get disconnectedStatus => 'Disconnected';

  @override
  String get openSeat => 'Open seat';

  @override
  String get addBot => 'Add bot';

  @override
  String get removeSeat => 'Remove seat';

  @override
  String botDefaultName(int number) {
    return 'Bot $number';
  }

  @override
  String get waitingForPlayers =>
      'Waiting for every human player to connect and mark ready.';

  @override
  String get startLanMatch => 'Start LAN match';

  @override
  String get playerColorLabel => 'Player color';

  @override
  String get playerColorMoss => 'Moss circle';

  @override
  String get playerColorCoral => 'Coral diamond';

  @override
  String get playerColorBlue => 'Blue triangle';

  @override
  String get playerColorGold => 'Gold square';

  @override
  String get savedLanMatch => 'Saved LAN seat';

  @override
  String get reconnectSavedLan => 'Reconnect';

  @override
  String get forgetSavedLan => 'Forget';

  @override
  String get continueMatch => 'Continue';

  @override
  String get soloPlay => 'Solo vs bots';

  @override
  String get soloSetupTitle => 'Solo game';

  @override
  String get soloSetupSubtitle =>
      'Choose your opponents, bot strength, and game board.';

  @override
  String get confirmMoveTitle => 'Place this band?';

  @override
  String get confirmMoveDescription =>
      'The move becomes final as soon as it is accepted.';

  @override
  String get placeBand => 'Place band';

  @override
  String get appSettingsTitle => 'Settings';

  @override
  String get profileAndLanguage => 'Player & language';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'Device language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKazakh => 'Kazakh';

  @override
  String get languageRussian => 'Russian';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeSystem => 'Follow device';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get highContrast => 'High contrast';

  @override
  String get highContrastDescription =>
      'Use stronger borders and text contrast.';

  @override
  String get playerSymbolsTitle => 'Color-independent markers';

  @override
  String get playerSymbolsDescription =>
      'Every player always has a unique circle, diamond, triangle, or square in addition to color.';

  @override
  String get audioTitle => 'Audio & haptics';

  @override
  String get accessibilityTitle => 'Motion & input';

  @override
  String get confirmMoves => 'Confirm each move';

  @override
  String get confirmMovesDescription =>
      'Ask before submitting a selected band. LAN moves are still final after host acceptance.';

  @override
  String get rulesTitle => 'Rules';

  @override
  String get rulesIntro =>
      'TriGrid is played on a triangular lattice inside a hexagon. Build one connected network of bands and claim the small triangles you complete.';

  @override
  String get rulesGoalTitle => 'Goal';

  @override
  String get rulesGoalBody =>
      'Capture more unit triangles than every opponent. Score is the number of triangles carrying your marker.';

  @override
  String get rulesPlacementTitle => 'Place a band';

  @override
  String get rulesPlacementBody =>
      'A move spans exactly four consecutive aligned pegs—three unit edges—along one of the lattice’s three axes. It must stay on the board and add at least one unused edge.';

  @override
  String get rulesConnectionTitle => 'Keep it connected';

  @override
  String get rulesConnectionBody =>
      'The first band may go anywhere. Every later band must share at least one peg with the existing network. Exact duplicate bands are not allowed; useful partial overlap is allowed.';

  @override
  String get rulesCaptureTitle => 'Capture triangles';

  @override
  String get rulesCaptureBody =>
      'When your new band completes the third boundary of an unclaimed unit triangle, you capture it immediately. One move can capture several triangles.';

  @override
  String get rulesEndingTitle => 'End and winner';

  @override
  String get rulesEndingBody =>
      'The match ends at the marker limit, after the available bands are used, or when no legal move remains. Highest score wins; tied top scores produce a tie.';

  @override
  String get rulesBoardsTitle => 'Boards and supplies';

  @override
  String get rulesBoardsBody =>
      'Classic is radius 3 with 37 pegs and 54 triangles. Two players receive 10 bands each; three or four receive 12. Other board sizes use clearly marked custom supply scaling.';

  @override
  String get botGuideTitle => 'Bot strengths';

  @override
  String get botGuideIntro =>
      'All bots obey the same rules and only see public game state. Higher levels evaluate more replies and defensive consequences; difficulty is not just a delay.';

  @override
  String get botBeginnerDescription =>
      'Mostly random legal play with occasional immediate captures. Fast and intentionally forgiving.';

  @override
  String get botEasyDescription =>
      'Prefers captures and avoids simple gifts, using a shallow tactical evaluation.';

  @override
  String get botNormalDescription =>
      'Balances score, triangles offered to the next player, connections, and blocking with limited lookahead.';

  @override
  String get botHardDescription =>
      'Uses time-bounded iterative deepening, move ordering, caching, and multiplayer search.';

  @override
  String get botExpertDescription =>
      'Searches more deeply within its budget and weighs traps, multi-captures, defense, and opponent responses.';

  @override
  String get botPersonalitiesTitle => 'Personalities';

  @override
  String get botPersonalitiesDescription =>
      'Aggressive values immediate captures, Defensive reduces opportunities for the next player, and Balanced combines both priorities.';

  @override
  String get tutorialTitle => 'Tutorial';

  @override
  String get tutorialPlaceTitle => 'Stretch across four pegs';

  @override
  String get tutorialPlaceBody =>
      'Tap a starting peg and a highlighted ending peg, or drag between them. Every band covers exactly three straight unit edges.';

  @override
  String get tutorialConnectTitle => 'Join the network';

  @override
  String get tutorialConnectBody =>
      'After the first move, every band must touch the connected network at one or more pegs.';

  @override
  String get tutorialCaptureTitle => 'Close a triangle';

  @override
  String get tutorialCaptureBody =>
      'Complete the third side of a small triangle to place your marker and score. A clever band may close several at once.';

  @override
  String get tutorialWinTitle => 'Read the board';

  @override
  String get tutorialWinBody =>
      'Watch supplies, protect future captures, and avoid offering a large reply. The highest final score wins.';

  @override
  String get previousStep => 'Previous';

  @override
  String get nextStep => 'Next';

  @override
  String get startPractice => 'Start practice';

  @override
  String get tutorialBotName => 'Practice bot';

  @override
  String get tutorialGameFirstMove => 'Try a first move anywhere on the board.';

  @override
  String get tutorialGameConnected =>
      'Now keep every new band connected to the network.';

  @override
  String get tutorialGameCapture =>
      'Look for triangles with two completed sides.';

  @override
  String get statisticsTitle => 'Statistics';

  @override
  String get clearStatistics => 'Clear statistics';

  @override
  String get clearStatisticsConfirmation =>
      'Remove every local and LAN statistic? Saved replays are kept.';

  @override
  String get clearAction => 'Clear';

  @override
  String get localStatistics => 'Local matches';

  @override
  String get lanStatistics => 'LAN matches';

  @override
  String get matchesPlayed => 'Matches played';

  @override
  String get wins => 'Wins';

  @override
  String get winRate => 'Win rate';

  @override
  String get capturedTrianglesStat => 'Triangles captured';

  @override
  String get largestMultiCapture => 'Largest multi-capture';

  @override
  String get averageScore => 'Average score';

  @override
  String get winRateByBotLevel => 'Win rate by bot level';

  @override
  String get replayLibraryTitle => 'Replays';

  @override
  String get noReplaysTitle => 'No saved replays';

  @override
  String get noReplaysDescription =>
      'Complete a match and its verified action history will appear here.';

  @override
  String get localMode => 'Local';

  @override
  String get lanMode => 'LAN';

  @override
  String replayMoveCount(int count) {
    return '$count moves';
  }

  @override
  String get replayActions => 'Replay actions';

  @override
  String get playReplay => 'Play replay';

  @override
  String get deleteReplay => 'Delete replay';

  @override
  String get aboutTitle => 'About';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutOriginalWork =>
      'An original Flutter and Flame strategy game with original visuals, generated sounds, and no copied game assets.';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacyBody =>
      'TriGrid works offline. Local matches, settings, statistics, replays, and LAN reconnect credentials stay on this device. LAN play sends game data only to devices in the room and uses no remote gameplay server.';

  @override
  String get thirdPartyLicenses => 'Open-source licenses';

  @override
  String get thirdPartyLicensesDescription =>
      'View licenses for Flutter and included packages.';

  @override
  String get assetCreditsBody =>
      'The shipped sound pack is generated specifically for TriGrid. Asset origins and replacement instructions are recorded in ASSET_LICENSES.md.';

  @override
  String get turnTimerLabel => 'Turn timer';

  @override
  String get turnTimerOff => 'Off';

  @override
  String turnTimerSeconds(int seconds) {
    return '$seconds seconds';
  }

  @override
  String turnTimerCompact(int seconds) {
    return '${seconds}s';
  }

  @override
  String get networkIntegrityError =>
      'State verification failed. Waiting for a valid host snapshot.';

  @override
  String get networkStateResynchronized =>
      'Game state was safely resynchronized with the host.';

  @override
  String get networkReconnectFailed =>
      'Could not reconnect to the host. Check the local network.';

  @override
  String get networkUnexpectedError =>
      'The host rejected that network operation.';

  @override
  String get networkHostEndedTitle => 'The host ended the match';

  @override
  String networkHostEndedDescription(int revision) {
    return 'The last verified position is revision $revision. You can save it on this device.';
  }

  @override
  String get saveLastPosition => 'Save last position';

  @override
  String get exitToMenu => 'Exit to menu';

  @override
  String get networkSnapshotSaved => 'Last verified LAN position saved.';

  @override
  String get networkSnapshotSaveFailed =>
      'That LAN position could not be verified or saved.';

  @override
  String get savedLanPosition => 'Saved LAN position';

  @override
  String get deleteSavedPosition => 'Delete saved position';

  @override
  String networkRevision(int revision) {
    return 'Revision $revision';
  }

  @override
  String get hostAddressExample => '192.168.1.10';

  @override
  String get lanPermissionTitle => 'Allow local network access';

  @override
  String get lanPermissionDescription =>
      'TriGrid needs Nearby devices access on modern Android versions to discover rooms and connect over Wi-Fi. You can continue and use manual IP if discovery is unavailable.';

  @override
  String get openSystemSettings => 'Open settings';

  @override
  String get continueAction => 'Continue';

  @override
  String get debugDiagnosticsTooltip => 'Debug diagnostics';

  @override
  String debugFps(String value) {
    return 'FPS $value';
  }

  @override
  String debugFrameTime(String value) {
    return 'Frame $value ms';
  }

  @override
  String debugLegalMoves(int count) {
    return 'Legal $count';
  }

  @override
  String debugBotNodes(int count) {
    return 'Nodes $count';
  }

  @override
  String debugLanLatency(String value) {
    return 'LAN $value';
  }

  @override
  String debugRevision(int revision) {
    return 'Rev $revision';
  }

  @override
  String debugStateHash(String value) {
    return 'Hash $value';
  }
}
