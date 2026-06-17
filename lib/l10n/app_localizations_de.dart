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
  String get substitutionPlan => 'Vertretungsplan';

  @override
  String get weather => 'Wetter';

  @override
  String get schedule => 'Stundenplan';

  @override
  String get krankmeldung => 'Krankmeldung';

  @override
  String get krankmeldungDisclaimer => 'Die Krankmeldung wird vom Lessing-Gymnasium bereitgestellt und ist unabhängig von der LGKA+ App.';

  @override
  String get krankmeldungContact => 'Bei technischen Fragen oder Problemen wende dich bitte direkt an das Lessing-Gymnasium Karlsruhe.';

  @override
  String get krankmeldungButton => 'Zur Krankmeldung';

  @override
  String get serverConnectionFailed => 'Serververbindung fehlgeschlagen';

  @override
  String get serverConnectionHint => 'Möglicherweise besteht keine Internetverbindung oder es finden gerade Wartungsarbeiten am Lessing-Gymnasium statt.';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get welcomeHeadline => 'Willkommen!';

  @override
  String get welcomeSubtitle => 'Bei der neuen App fürs Lessing-Gymnasium Karlsruhe.';

  @override
  String get continueLabel => 'Weiter';

  @override
  String get today => 'Heute';

  @override
  String get tomorrow => 'Morgen';

  @override
  String get errorLoading => 'Fehler beim Laden';

  @override
  String get noInfoYet => 'Noch keine Infos';

  @override
  String get settings => 'Einstellungen';

  @override
  String get accentColor => 'Akzentfarbe';

  @override
  String get privacyLabel => 'Datenschutzerklärung';

  @override
  String get legalLabel => 'Impressum';

  @override
  String get bugReport => 'Fehler gefunden?';

  @override
  String get bugReportTitle => 'Bug Report';

  @override
  String get loading => 'Lädt...';

  @override
  String get formLoadError => 'Formular konnte nicht geladen werden';

  @override
  String get formLoadErrorHint => 'Bitte überprüfe deine Internetverbindung und versuche es erneut.';

  @override
  String get krankmeldungInfoHeader => 'Hinweis zur Krankmeldung';

  @override
  String get loadingSickNote => 'Lade Krankmeldung...';

  @override
  String get checkingAvailability => 'Prüfe Verfügbarkeit...';

  @override
  String get loadingSchedules => 'Lade Stundenpläne...';

  @override
  String get loadingNews => 'Lade Neuigkeiten...';

  @override
  String get noSchedulesAvailable => 'Keine Stundenpläne verfügbar';

  @override
  String get tryAgainLater => 'Versuche es später erneut';

  @override
  String get loadingSchedule => 'Lade Stundenplan...';

  @override
  String get errorLoadingGeneric => 'Fehler beim Laden';

  @override
  String get browserTitle => 'Browser';

  @override
  String get searchInPdf => 'Im PDF suchen';

  @override
  String get cancelSearch => 'Suche abbrechen';

  @override
  String get newSearch => 'Neue Suche';

  @override
  String get sharePdf => 'PDF teilen';

  @override
  String get documentTitle => 'Dokument';

  @override
  String get filenameSchedulePrefix => 'LGKA_Stundenplan_';

  @override
  String get subjectSchedule => 'LGKA+ Stundenplan';

  @override
  String get filenameSubstitutionPrefix => 'LGKA_Vertretungsplan_';

  @override
  String get subjectSubstitution => 'LGKA+ Vertretungsplan';

  @override
  String get infoHeader => 'Alle Funktionen im Überblick';

  @override
  String get featureSubstitutionTitle => 'Vertretungsplan';

  @override
  String get featureSubstitutionDesc => 'Aktueller Vertretungsplan für heute/morgen';

  @override
  String get featureScheduleTitle => 'Stundenplan';

  @override
  String get featureScheduleDesc => 'Stundenplan fürs 1./2. Halbjahr';

  @override
  String get featureWeatherTitle => 'Wetterdaten';

  @override
  String get featureWeatherDesc => 'Aktuelle Wetterdaten via Open-Meteo';

  @override
  String get featureNewsTitle => 'Neuigkeiten';

  @override
  String get featureNewsDesc => 'Aktuelle Neuigkeiten und Ankündigungen der Schule';

  @override
  String get featureSickTitle => 'Krankmeldung';

  @override
  String get featureSickDesc => 'Krankmeldung direkt über die App einreichen';

  @override
  String get featureEventsTitle => 'Schulveranstaltungen';

  @override
  String get featureEventsDesc => 'Alle anstehenden Schulveranstaltungen auf einen Blick';

  @override
  String get letsGo => 'Los geht\'s!';

  @override
  String get username => 'Benutzername';

  @override
  String get password => 'Passwort';

  @override
  String get login => 'Anmelden';

  @override
  String get authTitle => 'Anmeldung erforderlich';

  @override
  String get authSubtitle => 'Verwende die Zugangsdaten, die du bereits von der Schulwebsite kennst';

  @override
  String get searchHint => 'Gib deine Klasse ein';

  @override
  String get firstSemester => '1. Halbjahr';

  @override
  String get secondSemester => '2. Halbjahr';

  @override
  String get grades5to10 => 'Klassen 5-10';

  @override
  String get j11j12 => 'J11/J12';

  @override
  String get monday => 'Montag';

  @override
  String get tuesday => 'Dienstag';

  @override
  String get wednesday => 'Mittwoch';

  @override
  String get thursday => 'Donnerstag';

  @override
  String get friday => 'Freitag';

  @override
  String get saturday => 'Samstag';

  @override
  String get sunday => 'Sonntag';

  @override
  String get scheduleNotAvailable => 'ist noch nicht verfügbar';

  @override
  String singleResultFound(String query) {
    return 'Dir wird jetzt immer Klasse $query angezeigt.';
  }

  @override
  String classAlreadySet(String className) {
    return 'Klasse $className ist bereits eingestellt.';
  }

  @override
  String multipleResultsFound(int count) {
    return '$count Ergebnisse gefunden';
  }

  @override
  String noResultsFound(String className) {
    return 'Klasse $className existiert nicht.';
  }

  @override
  String get shareError => 'Fehler beim Teilen';

  @override
  String errorNavigatingToPage(String page) {
    return 'Fehler beim Navigieren zur Seite $page';
  }

  @override
  String get setClassTitle => 'Klasse eingeben';

  @override
  String get setClassMessage => 'Bitte gib deine Klasse ein, um den Stundenplan anzuzeigen.';

  @override
  String get setClassButton => 'Speichern';

  @override
  String classChanged(String className) {
    return 'Deine Klasse wurde auf $className geändert.';
  }

  @override
  String get accentColorTitle => 'Deine Akzentfarbe';

  @override
  String get accentColorDescription => 'Wähle deine Lieblingsfarbe aus. Diese wird überall in der App verwendet.';

  @override
  String get appearanceTitle => 'Erscheinungsbild';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeAuto => 'Auto';

  @override
  String get news => 'Neuigkeiten';

  @override
  String get learnMore => 'Mehr erfahren';

  @override
  String get noNewsAvailable => 'Keine Neuigkeiten verfügbar';

  @override
  String get noNewsFound => 'Keine Neuigkeiten gefunden';

  @override
  String get errorLoadingNews => 'Fehler beim Laden der Neuigkeiten';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get weitereNeuigkeiten => 'Weitere Neuigkeiten';

  @override
  String get termine => 'Bevorstehende Termine';

  @override
  String get noEventsAvailable => 'Keine Termine verfügbar';

  @override
  String get weatherPageTitle => 'Wetter Karlsruhe';

  @override
  String get weatherDataNotAvailable => 'Wetterdaten nicht verfügbar';

  @override
  String get checkInternetConnection => 'Bitte prüfe deine Internetverbindung.';

  @override
  String get hourlyForecastLabel => 'STÜNDLICH';

  @override
  String get threeDayForecastLabel => '3 TAGE';

  @override
  String get weatherAttribution => 'Wetterdaten von Open-Meteo.com';

  @override
  String weatherFeelsLikeHighLow(int feelsLike, int high, int low) {
    return 'Gefühlt $feelsLike°  ·  $low° – $high°';
  }

  @override
  String weatherFeelsLikeHumidity(int feelsLike, int humidity) {
    return 'Gefühlt $feelsLike°  ·  $humidity% Luftfeuchte';
  }

  @override
  String get weatherHumidityShort => 'Luftfeuchte';

  @override
  String get weatherWindShort => 'Wind';

  @override
  String get uviLow => 'Niedrig';

  @override
  String get uviMedium => 'Mittel';

  @override
  String get uviHigh => 'Hoch';

  @override
  String get uviVeryHigh => 'Sehr hoch';

  @override
  String get uviExtreme => 'Extrem';

  @override
  String get scheduleNoClassTitle => 'In welcher Klasse bist du?';

  @override
  String get scheduleNoClassSub => 'Tippe, um deine Klasse festzulegen';

  @override
  String get settingsSectionAppearance => 'DARSTELLUNG';

  @override
  String get settingsSectionMore => 'MEHR';

  @override
  String weatherFeelsLike(int feelsLike) {
    return 'Gefühlt $feelsLike°';
  }

  @override
  String get jahrgang11 => 'Jahrgang 11';

  @override
  String get jahrgang12 => 'Jahrgang 12';

  @override
  String klasseLabel(String name) {
    return 'Klasse $name';
  }

  @override
  String get filenameDocumentDefault => 'LGKA_Document.pdf';

  @override
  String get wmoClearSky => 'Klarer Himmel';

  @override
  String get wmoMainlyClear => 'Überwiegend klar';

  @override
  String get wmoPartlyCloudy => 'Teilweise bewölkt';

  @override
  String get wmoOvercast => 'Bedeckt';

  @override
  String get wmoFog => 'Nebel';

  @override
  String get wmoDepositingRimeFog => 'Gefrierender Nebel';

  @override
  String get wmoDrizzleLight => 'Leichter Nieselregen';

  @override
  String get wmoDrizzleModerate => 'Mäßiger Nieselregen';

  @override
  String get wmoDrizzleDense => 'Dichter Nieselregen';

  @override
  String get wmoFreezingDrizzleLight => 'Leichter gefrierender Nieselregen';

  @override
  String get wmoFreezingDrizzleHeavy => 'Gefrierender Nieselregen';

  @override
  String get wmoRainLight => 'Leichter Regen';

  @override
  String get wmoRainModerate => 'Mäßiger Regen';

  @override
  String get wmoRainHeavy => 'Starker Regen';

  @override
  String get wmoFreezingRainLight => 'Leichter gefrierender Regen';

  @override
  String get wmoFreezingRainHeavy => 'Gefrierender Regen';

  @override
  String get wmoSnowLight => 'Leichter Schneefall';

  @override
  String get wmoSnowModerate => 'Mäßiger Schneefall';

  @override
  String get wmoSnowHeavy => 'Starker Schneefall';

  @override
  String get wmoSnowGrains => 'Schneekörner';

  @override
  String get wmoShowersLight => 'Leichte Regenschauer';

  @override
  String get wmoShowersModerate => 'Mäßige Regenschauer';

  @override
  String get wmoShowersHeavy => 'Starke Regenschauer';

  @override
  String get wmoSnowShowersLight => 'Leichte Schneeschauer';

  @override
  String get wmoSnowShowersHeavy => 'Starke Schneeschauer';

  @override
  String get wmoThunderstorm => 'Gewitter';

  @override
  String get wmoThunderstormHail => 'Gewitter mit Hagel';

  @override
  String get wmoThunderstormHeavyHail => 'Gewitter mit schwerem Hagel';
}
