import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const apiBase = 'https://hcs.eratime.eu/api/proxy';
const featureBase = '$apiBase/flt/myera/feature';

const _baseHeaders = {
  'Content-Type': 'application/x-www-form-urlencoded',
  'hcs-application-key': 'ERAATTENDANCE',
  'hcs-customer-key': 'lufthansa',
};

String pad(int n) => n.toString().padLeft(2, '0');
String ymd(DateTime d) => '${d.year}-${pad(d.month)}-${pad(d.day)}';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class Session {
  Session(this.user, this.token);
  final String user;
  final String token;
}

class Clocking {
  Clocking(this.isIn, this.time);
  final bool isIn;
  final DateTime time;
}

/// One day of the calendar endpoint (absences, clockings, schedule, holiday).
class CalendarDay {
  CalendarDay(this.date, this.clockings, this.absences, this.scheduleLabel, this.holiday, this.notes, this.absenceShort, this.absenceColor, this.anomalies, this.absenceLabels);

  final String date;
  final List<Clocking> clockings;
  final List<String> absences;
  final String? scheduleLabel;
  final bool holiday;
  final List<String> notes;
  final String? absenceShort;
  final String? absenceColor; // hex RRGGBB
  final List<String> anomalies; // "incidencias" of the day (labels)
  final List<String> absenceLabels; // absence type labels, e.g. "U-Vacaciones"

  bool get off => absences.isNotEmpty || holiday;

  factory CalendarDay.fromJson(Map<String, dynamic> j) {
    final clockings = ((j['clockings'] as List?) ?? [])
        .map((c) => Clocking(c['in'] == true, DateTime.parse(c['time'] as String)))
        .toList();
    final absences = ((j['absences'] as List?) ?? [])
        .map((a) => ((a['description'] ?? a['absence']?['label'] ?? '') as String))
        .toList();
    final schedule = j['schedule'] as Map<String, dynamic>?;
    final firstAbsence = ((j['absences'] as List?) ?? []).isEmpty ? null : (j['absences'] as List).first['absence'] as Map<String, dynamic>?;
    return CalendarDay(
      j['date'] as String,
      clockings,
      absences,
      schedule?['dayschedule']?['label'] as String?,
      (j['publicHoliday'] as Map?)?['enabled'] == true,
      ((j['notes'] as List?) ?? []).map((n) => n is Map ? (n['text'] ?? n['description'] ?? '').toString() : n.toString()).toList(),
      firstAbsence?['shortLabel'] as String?,
      firstAbsence?['color']?['background'] as String?,
      ((j['anomalies'] as List?) ?? []).map((x) => (x is Map ? (x['label'] ?? '') : x).toString()).where((x) => x.isNotEmpty).toList(),
      ((j['absences'] as List?) ?? []).map((x) => (x['absence']?['label'] ?? '').toString()).where((x) => x.isNotEmpty).toList(),
    );
  }
}

class Counter {
  Counter(this.label, this.unit, this.value);
  final String label;
  final String unit;
  final num? value;
}

class Message {
  Message(this.id, this.title, this.body, this.date, this.read);
  final String id;
  final String title;
  final String body;
  final String date;
  final bool read;
}

class RequestItem {
  RequestItem({
    required this.code,
    required this.allowDelete,
    required this.type,
    required this.status,
    required this.description,
    required this.from,
    required this.to,
    required this.requested,
    this.remark,
    this.fromCalendar = false,
  });
  final String code;
  final bool allowDelete;
  final String type;
  final String status;
  final String description;
  final String from;
  final String? to;
  final String requested;
  final String? remark;

  /// True for absences taken from the calendar that have no request behind them.
  final bool fromCalendar;
}

/// Absence type available for new requests (`requests/absence/items`).
class AbsenceType {
  AbsenceType({
    required this.code,
    required this.label,
    required this.allowFullday,
    required this.allowDaypart,
    required this.allowHours,
    required this.needRemark,
    required this.needFile,
    this.guidelines,
  });
  final String code;
  final String label;
  final bool allowFullday;
  final bool allowDaypart;
  final bool allowHours;
  final bool needRemark;
  final bool needFile;
  final String? guidelines;
}

class RegistrationRow {
  RegistrationRow(this.date, this.columns, this.anomaly, this.holiday, this.unapproved);
  final bool unapproved;
  final String date;
  final List<String> columns;
  final bool anomaly;
  final bool holiday;
}

