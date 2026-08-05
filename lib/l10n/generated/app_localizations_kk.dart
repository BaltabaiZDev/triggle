// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get appTitle => 'TriGrid';

  @override
  String get appTagline =>
      'Сызықтар, байланыстар және иеленген үшбұрыштар туралы тактикалық ойын.';

  @override
  String get boardPreviewLabel => 'Үшбұрышты қазықтары бар шағын ойын алаңы';

  @override
  String get playOnOnePhone => 'Бір телефонда ойнау';

  @override
  String get mainMenuLocalDescription =>
      'Екіден төрт ойыншыға дейін кезекпен ойнайтын ойын құрыңыз.';

  @override
  String get localGameSetupTitle => 'Жергілікті ойын';

  @override
  String get localGameSetupSubtitle =>
      'Ойын алаңын таңдап, әр кезектен кейін құрылғыны келесі ойыншыға беріңіз.';

  @override
  String get playerCountLabel => 'Ойыншылар';

  @override
  String get boardSizeLabel => 'Ойын алаңы';

  @override
  String get rulesetLabel => 'Ережелер';

  @override
  String get boardSizeSmall => 'Кіші';

  @override
  String get boardSizeClassic => 'Классикалық';

  @override
  String get boardSizeLarge => 'Үлкен';

  @override
  String get boardSizeHuge => 'Өте үлкен';

  @override
  String get boardSizeCustom => 'Арнайы';

  @override
  String get classicRules => 'Классикалық ережелер';

  @override
  String get customRules => 'Арнайы ережелер';

  @override
  String customRadiusLabel(int radius) {
    return 'Радиусы: $radius';
  }

  @override
  String get startMatch => 'Ойынды бастау';

  @override
  String playerDefaultName(int number) {
    return 'Ойыншы $number';
  }

  @override
  String get turnLabel => 'Кезек';

  @override
  String scoreLabel(int count) {
    return 'Ұпай: $count';
  }

  @override
  String bandsRemainingLabel(int count) {
    return '$count таспа';
  }

  @override
  String markersRemainingLabel(int count) {
    return '$count белгі';
  }

  @override
  String get pauseGame => 'Кідірту';

  @override
  String get resumeGame => 'Жалғастыру';

  @override
  String get restartMatch => 'Қайта бастау';

  @override
  String get backToSetup => 'Баптауға оралу';

  @override
  String get moveBoard => 'Алаңды жылжыту';

  @override
  String get resetCamera => 'Камераны қалпына келтіру';

  @override
  String get showHint => 'Жарамды жүрісті көрсету';

  @override
  String get chooseStartPeg =>
      'Қазықты түртіңіз немесе таспаны орнату үшін одан сүйреңіз.';

  @override
  String get chooseEndPeg => 'Белгіленген соңғы қазықтардың бірін таңдаңыз.';

  @override
  String get hintShown => 'Жарамды жүріс белгіленді.';

  @override
  String get invalidPlacement =>
      'Бұл жерге таспа қоюға болмайды. Белгіленген қазықты таңдаңыз.';

  @override
  String get moveGameEnded => 'Ойын аяқталды.';

  @override
  String get moveDuplicateAction => 'Бұл әрекет бұрын өңделген.';

  @override
  String get moveStaleRevision => 'Ойын алаңы өзгерді. Жүрісті қайталаңыз.';

  @override
  String get moveNotPlayersTurn => 'Қазір басқа ойыншының кезегі.';

  @override
  String get moveNoBandsRemaining => 'Бұл ойыншыда таспа қалмады.';

  @override
  String get moveUnknownEndpoint =>
      'Таспаның екі ұшы да алаңдағы қазықтарға бекітілуі керек.';

  @override
  String get moveWrongAxis => 'Таспа тордың үш бағытының бірімен жүруі керек.';

  @override
  String get moveWrongLength =>
      'Таспа қатар тұрған дәл төрт қазықты қамтуы керек.';

  @override
  String get moveOutsideBoard =>
      'Таспа толығымен ойын алаңының ішінде болуы керек.';

  @override
  String get moveDuplicateBand => 'Мұндай таспа алаңда бар.';

  @override
  String get moveAddsNoEdge => 'Бұл таспа жаңа қыр қоспайды.';

  @override
  String get moveNotConnected => 'Таспа бар желіге жанасуы керек.';

  @override
  String capturedTriangles(int count) {
    return '$count үшбұрыш иеленді.';
  }

  @override
  String get gamePaused => 'Ойын кідіртілді';

  @override
  String get gamePausedDescription =>
      'Жалғастырғанша ойын алаңын басқару өшірілді.';

  @override
  String get matchResultTitle => 'Ойын аяқталды';

  @override
  String winnerName(String name) {
    return 'Жеңімпаз: $name';
  }

  @override
  String tiedWinners(String names) {
    return 'Тең ойын: $names';
  }

  @override
  String get resultMarkerLimit => 'Белгілер шегіне жетті';

  @override
  String get resultBandsExhausted => 'Барлық таспа ойналды';

  @override
  String get resultNoLegalMoves => 'Жарамды жүріс қалмады';

  @override
  String get finalScores => 'Қорытынды ұпайлар';

  @override
  String get settingsTitle => 'Дыбыс және қозғалыс';

  @override
  String get musicVolume => 'Музыка';

  @override
  String get soundEffectsVolume => 'Дыбыс әсерлері';

  @override
  String get ambientVolume => 'Қоршаған дыбыс';

  @override
  String get muteAll => 'Барлық дыбысты өшіру';

  @override
  String get haptics => 'Діріл кері байланысы';

  @override
  String get reducedMotion => 'Қозғалысты азайту';

  @override
  String get reducedMotionDescription =>
      'Лезде ауысуды қолданып, камера әсерлерін өшіреді.';

  @override
  String get particles => 'Бөлшектер мен конфетти';

  @override
  String get screenShake => 'Иелену кезіндегі діріл';

  @override
  String get animationSpeed => 'Анимация жылдамдығы';

  @override
  String get replayMatch => 'Ойынды қайталау';

  @override
  String get replayingMatch => 'Қабылданған жүрістер қайталануда…';

  @override
  String get seatSetupTitle => 'Ойыншылар мен боттар';

  @override
  String get humanPlayer => 'Адам ойыншы';

  @override
  String get botPlayer => 'Бот ойыншы';

  @override
  String get botDifficultyLabel => 'Бот деңгейі';

  @override
  String get botPersonalityLabel => 'Бот мінезі';

  @override
  String botThinkingTime(int milliseconds) {
    return 'Ойлану уақыты: $milliseconds мс';
  }

  @override
  String get botDifficultyBeginner => 'Бастаушы';

  @override
  String get botDifficultyEasy => 'Жеңіл';

  @override
  String get botDifficultyNormal => 'Қалыпты';

  @override
  String get botDifficultyHard => 'Қиын';

  @override
  String get botDifficultyExpert => 'Сарапшы';

  @override
  String get botPersonalityAggressive => 'Шабуылшыл';

  @override
  String get botPersonalityDefensive => 'Қорғанысшыл';

  @override
  String get botPersonalityBalanced => 'Теңгерімді';

  @override
  String get botVsBotDebug => 'Барлық орынды бот ету';

  @override
  String botThinkingPlayer(String name) {
    return '$name ойланып жатыр…';
  }

  @override
  String get passDeviceTitle => 'Құрылғыны беріңіз';

  @override
  String passDeviceDescription(String name) {
    return 'Құрылғыны $name ойыншысына беріңіз. Ол дайын болғанша алаң жасырын тұрады.';
  }

  @override
  String get readyForTurn => 'Мен дайынмын';

  @override
  String connectionLatency(int milliseconds) {
    return 'Жергілікті желі $milliseconds мс';
  }

  @override
  String get connectionReconnecting => 'Қайта қосылу…';

  @override
  String get connectionDisconnected => 'Байланыс үзілді';

  @override
  String get connectionIncompatible => 'Нұсқалар сәйкес емес';

  @override
  String get connectionClosed => 'Байланыс жабылды';

  @override
  String get networkGamePaused => 'Жергілікті желідегі ойын кідіртілді';

  @override
  String networkWaitingFor(String names) {
    return '$names қайта қосылғанша күту.';
  }

  @override
  String get networkPlayerReconnected =>
      'Барлығы қосылды. Хост ойынды жалғастыра алады.';

  @override
  String get networkHostWillDecide =>
      'Хост күте алады, ойыншыны шығарады немесе ботпен алмастырады.';

  @override
  String get replaceWithBot => 'Ботпен алмастыру';

  @override
  String get removePlayer => 'Ойыншыны шығару';

  @override
  String get lanPlay => 'Жергілікті желі';

  @override
  String get lanDescription =>
      'Бір Wi-Fi желісінде немесе бір телефонның хотспоты арқылы ойнаңыз.';

  @override
  String get lanMenuTitle => 'Желілік ойын';

  @override
  String get hostRoom => 'Ойын құру';

  @override
  String get joinRoom => 'Ойынға қосылу';

  @override
  String get hostSetupTitle => 'Желілік ойын құру';

  @override
  String get joinSetupTitle => 'Желілік ойынға қосылу';

  @override
  String get playerNameLabel => 'Ойыншы аты';

  @override
  String get roomNameLabel => 'Бөлме атауы';

  @override
  String roomDefaultName(String name) {
    return '$name бөлмесі';
  }

  @override
  String get createRoom => 'Бөлме құру';

  @override
  String get discoveredRooms => 'Жақын бөлмелер';

  @override
  String get scanningNetwork => 'Жергілікті желі ізделуде…';

  @override
  String get manualJoin => 'IP арқылы қосылу';

  @override
  String get hostAddressLabel => 'Хост мекенжайы';

  @override
  String get portLabel => 'Порт';

  @override
  String get roomCodeLabel => 'Бөлме коды';

  @override
  String get scanQr => 'QR кодын сканерлеу';

  @override
  String get connectToRoom => 'Қосылу';

  @override
  String get lanConnectionFailed =>
      'Желілік бөлмеге қосылмады. Мекенжайды, кодты және Wi-Fi желісін тексеріңіз.';

  @override
  String get discoveryUnavailable =>
      'Автоматты іздеу қолжетімсіз. IP және QR арқылы қосылу жұмыс істейді.';

  @override
  String get qrScannerTitle => 'Бөлме QR кодын сканерлеу';

  @override
  String get qrInstruction =>
      'Камераны хост құрылғысындағы QR кодына бағыттаңыз.';

  @override
  String get invalidRoomQr => 'Бұл TriGrid бөлмесінің үйлесімді коды емес.';

  @override
  String get lobbyTitle => 'Ойын бөлмесі';

  @override
  String roomCodeDisplay(String code) {
    return 'Бөлме коды: $code';
  }

  @override
  String hostAddressDisplay(String address, int port) {
    return 'Хост: $address:$port';
  }

  @override
  String playersConnected(int count) {
    return '4 орынның $count орны толды';
  }

  @override
  String get hostBadge => 'Хост';

  @override
  String get readyStatus => 'Дайын';

  @override
  String get notReadyStatus => 'Дайын емес';

  @override
  String get connectedStatus => 'Қосылды';

  @override
  String get disconnectedStatus => 'Байланыс үзілді';

  @override
  String get openSeat => 'Бос орын';

  @override
  String get addBot => 'Бот қосу';

  @override
  String get removeSeat => 'Орынды босату';

  @override
  String botDefaultName(int number) {
    return 'Бот $number';
  }

  @override
  String get waitingForPlayers =>
      'Барлық адам ойыншы қосылып, дайын екенін белгілегенше күтіңіз.';

  @override
  String get startLanMatch => 'Желілік ойынды бастау';

  @override
  String get playerColorLabel => 'Ойыншы түсі';

  @override
  String get playerColorMoss => 'Мүк түсті шеңбер';

  @override
  String get playerColorCoral => 'Маржан түсті ромб';

  @override
  String get playerColorBlue => 'Көк үшбұрыш';

  @override
  String get playerColorGold => 'Алтын түсті шаршы';

  @override
  String get savedLanMatch => 'Сақталған желілік орын';

  @override
  String get reconnectSavedLan => 'Қайта қосылу';

  @override
  String get forgetSavedLan => 'Ұмыту';

  @override
  String get continueMatch => 'Жалғастыру';

  @override
  String get soloPlay => 'Боттарға қарсы';

  @override
  String get soloSetupTitle => 'Жеке ойын';

  @override
  String get soloSetupSubtitle =>
      'Қарсыластарды, бот күшін және ойын алаңын таңдаңыз.';

  @override
  String get confirmMoveTitle => 'Осы резеңкені орналастыру керек пе?';

  @override
  String get confirmMoveDescription =>
      'Жүріс қабылданған сәттен бастап қайтарылмайды.';

  @override
  String get placeBand => 'Резеңкені орналастыру';

  @override
  String get appSettingsTitle => 'Баптаулар';

  @override
  String get profileAndLanguage => 'Ойыншы және тіл';

  @override
  String get languageLabel => 'Тіл';

  @override
  String get languageSystem => 'Құрылғы тілі';

  @override
  String get languageEnglish => 'Ағылшын тілі';

  @override
  String get languageKazakh => 'Қазақ тілі';

  @override
  String get languageRussian => 'Орыс тілі';

  @override
  String get appearanceTitle => 'Сыртқы көрініс';

  @override
  String get themeLabel => 'Тақырып';

  @override
  String get themeSystem => 'Құрылғыға сай';

  @override
  String get themeLight => 'Ашық';

  @override
  String get themeDark => 'Қараңғы';

  @override
  String get highContrast => 'Жоғары контраст';

  @override
  String get highContrastDescription =>
      'Жиектер мен мәтін контрастын күшейтеді.';

  @override
  String get playerSymbolsTitle => 'Түске тәуелсіз белгілер';

  @override
  String get playerSymbolsDescription =>
      'Әр ойыншы түсімен бірге бірегей шеңбер, ромб, үшбұрыш немесе шаршымен белгіленеді.';

  @override
  String get audioTitle => 'Дыбыс және діріл';

  @override
  String get accessibilityTitle => 'Қозғалыс және басқару';

  @override
  String get confirmMoves => 'Әр жүрісті растау';

  @override
  String get confirmMovesDescription =>
      'Таңдалған резеңкені жібермес бұрын сұрайды. Хост қабылдаған желілік жүріс қайтарылмайды.';

  @override
  String get rulesTitle => 'Ережелер';

  @override
  String get rulesIntro =>
      'TriGrid алтыбұрыш ішіндегі үшбұрышты торда ойналады. Резеңкелерден бір байланысқан желі құрып, жапқан кіші үшбұрыштарды иеленіңіз.';

  @override
  String get rulesGoalTitle => 'Мақсат';

  @override
  String get rulesGoalBody =>
      'Қарсыластардан көбірек бірлік үшбұрыш иеленіңіз. Ұпай — белгіңіз қойылған үшбұрыштар саны.';

  @override
  String get rulesPlacementTitle => 'Резеңке орналастыру';

  @override
  String get rulesPlacementBody =>
      'Жүріс тордың үш бағытының бірінде қатар тұрған дәл төрт қазықты, яғни үш бірлік қырды қамтиды. Ол алаңнан шықпай, кемінде бір жаңа қыр қосуы керек.';

  @override
  String get rulesConnectionTitle => 'Желіні жалғау';

  @override
  String get rulesConnectionBody =>
      'Алғашқы резеңкені кез келген заңды жерге қоюға болады. Кейінгі әр резеңке бар желімен кемінде бір қазықта түйісуі тиіс. Дәл қайталауға болмайды, жаңа қыр қосатын жартылай қабаттасуға болады.';

  @override
  String get rulesCaptureTitle => 'Үшбұрышты иелену';

  @override
  String get rulesCaptureBody =>
      'Жаңа резеңке иесіз кіші үшбұрыштың үшінші қабырғасын жапса, ол бірден сізге өтеді. Бір жүріс бірнеше үшбұрышты жаба алады.';

  @override
  String get rulesEndingTitle => 'Ойынның соңы';

  @override
  String get rulesEndingBody =>
      'Белгі шегіне жеткенде, қолжетімді резеңкелер біткенде немесе заңды жүріс қалмағанда ойын аяқталады. Ең жоғары ұпай жеңеді; тең ұпай тең ойын болады.';

  @override
  String get rulesBoardsTitle => 'Алаңдар және қор';

  @override
  String get rulesBoardsBody =>
      'Классикалық алаңның радиусы 3, онда 37 қазық және 54 үшбұрыш бар. Екі ойыншыға 10-нан, үш не төрт ойыншыға 12-ден резеңке беріледі. Басқа өлшемдерде арнайы қор формуласы қолданылады.';

  @override
  String get botGuideTitle => 'Бот деңгейлері';

  @override
  String get botGuideIntro =>
      'Барлық бот бір ережемен ойнап, тек ашық ойын күйін көреді. Жоғары деңгейлер жауап жүрістер мен қорғаныс салдарын тереңірек бағалайды.';

  @override
  String get botBeginnerDescription =>
      'Көбіне кездейсоқ заңды жүріс жасап, кейде дайын ұпайды алады. Жылдам әрі әдейі жеңіл.';

  @override
  String get botEasyDescription =>
      'Таяу иеленуді таңдап, қарапайым сыйлықтан қашатын таяз тактикалық баға қолданады.';

  @override
  String get botNormalDescription =>
      'Ұпайды, келесі ойыншыға ашылатын мүмкіндікті, байланыс пен тосқауылды шектеулі тереңдікте теңестіреді.';

  @override
  String get botHardDescription =>
      'Уақытпен шектелген тереңдетілген іздеу, жүріс реттеу, кэш және көп ойыншылы іздеу қолданады.';

  @override
  String get botExpertDescription =>
      'Берілген уақыт ішінде тереңірек іздеп, тұзақтарды, көптік иеленуді, қорғанысты және қарсыластың жауабын бағалайды.';

  @override
  String get botPersonalitiesTitle => 'Мінездер';

  @override
  String get botPersonalitiesDescription =>
      'Шабуылшыл бот жедел ұпайды, Қорғанысшыл келесі ойыншының мүмкіндігін азайтуды, ал Теңгерімді бот екеуін де бағалайды.';

  @override
  String get tutorialTitle => 'Үйрету';

  @override
  String get tutorialPlaceTitle => 'Төрт қазықты қамтыңыз';

  @override
  String get tutorialPlaceBody =>
      'Бастапқы қазықты және белгіленген соңғы қазықты түртіңіз немесе екеуінің арасында сүйреңіз. Әр резеңке үш түзу бірлік қырды қамтиды.';

  @override
  String get tutorialConnectTitle => 'Желіге жалғаңыз';

  @override
  String get tutorialConnectBody =>
      'Алғашқы жүрістен кейін әр резеңке байланысқан желімен бір не бірнеше қазықта түйісуі керек.';

  @override
  String get tutorialCaptureTitle => 'Үшбұрышты жабыңыз';

  @override
  String get tutorialCaptureBody =>
      'Кіші үшбұрыштың үшінші қабырғасын аяқтап, белгі қойыңыз және ұпай алыңыз. Бір резеңке бірнешеуін жабуы мүмкін.';

  @override
  String get tutorialWinTitle => 'Алаңды оқыңыз';

  @override
  String get tutorialWinBody =>
      'Қорды бақылап, келешек иеленуді қорғаңыз және қарсыласқа үлкен жауап қалдырмаңыз. Ең жоғары қорытынды ұпай жеңеді.';

  @override
  String get previousStep => 'Алдыңғы';

  @override
  String get nextStep => 'Келесі';

  @override
  String get startPractice => 'Жаттығуды бастау';

  @override
  String get tutorialBotName => 'Жаттығу боты';

  @override
  String get tutorialGameFirstMove =>
      'Алғашқы жүрісті алаңның кез келген жерінде жасап көріңіз.';

  @override
  String get tutorialGameConnected => 'Енді әр жаңа резеңкені желіге жалғаңыз.';

  @override
  String get tutorialGameCapture => 'Екі қабырғасы дайын үшбұрыштарды іздеңіз.';

  @override
  String get statisticsTitle => 'Статистика';

  @override
  String get clearStatistics => 'Статистиканы тазалау';

  @override
  String get clearStatisticsConfirmation =>
      'Жергілікті және желілік статистиканың бәрін жою керек пе? Қайталаулар сақталады.';

  @override
  String get clearAction => 'Тазалау';

  @override
  String get localStatistics => 'Жергілікті ойындар';

  @override
  String get lanStatistics => 'Желілік ойындар';

  @override
  String get matchesPlayed => 'Ойналған ойын';

  @override
  String get wins => 'Жеңіс';

  @override
  String get winRate => 'Жеңіс үлесі';

  @override
  String get capturedTrianglesStat => 'Иеленген үшбұрыш';

  @override
  String get largestMultiCapture => 'Ең үлкен көптік иелену';

  @override
  String get averageScore => 'Орташа ұпай';

  @override
  String get winRateByBotLevel => 'Бот деңгейі бойынша жеңіс';

  @override
  String get replayLibraryTitle => 'Қайталаулар';

  @override
  String get noReplaysTitle => 'Сақталған қайталау жоқ';

  @override
  String get noReplaysDescription =>
      'Ойынды аяқтағанда тексерілген жүрістер тарихы осында пайда болады.';

  @override
  String get localMode => 'Жергілікті';

  @override
  String get lanMode => 'Желі';

  @override
  String replayMoveCount(int count) {
    return '$count жүріс';
  }

  @override
  String get replayActions => 'Қайталау әрекеттері';

  @override
  String get playReplay => 'Қайталауды ойнату';

  @override
  String get deleteReplay => 'Қайталауды жою';

  @override
  String get aboutTitle => 'Қолданба туралы';

  @override
  String appVersion(String version) {
    return '$version нұсқасы';
  }

  @override
  String get aboutOriginalWork =>
      'Flutter және Flame негізіндегі, өзіндік көріністері мен арнайы жасалған дыбыстары бар түпнұсқа стратегиялық ойын.';

  @override
  String get privacyTitle => 'Құпиялық';

  @override
  String get privacyBody =>
      'TriGrid интернетсіз жұмыс істейді. Ойындар, баптаулар, статистика, қайталаулар және желіге қайта қосылу деректері осы құрылғыда қалады. Желілік ойын деректерді тек бөлмедегі құрылғыларға жібереді және сыртқы сервер қолданбайды.';

  @override
  String get thirdPartyLicenses => 'Ашық код лицензиялары';

  @override
  String get thirdPartyLicensesDescription =>
      'Flutter және қосылған пакеттер лицензияларын көру.';

  @override
  String get assetCreditsBody =>
      'Қолданбадағы дыбыс жинағы TriGrid үшін арнайы жасалған. Дереккөздер мен ауыстыру нұсқаулары ASSET_LICENSES.md файлында жазылған.';

  @override
  String get turnTimerLabel => 'Жүріс таймері';

  @override
  String get turnTimerOff => 'Өшірулі';

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
      'Ойын күйін тексеру сәтсіз. Хостың жарамды көшірмесі күтілуде.';

  @override
  String get networkStateResynchronized =>
      'Ойын күйі хостпен қауіпсіз қайта синхрондалды.';

  @override
  String get networkReconnectFailed =>
      'Хостқа қайта қосылу мүмкін болмады. Жергілікті желіні тексеріңіз.';

  @override
  String get networkUnexpectedError => 'Хост бұл желілік әрекетті қабылдамады.';

  @override
  String get networkHostEndedTitle => 'Хост ойынды аяқтады';

  @override
  String networkHostEndedDescription(int revision) {
    return 'Соңғы тексерілген орын — $revision-нұсқа. Оны осы құрылғыда сақтауға болады.';
  }

  @override
  String get saveLastPosition => 'Соңғы орынды сақтау';

  @override
  String get exitToMenu => 'Мәзірге шығу';

  @override
  String get networkSnapshotSaved => 'Соңғы тексерілген желілік орын сақталды.';

  @override
  String get networkSnapshotSaveFailed =>
      'Бұл желілік орынды тексеру немесе сақтау мүмкін болмады.';

  @override
  String get savedLanPosition => 'Сақталған желілік орын';

  @override
  String get deleteSavedPosition => 'Сақталған орынды жою';

  @override
  String networkRevision(int revision) {
    return '$revision-нұсқа';
  }

  @override
  String get hostAddressExample => '192.168.1.10';

  @override
  String get lanPermissionTitle => 'Жергілікті желіге рұқсат беру';

  @override
  String get lanPermissionDescription =>
      'Қазіргі Android нұсқаларында бөлмелерді тауып, Wi-Fi арқылы қосылу үшін TriGrid-ке «Маңайдағы құрылғылар» рұқсаты қажет. Іздеу істемесе, жалғастырып, IP мекенжайын қолмен енгізуге болады.';

  @override
  String get openSystemSettings => 'Баптауларды ашу';

  @override
  String get continueAction => 'Жалғастыру';

  @override
  String get debugDiagnosticsTooltip => 'Жөндеу диагностикасы';

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
    return 'Заңды $count';
  }

  @override
  String debugBotNodes(int count) {
    return 'Түйін $count';
  }

  @override
  String debugLanLatency(String value) {
    return 'Желі $value';
  }

  @override
  String debugRevision(int revision) {
    return '$revision-нұсқа';
  }

  @override
  String debugStateHash(String value) {
    return 'Хэш $value';
  }
}
