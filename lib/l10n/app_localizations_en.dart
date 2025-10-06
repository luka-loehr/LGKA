// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LGKA+';

  @override
  String get welcomeTitle => 'Welcome to LGKA+';

  @override
  String get substitutionPlan => 'Substitution Plan';

  @override
  String get weather => 'Weather';

  @override
  String get schedule => 'Schedule';

  @override
  String get legal => 'Legal Notice';

  @override
  String get privacy => 'Privacy Policy';

  @override
  String get krankmeldung => 'Sick Note';

  @override
  String get krankmeldungDisclaimer => 'The sick note is provided by Lessing-Gymnasium and is independent of the LGKA+ app.';

  @override
  String get krankmeldungContact => 'For technical questions or problems, please contact Lessing-Gymnasium Karlsruhe directly.';

  @override
  String get krankmeldungButton => 'To Sick Note';

  @override
  String get serverMaintenance => 'Maintenance work in progress';

  @override
  String get serverConnectionFailed => 'Server connection failed';

  @override
  String get tryAgain => 'Try again';

  @override
  String get liveWeatherData => 'Live Weather Data';

  @override
  String get dataBeingCollected => 'Data being collected';

  @override
  String get liveWeatherDescription => 'Directly from the school\'s own weather station on the roof. Real-time data from your school!';

  @override
  String get dataCollectionDescription => 'The weather station is currently collecting new data for today. Charts are available from 0:30 AM.';
}