class Registrations {
  Registrations(this.titles, this.rows, this.totals);
  final List<String> titles;
  final List<RegistrationRow> rows;
  final List<String?> totals;
}

class MyEraApi {
  MyEraApi._();
  static final MyEraApi instance = MyEraApi._();

  static const _secure = FlutterSecureStorage();
  Session? _cached;
  DateTime? _cachedAt;

  Map<String, String> _auth(Session s) => {..._baseHeaders, 'hcs-user-code': s.user, 'hcs-token': s.token};

  Future<Map<String, dynamic>> _getJson(Session s, String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('$featureBase$path').replace(queryParameters: query);
    final res = await http.get(uri, headers: _auth(s));
    if (res.statusCode != 200) throw ApiException('HTTP ${res.statusCode} on $path');
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  // --- credentials ---------------------------------------------------------

  Future<bool> hasCredentials() async => (await _secure.read(key: 'user')) != null;

  Future<String?> savedName() async => (await SharedPreferences.getInstance()).getString('fullName');

  Future<void> clearCredentials() async {
    await _secure.deleteAll();
    final p = await SharedPreferences.getInstance();
    await p.remove('fullName');
    await p.remove('employeeCode');
    _cached = null;
  }

  Future<String> get employeeCode async {
    final code = (await SharedPreferences.getInstance()).getString('employeeCode');
    if (code == null) throw ApiException('Missing session, please log in again');
    return code;
  }

  // --- auth ----------------------------------------------------------------

  Future<Session> _login(String user, String pass) async {
    final res = await http.post(
      Uri.parse('$apiBase/login'),
      headers: {..._baseHeaders, 'hcs-user': user, 'hcs-pass': pass},
    );
    final token = res.headers['hcs-token'];
    if (token == null || token.isEmpty) {
      throw ApiException('Login failed (HTTP ${res.statusCode}). Check your user and password.');
    }
    return Session(user, token);
  }

  /// Verifies the credentials, stores them securely and caches the employee info.
  Future<String> loginAndSave(String user, String pass) async {
    final s = await _login(user, pass);
    final info = await _getJson(s, '/user/info');
    final data = info['data'] as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    await _secure.write(key: 'user', value: user);
    await _secure.write(key: 'pass', value: pass);
    await prefs.setString('employeeCode', data['employee']['code'] as String);
    final name = data['name']['full'] as String;
    await prefs.setString('fullName', name);
    _cached = s;
    _cachedAt = DateTime.now();
    return name;
  }

  /// Logs in with the saved credentials (token reused for a few minutes).
  Future<Session> session() async {
    if (_cached != null && DateTime.now().difference(_cachedAt!) < const Duration(minutes: 5)) return _cached!;
    final user = await _secure.read(key: 'user');
    final pass = await _secure.read(key: 'pass');
    if (user == null || pass == null) throw ApiException('Missing session, please log in again');
    _cached = await _login(user, pass);
    _cachedAt = DateTime.now();
    return _cached!;
  }

  // --- data ----------------------------------------------------------------

  Future<List<CalendarDay>> calendar(DateTime start, DateTime end) async {
    final s = await session();
    final code = await employeeCode;
    final j = await _getJson(s, '/calendar/employees/${Uri.encodeComponent(code)}', {
      'DATE_START': ymd(start),
      'DATE_END': ymd(end),
    });
    return ((j['data']['calendar'] as List?) ?? []).map((d) => CalendarDay.fromJson(d as Map<String, dynamic>)).toList();
  }

  /// type: 1 = clock in, 2 = clock out
  Future<void> clock(int type) async {
    final s = await session();
    final res = await http.post(Uri.parse('$featureBase/clocking?TYPE=$type'), headers: _auth(s));
    if (res.statusCode < 200 || res.statusCode >= 300) throw ApiException('Clocking failed (HTTP ${res.statusCode})');
  }

  Future<List<Counter>> counters() async {
    final s = await session();
    final code = await employeeCode;
    final j = await _getJson(s, '/employees/${Uri.encodeComponent(code)}/counters');
    return ((j['data']['counters'] as List?) ?? [])
        .map((c) => Counter(c['label'].toString().replaceAll(RegExp(r'\s+'), ' ').trim(), (c['unit']?['label'] ?? '').toString(), c['value'] as num?))
        .toList();
  }

  Future<Registrations> registrations(DateTime start, DateTime end) async {
    final s = await session();
    final j = await _getJson(s, '/registrations/list', {'DATE_START': ymd(start), 'DATE_END': ymd(end)});
    final data = j['data'] as Map<String, dynamic>;
    final cols = ((data['columns'] as List?) ?? []).cast<Map<String, dynamic>>();
    final rows = ((data['rows'] as List?) ?? []).map((r) {
      final m = r as Map<String, dynamic>;
      return RegistrationRow(
        m['date'] as String,
        ((m['columns'] as List?) ?? []).map((c) => (c['label'] ?? '').toString()).toList(),
        m['anomaly'] == true,
        (m['publicHoliday'] as Map?)?['enabled'] == true,
        m['unapproved'] == true,
      );
    }).toList();
    return Registrations(
      cols.map((c) => c['title'].toString()).toList(),
      rows,
      cols.map((c) => c['total']?.toString()).toList(),
    );
  }

  /// Every request of the current year (by the date of the act, newest first): the requests list
  /// with all states and types, plus the calendar absences that have no request behind them
  /// (e.g. vacations loaded before the requests existed in MyEra).
  Future<List<RequestItem>> requests() async {
    final s = await session();
    final year = DateTime.now().year;
    final opts = await _getJson(s, '/requests/data/options');
    final filters = [
      for (final f in ((opts['data']?['filters'] as List?) ?? []))
        {'code': f['code'], 'values': [for (final v in (f['values'] as List? ?? [])) v['code']]},
    ];
    final j = await _getJson(s, '/requests/list', {if (filters.isNotEmpty) 'filter': jsonEncode(filters)});
    final out = <RequestItem>[];
    for (final g in ((j['data']['groups'] as List?) ?? [])) {
      for (final r in ((g['requests'] as List?) ?? [])) {
        final from = (r['date'] ?? '').toString();
        final to = r['dateEnd']?.toString() ?? from;
        // Keep the requests that touch the current year.
        if (from.compareTo('$year-01-01') < 0 && to.compareTo('$year-01-01') < 0) continue;
        if (from.compareTo('$year-12-31') > 0) continue;
        out.add(RequestItem(
          code: (r['code'] ?? '').toString(),
          allowDelete: r['allowDelete'] == true,
          type: (r['type']?['label'] ?? '').toString(),
          status: (r['status']?['label'] ?? '').toString(),
          description: (r['description'] ?? '').toString(),
          from: from,
          to: r['dateEnd']?.toString(),
          requested: (r['requested'] ?? '').toString(),
          remark: r['remark']?.toString(),
        ));
      }
    }

    // Absence days from the calendar not covered by a request of the same absence type.
    final covered = <String>{};
    for (final r in out) {
      if (r.type != 'ausencia') continue;
      for (var d = DateTime.parse(r.from); !d.isAfter(DateTime.parse(r.to ?? r.from)); d = DateTime(d.year, d.month, d.day + 1)) {
        covered.add('${ymd(d)}|${r.description}');
      }
    }
    final days = await calendar(DateTime(year, 1, 1), DateTime(year, 12, 31));
    final loose = <String, List<DateTime>>{}; // label -> days
    for (final d in days) {
      for (final label in d.absenceLabels) {
        if (!covered.contains('${d.date}|$label')) (loose[label] ??= []).add(DateTime.parse(d.date));
      }
    }
    bool onlyWeekendBetween(DateTime a, DateTime b) {
      for (var d = DateTime(a.year, a.month, a.day + 1); d.isBefore(b); d = DateTime(d.year, d.month, d.day + 1)) {
        if (d.weekday < 6) return false;
      }
      return true;
    }

    loose.forEach((label, ds) {
      ds.sort();
      var start = ds.first, end = ds.first;
      void flush() => out.add(RequestItem(
            code: '',
            allowDelete: false,
            type: 'ausencia',
            status: 'registrada',
            description: label,
            from: ymd(start),
            to: end == start ? null : ymd(end),
            requested: '',
            fromCalendar: true,
          ));
      for (final d in ds.skip(1)) {
        if (onlyWeekendBetween(end, d)) {
          end = d;
        } else {
          flush();
          start = end = d;
        }
      }
      flush();
    });

    // Newest event first (by the start date of the act, then by its end).
    out.sort((x, y) {
      final c = y.from.compareTo(x.from);
      return c != 0 ? c : (y.to ?? y.from).compareTo(x.to ?? x.from);
    });
    return out;
  }

  /// `data.messages[]`: `message` is the text (first line = title, split by \r), `code`, `read`, `time`.
  Future<List<Message>> messages() async {
    final s = await session();
    final j = await _getJson(s, '/messages');
    final list = (j['data']?['messages'] as List?) ?? [];
    return list.map((m) {
      final x = m as Map<String, dynamic>;
      final lines = (x['message'] ?? '').toString().split('\r');
      return Message(
        (x['code'] ?? '').toString(),
        lines.first,
        lines.skip(1).join('\n').trim(),
        (x['time'] ?? '').toString(),
        x['read'] == true,
      );
    }).toList();
  }

  Future<void> setMessageRead(String id, bool read) async {
    final s = await session();
    final res = await http.put(Uri.parse('$featureBase/messages/$id/${read ? 'read' : 'unread'}'), headers: _auth(s));
    if (res.statusCode >= 300) throw ApiException('HTTP ${res.statusCode}');
  }

  Future<void> readAllMessages() async {
    final s = await session();
    final res = await http.put(Uri.parse('$featureBase/messages/readall'), headers: _auth(s));
    if (res.statusCode >= 300) throw ApiException('HTTP ${res.statusCode}');
  }

  // --- requests (create / delete) -----------------------------------------

  Uri _codeUri(String path, String code) => Uri.parse('$featureBase/$path/%7B$code%7D');

  Future<List<AbsenceType>> absenceTypes() async {
    final s = await session();
    final j = await _getJson(s, '/requests/absence/items');
    return ((j['data']?['absences'] as List?) ?? [])
        .map((a) => AbsenceType(
              code: a['code'] as String,
              label: (a['label'] ?? '').toString(),
              allowFullday: a['allowFullday'] == true,
              allowDaypart: a['allowDaypart'] == true,
              allowHours: a['allowHours'] == true,
              needRemark: a['needRemark'] == true,
              needFile: a['needFile'] == true,
              guidelines: a['guidelines']?.toString(),
            ))
        .toList();
  }

  Future<void> _postForm(Uri uri, Map<String, String> body) async {
    final s = await session();
    final res = await http.post(uri, headers: _auth(s), body: body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      var detail = '';
      try {
        detail = (jsonDecode(utf8.decode(res.bodyBytes)) as Map)['meta']?['status']?['name']?.toString() ?? '';
      } catch (_) {}
      throw ApiException('Request failed (HTTP ${res.statusCode}${detail.isEmpty ? '' : ' $detail'})');
    }
  }

  /// POST requests/absence/{code}. Full days: [start]..[end]. Partial: [start] only with [dayPart]
  /// (1 = first part, 2 = second part) or [hourStart]/[hourEnd] (HH:mm).
  Future<void> requestAbsence(
    AbsenceType type, {
    required DateTime start,
    DateTime? end,
    int dayPart = 0,
    String? hourStart,
    String? hourEnd,
    String? remark,
  }) {
    final body = <String, String>{
      'DATE': ymd(start),
      'DATE_START': ymd(start),
      'DATE_END': ymd(end ?? start),
      if (dayPart > 0 && dayPart < 3) 'DAY_PART': '$dayPart',
      'HOUR_START': ?hourStart,
      'HOUR_END': ?hourEnd,
      if (remark != null && remark.isNotEmpty) 'REMARK': remark,
    };
    return _postForm(_codeUri('requests/absence', type.code), body);
  }

  /// POST requests/clocking ("fichaje en reloj"): worked hours [hourStart]..[hourEnd] (HH:mm) on [date].
  Future<void> requestClocking(DateTime date, String hourStart, String hourEnd, {String? remark}) {
    return _postForm(Uri.parse('$featureBase/requests/clocking'), {
      'DATE': ymd(date),
      'HOUR_START': hourStart,
      'HOUR_END': hourEnd,
      if (remark != null && remark.isNotEmpty) 'REMARK': remark,
    });
  }

  /// DELETE requests/{code}: withdraws a pending request (only when `allowDelete`).
  Future<void> deleteRequest(String code) async {
    final s = await session();
    final res = await http.delete(Uri.parse('$featureBase/requests/%7B$code%7D'), headers: _auth(s));
    if (res.statusCode < 200 || res.statusCode >= 300) throw ApiException('Delete failed (HTTP ${res.statusCode})');
  }
}
