import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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
    Locale('es'),
  ];

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get navSummary;

  /// No description provided for @navRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get navRequests;

  /// No description provided for @navCounters.
  ///
  /// In en, this message translates to:
  /// **'Counters'**
  String get navCounters;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @loginUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach MyEra. Check your connection.'**
  String get loginUnreachable;

  /// No description provided for @loginEnterAll.
  ///
  /// In en, this message translates to:
  /// **'Enter your customer key, user and password'**
  String get loginEnterAll;

  /// No description provided for @customerKey.
  ///
  /// In en, this message translates to:
  /// **'Customer key'**
  String get customerKey;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @loginNote.
  ///
  /// In en, this message translates to:
  /// **'Credentials are stored encrypted on this device and only sent to MyEra.'**
  String get loginNote;

  /// No description provided for @clockIn.
  ///
  /// In en, this message translates to:
  /// **'Clock in'**
  String get clockIn;

  /// No description provided for @clockOut.
  ///
  /// In en, this message translates to:
  /// **'Clock out'**
  String get clockOut;

  /// No description provided for @clockedInAt.
  ///
  /// In en, this message translates to:
  /// **'Clocked in at {time}'**
  String clockedInAt(String time);

  /// No description provided for @clockedOutAt.
  ///
  /// In en, this message translates to:
  /// **'Clocked out at {time}'**
  String clockedOutAt(String time);

  /// No description provided for @newRequest.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get newRequest;

  /// No description provided for @worked.
  ///
  /// In en, this message translates to:
  /// **'Worked'**
  String get worked;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @lunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get lunch;

  /// No description provided for @edited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get edited;

  /// No description provided for @noClockings.
  ///
  /// In en, this message translates to:
  /// **'No clockings'**
  String get noClockings;

  /// No description provided for @noClockingsYet.
  ///
  /// In en, this message translates to:
  /// **'No clockings yet'**
  String get noClockingsYet;

  /// No description provided for @nowLabel.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get nowLabel;

  /// No description provided for @breakDuration.
  ///
  /// In en, this message translates to:
  /// **'break {duration}'**
  String breakDuration(String duration);

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absent;

  /// No description provided for @holiday.
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get holiday;

  /// No description provided for @absentInitial.
  ///
  /// In en, this message translates to:
  /// **'A'**
  String get absentInitial;

  /// No description provided for @holidayInitial.
  ///
  /// In en, this message translates to:
  /// **'H'**
  String get holidayInitial;

  /// No description provided for @noTargetToday.
  ///
  /// In en, this message translates to:
  /// **'No target today'**
  String get noTargetToday;

  /// No description provided for @lunchBreakOn.
  ///
  /// In en, this message translates to:
  /// **'Lunch break · {day}'**
  String lunchBreakOn(String day);

  /// No description provided for @lunchOnlyThisDay.
  ///
  /// In en, this message translates to:
  /// **'Only for this day. Your weekly settings stay as they are.'**
  String get lunchOnlyThisDay;

  /// No description provided for @fromTime.
  ///
  /// In en, this message translates to:
  /// **'From {time}'**
  String fromTime(String time);

  /// No description provided for @toTime.
  ///
  /// In en, this message translates to:
  /// **'To {time}'**
  String toTime(String time);

  /// No description provided for @endAfterStart.
  ///
  /// In en, this message translates to:
  /// **'The end must be after the start.'**
  String get endAfterStart;

  /// No description provided for @resetToSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset to settings'**
  String get resetToSettings;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export month as PDF'**
  String get exportPdf;

  /// No description provided for @stillLoading.
  ///
  /// In en, this message translates to:
  /// **'Still loading, try again in a moment'**
  String get stillLoading;

  /// No description provided for @pdfError.
  ///
  /// In en, this message translates to:
  /// **'Could not create the PDF: {error}'**
  String pdfError(String error);

  /// No description provided for @ofTargetThisWeek.
  ///
  /// In en, this message translates to:
  /// **'of {target} this week'**
  String ofTargetThisWeek(String target);

  /// No description provided for @monthTarget.
  ///
  /// In en, this message translates to:
  /// **'Month target'**
  String get monthTarget;

  /// No description provided for @stillToWork.
  ///
  /// In en, this message translates to:
  /// **'Still to work'**
  String get stillToWork;

  /// No description provided for @monthFootnote.
  ///
  /// In en, this message translates to:
  /// **'Target counts the days up to today. Small figures per day: worked above, target below.'**
  String get monthFootnote;

  /// No description provided for @overMonthTarget.
  ///
  /// In en, this message translates to:
  /// **'Over the month target'**
  String get overMonthTarget;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
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

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @settingsClocking.
  ///
  /// In en, this message translates to:
  /// **'Clocking'**
  String get settingsClocking;

  /// No description provided for @clockReminders.
  ///
  /// In en, this message translates to:
  /// **'Clock reminders'**
  String get clockReminders;

  /// No description provided for @clockRemindersSub.
  ///
  /// In en, this message translates to:
  /// **'Notification at each scheduled clock in/out'**
  String get clockRemindersSub;

  /// No description provided for @autoClock.
  ///
  /// In en, this message translates to:
  /// **'Auto clock'**
  String get autoClock;

  /// No description provided for @autoClockSub.
  ///
  /// In en, this message translates to:
  /// **'Clock in/out automatically at the scheduled times'**
  String get autoClockSub;

  /// No description provided for @weeklySchedule.
  ///
  /// In en, this message translates to:
  /// **'Weekly schedule'**
  String get weeklySchedule;

  /// No description provided for @tapToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap a time to change it'**
  String get tapToChange;

  /// No description provided for @presetStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard 7h 36m'**
  String get presetStandard;

  /// No description provided for @presetIrregular.
  ///
  /// In en, this message translates to:
  /// **'Irregular'**
  String get presetIrregular;

  /// No description provided for @presetStandardTitle.
  ///
  /// In en, this message translates to:
  /// **'Standard 7h 36m'**
  String get presetStandardTitle;

  /// No description provided for @presetIrregularTitle.
  ///
  /// In en, this message translates to:
  /// **'Irregular schedule'**
  String get presetIrregularTitle;

  /// No description provided for @presetStandardDesc.
  ///
  /// In en, this message translates to:
  /// **'7h 36m per day from the start time, with the break below. Clock out is calculated.'**
  String get presetStandardDesc;

  /// No description provided for @presetIrregularDesc.
  ///
  /// In en, this message translates to:
  /// **'8h Mon–Thu (start + 8h + break) and 6h on Fri without break (start + 6h).'**
  String get presetIrregularDesc;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @breakFrom.
  ///
  /// In en, this message translates to:
  /// **'Break from'**
  String get breakFrom;

  /// No description provided for @breakTo.
  ///
  /// In en, this message translates to:
  /// **'Break to'**
  String get breakTo;

  /// No description provided for @autoClockWarning.
  ///
  /// In en, this message translates to:
  /// **'The app will clock in and out for you at the scheduled times, even when it is closed. Android may delay or skip it (battery saver, device asleep). It re-checks MyEra first and never doubles a clocking, but you stay responsible for your clockings. Keep checking them.'**
  String get autoClockWarning;

  /// No description provided for @iUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get iUnderstand;

  /// No description provided for @savedOk.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedOk;

  /// No description provided for @savedWarnShortBreak.
  ///
  /// In en, this message translates to:
  /// **'Saved. Warning: break under 30 min on {days}'**
  String savedWarnShortBreak(String days);

  /// No description provided for @inLabel.
  ///
  /// In en, this message translates to:
  /// **'Clock in'**
  String get inLabel;

  /// No description provided for @outLabel.
  ///
  /// In en, this message translates to:
  /// **'Clock out'**
  String get outLabel;

  /// No description provided for @lunchBreak.
  ///
  /// In en, this message translates to:
  /// **'Lunch break'**
  String get lunchBreak;

  /// No description provided for @netTime.
  ///
  /// In en, this message translates to:
  /// **'{duration} net'**
  String netTime(String duration);

  /// No description provided for @scheduleFootnote.
  ///
  /// In en, this message translates to:
  /// **'The lunch break is unpaid and deducted from the daily worked time. The minimum required break is 30 min; switch it off for days without one. The target is only used to compare against the worked time in the summary.'**
  String get scheduleFootnote;

  /// No description provided for @fromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromLabel;

  /// No description provided for @toLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toLabel;

  /// No description provided for @noRequestsYear.
  ///
  /// In en, this message translates to:
  /// **'No requests in {year}'**
  String noRequestsYear(String year);

  /// No description provided for @absenceRequest.
  ///
  /// In en, this message translates to:
  /// **'Absence request'**
  String get absenceRequest;

  /// No description provided for @clockingRequest.
  ///
  /// In en, this message translates to:
  /// **'Clocking request'**
  String get clockingRequest;

  /// No description provided for @withdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw request?'**
  String get withdrawTitle;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @holdToWithdraw.
  ///
  /// In en, this message translates to:
  /// **'hold to withdraw'**
  String get holdToWithdraw;

  /// No description provided for @fromCalendar.
  ///
  /// In en, this message translates to:
  /// **'from calendar'**
  String get fromCalendar;

  /// No description provided for @newShort.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newShort;

  /// No description provided for @requestCancellation.
  ///
  /// In en, this message translates to:
  /// **'Request cancellation'**
  String get requestCancellation;

  /// No description provided for @holdToCancel.
  ///
  /// In en, this message translates to:
  /// **'hold to request cancellation'**
  String get holdToCancel;

  /// No description provided for @cancelNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'This absence cannot be cancelled from the app.'**
  String get cancelNotAvailable;

  /// No description provided for @cancellationRequested.
  ///
  /// In en, this message translates to:
  /// **'Cancellation requested'**
  String get cancellationRequested;

  /// No description provided for @cancelAbsenceNote.
  ///
  /// In en, this message translates to:
  /// **'A cancellation request will be sent to MyEra. The absence stays until it is approved.'**
  String get cancelAbsenceNote;

  /// No description provided for @absenceToCancel.
  ///
  /// In en, this message translates to:
  /// **'Absence'**
  String get absenceToCancel;

  /// No description provided for @chooseAbsence.
  ///
  /// In en, this message translates to:
  /// **'Choose the absence to cancel'**
  String get chooseAbsence;

  /// No description provided for @chooseType.
  ///
  /// In en, this message translates to:
  /// **'Choose an absence type'**
  String get chooseType;

  /// No description provided for @chooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get chooseDate;

  /// No description provided for @endBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'End date is before start date'**
  String get endBeforeStart;

  /// No description provided for @chooseHours.
  ///
  /// In en, this message translates to:
  /// **'Choose the hours'**
  String get chooseHours;

  /// No description provided for @remarkRequired.
  ///
  /// In en, this message translates to:
  /// **'A remark is required for this type'**
  String get remarkRequired;

  /// No description provided for @needsAttachment.
  ///
  /// In en, this message translates to:
  /// **'This type needs an attachment, which the app does not support yet. Use the web app.'**
  String get needsAttachment;

  /// No description provided for @sendRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Send request?'**
  String get sendRequestTitle;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get requestSent;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @fullDay.
  ///
  /// In en, this message translates to:
  /// **'Full day'**
  String get fullDay;

  /// No description provided for @firstPart.
  ///
  /// In en, this message translates to:
  /// **'1st part'**
  String get firstPart;

  /// No description provided for @secondPart.
  ///
  /// In en, this message translates to:
  /// **'2nd part'**
  String get secondPart;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @endDateOptional.
  ///
  /// In en, this message translates to:
  /// **'End date (optional)'**
  String get endDateOptional;

  /// No description provided for @firstPartSuffix.
  ///
  /// In en, this message translates to:
  /// **'(first part)'**
  String get firstPartSuffix;

  /// No description provided for @secondPartSuffix.
  ///
  /// In en, this message translates to:
  /// **'(second part)'**
  String get secondPartSuffix;

  /// No description provided for @remark.
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get remark;

  /// No description provided for @remarkRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Remark (required)'**
  String get remarkRequiredLabel;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get sendRequest;

  /// No description provided for @chooseDateStartEnd.
  ///
  /// In en, this message translates to:
  /// **'Choose date, start and end'**
  String get chooseDateStartEnd;

  /// No description provided for @endAfterStartShort.
  ///
  /// In en, this message translates to:
  /// **'End must be after start'**
  String get endAfterStartShort;

  /// No description provided for @clockingSummary.
  ///
  /// In en, this message translates to:
  /// **'Clocking {date}\n{from} – {to}'**
  String clockingSummary(String date, String from, String to);

  /// No description provided for @noCounters.
  ///
  /// In en, this message translates to:
  /// **'No counters'**
  String get noCounters;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get noMessages;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @markUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark as unread'**
  String get markUnread;

  /// No description provided for @messageTitle.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageTitle;

  /// No description provided for @errHttp.
  ///
  /// In en, this message translates to:
  /// **'HTTP {code} on {path}'**
  String errHttp(String code, String path);

  /// No description provided for @errHttpCode.
  ///
  /// In en, this message translates to:
  /// **'HTTP {code}'**
  String errHttpCode(String code);

  /// No description provided for @errMissingSession.
  ///
  /// In en, this message translates to:
  /// **'Missing session, please log in again'**
  String get errMissingSession;

  /// No description provided for @errLogin.
  ///
  /// In en, this message translates to:
  /// **'Login failed (HTTP {code}). Check your customer key, user and password.'**
  String errLogin(String code);

  /// No description provided for @errClocking.
  ///
  /// In en, this message translates to:
  /// **'Clocking failed (HTTP {code})'**
  String errClocking(String code);

  /// No description provided for @errRequest.
  ///
  /// In en, this message translates to:
  /// **'Request failed (HTTP {code}{detail})'**
  String errRequest(String code, String detail);

  /// No description provided for @errDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete failed (HTTP {code})'**
  String errDelete(String code);

  /// No description provided for @notifChannelName.
  ///
  /// In en, this message translates to:
  /// **'Clock reminders'**
  String get notifChannelName;

  /// No description provided for @notifChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Clock in/out reminders and auto clock results'**
  String get notifChannelDesc;

  /// No description provided for @notifTimeToClockIn.
  ///
  /// In en, this message translates to:
  /// **'Time to clock in'**
  String get notifTimeToClockIn;

  /// No description provided for @notifTimeToClockOut.
  ///
  /// In en, this message translates to:
  /// **'Time to clock out'**
  String get notifTimeToClockOut;

  /// No description provided for @notifOpenApp.
  ///
  /// In en, this message translates to:
  /// **'Open MyEra.'**
  String get notifOpenApp;

  /// No description provided for @autoInSkipped.
  ///
  /// In en, this message translates to:
  /// **'Auto clock in skipped'**
  String get autoInSkipped;

  /// No description provided for @autoOutSkipped.
  ///
  /// In en, this message translates to:
  /// **'Auto clock out skipped'**
  String get autoOutSkipped;

  /// No description provided for @autoMissedBody.
  ///
  /// In en, this message translates to:
  /// **'Missed by {minutes} min (device was asleep). Please clock manually.'**
  String autoMissedBody(String minutes);

  /// No description provided for @autoAbsenceBody.
  ///
  /// In en, this message translates to:
  /// **'Today is an absence or holiday.'**
  String get autoAbsenceBody;

  /// No description provided for @autoAlreadyClocking.
  ///
  /// In en, this message translates to:
  /// **'There is already a clocking today.'**
  String get autoAlreadyClocking;

  /// No description provided for @autoNoOpenIn.
  ///
  /// In en, this message translates to:
  /// **'There is no open clock in (already clocked out, or never clocked in).'**
  String get autoNoOpenIn;

  /// No description provided for @autoInDone.
  ///
  /// In en, this message translates to:
  /// **'Auto clock in done'**
  String get autoInDone;

  /// No description provided for @autoOutDone.
  ///
  /// In en, this message translates to:
  /// **'Auto clock out done'**
  String get autoOutDone;

  /// No description provided for @autoInUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Auto clock in sent, not confirmed'**
  String get autoInUnconfirmed;

  /// No description provided for @autoOutUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Auto clock out sent, not confirmed'**
  String get autoOutUnconfirmed;

  /// No description provided for @autoDoneInBody.
  ///
  /// In en, this message translates to:
  /// **'Clocked in at {time}.'**
  String autoDoneInBody(String time);

  /// No description provided for @autoDoneOutBody.
  ///
  /// In en, this message translates to:
  /// **'Clocked out at {time}.'**
  String autoDoneOutBody(String time);

  /// No description provided for @autoUnconfirmedBody.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm it in MyEra. Please check manually.'**
  String get autoUnconfirmedBody;

  /// No description provided for @autoInFailed.
  ///
  /// In en, this message translates to:
  /// **'Auto clock in failed'**
  String get autoInFailed;

  /// No description provided for @autoOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Auto clock out failed'**
  String get autoOutFailed;

  /// No description provided for @autoFailedBody.
  ///
  /// In en, this message translates to:
  /// **'{error}. Please clock manually.'**
  String autoFailedBody(String error);

  /// No description provided for @pdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Time report - {month} {year}'**
  String pdfTitle(String month, String year);

  /// No description provided for @pdfDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get pdfDay;

  /// No description provided for @pdfClockings.
  ///
  /// In en, this message translates to:
  /// **'Clockings'**
  String get pdfClockings;

  /// No description provided for @pdfBreaks.
  ///
  /// In en, this message translates to:
  /// **'Breaks'**
  String get pdfBreaks;

  /// No description provided for @pdfDiff.
  ///
  /// In en, this message translates to:
  /// **'Diff'**
  String get pdfDiff;

  /// No description provided for @pdfWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get pdfWeek;

  /// No description provided for @pdfExpectedSoFar.
  ///
  /// In en, this message translates to:
  /// **'Expected so far'**
  String get pdfExpectedSoFar;

  /// No description provided for @pdfExpected.
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get pdfExpected;

  /// No description provided for @pdfDifference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get pdfDifference;

  /// No description provided for @pdfOverTarget.
  ///
  /// In en, this message translates to:
  /// **'Over the target'**
  String get pdfOverTarget;

  /// No description provided for @pdfNoClockOut.
  ///
  /// In en, this message translates to:
  /// **'no clock-out'**
  String get pdfNoClockOut;

  /// No description provided for @pdfFootnote.
  ///
  /// In en, this message translates to:
  /// **'Worked = time between clockings minus the lunch break. Weekly targets follow the configured daily targets; on weeks with an absence or holiday the weekly average is spread over the remaining days.'**
  String get pdfFootnote;

  /// No description provided for @pdfLunchEdited.
  ///
  /// In en, this message translates to:
  /// **' * Lunch break changed manually for that day.'**
  String get pdfLunchEdited;

  /// No description provided for @pdfPage.
  ///
  /// In en, this message translates to:
  /// **'Page {page} / {total}'**
  String pdfPage(String page, String total);
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
