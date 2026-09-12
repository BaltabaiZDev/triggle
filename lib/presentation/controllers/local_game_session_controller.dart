import 'dart:async';

import 'package:get/get.dart';
import 'package:trigrid/core/ai/trigrid_ai.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/services/game_feel/game_feedback.dart';
import 'package:trigrid/services/game_feel/game_feel_settings.dart';
import 'package:uuid/uuid.dart';

enum BoardPromptType {
  chooseStart,
  chooseEnd,
  hint,
  invalidPlacement,
  validationError,
  captured,
}

class BoardPrompt {
  const BoardPrompt._({
    required this.type,
    this.errorCode,
    this.captureCount = 0,
  });

  const BoardPrompt.chooseStart() : this._(type: BoardPromptType.chooseStart);

  const BoardPrompt.chooseEnd() : this._(type: BoardPromptType.chooseEnd);

  const BoardPrompt.hint() : this._(type: BoardPromptType.hint);

  const BoardPrompt.invalidPlacement()
    : this._(type: BoardPromptType.invalidPlacement);

  const BoardPrompt.validationError(MoveValidationErrorCode errorCode)
    : this._(type: BoardPromptType.validationError, errorCode: errorCode);

  const BoardPrompt.captured(int captureCount)
    : this._(type: BoardPromptType.captured, captureCount: captureCount);

  final BoardPromptType type;
  final MoveValidationErrorCode? errorCode;
  final int captureCount;
}

class LocalGameSessionController extends GetxController {
  LocalGameSessionController(
    GameSettings settings, {
    GameFeedback feedback = const NoopGameFeedback(),
    GameFeelSettings? initialFeelSettings,
    BotMoveProvider botMoveProvider = const BotWorker(),
    this.enablePassAndPlayHandoffs = false,
    this.feedbackPerspectivePlayerId,
    this.disposeFeedbackOnClose = true,
  }) : _settings = settings,
       engine = GameEngine(settings),
       _feedback = feedback,
       _botMoveProvider = botMoveProvider {
    state = engine.createInitialState(settings).obs;
    feelSettings = (initialFeelSettings ?? GameFeelSettings()).obs;
  }

  GameSettings _settings;
  GameSettings get settings => _settings;
  final GameEngine engine;
  final GameFeedback _feedback;
  final BotMoveProvider _botMoveProvider;
  final bool enablePassAndPlayHandoffs;
  final String? feedbackPerspectivePlayerId;
  final bool disposeFeedbackOnClose;
  late final Rx<GameState> state;
  late final Rx<GameFeelSettings> feelSettings;
  final RxBool isPaused = false.obs;
  final RxBool showResult = false.obs;
  final RxBool isReplaying = false.obs;
  final RxBool isBotThinking = false.obs;
  final RxBool awaitingHandoff = false.obs;
  final Rxn<BotDecision> lastBotDecision = Rxn<BotDecision>();
  final Rx<BoardPrompt> prompt = const BoardPrompt.chooseStart().obs;
  final List<SubmitMoveAction> _acceptedActions = [];
  void Function(GameTransition transition)? onAcceptedTransition;
  void Function()? onInvalidFeedback;
  void Function(GameState state)? onStateChanged;
  void Function(
    GameState state,
    List<SubmitMoveAction> actions,
    int largestMultiCapture,
  )?
  onMatchCompleted;

  var _attempt = 0;
  var _largestMultiCapture = 0;
  var _completionReported = false;
  var _presentationGeneration = 0;
  var _automationGeneration = 0;
  Timer? _resultTimer;

  GameState get currentState => state.value;

  bool get canCurrentPlayerInteract =>
      currentState.currentPlayer.controllerType == PlayerControllerType.human;

  List<SubmitMoveAction> get acceptedActions =>
      List<SubmitMoveAction>.unmodifiable(_acceptedActions);

  int get largestMultiCapture => _largestMultiCapture;

  @override
  void onInit() {
    super.onInit();
    playFeedback(_initializeFeedback());
  }

  @override
  void onReady() {
    super.onReady();
    startAutomatedTurnIfNeeded();
  }

