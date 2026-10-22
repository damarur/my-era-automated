import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'api.dart';
import 'l10n.dart';
import 'summary.dart';


String _hm(DateTime t) => '${pad(t.hour)}:${pad(t.minute)}';

/// Plain ASCII sign.
String _signed(int ms) => '${ms < 0 ? '-' : '+'}${fmtDuration(ms)}';

String _short(int ms) {
  final m = ms.abs() ~/ 60000;
  if (m < 60) return '${m}m';
  return m % 60 == 0 ? '${m ~/ 60}h' : '${m ~/ 60}h ${pad(m % 60)}m';
}

/// One working day of the report.
class ReportDay {
  ReportDay({
    required this.row,
    required this.clockings,
    required this.lunch,
    required this.breaks,
    required this.worked,
    required this.target,
    required this.diff,
    required this.due,
  });
  final DayRow row;
  final String clockings; // "07:48 - 14:04   15:14 - 18:05", or the absence / holiday of the day
  final String lunch; // "13:00-14:00 (1h)" or "-"
  final String breaks; // clocked breaks, "1h 10m" or "-"
  final String worked;
  final String target;
  final String diff;
  final bool due; // false for days still to come (not part of the totals)
}

class ReportWeek {
  ReportWeek(this.monday, this.days, this.worked, this.target);
  final DateTime monday;
  final List<ReportDay> days;
  final int worked;
  final int target; // of the days already due
  int get diff => worked - target;
}

class ReportModel {
  ReportModel(this.month, this.weeks, this.worked, this.target, this.fullTarget);
  final DateTime month;
  final List<ReportWeek> weeks;
  final int worked;
  final int target; // of the days already due
  final int fullTarget; // of the whole month
  int get diff => worked - target;
}

/// Groups the rows of a month summary by week and computes the totals. Days after [today] are
/// listed but not part of the worked/target totals.
ReportModel buildReportModel(PeriodSummary summary, DateTime month, DateTime today) {
  final todayKey = ymd(today);
  final byWeek = <DateTime, List<DayRow>>{};
  for (final r in summary.rows) {
    byWeek.putIfAbsent(weekStart(r.date), () => []).add(r);
  }
  final weeks = <ReportWeek>[];
  var worked = 0, target = 0;
  for (final e in byWeek.entries) {
    final days = <ReportDay>[];
    var wWorked = 0, wTarget = 0;
    for (final r in e.value) {
      final due = r.key.compareTo(todayKey) <= 0;
      final items = buildTimeline(r.clockings, r.key, r.key == todayKey, r.cfg, today);
      final blocks = items.where((i) => !i.isBreak).toList();
      final lunchMs = blocks.fold<int>(0, (s, i) => s + i.lunchMs);
      final breakMs = items.where((i) => i.isBreak).fold<int>(0, (s, i) => s + i.ms);
      final hasClockings = r.clockings.isNotEmpty;
      final off = r.off == null ? null : [offLabel(L10n.current, r.off!), ...r.absenceLabels].join(' - ');
      days.add(ReportDay(
        row: r,
        clockings: blocks.isEmpty
            ? (off ?? '-')
            : blocks.map((b) => '${_hm(b.from.time)} - ${b.to == null ? L10n.current.pdfNoClockOut : _hm(b.to!.time)}').join('    ') + (off == null ? '' : '    ($off)'),
        lunch: lunchMs > 0 ? '${r.cfg.breakStart}-${r.cfg.breakEnd} (${_short(lunchMs)})${r.lunchEdited ? ' *' : ''}' : (r.lunchEdited ? '${L10n.current.none.toLowerCase()} *' : '-'),
        breaks: breakMs > 0 ? fmtDuration(breakMs) : '-',
        worked: hasClockings ? fmtDuration(r.ms) : '-',
        target: r.off != null ? '-' : fmtDuration(r.target),
        diff: hasClockings && due ? _signed(r.ms - r.target) : '-',
        due: due,
      ));
      if (due) {
        wWorked += r.ms;
        wTarget += r.target;
      }
    }
    weeks.add(ReportWeek(e.key, days, wWorked, wTarget));
    worked += wWorked;
    target += wTarget;
  }
  weeks.sort((a, b) => a.monday.compareTo(b.monday));
  return ReportModel(month, weeks, worked, target, summary.fullTarget);
}

String _weekLabel(DateTime monday, DateTime month) {
  final first = monday.isBefore(DateTime(month.year, month.month, 1)) ? DateTime(month.year, month.month, 1) : monday;
  final friday = DateTime(monday.year, monday.month, monday.day + 4);
  final lastOfMonth = DateTime(month.year, month.month + 1, 0);
  final last = friday.isAfter(lastOfMonth) ? lastOfMonth : friday;
  String dm(DateTime d) => '${pad(d.day)}/${pad(d.month)}';
  return '${dm(first)} - ${dm(last)}';
}

