import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'LGKA+'**
  String get appTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to LGKA+'**
  String get welcomeTitle;

  /// No description provided for @substitutionPlan.
  ///
  /// In en, this message translates to:
  /// **'Substitution Plan'**
  String get substitutionPlan;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal Notice'**
  String get legal;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy;

  /// No description provided for @krankmeldung.
  ///
  /// In en, this message translates to:
  /// **'Sick Note'**
  String get krankmeldung;

  /// No description provided for @krankmeldungDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'The sick note is provided by Lessing-Gymnasium and is independent of the LGKA+ app.'**
  String get krankmeldungDisclaimer;

  /// No description provided for @krankmeldungContact.
  ///
  /// In en, this message translates to:
  /// **'For technical questions or problems, please contact Lessing-Gymnasium Karlsruhe directly.'**
  String get krankmeldungContact;

  /// No description provided for @krankmeldungButton.
  ///
  /// In en, this message translates to:
  /// **'To Sick Note'**
  String get krankmeldungButton;

  /// No description provided for @serverMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance work in progress'**
  String get serverMaintenance;

  /// No description provided for @serverConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Server connection failed'**
  String get serverConnectionFailed;

  /// No description provided for @serverConnectionHint.
  ///
  /// In en, this message translates to:
  /// **'This may be due to no internet connection or ongoing maintenance at Lessing-Gymnasium.'**
  String get serverConnectionHint;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @liveWeatherData.
  ///
  /// In en, this message translates to:
  /// **'Live Weather Data'**
  String get liveWeatherData;

  /// No description provided for @dataBeingCollected.
  ///
  /// In en, this message translates to:
  /// **'Data being collected'**
  String get dataBeingCollected;

  /// No description provided for @liveWeatherDescription.
  ///
  /// In en, this message translates to:
  /// **'Directly from the school\'s own weather station on the roof. Real-time data from your school!'**
  String get liveWeatherDescription;

  /// No description provided for @dataCollectionDescription.
  ///
  /// In en, this message translates to:
  /// **'The weather station is currently collecting new data for today. Charts are available from 0:30 AM.'**
  String get dataCollectionDescription;

  /// No description provided for @welcomeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcomeHeadline;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To the new app for Lessing-Gymnasium Karlsruhe.'**
  String get welcomeSubtitle;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @loadingSubstitutions.
  ///
  /// In en, this message translates to:
  /// **'Loading substitution plans...'**
  String get loadingSubstitutions;

  /// No description provided for @errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading'**
  String get errorLoading;

  /// No description provided for @noInfoYet.
  ///
  /// In en, this message translates to:
  /// **'No info yet'**
  String get noInfoYet;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accentColor;

  /// No description provided for @chooseAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred accent color'**
  String get chooseAccentColor;

  /// No description provided for @classes5to7.
  ///
  /// In en, this message translates to:
  /// **'Grades 5-7'**
  String get classes5to7;

  /// No description provided for @classes8to10.
  ///
  /// In en, this message translates to:
  /// **'Grades 8-10'**
  String get classes8to10;

  /// No description provided for @upperSchool.
  ///
  /// In en, this message translates to:
  /// **'Upper school'**
  String get upperSchool;

  /// No description provided for @privacyLabel.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyLabel;

  /// No description provided for @legalLabel.
  ///
  /// In en, this message translates to:
  /// **'Legal Notice'**
  String get legalLabel;

  /// No description provided for @bugReport.
  ///
  /// In en, this message translates to:
  /// **'Found a Bug?'**
  String get bugReport;

  /// No description provided for @bugReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Bug Report'**
  String get bugReportTitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @formLoadError.
  ///
  /// In en, this message translates to:
  /// **'Form could not be loaded'**
  String get formLoadError;

  /// No description provided for @formLoadErrorHint.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get formLoadErrorHint;

  /// No description provided for @krankmeldungInfoHeader.
  ///
  /// In en, this message translates to:
  /// **'Sick Note Information'**
  String get krankmeldungInfoHeader;

  /// No description provided for @loadingSickNote.
  ///
  /// In en, this message translates to:
  /// **'Loading sick note...'**
  String get loadingSickNote;

  /// No description provided for @loadingWeather.
  ///
  /// In en, this message translates to:
  /// **'Loading weather data...'**
  String get loadingWeather;

  /// No description provided for @noWeatherData.
  ///
  /// In en, this message translates to:
  /// **'No weather data available'**
  String get noWeatherData;

  /// No description provided for @temperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperatureLabel;

  /// No description provided for @humidityLabel.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidityLabel;

  /// No description provided for @windSpeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get windSpeedLabel;

  /// No description provided for @pressureLabel.
  ///
  /// In en, this message translates to:
  /// **'Solar radiation'**
  String get pressureLabel;

  /// No description provided for @temperatureTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperatureTodayTitle;

  /// No description provided for @humidityTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidityTodayTitle;

  /// No description provided for @windSpeedTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get windSpeedTodayTitle;

  /// No description provided for @pressureTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Solar radiation'**
  String get pressureTodayTitle;

  /// No description provided for @yAxisTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature (°C)'**
  String get yAxisTemperature;

  /// No description provided for @yAxisHumidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity (%)'**
  String get yAxisHumidity;

  /// No description provided for @yAxisWindSpeed.
  ///
  /// In en, this message translates to:
  /// **'Wind (km/h)'**
  String get yAxisWindSpeed;

  /// No description provided for @yAxisPressure.
  ///
  /// In en, this message translates to:
  /// **'Solar radiation (W/m²)'**
  String get yAxisPressure;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @chartsAvailableAt.
  ///
  /// In en, this message translates to:
  /// **'Charts are available from 0:30 AM.'**
  String get chartsAvailableAt;

  /// No description provided for @checkingAvailability.
  ///
  /// In en, this message translates to:
  /// **'Checking availability...'**
  String get checkingAvailability;

  /// No description provided for @loadingSchedules.
  ///
  /// In en, this message translates to:
  /// **'Loading schedules...'**
  String get loadingSchedules;

  /// No description provided for @noSchedulesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No schedules available'**
  String get noSchedulesAvailable;

  /// No description provided for @tryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get tryAgainLater;

  /// No description provided for @loadingSchedule.
  ///
  /// In en, this message translates to:
  /// **'Loading schedule...'**
  String get loadingSchedule;

  /// No description provided for @notAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'is not available yet'**
  String get notAvailableYet;

  /// No description provided for @errorLoadingGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error loading'**
  String get errorLoadingGeneric;

  /// No description provided for @browserTitle.
  ///
  /// In en, this message translates to:
  /// **'Browser'**
  String get browserTitle;

  /// No description provided for @searchInPdf.
  ///
  /// In en, this message translates to:
  /// **'Search in PDF'**
  String get searchInPdf;

  /// No description provided for @cancelSearch.
  ///
  /// In en, this message translates to:
  /// **'Cancel search'**
  String get cancelSearch;

  /// No description provided for @previousResult.
  ///
  /// In en, this message translates to:
  /// **'Previous result'**
  String get previousResult;

  /// No description provided for @nextResult.
  ///
  /// In en, this message translates to:
  /// **'Next result'**
  String get nextResult;

  /// No description provided for @newSearch.
  ///
  /// In en, this message translates to:
  /// **'New search'**
  String get newSearch;

  /// No description provided for @sharePdf.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get sharePdf;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleTitle;

  /// No description provided for @documentTitle.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get documentTitle;

  /// No description provided for @filenameSchedulePrefix.
  ///
  /// In en, this message translates to:
  /// **'LGKA_Schedule_'**
  String get filenameSchedulePrefix;

  /// No description provided for @subjectSchedule.
  ///
  /// In en, this message translates to:
  /// **'LGKA+ Schedule'**
  String get subjectSchedule;

  /// No description provided for @filenameSubstitutionPrefix.
  ///
  /// In en, this message translates to:
  /// **'LGKA_Substitution_'**
  String get filenameSubstitutionPrefix;

  /// No description provided for @subjectSubstitution.
  ///
  /// In en, this message translates to:
  /// **'LGKA+ Substitution'**
  String get subjectSubstitution;

  /// No description provided for @infoHeader.
  ///
  /// In en, this message translates to:
  /// **'What can you do with the app?'**
  String get infoHeader;

  /// No description provided for @featureSubstitutionTitle.
  ///
  /// In en, this message translates to:
  /// **'Substitution Plan'**
  String get featureSubstitutionTitle;

  /// No description provided for @featureSubstitutionDesc.
  ///
  /// In en, this message translates to:
  /// **'Current substitution plan for today/tomorrow'**
  String get featureSubstitutionDesc;

  /// No description provided for @featureScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get featureScheduleTitle;

  /// No description provided for @featureScheduleDesc.
  ///
  /// In en, this message translates to:
  /// **'Schedule for 1st/2nd semester'**
  String get featureScheduleDesc;

  /// No description provided for @featureWeatherTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather Data'**
  String get featureWeatherTitle;

  /// No description provided for @featureWeatherDesc.
  ///
  /// In en, this message translates to:
  /// **'Access the school\'s own weather station'**
  String get featureWeatherDesc;

  /// No description provided for @featureSickTitle.
  ///
  /// In en, this message translates to:
  /// **'Sick Note'**
  String get featureSickTitle;

  /// No description provided for @featureSickDesc.
  ///
  /// In en, this message translates to:
  /// **'Submit a sick note directly via the app'**
  String get featureSickDesc;

  /// No description provided for @yourAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Your accent color'**
  String get yourAccentColor;

  /// No description provided for @chooseFavoriteColor.
  ///
  /// In en, this message translates to:
  /// **'Choose your favorite color. It will be used throughout the app.'**
  String get chooseFavoriteColor;

  /// No description provided for @letsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go!'**
  String get letsGo;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @authTitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication required'**
  String get authTitle;

  /// No description provided for @authSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the credentials you already know from the substitution plan'**
  String get authSubtitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Enter search term...'**
  String get searchHint;

  /// No description provided for @firstSemester.
  ///
  /// In en, this message translates to:
  /// **'1st semester'**
  String get firstSemester;

  /// No description provided for @secondSemester.
  ///
  /// In en, this message translates to:
  /// **'2nd semester'**
  String get secondSemester;

  /// No description provided for @grades5to10.
  ///
  /// In en, this message translates to:
  /// **'Grades 5-10'**
  String get grades5to10;

  /// No description provided for @j11j12.
  ///
  /// In en, this message translates to:
  /// **'J11/J12'**
  String get j11j12;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @scheduleNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'is not available yet'**
  String get scheduleNotAvailable;

  /// No description provided for @chartLoading.
  ///
  /// In en, this message translates to:
  /// **'Chart is loading...'**
  String get chartLoading;

  /// No description provided for @singleResultFound.
  ///
  /// In en, this message translates to:
  /// **'1 result found'**
  String get singleResultFound;

  /// No description provided for @multipleResultsFound.
  ///
  /// In en, this message translates to:
  /// **'{count} results found'**
  String multipleResultsFound(int count);

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @shareError.
  ///
  /// In en, this message translates to:
  /// **'Error sharing'**
  String get shareError;

  /// No description provided for @errorNavigatingToPage.
  ///
  /// In en, this message translates to:
  /// **'Error navigating to page {page}'**
  String errorNavigatingToPage(String page);

  /// No description provided for @foundPages.
  ///
  /// In en, this message translates to:
  /// **'Found pages: {pages}'**
  String foundPages(String pages);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