  GameTransition? submitMove(GridCoordinate start, GridCoordinate end) {
    if (isPaused.value ||
        isReplaying.value ||
        awaitingHandoff.value ||
        currentState.isGameOver) {
      return null;
    }
    if (currentState.currentPlayer.controllerType == PlayerControllerType.bot) {
      return null;
    }
    return _submitAuthoritativeMove(start, end);
  }

  GameTransition _submitAuthoritativeMove(
    GridCoordinate start,
    GridCoordinate end,
  ) {
    final action = SubmitMoveAction(
      actionId: 'local:${settings.matchId}:${_attempt++}',
      playerId: currentState.currentPlayer.id,
      expectedRevision: currentState.revision,
      start: start,
      end: end,
    );
    final transition = engine.submitMove(currentState, action);
    if (transition.wasAccepted) {
      applyConfirmedTransition(transition);
    } else {
      showValidationError(transition.validation.errorCode!);
    }
    if (transition.wasAccepted) {
      startAutomatedTurnIfNeeded();
    }
    return transition;
  }

  /// Applies a transition already confirmed by an authoritative engine.
  ///
  /// LAN clients use this after verifying the host's state hash so network
  /// moves share the same animation, feedback, result, and replay path as
  /// local moves.
  void applyConfirmedTransition(
    GameTransition transition, {
    bool recordAction = true,
    bool scheduleResult = true,
    bool allowHandoff = true,
  }) {
    if (!transition.wasAccepted) {
      throw ArgumentError.value(
        transition,
        'transition',
        'Only accepted transitions can be presented.',
      );
    }
    if (recordAction &&
        !_acceptedActions.any(
          (action) => action.actionId == transition.action.actionId,
        )) {
      _acceptedActions.add(transition.action);
    }
    _presentAcceptedTransition(
      transition,
      scheduleResult: scheduleResult,
      allowHandoff: allowHandoff,
    );
  }

  void showChooseStart() {
    prompt.value = const BoardPrompt.chooseStart();
  }

  void showChooseEnd() {
    prompt.value = const BoardPrompt.chooseEnd();
  }

  void showHint() {
    prompt.value = const BoardPrompt.hint();
  }

  void showInvalidPlacement() {
    prompt.value = const BoardPrompt.invalidPlacement();
    onInvalidFeedback?.call();
    playFeedback(_feedback.invalidMove());
  }

  void showValidationError(MoveValidationErrorCode code) {
    prompt.value = BoardPrompt.validationError(code);
    onInvalidFeedback?.call();
    playFeedback(_feedback.invalidMove());
  }

  void pegTouch() {
    playFeedback(_feedback.pegTouch());
  }

  void elasticStretch() {
    playFeedback(_feedback.elasticStretch());
  }

  void buttonPress() {
    playFeedback(_feedback.buttonPress());
  }

  void updateFeelSettings(GameFeelSettings next) {
    feelSettings.value = next;
    playFeedback(_feedback.updateSettings(next));
  }

  void setPaused(bool value) {
    isPaused.value = value;
    if (value) {
      _automationGeneration++;
      isBotThinking.value = false;
    } else {
      startAutomatedTurnIfNeeded();
    }
  }

  void restart({bool newRound = true}) {
    _presentationGeneration++;
    _automationGeneration++;
    _resultTimer?.cancel();
    _acceptedActions.clear();
    _attempt = 0;
    _largestMultiCapture = 0;
    _completionReported = false;
    isPaused.value = false;
    isReplaying.value = false;
    isBotThinking.value = false;
    awaitingHandoff.value = false;
    lastBotDecision.value = null;
    showResult.value = false;
    if (newRound) _settings = settings.nextRound(matchId: const Uuid().v4());
    state.value = engine.createInitialState(settings);
    prompt.value = const BoardPrompt.chooseStart();
    onStateChanged?.call(state.value);
    startAutomatedTurnIfNeeded();
  }

