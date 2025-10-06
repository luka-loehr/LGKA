// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'LGKA+';

  @override
  String get welcomeTitle => 'Willkommen bei LGKA+';

  @override
  String get substitutionPlan => 'Vertretungsplan';

  @override
  String get weather => 'Wetter';

  @override
  String get schedule => 'Stundenplan';

  @override
  String get legal => 'Impressum';

  @override
  String get privacy => 'Datenschutz';

  @override
  String get krankmeldung => 'Krankmeldung';

  @override
  String get krankmeldungDisclaimer => 'Die Krankmeldung wird vom Lessing-Gymnasium bereitgestellt und ist unabhängig von der LGKA+ App.';

  @override
  String get krankmeldungContact => 'Bei technischen Fragen oder Problemen wende dich bitte direkt an das Lessing-Gymnasium Karlsruhe.';

  @override
  String get krankmeldungButton => 'Zur Krankmeldung';

  @override
  String get serverMaintenance => 'Reparaturarbeiten werden durchgeführt';

  @override
  String get serverConnectionFailed => 'Serververbindung fehlgeschlagen';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get liveWeatherData => 'Live Wetterdaten';

  @override
  String get dataBeingCollected => 'Daten werden gesammelt';

  @override
  String get liveWeatherDescription => 'Direkt von der schuleigenen Wetterstation auf dem Dach. Echtzeit-Daten von deiner Schule!';

  @override
  String get dataCollectionDescription => 'Die Wetterstation sammelt gerade neue Daten für heute. Diagramme sind ab 0:30 Uhr verfügbar.';
}
