// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get retry => 'Retry';

  @override
  String get today => 'Today';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get send => 'Send';

  @override
  String get apply => 'Apply';

  @override
  String get none => 'None';

  @override
  String get navHome => 'Home';

  @override
  String get navSummary => 'Summary';

  @override
  String get navRequests => 'Requests';

  @override
  String get navCounters => 'Counters';

  @override
  String get navSettings => 'Settings';

  @override
  String get messages => 'Messages';

  @override
  String get logOut => 'Log out';

  @override
  String get loginUnreachable =>
      'Could not reach MyEra. Check your connection.';

  @override
  String get loginEnterAll => 'Enter your customer key, user and password';

  @override
  String get customerKey => 'Customer key';

  @override
  String get user => 'User';

  @override
  String get password => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get logIn => 'Log in';

  @override
  String get loginNote =>
      'Credentials are stored encrypted on this device and only sent to MyEra.';

  @override
  String get clockIn => 'Clock in';

  @override
  String get clockOut => 'Clock out';

  @override
  String clockedInAt(String time) {
    return 'Clocked in at $time';
  }

  @override
  String clockedOutAt(String time) {
    return 'Clocked out at $time';
  }

  @override
  String get newRequest => 'New request';

  @override
  String get worked => 'Worked';

  @override
  String get target => 'Target';

  @override
  String get lunch => 'Lunch';

  @override
  String get edited => 'edited';

  @override
  String get noClockings => 'No clockings';

  @override
  String get noClockingsYet => 'No clockings yet';

  @override
  String get nowLabel => 'now';

  @override
  String breakDuration(String duration) {
    return 'break $duration';
  }

  @override
  String get absent => 'Absent';

  @override
  String get holiday => 'Holiday';

  @override
  String get absentInitial => 'A';

  @override
  String get holidayInitial => 'H';

  @override
  String get noTargetToday => 'No target today';

  @override
  String lunchBreakOn(String day) {
    return 'Lunch break · $day';
  }

  @override
  String get lunchOnlyThisDay =>
      'Only for this day. Your weekly settings stay as they are.';

  @override
  String fromTime(String time) {
    return 'From $time';
  }

  @override
  String toTime(String time) {
    return 'To $time';
  }

  @override
  String get endAfterStart => 'The end must be after the start.';

  @override
  String get resetToSettings => 'Reset to settings';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get exportPdf => 'Export month as PDF';

  @override
  String get stillLoading => 'Still loading, try again in a moment';

  @override
  String pdfError(String error) {
    return 'Could not create the PDF: $error';
  }

  @override
  String ofTargetThisWeek(String target) {
    return 'of $target this week';
  }

  @override
  String get monthTarget => 'Month target';

  @override
  String get stillToWork => 'Still to work';

  @override
  String get monthFootnote =>
      'Target counts the days up to today. Small figures per day: worked above, target below.';

  @override
  String get overMonthTarget => 'Over the month target';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get settingsClocking => 'Clocking';

  @override
  String get clockReminders => 'Clock reminders';

  @override
  String get clockRemindersSub => 'Notification at each scheduled clock in/out';

  @override
  String get autoClock => 'Auto clock';

  @override
  String get autoClockSub =>
      'Clock in/out automatically at the scheduled times';

  @override
  String get weeklySchedule => 'Weekly schedule';

  @override
  String get tapToChange => 'Tap a time to change it';

  @override
  String get presetStandard => 'Standard 7h 36m';

  @override
  String get presetIrregular => 'Irregular';

  @override
  String get presetStandardTitle => 'Standard 7h 36m';

  @override
  String get presetIrregularTitle => 'Irregular schedule';

  @override
  String get presetStandardDesc =>
      '7h 36m per day from the start time, with the break below. Clock out is calculated.';

  @override
  String get presetIrregularDesc =>
      '8h Mon–Thu (start + 8h + break) and 6h on Fri without break (start + 6h).';

  @override
  String get start => 'Start';

  @override
  String get breakFrom => 'Break from';

  @override
  String get breakTo => 'Break to';

  @override
  String get autoClockWarning =>
      'The app will clock in and out for you at the scheduled times, even when it is closed. Android may delay or skip it (battery saver, device asleep). It re-checks MyEra first and never doubles a clocking, but you stay responsible for your clockings. Keep checking them.';

  @override
  String get iUnderstand => 'I understand';

  @override
  String get savedOk => 'Saved';

  @override
  String savedWarnShortBreak(String days) {
    return 'Saved. Warning: break under 30 min on $days';
  }

  @override
  String get inLabel => 'Clock in';

  @override
  String get outLabel => 'Clock out';

  @override
  String get lunchBreak => 'Lunch break';

  @override
  String netTime(String duration) {
    return '$duration net';
  }

  @override
  String get scheduleFootnote =>
      'The lunch break is unpaid and deducted from the daily worked time. The minimum required break is 30 min; switch it off for days without one. The target is only used to compare against the worked time in the summary.';

  @override
  String get fromLabel => 'From';

  @override
  String get toLabel => 'To';

  @override
  String noRequestsYear(String year) {
    return 'No requests in $year';
  }

  @override
  String get absenceRequest => 'Absence request';

  @override
  String get clockingRequest => 'Clocking request';

  @override
  String get withdrawTitle => 'Withdraw request?';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get holdToWithdraw => 'hold to withdraw';

  @override
  String get fromCalendar => 'from calendar';

  @override
  String get newShort => 'New';

  @override
  String get requestCancellation => 'Request cancellation';

  @override
  String get holdToCancel => 'hold to request cancellation';

  @override
  String get cancelNotAvailable =>
      'This absence cannot be cancelled from the app.';

  @override
  String get cancellationRequested => 'Cancellation requested';

  @override
  String get cancelAbsenceNote =>
      'A cancellation request will be sent to MyEra. The absence stays until it is approved.';

  @override
  String get absenceToCancel => 'Absence';

  @override
  String get chooseAbsence => 'Choose the absence to cancel';

  @override
  String get chooseType => 'Choose an absence type';

  @override
  String get chooseDate => 'Choose a date';

  @override
  String get endBeforeStart => 'End date is before start date';

  @override
  String get chooseHours => 'Choose the hours';

  @override
  String get remarkRequired => 'A remark is required for this type';

  @override
  String get needsAttachment =>
      'This type needs an attachment, which the app does not support yet. Use the web app.';

  @override
  String get sendRequestTitle => 'Send request?';

  @override
  String get requestSent => 'Request sent';

  @override
  String get typeLabel => 'Type';

  @override
  String get fullDay => 'Full day';

  @override
  String get firstPart => '1st part';

  @override
  String get secondPart => '2nd part';

  @override
  String get hours => 'Hours';

  @override
  String get startDate => 'Start date';

  @override
  String get dateLabel => 'Date';

  @override
  String get endDateOptional => 'End date (optional)';

  @override
  String get firstPartSuffix => '(first part)';

  @override
  String get secondPartSuffix => '(second part)';

  @override
  String get remark => 'Remark';

  @override
  String get remarkRequiredLabel => 'Remark (required)';

  @override
  String get sendRequest => 'Send request';

  @override
  String get chooseDateStartEnd => 'Choose date, start and end';

  @override
  String get endAfterStartShort => 'End must be after start';

  @override
  String clockingSummary(String date, String from, String to) {
    return 'Clocking $date\n$from – $to';
  }

  @override
  String get noCounters => 'No counters';

  @override
  String get noMessages => 'No messages';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get markUnread => 'Mark as unread';

  @override
  String get messageTitle => 'Message';

  @override
  String errHttp(String code, String path) {
    return 'HTTP $code on $path';
  }

  @override
  String errHttpCode(String code) {
    return 'HTTP $code';
  }

  @override
  String get errMissingSession => 'Missing session, please log in again';

  @override
  String errLogin(String code) {
    return 'Login failed (HTTP $code). Check your customer key, user and password.';
  }

  @override
  String errClocking(String code) {
    return 'Clocking failed (HTTP $code)';
  }

  @override
  String errRequest(String code, String detail) {
    return 'Request failed (HTTP $code$detail)';
  }

  @override
  String errDelete(String code) {
    return 'Delete failed (HTTP $code)';
  }

  @override
  String get notifChannelName => 'Clock reminders';

  @override
  String get notifChannelDesc =>
      'Clock in/out reminders and auto clock results';

  @override
  String get notifTimeToClockIn => 'Time to clock in';

  @override
  String get notifTimeToClockOut => 'Time to clock out';

  @override
  String get notifOpenApp => 'Open MyEra.';

  @override
  String get autoInSkipped => 'Auto clock in skipped';

  @override
  String get autoOutSkipped => 'Auto clock out skipped';

  @override
  String autoMissedBody(String minutes) {
    return 'Missed by $minutes min (device was asleep). Please clock manually.';
  }

  @override
  String get autoAbsenceBody => 'Today is an absence or holiday.';

  @override
  String get autoAlreadyClocking => 'There is already a clocking today.';

  @override
  String get autoNoOpenIn =>
      'There is no open clock in (already clocked out, or never clocked in).';

  @override
  String get autoInDone => 'Auto clock in done';

  @override
  String get autoOutDone => 'Auto clock out done';

  @override
  String get autoInUnconfirmed => 'Auto clock in sent, not confirmed';

  @override
  String get autoOutUnconfirmed => 'Auto clock out sent, not confirmed';

  @override
  String autoDoneInBody(String time) {
    return 'Clocked in at $time.';
  }

  @override
  String autoDoneOutBody(String time) {
    return 'Clocked out at $time.';
  }

  @override
  String get autoUnconfirmedBody =>
      'Could not confirm it in MyEra. Please check manually.';

  @override
  String get autoInFailed => 'Auto clock in failed';

  @override
  String get autoOutFailed => 'Auto clock out failed';

  @override
  String autoFailedBody(String error) {
    return '$error. Please clock manually.';
  }

  @override
  String pdfTitle(String month, String year) {
    return 'Time report - $month $year';
  }

  @override
  String get pdfDay => 'Day';

  @override
  String get pdfClockings => 'Clockings';

  @override
  String get pdfBreaks => 'Breaks';

  @override
  String get pdfDiff => 'Diff';

  @override
  String get pdfWeek => 'Week';

  @override
  String get pdfExpectedSoFar => 'Expected so far';

  @override
  String get pdfExpected => 'Expected';

  @override
  String get pdfDifference => 'Difference';

  @override
  String get pdfOverTarget => 'Over the target';

  @override
  String get pdfNoClockOut => 'no clock-out';

  @override
  String get pdfFootnote =>
      'Worked = time between clockings minus the lunch break. Weekly targets follow the configured daily targets; on weeks with an absence or holiday the weekly average is spread over the remaining days.';

  @override
  String get pdfLunchEdited => ' * Lunch break changed manually for that day.';

  @override
  String pdfPage(String page, String total) {
    return 'Page $page / $total';
  }
}