  void restoreVerifiedState({
    required GameState restoredState,
    required List<SubmitMoveAction> actions,
    required String expectedHash,
  }) {
    if (restoredState.settings.matchId != settings.matchId ||
        restoredState.isGameOver ||
        GameStateHasher.hash(restoredState) != expectedHash) {
      throw const ReplayVerificationException(
        'Saved match state is not compatible with this session.',
      );
    }
    final replayResult = ReplayRunner.run(
      GameReplay(
        settings: settings,
        actions: actions,
        expectedFinalHash: expectedHash,
      ),
    );
    if (replayResult.finalHash != expectedHash) {
      throw const ReplayVerificationException(
        'Saved actions do not reproduce the saved state.',
      );
    }
    _presentationGeneration++;
    _automationGeneration++;
    _resultTimer?.cancel();
    _acceptedActions
      ..clear()
      ..addAll(actions);
    _attempt = actions.length;
    _largestMultiCapture = _largestCaptureIn(actions);
    _completionReported = false;
    isPaused.value = false;
    isReplaying.value = false;
    isBotThinking.value = false;
    showResult.value = false;
    state.value = restoredState;
    awaitingHandoff.value =
        enablePassAndPlayHandoffs &&
        restoredState.currentPlayer.controllerType ==
            PlayerControllerType.human;
    prompt.value = const BoardPrompt.chooseStart();
  }

  void prepareReplayActions(List<SubmitMoveAction> actions) {
    if (currentState.revision != 0) {
      throw StateError('Replay actions must be loaded into a fresh session.');
    }
    ReplayRunner.run(GameReplay(settings: settings, actions: actions));
    _acceptedActions
      ..clear()
      ..addAll(actions);
    _largestMultiCapture = _largestCaptureIn(actions);
    _completionReported = true;
  }

  Future<void> replayAcceptedActions() async {
    if (isReplaying.value || _acceptedActions.isEmpty) {
      return;
    }
    final actions = List<SubmitMoveAction>.of(_acceptedActions);
    final generation = ++_presentationGeneration;
    _automationGeneration++;
    _resultTimer?.cancel();
    isPaused.value = false;
    isReplaying.value = true;
    isBotThinking.value = false;
    awaitingHandoff.value = false;
    showResult.value = false;
    state.value = engine.createInitialState(settings);
    prompt.value = const BoardPrompt.chooseStart();

    for (final action in actions) {
      if (generation != _presentationGeneration) {
        return;
      }
      final transition = engine.submitMove(currentState, action);
      if (!transition.wasAccepted) {
        isReplaying.value = false;
        return;
      }
      _presentAcceptedTransition(
        transition,
        scheduleResult: false,
        allowHandoff: false,
      );
      final delay = feelSettings.value.reducedMotion
          ? Duration.zero
          : Duration(
              milliseconds: (430 * feelSettings.value.motionScale).round(),
            );
      if (delay != Duration.zero) {
        await Future<void>.delayed(delay);
      }
    }

    if (generation != _presentationGeneration) {
      return;
    }
    isReplaying.value = false;
    if (currentState.matchResult != null) {
      _scheduleResult(generation);
    }
  }

  Future<void> startAutomatedTurnIfNeeded() async {
    if (isPaused.value ||
        isReplaying.value ||
        isBotThinking.value ||
        currentState.isGameOver ||
        awaitingHandoff.value ||
        currentState.currentPlayer.controllerType != PlayerControllerType.bot) {
      return;
    }
    final startingState = currentState;
    final botSettings =
        startingState.currentPlayer.botSettings ?? BotSettings.standard;
    final generation = _automationGeneration;
    isBotThinking.value = true;

    BotDecision? decision;
    try {
      decision = await _botMoveProvider.chooseMove(startingState, botSettings);
    } on Object {
      final fallbackMoves = engine.validator.legalMoves(startingState);
      if (fallbackMoves.isNotEmpty) {
        decision = BotDecision(
          move: fallbackMoves.first,
          difficulty: botSettings.difficulty,
          estimatedValue: 0,
          nodesVisited: 0,
          completedDepth: 0,
          elapsedMilliseconds: 0,
        );
      }
    }

    if (generation != _automationGeneration) return;
    if (isPaused.value ||
        isReplaying.value ||
        currentState.revision != startingState.revision ||
        currentState.currentPlayer.id != startingState.currentPlayer.id) {
      isBotThinking.value = false;
      return;
    }
    isBotThinking.value = false;
    if (decision == null) {
      return;
    }
    final legalMove = engine.board.bandMoveById[decision.move.id];
    if (legalMove == null ||
        !engine.validator
            .legalMoves(currentState)
            .any((move) => move.id == legalMove.id)) {
      return;
    }
    lastBotDecision.value = decision;
    _submitAuthoritativeMove(legalMove.start, legalMove.end);
  }