Future<Uint8List> buildMonthReportPdf({required PeriodSummary summary, required DateTime month, required String employee, DateTime? now}) async {
  final today = now ?? DateTime.now();
  final l = L10n.current;
  final m = buildReportModel(summary, month, today);
  // Roboto instead of the built-in Helvetica, which has no accents (incidencias and absences are in Spanish).
  final base = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
  final doc = pw.Document(title: l.pdfTitle(monthName(month.month), '${month.year}'), author: employee);

  const grey = PdfColor.fromInt(0xFFEEEEEE);
  const weekGrey = PdfColor.fromInt(0xFFF6F6F6);
  const green = PdfColor.fromInt(0xFF2E7D32);
  const red = PdfColor.fromInt(0xFFC62828);
  const muted = PdfColor.fromInt(0xFF666666);
  PdfColor diffColor(int ms) => ms >= 0 ? green : red;

  // Compact cells so a whole month (up to 6 weeks) fits on one A4 page.
  pw.Widget cell(String t, {bool bold = false, pw.TextAlign align = pw.TextAlign.left, PdfColor? color, double size = 9}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: pw.Text(t, textAlign: align, style: pw.TextStyle(fontSize: size, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color)),
      );
  pw.Widget empty() => pw.SizedBox();

  final widths = <int, pw.TableColumnWidth>{
    0: const pw.FixedColumnWidth(52),
    1: const pw.FlexColumnWidth(3.4),
    2: const pw.FlexColumnWidth(2),
    3: const pw.FixedColumnWidth(46),
    4: const pw.FixedColumnWidth(50),
    5: const pw.FixedColumnWidth(50),
    6: const pw.FixedColumnWidth(50),
  };

  final rows = <pw.TableRow>[
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: grey),
      children: [
        cell(l.pdfDay, bold: true),
        cell(l.pdfClockings, bold: true),
        cell(l.lunchBreak, bold: true),
        cell(l.pdfBreaks, bold: true, align: pw.TextAlign.right),
        cell(l.worked, bold: true, align: pw.TextAlign.right),
        cell(l.target, bold: true, align: pw.TextAlign.right),
        cell(l.pdfDiff, bold: true, align: pw.TextAlign.right),
      ],
    ),
  ];
  for (final w in m.weeks) {
    for (final d in w.days) {
      final r = d.row;
      final c = d.due ? null : muted;
      rows.add(pw.TableRow(children: [
        cell('${weekdayShort(r.date.weekday)} ${pad(r.date.day)}/${pad(r.date.month)}', bold: true, color: c),
        cell(d.clockings, color: c),
        cell(d.lunch, color: c),
        cell(d.breaks, align: pw.TextAlign.right, color: c),
        cell(d.worked, align: pw.TextAlign.right, color: c),
        cell(d.target, align: pw.TextAlign.right, color: c),
        cell(d.diff, align: pw.TextAlign.right, bold: true, color: d.diff == '-' ? muted : diffColor(r.ms - r.target)),
      ]));
    }
    // Week subtotal right after its days.
    rows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: weekGrey),
      children: [
        cell(l.pdfWeek, bold: true),
        cell(_weekLabel(w.monday, m.month), color: muted),
        empty(),
        empty(),
        cell(fmtDuration(w.worked), bold: true, align: pw.TextAlign.right),
        cell(fmtDuration(w.target), bold: true, align: pw.TextAlign.right),
        cell(_signed(w.diff), bold: true, align: pw.TextAlign.right, color: diffColor(w.diff)),
      ],
    ));
  }

  pw.Widget stat(String label, String value, {PdfColor? color}) => pw.Expanded(
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: muted)),
          pw.SizedBox(height: 1),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color)),
        ]),
      );

  final inCurrentMonth = today.year == month.year && today.month == month.month;
  final edited = m.weeks.any((w) => w.days.any((d) => d.row.lunchEdited));

  doc.addPage(pw.MultiPage(
    theme: pw.ThemeData.withFont(base: base, bold: bold),
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 30),
    footer: (ctx) => pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(ctx.pagesCount > 1 ? l.pdfPage('${ctx.pageNumber}', '${ctx.pagesCount}') : '', style: const pw.TextStyle(fontSize: 8, color: muted)),
    ),
    build: (ctx) => [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(l.pdfTitle(monthName(month.month), '${month.year}'), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text('${employee.isEmpty ? '' : '$employee  -  '}${pad(today.day)}/${pad(today.month)}/${today.year}', style: const pw.TextStyle(fontSize: 8.5, color: muted)),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Table(
        columnWidths: widths,
        border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.4), bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
        children: rows,
      ),
      pw.SizedBox(height: 10),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey500), borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Row(children: [
          stat(l.worked, fmtDuration(m.worked)),
          stat(inCurrentMonth ? l.pdfExpectedSoFar : l.pdfExpected, fmtDuration(m.target)),
          stat(l.pdfDifference, _signed(m.diff), color: diffColor(m.diff)),
          if (inCurrentMonth) ...[
            stat(l.monthTarget, fmtDuration(m.fullTarget)),
            stat(m.fullTarget > m.worked ? l.stillToWork : l.pdfOverTarget, fmtDuration((m.fullTarget - m.worked).abs())),
          ],
        ]),
      ),
      pw.SizedBox(height: 6),
      pw.Text(
        '${l.pdfFootnote}${edited ? l.pdfLunchEdited : ''}',
        style: const pw.TextStyle(fontSize: 7, color: muted),
      ),
    ],
  ));

  return doc.save();
}
