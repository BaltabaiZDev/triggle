// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'TriGrid';

  @override
  String get appTagline =>
      'Тактильная стратегия о линиях, связях и захвате треугольников.';

  @override
  String get boardPreviewLabel =>
      'Миниатюрное треугольное игровое поле с колышками';

  @override
  String get playOnOnePhone => 'Играть на одном телефоне';

  @override
  String get mainMenuLocalDescription =>
      'Создайте матч для двух–четырёх игроков с передачей устройства.';

  @override
  String get localGameSetupTitle => 'Локальная игра';

  @override
  String get localGameSetupSubtitle =>
      'Выберите поле и передавайте устройство после каждого хода.';

  @override
  String get playerCountLabel => 'Игроки';

  @override
  String get boardSizeLabel => 'Игровое поле';

  @override
  String get boardSizeSmall => 'Малое';

  @override
  String get boardSizeClassic => 'Классическое поле';

  @override
  String get boardSizeLarge => 'Большое';

  @override
  String get boardSizeHuge => 'Огромное';

  @override
  String get boardSizeCustom => 'Свой размер';

  @override
  String get classicBoardDetails =>
      '37 колышков · 54 треугольника · резинки: 10 для 2 игроков, 12 для 3–4';

  @override
  String get scaledBoardDetails =>
      'Количество резинок и маркеров автоматически зависит от размера поля и числа игроков.';

  @override
  String customRadiusLabel(int radius) {
    return 'Радиус: $radius';
  }

  @override
  String get startMatch => 'Начать матч';

  @override
  String playerDefaultName(int number) {
    return 'Игрок $number';
  }

  @override
  String get turnLabel => 'Ход';

  @override
  String scoreLabel(int count) {
    return 'Счёт: $count';
  }

  @override
  String bandsRemainingLabel(int count) {
    return 'Резинки: $count';
  }

  @override
  String markersRemainingLabel(int count) {
    return 'Метки: $count';
  }

  @override
  String get pauseGame => 'Пауза';

  @override
  String get resumeGame => 'Продолжить';

  @override
  String get restartMatch => 'Начать заново';

  @override
  String get backToSetup => 'К настройке';

  @override
  String get moveBoard => 'Переместить поле';

  @override
  String get resetCamera => 'Сбросить камеру';

  @override
  String get showHint => 'Показать допустимый ход';

  @override
  String get chooseStartPeg =>
      'Коснитесь колышка или потяните от него, чтобы поставить резинку.';

  @override
  String get chooseEndPeg => 'Выберите один из подсвеченных конечных колышков.';

  @override
  String get hintShown => 'Допустимый ход подсвечен.';

  @override
  String get invalidPlacement =>
      'Здесь нельзя поставить резинку. Выберите подсвеченный колышек.';

  @override
  String get moveGameEnded => 'Матч уже завершён.';

  @override
  String get moveDuplicateAction => 'Это действие уже обработано.';

  @override
  String get moveStaleRevision => 'Поле изменилось. Повторите ход.';

  @override
  String get moveNotPlayersTurn => 'Сейчас ход другого игрока.';

  @override
  String get moveNoBandsRemaining => 'У этого игрока не осталось резинок.';

  @override
  String get moveUnknownEndpoint =>
      'Оба конца должны быть закреплены на колышках игрового поля.';

  @override
  String get moveWrongAxis =>
      'Резинка должна идти по одному из трёх направлений сетки.';

  @override
  String get moveWrongLength =>
      'Резинка должна охватывать ровно четыре соседних колышка.';

  @override
  String get moveOutsideBoard =>
      'Вся резинка должна находиться внутри игрового поля.';

  @override
  String get moveDuplicateBand => 'Такая резинка уже есть на поле.';

  @override
  String get moveAddsNoEdge => 'Эта резинка не добавит нового ребра.';

  @override
  String get moveNotConnected => 'Резинка должна касаться существующей сети.';

  @override
  String capturedTriangles(int count) {
    return 'Захвачено треугольников: $count.';
  }

  @override
  String get gamePaused => 'Игра на паузе';

  @override
  String get gamePausedDescription =>
      'Управление полем отключено до продолжения игры.';

  @override
  String get matchResultTitle => 'Матч завершён';

  @override
  String winnerName(String name) {
    return 'Победитель: $name';
  }

  @override
  String tiedWinners(String names) {
    return 'Ничья: $names';
  }

  @override
  String get resultMarkerLimit => 'Достигнут лимит меток';

  @override
  String get resultBandsExhausted => 'Все резинки сыграны';

  @override
  String get resultNoLegalMoves => 'Допустимых ходов не осталось';

  @override
  String get finalScores => 'Итоговый счёт';

  @override
  String get settingsTitle => 'Звук и движение';

  @override
  String get musicVolume => 'Музыка';

  @override
  String get soundEffectsVolume => 'Звуковые эффекты';

  @override
  String get ambientVolume => 'Фоновый звук';

  @override
  String get muteAll => 'Выключить весь звук';

  @override
  String get haptics => 'Тактильная отдача';

  @override
  String get reducedMotion => 'Уменьшить движение';

  @override
  String get reducedMotionDescription =>
      'Использует мгновенные переходы и отключает эффекты камеры.';

  @override
  String get particles => 'Частицы и конфетти';

  @override
  String get screenShake => 'Встряска при захвате';

  @override
  String get animationSpeed => 'Скорость анимации';

  @override
  String get replayMatch => 'Повтор матча';

  @override
  String get replayingMatch => 'Повтор принятых ходов…';

  @override
  String get seatSetupTitle => 'Игроки и боты';

  @override
  String get humanPlayer => 'Игрок-человек';

  @override
  String get botPlayer => 'Игрок-бот';

  @override
  String get botDifficultyLabel => 'Уровень бота';

  @override
  String get botPersonalityLabel => 'Характер бота';

  @override
  String botThinkingTime(int milliseconds) {
    return 'Время на ход: $milliseconds мс';
  }

  @override
  String get botDifficultyBeginner => 'Новичок';

  @override
  String get botDifficultyEasy => 'Лёгкий';

  @override
  String get botDifficultyNormal => 'Средний';

  @override
  String get botDifficultyHard => 'Сложный';

  @override
  String get botDifficultyExpert => 'Эксперт';

  @override
  String get botPersonalityAggressive => 'Агрессивный';

  @override
  String get botPersonalityDefensive => 'Оборонительный';

  @override
  String get botPersonalityBalanced => 'Сбалансированный';

  @override
  String get botVsBotDebug => 'Сделать все места ботами';

  @override
  String botThinkingPlayer(String name) {
    return '$name думает…';
  }

  @override
  String get passDeviceTitle => 'Передайте устройство';

  @override
  String passDeviceDescription(String name) {
    return 'Передайте устройство игроку $name. Поле скрыто, пока игрок не будет готов.';
  }

  @override
  String get readyForTurn => 'Я готов';

  @override
  String connectionLatency(int milliseconds) {
    return 'LAN $milliseconds мс';
  }

  @override
  String get connectionReconnecting => 'Переподключение…';

  @override
  String get connectionDisconnected => 'Связь потеряна';

  @override
  String get connectionIncompatible => 'Несовместимая версия';

  @override
  String get connectionClosed => 'Соединение закрыто';

  @override
  String get networkGamePaused => 'Матч по LAN приостановлен';

  @override
  String networkWaitingFor(String names) {
    return 'Ожидание переподключения: $names.';
  }

  @override
  String get networkPlayerReconnected =>
      'Все подключены. Хост может продолжить матч.';

  @override
  String get networkHostWillDecide =>
      'Хост может подождать, удалить игрока или заменить его ботом.';

  @override
  String get replaceWithBot => 'Заменить ботом';

  @override
  String get removePlayer => 'Удалить игрока';

  @override
  String get lanPlay => 'Локальная сеть';

  @override
  String get lanDescription =>
      'Играйте через одну сеть Wi-Fi или точку доступа телефона.';

  @override
  String get lanMenuTitle => 'Игра по LAN';

  @override
  String get hostRoom => 'Создать игру';

  @override
  String get joinRoom => 'Присоединиться';

  @override
  String get hostSetupTitle => 'Создать игру по LAN';

  @override
  String get joinSetupTitle => 'Присоединиться к игре';

  @override
  String get playerNameLabel => 'Имя игрока';

  @override
  String get roomNameLabel => 'Название комнаты';

  @override
  String roomDefaultName(String name) {
    return 'Комната игрока $name';
  }

  @override
  String get createRoom => 'Создать комнату';

  @override
  String get discoveredRooms => 'Комнаты рядом';

  @override
  String get scanningNetwork => 'Поиск в локальной сети…';

  @override
  String get manualJoin => 'Подключение по IP';

  @override
  String get hostAddressLabel => 'Адрес хоста';

  @override
  String get portLabel => 'Порт';

  @override
  String get roomCodeLabel => 'Код комнаты';

  @override
  String get scanQr => 'Сканировать QR-код';

  @override
  String get connectToRoom => 'Подключиться';

  @override
  String get lanConnectionFailed =>
      'Не удалось подключиться. Проверьте адрес, код комнаты и Wi-Fi.';

  @override
  String get discoveryUnavailable =>
      'Автопоиск недоступен. Можно подключиться по IP или QR-коду.';

  @override
  String get qrScannerTitle => 'Сканирование QR комнаты';

  @override
  String get qrInstruction => 'Наведите камеру на QR-код на устройстве хоста.';

  @override
  String get invalidRoomQr => 'Это не совместимый код комнаты TriGrid.';

  @override
  String get lobbyTitle => 'Игровая комната';

  @override
  String roomCodeDisplay(String code) {
    return 'Код комнаты: $code';
  }

  @override
  String hostAddressDisplay(String address, int port) {
    return 'Хост: $address:$port';
  }

  @override
  String playersConnected(int count) {
    return 'Занято мест: $count из 4';
  }

  @override
  String get hostBadge => 'Хост';

  @override
  String get readyStatus => 'Готов';

  @override
  String get notReadyStatus => 'Не готов';

  @override
  String get connectedStatus => 'Подключён';

  @override
  String get disconnectedStatus => 'Связь потеряна';

  @override
  String get openSeat => 'Свободное место';

  @override
  String get addBot => 'Добавить бота';

  @override
  String get removeSeat => 'Освободить место';

  @override
  String botDefaultName(int number) {
    return 'Бот $number';
  }

  @override
  String get waitingForPlayers =>
      'Дождитесь подключения и готовности всех игроков.';

  @override
  String get startLanMatch => 'Начать матч по LAN';

  @override
  String get playerColorLabel => 'Цвет игрока';

  @override
  String get playerColorMoss => 'Мшистый круг';

  @override
  String get playerColorCoral => 'Коралловый ромб';

  @override
  String get playerColorBlue => 'Синий треугольник';

  @override
  String get playerColorGold => 'Золотой квадрат';

  @override
  String get savedLanMatch => 'Сохранённое место в LAN';

  @override
  String get reconnectSavedLan => 'Переподключиться';

  @override
  String get forgetSavedLan => 'Забыть';

  @override
  String get continueMatch => 'Продолжить';

  @override
  String get soloPlay => 'Игра с ботами';

  @override
  String get soloSetupTitle => 'Одиночная игра';

  @override
  String get soloSetupSubtitle =>
      'Выберите соперников, силу ботов и игровое поле.';

  @override
  String get confirmMoveTitle => 'Поставить эту резинку?';

  @override
  String get confirmMoveDescription =>
      'Ход станет окончательным сразу после принятия.';

  @override
  String get placeBand => 'Поставить резинку';

  @override
  String get appSettingsTitle => 'Настройки';

  @override
  String get profileAndLanguage => 'Игрок и язык';

  @override
  String get languageLabel => 'Язык';

  @override
  String get languageSystem => 'Язык устройства';

  @override
  String get languageEnglish => 'Английский';

  @override
  String get languageKazakh => 'Казахский';

  @override
  String get languageRussian => 'Русский';

  @override
  String get appearanceTitle => 'Оформление';

  @override
  String get themeLabel => 'Тема';

  @override
  String get themeSystem => 'Как на устройстве';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get highContrast => 'Высокая контрастность';

  @override
  String get highContrastDescription => 'Усилить контраст текста и границ.';

  @override
  String get playerSymbolsTitle => 'Маркеры без зависимости от цвета';

  @override
  String get playerSymbolsDescription =>
      'У каждого игрока всегда есть уникальная фигура: круг, ромб, треугольник или квадрат.';

  @override
  String get audioTitle => 'Звук и вибрация';

  @override
  String get accessibilityTitle => 'Движение и управление';

  @override
  String get confirmMoves => 'Подтверждать каждый ход';

  @override
  String get confirmMovesDescription =>
      'Спрашивать перед отправкой выбранной резинки. Ход по LAN нельзя отменить после принятия хостом.';

  @override
  String get rulesTitle => 'Правила';

  @override
  String get rulesIntro =>
      'TriGrid проходит на треугольной решётке внутри шестиугольника. Стройте единую сеть резинок и забирайте маленькие треугольники, которые замкнули.';

  @override
  String get rulesGoalTitle => 'Цель';

  @override
  String get rulesGoalBody =>
      'Захватите больше единичных треугольников, чем соперники. Счёт равен числу треугольников с вашим маркером.';

  @override
  String get rulesPlacementTitle => 'Установка резинки';

  @override
  String get rulesPlacementBody =>
      'Ход охватывает ровно четыре последовательных колышка — три единичных ребра — вдоль одной из трёх осей решётки. Он должен оставаться на поле и добавлять хотя бы одно новое ребро.';

  @override
  String get rulesConnectionTitle => 'Связная сеть';

  @override
  String get rulesConnectionBody =>
      'Первую резинку можно поставить в любом допустимом месте. Каждая следующая должна касаться существующей сети хотя бы одним колышком. Полный дубликат запрещён, полезное частичное перекрытие разрешено.';

  @override
  String get rulesCaptureTitle => 'Захват треугольников';

  @override
  String get rulesCaptureBody =>
      'Если новая резинка завершает третью сторону свободного маленького треугольника, вы сразу его захватываете. Один ход может закрыть несколько треугольников.';

  @override
  String get rulesEndingTitle => 'Конец игры';

  @override
  String get rulesEndingBody =>
      'Матч заканчивается при достижении лимита маркеров, после использования доступных резинок или когда не осталось допустимых ходов. Побеждает лучший счёт; равные лучшие результаты дают ничью.';

  @override
  String get rulesBoardsTitle => 'Поля и запас';

  @override
  String get rulesBoardsBody =>
      'Классическое поле имеет радиус 3, 37 колышков и 54 треугольника. Два игрока получают по 10 резинок, три или четыре — по 12. Для других размеров действует явно отмеченный расчёт пользовательских запасов.';

  @override
  String get botGuideTitle => 'Сила ботов';

  @override
  String get botGuideIntro =>
      'Все боты соблюдают те же правила и видят только открытое состояние игры. Высокие уровни глубже оценивают ответы и последствия для защиты; сложность — не просто задержка.';

  @override
  String get botBeginnerDescription =>
      'В основном случайные допустимые ходы с редкими немедленными захватами. Быстрый и намеренно снисходительный.';

  @override
  String get botEasyDescription =>
      'Предпочитает захваты и избегает простых подарков, используя неглубокую тактическую оценку.';

  @override
  String get botNormalDescription =>
      'Сочетает счёт, возможности следующего игрока, связи и блокирование с ограниченным просмотром вперёд.';

  @override
  String get botHardDescription =>
      'Использует ограниченное временем углубление, порядок ходов, кэш и многопользовательский поиск.';

  @override
  String get botExpertDescription =>
      'Ищет глубже в рамках бюджета и оценивает ловушки, множественные захваты, защиту и ответы соперников.';

  @override
  String get botPersonalitiesTitle => 'Характеры';

  @override
  String get botPersonalitiesDescription =>
      'Агрессивный ценит быстрый захват, Оборонительный сокращает возможности следующего игрока, а Сбалансированный сочетает оба подхода.';

  @override
  String get tutorialTitle => 'Обучение';

  @override
  String get tutorialPlaceTitle => 'Растяните через четыре колышка';

  @override
  String get tutorialPlaceBody =>
      'Коснитесь начального и подсвеченного конечного колышка или проведите между ними. Каждая резинка покрывает ровно три прямых единичных ребра.';

  @override
  String get tutorialConnectTitle => 'Присоединитесь к сети';

  @override
  String get tutorialConnectBody =>
      'После первого хода каждая резинка должна касаться связной сети одним или несколькими колышками.';

  @override
  String get tutorialCaptureTitle => 'Замкните треугольник';

  @override
  String get tutorialCaptureBody =>
      'Завершите третью сторону маленького треугольника, чтобы поставить маркер и получить очко. Одна резинка может замкнуть сразу несколько.';

  @override
  String get tutorialWinTitle => 'Читайте поле';

  @override
  String get tutorialWinBody =>
      'Следите за запасом, защищайте будущие захваты и не оставляйте сопернику сильный ответ. Побеждает лучший итоговый счёт.';

  @override
  String get previousStep => 'Назад';

  @override
  String get nextStep => 'Далее';

  @override
  String get startPractice => 'Начать практику';

  @override
  String get tutorialBotName => 'Учебный бот';

  @override
  String get tutorialGameFirstMove =>
      'Попробуйте сделать первый ход в любом месте поля.';

  @override
  String get tutorialGameConnected =>
      'Теперь соединяйте каждую новую резинку с сетью.';

  @override
  String get tutorialGameCapture =>
      'Ищите треугольники с двумя готовыми сторонами.';

  @override
  String get statisticsTitle => 'Статистика';

  @override
  String get clearStatistics => 'Очистить статистику';

  @override
  String get clearStatisticsConfirmation =>
      'Удалить всю локальную и LAN-статистику? Сохранённые повторы останутся.';

  @override
  String get clearAction => 'Очистить';

  @override
  String get localStatistics => 'Локальные матчи';

  @override
  String get lanStatistics => 'Матчи по LAN';

  @override
  String get matchesPlayed => 'Сыграно матчей';

  @override
  String get wins => 'Победы';

  @override
  String get winRate => 'Доля побед';

  @override
  String get capturedTrianglesStat => 'Захвачено треугольников';

  @override
  String get largestMultiCapture => 'Лучший множественный захват';

  @override
  String get averageScore => 'Средний счёт';

  @override
  String get winRateByBotLevel => 'Победы по уровню бота';

  @override
  String get replayLibraryTitle => 'Повторы';

  @override
  String get noReplaysTitle => 'Нет сохранённых повторов';

  @override
  String get noReplaysDescription =>
      'Завершите матч, и его проверенная история ходов появится здесь.';

  @override
  String get localMode => 'Локально';

  @override
  String get lanMode => 'LAN';

  @override
  String replayMoveCount(int count) {
    return 'Ходов: $count';
  }

  @override
  String get replayActions => 'Действия с повтором';

  @override
  String get playReplay => 'Воспроизвести';

  @override
  String get deleteReplay => 'Удалить повтор';

  @override
  String get aboutTitle => 'О приложении';

  @override
  String appVersion(String version) {
    return 'Версия $version';
  }

  @override
  String get aboutOriginalWork =>
      'Оригинальная стратегическая игра на Flutter и Flame с собственным оформлением, созданными звуками и без скопированных игровых ресурсов.';

  @override
  String get privacyTitle => 'Конфиденциальность';

  @override
  String get privacyBody =>
      'TriGrid работает без интернета. Локальные матчи, настройки, статистика, повторы и данные переподключения по LAN остаются на устройстве. Игра по LAN отправляет данные только устройствам в комнате и не использует внешний игровой сервер.';

  @override
  String get thirdPartyLicenses => 'Лицензии открытого ПО';

  @override
  String get thirdPartyLicensesDescription =>
      'Просмотреть лицензии Flutter и подключённых пакетов.';

  @override
  String get assetCreditsBody =>
      'Поставляемый набор звуков создан специально для TriGrid. Источники и инструкции по замене записаны в ASSET_LICENSES.md.';

  @override
  String get turnTimerLabel => 'Таймер хода';

  @override
  String get turnTimerOff => 'Выключен';

  @override
  String turnTimerSeconds(int seconds) {
    return '$seconds секунд';
  }

  @override
  String turnTimerCompact(int seconds) {
    return '$seconds с';
  }

  @override
  String get networkIntegrityError =>
      'Не удалось проверить состояние. Ожидание корректного снимка от хоста.';

  @override
  String get networkStateResynchronized =>
      'Состояние игры безопасно синхронизировано с хостом.';

  @override
  String get networkReconnectFailed =>
      'Не удалось подключиться к хосту повторно. Проверьте локальную сеть.';

  @override
  String get networkUnexpectedError => 'Хост отклонил эту сетевую операцию.';

  @override
  String get networkHostEndedTitle => 'Хост завершил матч';

  @override
  String networkHostEndedDescription(int revision) {
    return 'Последняя проверенная позиция — ревизия $revision. Её можно сохранить на этом устройстве.';
  }

  @override
  String get saveLastPosition => 'Сохранить позицию';

  @override
  String get exitToMenu => 'Выйти в меню';

  @override
  String get networkSnapshotSaved =>
      'Последняя проверенная позиция LAN сохранена.';

  @override
  String get networkSnapshotSaveFailed =>
      'Не удалось проверить или сохранить эту позицию LAN.';

  @override
  String get savedLanPosition => 'Сохранённая позиция LAN';

  @override
  String get deleteSavedPosition => 'Удалить сохранённую позицию';

  @override
  String networkRevision(int revision) {
    return 'Ревизия $revision';
  }

  @override
  String get hostAddressExample => '192.168.1.10';

  @override
  String get lanPermissionTitle => 'Разрешить доступ к локальной сети';

  @override
  String get lanPermissionDescription =>
      'В современных версиях Android TriGrid нужен доступ к ближайшим устройствам, чтобы находить комнаты и подключаться по Wi-Fi. Если поиск недоступен, можно продолжить и ввести IP вручную.';

  @override
  String get openSystemSettings => 'Открыть настройки';

  @override
  String get continueAction => 'Продолжить';

  @override
  String get debugDiagnosticsTooltip => 'Отладочная диагностика';

  @override
  String debugFps(String value) {
    return 'FPS $value';
  }

  @override
  String debugFrameTime(String value) {
    return 'Кадр $value мс';
  }

  @override
  String debugLegalMoves(int count) {
    return 'Допустимых: $count';
  }

  @override
  String debugBotNodes(int count) {
    return 'Узлов: $count';
  }

  @override
  String debugLanLatency(String value) {
    return 'LAN $value';
  }

  @override
  String debugRevision(int revision) {
    return 'Рев. $revision';
  }

  @override
  String debugStateHash(String value) {
    return 'Хэш $value';
  }
}