  void _presentAcceptedTransition(
    GameTransition transition, {
    bool scheduleResult = true,
    bool allowHandoff = true,
  }) {
    state.value = transition.state;
    onAcceptedTransition?.call(transition);
    final captured = transition.validation.newlyCapturedTriangles.length;
    if (captured > _largestMultiCapture) {
      _largestMultiCapture = captured;
    }
    prompt.value = captured == 0
        ? const BoardPrompt.chooseStart()
        : BoardPrompt.captured(captured);

    if (captured > 0) {
      playFeedback(_feedback.capture(captured));
    } else {
      playFeedback(_feedback.elasticSnap());
    }
    final result = transition.state.matchResult;
    if (result != null) {
      if (scheduleResult) {
        _scheduleResult(_presentationGeneration);
      }
    } else {
      playFeedback(_feedback.turnChange());
      if (allowHandoff &&
          enablePassAndPlayHandoffs &&
          transition.state.currentPlayer.controllerType ==
              PlayerControllerType.human &&
          transition.state.currentPlayer.id != transition.action.playerId) {
        awaitingHandoff.value = true;
      }
    }
    onStateChanged?.call(transition.state);
    if (result != null && !_completionReported) {
      _completionReported = true;
      onMatchCompleted?.call(
        transition.state,
        acceptedActions,
        _largestMultiCapture,
      );
    }
  }

  Future<void> _matchEndFeedback(MatchResult result) {
    if (result.isTie) {
      return _feedback.draw();
    }
    final perspectivePlayerId =
        feedbackPerspectivePlayerId ?? _singleHumanPlayerId;
    if (perspectivePlayerId != null &&
        !result.winnerPlayerIds.contains(perspectivePlayerId)) {
      return _feedback.defeat();
    }
    return _feedback.victory();
  }

  String? get _singleHumanPlayerId {
    final humans = settings.players
        .where((player) => player.controllerType == PlayerControllerType.human)
        .toList(growable: false);
    return humans.length == 1 ? humans.single.id : null;
  }

  int _largestCaptureIn(List<SubmitMoveAction> actions) {
    var replayState = engine.createInitialState(settings);
    var largest = 0;
    for (final action in actions) {
      final transition = engine.submitMove(replayState, action);
      if (!transition.wasAccepted) {
        return largest;
      }
      final count = transition.validation.newlyCapturedTriangles.length;
      if (count > largest) {
        largest = count;
      }
      replayState = transition.state;
    }
    return largest;
  }

  void confirmHandoff() {
    if (!awaitingHandoff.value) {
      return;
    }
    buttonPress();
    awaitingHandoff.value = false;
    prompt.value = const BoardPrompt.chooseStart();
    startAutomatedTurnIfNeeded();
  }

  /// Snapshots can follow the final accepted action in the same network burst.
  /// They must neither skip nor continually restart the final-move presentation.
  void presentResultWhenReady() {
    if (currentState.isGameOver) _scheduleResult(_presentationGeneration);
  }

  void _scheduleResult(int generation) {
    if (showResult.value || (_resultTimer?.isActive ?? false)) return;
    if (onAcceptedTransition == null) {
      showResult.value = true;
      playFeedback(_matchEndFeedback(currentState.matchResult!));
      return;
    }
    final delay = feelSettings.value.reducedMotion
        ? const Duration(milliseconds: 700)
        : Duration(
            milliseconds: (1900 * feelSettings.value.motionScale).round().clamp(
              1600,
              3000,
            ),
          );
    _resultTimer = Timer(delay, () {
      if (generation == _presentationGeneration &&
          currentState.matchResult != null) {
        showResult.value = true;
        playFeedback(_matchEndFeedback(currentState.matchResult!));
      }
    });
  }

  Future<void> _initializeFeedback() async {
    await _feedback.initialize(feelSettings.value);
    for (var index = 0; index < settings.players.length; index++) {
      await _feedback.playerJoin();
    }
    await _feedback.countdown();
  }

  @override
  void onClose() {
    _presentationGeneration++;
    _automationGeneration++;
    isBotThinking.value = false;
    _resultTimer?.cancel();
    if (disposeFeedbackOnClose) {
      playFeedback(_feedback.dispose());
    }
    super.onClose();
  }
}
