import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'TriGrid'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'A tactile strategy game of lines, links, and captured triangles.'**
  String get appTagline;

  /// No description provided for @boardPreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'A miniature triangular peg board'**
  String get boardPreviewLabel;

  /// No description provided for @playOnOnePhone.
  ///
  /// In en, this message translates to:
  /// **'Play on one phone'**
  String get playOnOnePhone;

  /// No description provided for @mainMenuLocalDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a pass-and-play match for two to four players.'**
  String get mainMenuLocalDescription;

  /// No description provided for @localGameSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Local game'**
  String get localGameSetupTitle;

  /// No description provided for @localGameSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the board and pass this device between turns.'**
  String get localGameSetupSubtitle;

  /// No description provided for @playerCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get playerCountLabel;

  /// No description provided for @boardSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Game board'**
  String get boardSizeLabel;

  /// No description provided for @boardSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get boardSizeSmall;

  /// No description provided for @boardSizeClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic board'**
  String get boardSizeClassic;

  /// No description provided for @boardSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get boardSizeLarge;

  /// No description provided for @boardSizeHuge.
  ///
  /// In en, this message translates to:
  /// **'Huge'**
  String get boardSizeHuge;

  /// No description provided for @boardSizeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom size'**
  String get boardSizeCustom;

  /// No description provided for @classicBoardDetails.
  ///
  /// In en, this message translates to:
  /// **'37 pegs · 54 triangles · bands: 10 for 2 players, 12 for 3–4'**
  String get classicBoardDetails;

  /// No description provided for @scaledBoardDetails.
  ///
  /// In en, this message translates to:
  /// **'Band and marker supplies scale automatically with board size and player count.'**
  String get scaledBoardDetails;

  /// No description provided for @customRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Radius {radius}'**
  String customRadiusLabel(int radius);

  /// No description provided for @startMatch.
  ///
  /// In en, this message translates to:
  /// **'Start match'**
  String get startMatch;

  /// No description provided for @playerDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Player {number}'**
  String playerDefaultName(int number);

  /// No description provided for @turnLabel.
  ///
  /// In en, this message translates to:
  /// **'Turn'**
  String get turnLabel;

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score {count}'**
  String scoreLabel(int count);

  /// No description provided for @bandsRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} bands'**
  String bandsRemainingLabel(int count);

  /// No description provided for @markersRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} markers'**
  String markersRemainingLabel(int count);

  /// No description provided for @pauseGame.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseGame;

  /// No description provided for @resumeGame.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeGame;

  /// No description provided for @restartMatch.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restartMatch;

  /// No description provided for @backToSetup.
  ///
  /// In en, this message translates to:
  /// **'Back to setup'**
  String get backToSetup;

  /// No description provided for @moveBoard.
  ///
  /// In en, this message translates to:
  /// **'Move board'**
  String get moveBoard;

  /// No description provided for @resetCamera.
  ///
  /// In en, this message translates to:
  /// **'Reset camera'**
  String get resetCamera;

  /// No description provided for @showHint.
  ///
  /// In en, this message translates to:
  /// **'Show a legal move'**
  String get showHint;

  /// No description provided for @chooseStartPeg.
  ///
  /// In en, this message translates to:
  /// **'Tap a peg or drag from one to place a band.'**
  String get chooseStartPeg;

  /// No description provided for @chooseEndPeg.
  ///
  /// In en, this message translates to:
  /// **'Choose one of the highlighted ending pegs.'**
  String get chooseEndPeg;

  /// No description provided for @hintShown.
  ///
  /// In en, this message translates to:
  /// **'A legal move is highlighted.'**
  String get hintShown;

  /// No description provided for @invalidPlacement.
  ///
  /// In en, this message translates to:
  /// **'That band cannot be placed here. Use a highlighted peg.'**
  String get invalidPlacement;

  /// No description provided for @moveGameEnded.
  ///
  /// In en, this message translates to:
  /// **'The match has already ended.'**
  String get moveGameEnded;

  /// No description provided for @moveDuplicateAction.
  ///
  /// In en, this message translates to:
  /// **'That action was already processed.'**
  String get moveDuplicateAction;

  /// No description provided for @moveStaleRevision.
  ///
  /// In en, this message translates to:
  /// **'The board changed. Try the move again.'**
  String get moveStaleRevision;

  /// No description provided for @moveNotPlayersTurn.
  ///
  /// In en, this message translates to:
  /// **'It is another player\'s turn.'**
  String get moveNotPlayersTurn;

  /// No description provided for @moveNoBandsRemaining.
  ///
  /// In en, this message translates to:
  /// **'This player has no bands remaining.'**
  String get moveNoBandsRemaining;

  /// No description provided for @moveUnknownEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Both ends must attach to pegs on the board.'**
  String get moveUnknownEndpoint;

  /// No description provided for @moveWrongAxis.
  ///
  /// In en, this message translates to:
  /// **'Bands must follow one of the three grid directions.'**
  String get moveWrongAxis;

  /// No description provided for @moveWrongLength.
  ///
  /// In en, this message translates to:
  /// **'A band must span exactly four consecutive pegs.'**
  String get moveWrongLength;

  /// No description provided for @moveOutsideBoard.
  ///
  /// In en, this message translates to:
  /// **'The complete band must stay inside the board.'**
  String get moveOutsideBoard;

  /// No description provided for @moveDuplicateBand.
  ///
  /// In en, this message translates to:
  /// **'That exact band is already on the board.'**
  String get moveDuplicateBand;

  /// No description provided for @moveAddsNoEdge.
  ///
  /// In en, this message translates to:
  /// **'This band would not add a new edge.'**
  String get moveAddsNoEdge;

  /// No description provided for @moveNotConnected.
  ///
  /// In en, this message translates to:
  /// **'The band must touch the existing network.'**
  String get moveNotConnected;

  /// No description provided for @capturedTriangles.
  ///
  /// In en, this message translates to:
  /// **'Captured {count} triangle(s).'**
  String capturedTriangles(int count);

  /// No description provided for @gamePaused.
  ///
  /// In en, this message translates to:
  /// **'Game paused'**
  String get gamePaused;

  /// No description provided for @gamePausedDescription.
  ///
  /// In en, this message translates to:
  /// **'Board input is disabled until you resume.'**
  String get gamePausedDescription;

  /// No description provided for @matchResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Match complete'**
  String get matchResultTitle;

  /// No description provided for @winnerName.
  ///
  /// In en, this message translates to:
  /// **'{name} wins!'**
  String winnerName(String name);

  /// No description provided for @tiedWinners.
  ///
  /// In en, this message translates to:
  /// **'Tie: {names}'**
  String tiedWinners(String names);

  /// No description provided for @resultMarkerLimit.
  ///
  /// In en, this message translates to:
  /// **'Marker limit reached'**
  String get resultMarkerLimit;

  /// No description provided for @resultBandsExhausted.
  ///
  /// In en, this message translates to:
  /// **'All bands were played'**
  String get resultBandsExhausted;

  /// No description provided for @resultNoLegalMoves.
  ///
  /// In en, this message translates to:
  /// **'No legal moves remain'**
  String get resultNoLegalMoves;

  /// No description provided for @finalScores.
  ///
  /// In en, this message translates to:
  /// **'Final scores'**
  String get finalScores;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sound & motion'**
  String get settingsTitle;

  /// No description provided for @musicVolume.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get musicVolume;

  /// No description provided for @soundEffectsVolume.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get soundEffectsVolume;

  /// No description provided for @ambientVolume.
  ///
  /// In en, this message translates to:
  /// **'Ambience'**
  String get ambientVolume;

  /// No description provided for @muteAll.
  ///
  /// In en, this message translates to:
  /// **'Mute all audio'**
  String get muteAll;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get haptics;

  /// No description provided for @reducedMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get reducedMotion;

  /// No description provided for @reducedMotionDescription.
  ///
  /// In en, this message translates to:
  /// **'Use instant transitions and disable camera effects.'**
  String get reducedMotionDescription;

  /// No description provided for @particles.
  ///
  /// In en, this message translates to:
  /// **'Particles & confetti'**
  String get particles;

  /// No description provided for @screenShake.
  ///
  /// In en, this message translates to:
  /// **'Capture shake'**
  String get screenShake;

  /// No description provided for @animationSpeed.
  ///
  /// In en, this message translates to:
  /// **'Animation speed'**
  String get animationSpeed;

  /// No description provided for @replayMatch.
  ///
  /// In en, this message translates to:
  /// **'Replay match'**
  String get replayMatch;

  /// No description provided for @replayingMatch.
  ///
  /// In en, this message translates to:
  /// **'Replaying the accepted moves…'**
  String get replayingMatch;

  /// No description provided for @seatSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Players & bots'**
  String get seatSetupTitle;

  /// No description provided for @humanPlayer.
  ///
  /// In en, this message translates to:
  /// **'Human player'**
  String get humanPlayer;

  /// No description provided for @botPlayer.
  ///
  /// In en, this message translates to:
  /// **'Bot player'**
  String get botPlayer;

  /// No description provided for @botDifficultyLabel.
  ///
  /// In en, this message translates to:
  /// **'Bot difficulty'**
  String get botDifficultyLabel;

  /// No description provided for @botPersonalityLabel.
  ///
  /// In en, this message translates to:
  /// **'Bot personality'**
  String get botPersonalityLabel;

  /// No description provided for @botThinkingTime.
  ///
  /// In en, this message translates to:
  /// **'Thinking time: {milliseconds} ms'**
  String botThinkingTime(int milliseconds);

  /// No description provided for @botDifficultyBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get botDifficultyBeginner;

  /// No description provided for @botDifficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get botDifficultyEasy;

  /// No description provided for @botDifficultyNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get botDifficultyNormal;

  /// No description provided for @botDifficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get botDifficultyHard;

  /// No description provided for @botDifficultyExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get botDifficultyExpert;

  /// No description provided for @botPersonalityAggressive.
  ///
  /// In en, this message translates to:
  /// **'Aggressive'**
  String get botPersonalityAggressive;

  /// No description provided for @botPersonalityDefensive.
  ///
  /// In en, this message translates to:
  /// **'Defensive'**
  String get botPersonalityDefensive;

  /// No description provided for @botPersonalityBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get botPersonalityBalanced;

  /// No description provided for @botVsBotDebug.
  ///
  /// In en, this message translates to:
  /// **'Set all seats to bots'**
  String get botVsBotDebug;

  /// No description provided for @botThinkingPlayer.
  ///
  /// In en, this message translates to:
  /// **'{name} is thinking…'**
  String botThinkingPlayer(String name);

  /// No description provided for @passDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Pass the device'**
  String get passDeviceTitle;

  /// No description provided for @passDeviceDescription.
  ///
  /// In en, this message translates to:
  /// **'Hand the device to {name}. The board is hidden until they are ready.'**
  String passDeviceDescription(String name);

  /// No description provided for @readyForTurn.
  ///
  /// In en, this message translates to:
  /// **'I’m ready'**
  String get readyForTurn;

  /// No description provided for @connectionLatency.
  ///
  /// In en, this message translates to:
  /// **'LAN {milliseconds} ms'**
  String connectionLatency(int milliseconds);

  /// No description provided for @connectionReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get connectionReconnecting;

  /// No description provided for @connectionDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get connectionDisconnected;

  /// No description provided for @connectionIncompatible.
  ///
  /// In en, this message translates to:
  /// **'Incompatible version'**
  String get connectionIncompatible;

  /// No description provided for @connectionClosed.
  ///
  /// In en, this message translates to:
  /// **'Connection closed'**
  String get connectionClosed;

  /// No description provided for @networkGamePaused.
  ///
  /// In en, this message translates to:
  /// **'LAN match paused'**
  String get networkGamePaused;

  /// No description provided for @networkWaitingFor.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {names} to reconnect.'**
  String networkWaitingFor(String names);

  /// No description provided for @networkPlayerReconnected.
  ///
  /// In en, this message translates to:
  /// **'Everyone is connected. The host can resume.'**
  String get networkPlayerReconnected;

  /// No description provided for @networkHostWillDecide.
  ///
  /// In en, this message translates to:
  /// **'The host can wait, remove the player, or replace them with a bot.'**
  String get networkHostWillDecide;

  /// No description provided for @replaceWithBot.
  ///
  /// In en, this message translates to:
  /// **'Replace with bot'**
  String get replaceWithBot;

  /// No description provided for @removePlayer.
  ///
  /// In en, this message translates to:
  /// **'Remove player'**
  String get removePlayer;

  /// No description provided for @lanPlay.
  ///
  /// In en, this message translates to:
  /// **'Local network'**
  String get lanPlay;

  /// No description provided for @lanDescription.
  ///
  /// In en, this message translates to:
  /// **'Play together over the same Wi-Fi or one phone’s hotspot.'**
  String get lanDescription;

  /// No description provided for @lanMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'LAN multiplayer'**
  String get lanMenuTitle;

  /// No description provided for @hostRoom.
  ///
  /// In en, this message translates to:
  /// **'Create a game'**
  String get hostRoom;

  /// No description provided for @joinRoom.
  ///
  /// In en, this message translates to:
  /// **'Join a game'**
  String get joinRoom;

  /// No description provided for @hostSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create LAN game'**
  String get hostSetupTitle;

  /// No description provided for @joinSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Join LAN game'**
  String get joinSetupTitle;

  /// No description provided for @playerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Player name'**
  String get playerNameLabel;

  /// No description provided for @roomNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Room name'**
  String get roomNameLabel;

  /// No description provided for @roomDefaultName.
  ///
  /// In en, this message translates to:
  /// **'{name}’s room'**
  String roomDefaultName(String name);

  /// No description provided for @createRoom.
  ///
  /// In en, this message translates to:
  /// **'Create room'**
  String get createRoom;

  /// No description provided for @discoveredRooms.
  ///
  /// In en, this message translates to:
  /// **'Nearby rooms'**
  String get discoveredRooms;

  /// No description provided for @scanningNetwork.
  ///
  /// In en, this message translates to:
  /// **'Scanning the local network…'**
  String get scanningNetwork;

  /// No description provided for @manualJoin.
  ///
  /// In en, this message translates to:
  /// **'Manual IP'**
  String get manualJoin;

  /// No description provided for @hostAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Host address'**
  String get hostAddressLabel;

  /// No description provided for @portLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get portLabel;

  /// No description provided for @roomCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Room code'**
  String get roomCodeLabel;

  /// No description provided for @scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanQr;

  /// No description provided for @connectToRoom.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectToRoom;

  /// No description provided for @lanConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the LAN room. Check the address, code, and Wi-Fi.'**
  String get lanConnectionFailed;

  /// No description provided for @discoveryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Automatic discovery is unavailable. Manual IP and QR joining still work.'**
  String get discoveryUnavailable;

  /// No description provided for @qrScannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan room QR'**
  String get qrScannerTitle;

  /// No description provided for @qrInstruction.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the QR code on the host device.'**
  String get qrInstruction;

  /// No description provided for @invalidRoomQr.
  ///
  /// In en, this message translates to:
  /// **'That is not a compatible TriGrid room code.'**
  String get invalidRoomQr;

  /// No description provided for @lobbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Game lobby'**
  String get lobbyTitle;

  /// No description provided for @roomCodeDisplay.
  ///
  /// In en, this message translates to:
  /// **'Room code: {code}'**
  String roomCodeDisplay(String code);

  /// No description provided for @hostAddressDisplay.
  ///
  /// In en, this message translates to:
  /// **'Host: {address}:{port}'**
  String hostAddressDisplay(String address, int port);

  /// No description provided for @playersConnected.
  ///
  /// In en, this message translates to:
  /// **'{count} of 4 seats filled'**
  String playersConnected(int count);

  /// No description provided for @hostBadge.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get hostBadge;

  /// No description provided for @readyStatus.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get readyStatus;

  /// No description provided for @notReadyStatus.
  ///
  /// In en, this message translates to:
  /// **'Not ready'**
  String get notReadyStatus;

  /// No description provided for @connectedStatus.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connectedStatus;

  /// No description provided for @disconnectedStatus.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnectedStatus;

  /// No description provided for @openSeat.
  ///
  /// In en, this message translates to:
  /// **'Open seat'**
  String get openSeat;

  /// No description provided for @addBot.
  ///
  /// In en, this message translates to:
  /// **'Add bot'**
  String get addBot;

  /// No description provided for @removeSeat.
  ///
  /// In en, this message translates to:
  /// **'Remove seat'**
  String get removeSeat;

  /// No description provided for @botDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Bot {number}'**
  String botDefaultName(int number);

  /// No description provided for @waitingForPlayers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for every human player to connect and mark ready.'**
  String get waitingForPlayers;

  /// No description provided for @startLanMatch.
  ///
  /// In en, this message translates to:
  /// **'Start LAN match'**
  String get startLanMatch;

  /// No description provided for @playerColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Player color'**
  String get playerColorLabel;

  /// No description provided for @playerColorMoss.
  ///
  /// In en, this message translates to:
  /// **'Moss circle'**
  String get playerColorMoss;

  /// No description provided for @playerColorCoral.
  ///
  /// In en, this message translates to:
  /// **'Coral diamond'**
  String get playerColorCoral;

  /// No description provided for @playerColorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue triangle'**
  String get playerColorBlue;

  /// No description provided for @playerColorGold.
  ///
  /// In en, this message translates to:
  /// **'Gold square'**
  String get playerColorGold;

  /// No description provided for @savedLanMatch.
  ///
  /// In en, this message translates to:
  /// **'Saved LAN seat'**
  String get savedLanMatch;

  /// No description provided for @reconnectSavedLan.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnectSavedLan;

  /// No description provided for @forgetSavedLan.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get forgetSavedLan;

  /// No description provided for @continueMatch.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueMatch;

  /// No description provided for @soloPlay.
  ///
  /// In en, this message translates to:
  /// **'Solo vs bots'**
  String get soloPlay;

  /// No description provided for @soloSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Solo game'**
  String get soloSetupTitle;

  /// No description provided for @soloSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your opponents, bot strength, and game board.'**
  String get soloSetupSubtitle;

  /// No description provided for @confirmMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Place this band?'**
  String get confirmMoveTitle;

  /// No description provided for @confirmMoveDescription.
  ///
  /// In en, this message translates to:
  /// **'The move becomes final as soon as it is accepted.'**
  String get confirmMoveDescription;

  /// No description provided for @placeBand.
  ///
  /// In en, this message translates to:
  /// **'Place band'**
  String get placeBand;

  /// No description provided for @appSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get appSettingsTitle;

  /// No description provided for @profileAndLanguage.
  ///
  /// In en, this message translates to:
  /// **'Player & language'**
  String get profileAndLanguage;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageKazakh.
  ///
  /// In en, this message translates to:
  /// **'Kazakh'**
  String get languageKazakh;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get languageRussian;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow device'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @highContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get highContrast;

  /// No description provided for @highContrastDescription.
  ///
  /// In en, this message translates to:
  /// **'Use stronger borders and text contrast.'**
  String get highContrastDescription;

  /// No description provided for @playerSymbolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Color-independent markers'**
  String get playerSymbolsTitle;

  /// No description provided for @playerSymbolsDescription.
  ///
  /// In en, this message translates to:
  /// **'Every player always has a unique circle, diamond, triangle, or square in addition to color.'**
  String get playerSymbolsDescription;

  /// No description provided for @audioTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio & haptics'**
  String get audioTitle;

  /// No description provided for @accessibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Motion & input'**
  String get accessibilityTitle;

  /// No description provided for @confirmMoves.
  ///
  /// In en, this message translates to:
  /// **'Confirm each move'**
  String get confirmMoves;

  /// No description provided for @confirmMovesDescription.
  ///
  /// In en, this message translates to:
  /// **'Ask before submitting a selected band. LAN moves are still final after host acceptance.'**
  String get confirmMovesDescription;

  /// No description provided for @rulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get rulesTitle;

  /// No description provided for @rulesIntro.
  ///
  /// In en, this message translates to:
  /// **'TriGrid is played on a triangular lattice inside a hexagon. Build one connected network of bands and claim the small triangles you complete.'**
  String get rulesIntro;

  /// No description provided for @rulesGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get rulesGoalTitle;

  /// No description provided for @rulesGoalBody.
  ///
  /// In en, this message translates to:
  /// **'Capture more unit triangles than every opponent. Score is the number of triangles carrying your marker.'**
  String get rulesGoalBody;

  /// No description provided for @rulesPlacementTitle.
  ///
  /// In en, this message translates to:
  /// **'Place a band'**
  String get rulesPlacementTitle;

  /// No description provided for @rulesPlacementBody.
  ///
  /// In en, this message translates to:
  /// **'A move spans exactly four consecutive aligned pegs—three unit edges—along one of the lattice’s three axes. It must stay on the board and add at least one unused edge.'**
  String get rulesPlacementBody;

  /// No description provided for @rulesConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep it connected'**
  String get rulesConnectionTitle;

  /// No description provided for @rulesConnectionBody.
  ///
  /// In en, this message translates to:
  /// **'The first band may go anywhere. Every later band must share at least one peg with the existing network. Exact duplicate bands are not allowed; useful partial overlap is allowed.'**
  String get rulesConnectionBody;

  /// No description provided for @rulesCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Capture triangles'**
  String get rulesCaptureTitle;

  /// No description provided for @rulesCaptureBody.
  ///
  /// In en, this message translates to:
  /// **'When your new band completes the third boundary of an unclaimed unit triangle, you capture it immediately. One move can capture several triangles.'**
  String get rulesCaptureBody;

  /// No description provided for @rulesEndingTitle.
  ///
  /// In en, this message translates to:
  /// **'End and winner'**
  String get rulesEndingTitle;

  /// No description provided for @rulesEndingBody.
  ///
  /// In en, this message translates to:
  /// **'The match ends at the marker limit, after the available bands are used, or when no legal move remains. Highest score wins; tied top scores produce a tie.'**
  String get rulesEndingBody;

  /// No description provided for @rulesBoardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Boards and supplies'**
  String get rulesBoardsTitle;

  /// No description provided for @rulesBoardsBody.
  ///
  /// In en, this message translates to:
  /// **'Classic is radius 3 with 37 pegs and 54 triangles. Two players receive 10 bands each; three or four receive 12. Other board sizes use clearly marked custom supply scaling.'**
  String get rulesBoardsBody;

  /// No description provided for @botGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Bot strengths'**
  String get botGuideTitle;

  /// No description provided for @botGuideIntro.
  ///
  /// In en, this message translates to:
  /// **'All bots obey the same rules and only see public game state. Higher levels evaluate more replies and defensive consequences; difficulty is not just a delay.'**
  String get botGuideIntro;

  /// No description provided for @botBeginnerDescription.
  ///
  /// In en, this message translates to:
  /// **'Mostly random legal play with occasional immediate captures. Fast and intentionally forgiving.'**
  String get botBeginnerDescription;

  /// No description provided for @botEasyDescription.
  ///
  /// In en, this message translates to:
  /// **'Prefers captures and avoids simple gifts, using a shallow tactical evaluation.'**
  String get botEasyDescription;

  /// No description provided for @botNormalDescription.
  ///
  /// In en, this message translates to:
  /// **'Balances score, triangles offered to the next player, connections, and blocking with limited lookahead.'**
  String get botNormalDescription;

  /// No description provided for @botHardDescription.
  ///
  /// In en, this message translates to:
  /// **'Uses time-bounded iterative deepening, move ordering, caching, and multiplayer search.'**
  String get botHardDescription;

  /// No description provided for @botExpertDescription.
  ///
  /// In en, this message translates to:
  /// **'Searches more deeply within its budget and weighs traps, multi-captures, defense, and opponent responses.'**
  String get botExpertDescription;

  /// No description provided for @botPersonalitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Personalities'**
  String get botPersonalitiesTitle;

  /// No description provided for @botPersonalitiesDescription.
  ///
  /// In en, this message translates to:
  /// **'Aggressive values immediate captures, Defensive reduces opportunities for the next player, and Balanced combines both priorities.'**
  String get botPersonalitiesDescription;

  /// No description provided for @tutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get tutorialTitle;

  /// No description provided for @tutorialPlaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Stretch across four pegs'**
  String get tutorialPlaceTitle;

  /// No description provided for @tutorialPlaceBody.
  ///
  /// In en, this message translates to:
  /// **'Tap a starting peg and a highlighted ending peg, or drag between them. Every band covers exactly three straight unit edges.'**
  String get tutorialPlaceBody;

  /// No description provided for @tutorialConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Join the network'**
  String get tutorialConnectTitle;

  /// No description provided for @tutorialConnectBody.
  ///
  /// In en, this message translates to:
  /// **'After the first move, every band must touch the connected network at one or more pegs.'**
  String get tutorialConnectBody;

  /// No description provided for @tutorialCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Close a triangle'**
  String get tutorialCaptureTitle;

  /// No description provided for @tutorialCaptureBody.
  ///
  /// In en, this message translates to:
  /// **'Complete the third side of a small triangle to place your marker and score. A clever band may close several at once.'**
  String get tutorialCaptureBody;

  /// No description provided for @tutorialWinTitle.
  ///
  /// In en, this message translates to:
  /// **'Read the board'**
  String get tutorialWinTitle;

  /// No description provided for @tutorialWinBody.
  ///
  /// In en, this message translates to:
  /// **'Watch supplies, protect future captures, and avoid offering a large reply. The highest final score wins.'**
  String get tutorialWinBody;

  /// No description provided for @previousStep.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousStep;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextStep;

  /// No description provided for @startPractice.
  ///
  /// In en, this message translates to:
  /// **'Start practice'**
  String get startPractice;

  /// No description provided for @tutorialBotName.
  ///
  /// In en, this message translates to:
  /// **'Practice bot'**
  String get tutorialBotName;

  /// No description provided for @tutorialGameFirstMove.
  ///
  /// In en, this message translates to:
  /// **'Try a first move anywhere on the board.'**
  String get tutorialGameFirstMove;

  /// No description provided for @tutorialGameConnected.
  ///
  /// In en, this message translates to:
  /// **'Now keep every new band connected to the network.'**
  String get tutorialGameConnected;

  /// No description provided for @tutorialGameCapture.
  ///
  /// In en, this message translates to:
  /// **'Look for triangles with two completed sides.'**
  String get tutorialGameCapture;

  /// No description provided for @statisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statisticsTitle;

  /// No description provided for @clearStatistics.
  ///
  /// In en, this message translates to:
  /// **'Clear statistics'**
  String get clearStatistics;

  /// No description provided for @clearStatisticsConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Remove every local and LAN statistic? Saved replays are kept.'**
  String get clearStatisticsConfirmation;

  /// No description provided for @clearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearAction;

  /// No description provided for @localStatistics.
  ///
  /// In en, this message translates to:
  /// **'Local matches'**
  String get localStatistics;

  /// No description provided for @lanStatistics.
  ///
  /// In en, this message translates to:
  /// **'LAN matches'**
  String get lanStatistics;

  /// No description provided for @matchesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Matches played'**
  String get matchesPlayed;

  /// No description provided for @wins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get wins;

  /// No description provided for @winRate.
  ///
  /// In en, this message translates to:
  /// **'Win rate'**
  String get winRate;

  /// No description provided for @capturedTrianglesStat.
  ///
  /// In en, this message translates to:
  /// **'Triangles captured'**
  String get capturedTrianglesStat;

  /// No description provided for @largestMultiCapture.
  ///
  /// In en, this message translates to:
  /// **'Largest multi-capture'**
  String get largestMultiCapture;

  /// No description provided for @averageScore.
  ///
  /// In en, this message translates to:
  /// **'Average score'**
  String get averageScore;

  /// No description provided for @winRateByBotLevel.
  ///
  /// In en, this message translates to:
  /// **'Win rate by bot level'**
  String get winRateByBotLevel;

  /// No description provided for @replayLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Replays'**
  String get replayLibraryTitle;

  /// No description provided for @noReplaysTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved replays'**
  String get noReplaysTitle;

  /// No description provided for @noReplaysDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete a match and its verified action history will appear here.'**
  String get noReplaysDescription;

  /// No description provided for @localMode.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get localMode;

  /// No description provided for @lanMode.
  ///
  /// In en, this message translates to:
  /// **'LAN'**
  String get lanMode;

  /// No description provided for @replayMoveCount.
  ///
  /// In en, this message translates to:
  /// **'{count} moves'**
  String replayMoveCount(int count);

  /// No description provided for @replayActions.
  ///
  /// In en, this message translates to:
  /// **'Replay actions'**
  String get replayActions;

  /// No description provided for @playReplay.
  ///
  /// In en, this message translates to:
  /// **'Play replay'**
  String get playReplay;

  /// No description provided for @deleteReplay.
  ///
  /// In en, this message translates to:
  /// **'Delete replay'**
  String get deleteReplay;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// No description provided for @aboutOriginalWork.
  ///
  /// In en, this message translates to:
  /// **'An original Flutter and Flame strategy game with original visuals, generated sounds, and no copied game assets.'**
  String get aboutOriginalWork;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'TriGrid works offline. Local matches, settings, statistics, replays, and LAN reconnect credentials stay on this device. LAN play sends game data only to devices in the room and uses no remote gameplay server.'**
  String get privacyBody;

  /// No description provided for @thirdPartyLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get thirdPartyLicenses;

  /// No description provided for @thirdPartyLicensesDescription.
  ///
  /// In en, this message translates to:
  /// **'View licenses for Flutter and included packages.'**
  String get thirdPartyLicensesDescription;

  /// No description provided for @assetCreditsBody.
  ///
  /// In en, this message translates to:
  /// **'The shipped sound pack is generated specifically for TriGrid. Asset origins and replacement instructions are recorded in ASSET_LICENSES.md.'**
  String get assetCreditsBody;

  /// No description provided for @turnTimerLabel.
  ///
  /// In en, this message translates to:
  /// **'Turn timer'**
  String get turnTimerLabel;

  /// No description provided for @turnTimerOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get turnTimerOff;

  /// No description provided for @turnTimerSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String turnTimerSeconds(int seconds);

  /// No description provided for @turnTimerCompact.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String turnTimerCompact(int seconds);

  /// No description provided for @networkIntegrityError.
  ///
  /// In en, this message translates to:
  /// **'State verification failed. Waiting for a valid host snapshot.'**
  String get networkIntegrityError;

  /// No description provided for @networkStateResynchronized.
  ///
  /// In en, this message translates to:
  /// **'Game state was safely resynchronized with the host.'**
  String get networkStateResynchronized;

  /// No description provided for @networkReconnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reconnect to the host. Check the local network.'**
  String get networkReconnectFailed;

  /// No description provided for @networkUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'The host rejected that network operation.'**
  String get networkUnexpectedError;

  /// No description provided for @networkHostEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'The host ended the match'**
  String get networkHostEndedTitle;

  /// No description provided for @networkHostEndedDescription.
  ///
  /// In en, this message translates to:
  /// **'The last verified position is revision {revision}. You can save it on this device.'**
  String networkHostEndedDescription(int revision);

  /// No description provided for @saveLastPosition.
  ///
  /// In en, this message translates to:
  /// **'Save last position'**
  String get saveLastPosition;

  /// No description provided for @exitToMenu.
  ///
  /// In en, this message translates to:
  /// **'Exit to menu'**
  String get exitToMenu;

  /// No description provided for @networkSnapshotSaved.
  ///
  /// In en, this message translates to:
  /// **'Last verified LAN position saved.'**
  String get networkSnapshotSaved;

  /// No description provided for @networkSnapshotSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'That LAN position could not be verified or saved.'**
  String get networkSnapshotSaveFailed;

  /// No description provided for @savedLanPosition.
  ///
  /// In en, this message translates to:
  /// **'Saved LAN position'**
  String get savedLanPosition;

  /// No description provided for @deleteSavedPosition.
  ///
  /// In en, this message translates to:
  /// **'Delete saved position'**
  String get deleteSavedPosition;

  /// No description provided for @networkRevision.
  ///
  /// In en, this message translates to:
  /// **'Revision {revision}'**
  String networkRevision(int revision);

  /// No description provided for @hostAddressExample.
  ///
  /// In en, this message translates to:
  /// **'192.168.1.10'**
  String get hostAddressExample;

  /// No description provided for @lanPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow local network access'**
  String get lanPermissionTitle;

  /// No description provided for @lanPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'TriGrid needs Nearby devices access on modern Android versions to discover rooms and connect over Wi-Fi. You can continue and use manual IP if discovery is unavailable.'**
  String get lanPermissionDescription;

  /// No description provided for @openSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSystemSettings;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @debugDiagnosticsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Debug diagnostics'**
  String get debugDiagnosticsTooltip;

  /// No description provided for @debugFps.
  ///
  /// In en, this message translates to:
  /// **'FPS {value}'**
  String debugFps(String value);

  /// No description provided for @debugFrameTime.
  ///
  /// In en, this message translates to:
  /// **'Frame {value} ms'**
  String debugFrameTime(String value);

  /// No description provided for @debugLegalMoves.
  ///
  /// In en, this message translates to:
  /// **'Legal {count}'**
  String debugLegalMoves(int count);

  /// No description provided for @debugBotNodes.
  ///
  /// In en, this message translates to:
  /// **'Nodes {count}'**
  String debugBotNodes(int count);

  /// No description provided for @debugLanLatency.
  ///
  /// In en, this message translates to:
  /// **'LAN {value}'**
  String debugLanLatency(String value);

  /// No description provided for @debugRevision.
  ///
  /// In en, this message translates to:
  /// **'Rev {revision}'**
  String debugRevision(int revision);

  /// No description provided for @debugStateHash.
  ///
  /// In en, this message translates to:
  /// **'Hash {value}'**
  String debugStateHash(String value);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
