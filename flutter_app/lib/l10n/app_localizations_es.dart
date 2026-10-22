// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get retry => 'Reintentar';

  @override
  String get today => 'Hoy';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get close => 'Cerrar';

  @override
  String get send => 'Enviar';

  @override
  String get apply => 'Aplicar';

  @override
  String get none => 'Ninguna';

  @override
  String get navHome => 'Inicio';

  @override
  String get navSummary => 'Resumen';

  @override
  String get navRequests => 'Solicitudes';

  @override
  String get navCounters => 'Contadores';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get messages => 'Mensajes';

  @override
  String get logOut => 'Cerrar sesión';

  @override
  String get loginUnreachable =>
      'No se pudo conectar con MyEra. Revisa tu conexión.';

  @override
  String get loginEnterAll =>
      'Introduce tu clave de cliente, usuario y contraseña';

  @override
  String get customerKey => 'Clave de cliente';

  @override
  String get user => 'Usuario';

  @override
  String get password => 'Contraseña';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String get logIn => 'Iniciar sesión';

  @override
  String get loginNote =>
      'Las credenciales se guardan cifradas en este dispositivo y solo se envían a MyEra.';

  @override
  String get clockIn => 'Fichar entrada';

  @override
  String get clockOut => 'Fichar salida';

  @override
  String clockedInAt(String time) {
    return 'Entrada fichada a las $time';
  }

  @override
  String clockedOutAt(String time) {
    return 'Salida fichada a las $time';
  }

  @override
  String get newRequest => 'Nueva solicitud';

  @override
  String get worked => 'Trabajado';

  @override
  String get target => 'Objetivo';

  @override
  String get lunch => 'Comida';

  @override
  String get edited => 'editado';

  @override
  String get noClockings => 'Sin fichajes';

  @override
  String get noClockingsYet => 'Aún sin fichajes';

  @override
  String get nowLabel => 'ahora';

  @override
  String breakDuration(String duration) {
    return 'pausa $duration';
  }

  @override
  String get absent => 'Ausente';

  @override
  String get holiday => 'Festivo';

  @override
  String get absentInitial => 'A';

  @override
  String get holidayInitial => 'F';

  @override
  String get noTargetToday => 'Sin objetivo hoy';

  @override
  String lunchBreakOn(String day) {
    return 'Pausa de comida · $day';
  }

  @override
  String get lunchOnlyThisDay =>
      'Solo para este día. Tus ajustes semanales no cambian.';

  @override
  String fromTime(String time) {
    return 'Desde $time';
  }

  @override
  String toTime(String time) {
    return 'Hasta $time';
  }

  @override
  String get endAfterStart => 'El final debe ser posterior al inicio.';

  @override
  String get resetToSettings => 'Restablecer a ajustes';

  @override
  String get week => 'Semana';

  @override
  String get month => 'Mes';

  @override
  String get exportPdf => 'Exportar el mes a PDF';

  @override
  String get stillLoading => 'Aún cargando, inténtalo de nuevo en un momento';

  @override
  String pdfError(String error) {
    return 'No se pudo crear el PDF: $error';
  }

  @override
  String ofTargetThisWeek(String target) {
    return 'de $target esta semana';
  }

  @override
  String get monthTarget => 'Objetivo del mes';

  @override
  String get stillToWork => 'Pendiente de trabajar';

  @override
  String get monthFootnote =>
      'El objetivo cuenta los días hasta hoy. Cifras pequeñas por día: trabajado arriba, objetivo abajo.';

  @override
  String get overMonthTarget => 'Por encima del objetivo';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get settingsClocking => 'Fichajes';

  @override
  String get clockReminders => 'Recordatorios de fichaje';

  @override
  String get clockRemindersSub =>
      'Notificación en cada entrada/salida programada';

  @override
  String get autoClock => 'Fichaje automático';

  @override
  String get autoClockSub =>
      'Ficha entrada/salida automáticamente a las horas programadas';

  @override
  String get weeklySchedule => 'Horario semanal';

  @override
  String get tapToChange => 'Toca una hora para cambiarla';

  @override
  String get presetStandard => 'Estándar 7h 36m';

  @override
  String get presetIrregular => 'Irregular';

  @override
  String get presetStandardTitle => 'Estándar 7h 36m';

  @override
  String get presetIrregularTitle => 'Horario irregular';

  @override
  String get presetStandardDesc =>
      '7h 36m al día desde la hora de inicio, con la pausa indicada. La salida se calcula.';

  @override
  String get presetIrregularDesc =>
      '8h de lunes a jueves (inicio + 8h + pausa) y 6h el viernes sin pausa (inicio + 6h).';

  @override
  String get start => 'Inicio';

  @override
  String get breakFrom => 'Pausa desde';

  @override
  String get breakTo => 'Pausa hasta';

  @override
  String get autoClockWarning =>
      'La app fichará la entrada y la salida por ti a las horas programadas, incluso con la app cerrada. Android puede retrasarlo u omitirlo (ahorro de batería, dispositivo en reposo). Antes comprueba MyEra y nunca duplica un fichaje, pero sigues siendo responsable de tus fichajes. Revísalos.';

  @override
  String get iUnderstand => 'Lo entiendo';

  @override
  String get savedOk => 'Guardado';

  @override
  String savedWarnShortBreak(String days) {
    return 'Guardado. Aviso: pausa de menos de 30 min el $days';
  }

  @override
  String get inLabel => 'Entrada';

  @override
  String get outLabel => 'Salida';

  @override
  String get lunchBreak => 'Pausa de comida';

  @override
  String netTime(String duration) {
    return '$duration netas';
  }

  @override
  String get scheduleFootnote =>
      'La pausa de comida no se paga y se descuenta del tiempo trabajado del día. La pausa mínima exigida es de 30 min; desactívala en los días sin pausa. El objetivo solo sirve para compararlo con el tiempo trabajado en el resumen.';

  @override
  String get fromLabel => 'Desde';

  @override
  String get toLabel => 'Hasta';

  @override
  String noRequestsYear(String year) {
    return 'Sin solicitudes en $year';
  }

  @override
  String get absenceRequest => 'Solicitud de ausencia';

  @override
  String get clockingRequest => 'Solicitud de fichaje';

  @override
  String get withdrawTitle => '¿Retirar la solicitud?';

  @override
  String get withdraw => 'Retirar';

  @override
  String get holdToWithdraw => 'mantén para retirar';

  @override
  String get fromCalendar => 'del calendario';

  @override
  String get newShort => 'Nueva';

  @override
  String get requestCancellation => 'Solicitar cancelación';

  @override
  String get holdToCancel => 'mantén para solicitar la cancelación';

  @override
  String get cancelNotAvailable =>
      'Esta ausencia no se puede cancelar desde la app.';

  @override
  String get cancellationRequested => 'Cancelación solicitada';

  @override
  String get cancelAbsenceNote =>
      'Se enviará una solicitud de cancelación a MyEra. La ausencia se mantiene hasta que se apruebe.';

  @override
  String get absenceToCancel => 'Ausencia';

  @override
  String get chooseAbsence => 'Elige la ausencia a cancelar';

  @override
  String get chooseType => 'Elige un tipo de ausencia';

  @override
  String get chooseDate => 'Elige una fecha';

  @override
  String get endBeforeStart => 'La fecha final es anterior a la inicial';

  @override
  String get chooseHours => 'Elige las horas';

  @override
  String get remarkRequired => 'Este tipo requiere una observación';

  @override
  String get needsAttachment =>
      'Este tipo necesita un adjunto, que la app aún no admite. Usa la web.';

  @override
  String get sendRequestTitle => '¿Enviar la solicitud?';

  @override
  String get requestSent => 'Solicitud enviada';

  @override
  String get typeLabel => 'Tipo';

  @override
  String get fullDay => 'Día completo';

  @override
  String get firstPart => '1ª parte';

  @override
  String get secondPart => '2ª parte';

  @override
  String get hours => 'Horas';

  @override
  String get startDate => 'Fecha de inicio';

  @override
  String get dateLabel => 'Fecha';

  @override
  String get endDateOptional => 'Fecha final (opcional)';

  @override
  String get firstPartSuffix => '(primera parte)';

  @override
  String get secondPartSuffix => '(segunda parte)';

  @override
  String get remark => 'Observación';

  @override
  String get remarkRequiredLabel => 'Observación (obligatoria)';

  @override
  String get sendRequest => 'Enviar solicitud';

  @override
  String get chooseDateStartEnd => 'Elige fecha, inicio y fin';

  @override
  String get endAfterStartShort => 'El fin debe ser posterior al inicio';

  @override
  String clockingSummary(String date, String from, String to) {
    return 'Fichaje $date\n$from – $to';
  }

  @override
  String get noCounters => 'Sin contadores';

  @override
  String get noMessages => 'Sin mensajes';

  @override
  String get markAllRead => 'Marcar todos como leídos';

  @override
  String get markUnread => 'Marcar como no leído';

  @override
  String get messageTitle => 'Mensaje';

  @override
  String errHttp(String code, String path) {
    return 'HTTP $code en $path';
  }

  @override
  String errHttpCode(String code) {
    return 'HTTP $code';
  }

  @override
  String get errMissingSession => 'Falta la sesión, vuelve a iniciar sesión';

  @override
  String errLogin(String code) {
    return 'Error al iniciar sesión (HTTP $code). Revisa tu clave de cliente, usuario y contraseña.';
  }

  @override
  String errClocking(String code) {
    return 'Error al fichar (HTTP $code)';
  }

  @override
  String errRequest(String code, String detail) {
    return 'Error en la solicitud (HTTP $code$detail)';
  }

  @override
  String errDelete(String code) {
    return 'Error al retirar (HTTP $code)';
  }

  @override
  String get notifChannelName => 'Recordatorios de fichaje';

  @override
  String get notifChannelDesc =>
      'Recordatorios de entrada/salida y resultados del fichaje automático';

  @override
  String get notifTimeToClockIn => 'Hora de fichar la entrada';

  @override
  String get notifTimeToClockOut => 'Hora de fichar la salida';

  @override
  String get notifOpenApp => 'Abre MyEra.';

  @override
  String get autoInSkipped => 'Entrada automática omitida';

  @override
  String get autoOutSkipped => 'Salida automática omitida';

  @override
  String autoMissedBody(String minutes) {
    return 'Retraso de $minutes min (el dispositivo estaba en reposo). Ficha manualmente.';
  }

  @override
  String get autoAbsenceBody => 'Hoy es una ausencia o un festivo.';

  @override
  String get autoAlreadyClocking => 'Ya hay un fichaje hoy.';

  @override
  String get autoNoOpenIn =>
      'No hay ninguna entrada abierta (ya fichaste la salida o nunca fichaste la entrada).';

  @override
  String get autoInDone => 'Entrada automática fichada';

  @override
  String get autoOutDone => 'Salida automática fichada';

  @override
  String get autoInUnconfirmed => 'Entrada automática enviada, sin confirmar';

  @override
  String get autoOutUnconfirmed => 'Salida automática enviada, sin confirmar';

  @override
  String autoDoneInBody(String time) {
    return 'Entrada fichada a las $time.';
  }

  @override
  String autoDoneOutBody(String time) {
    return 'Salida fichada a las $time.';
  }

  @override
  String get autoUnconfirmedBody =>
      'No se pudo confirmar en MyEra. Compruébalo manualmente.';

  @override
  String get autoInFailed => 'Falló la entrada automática';

  @override
  String get autoOutFailed => 'Falló la salida automática';

  @override
  String autoFailedBody(String error) {
    return '$error. Ficha manualmente.';
  }

  @override
  String pdfTitle(String month, String year) {
    return 'Informe de tiempo - $month $year';
  }

  @override
  String get pdfDay => 'Día';

  @override
  String get pdfClockings => 'Fichajes';

  @override
  String get pdfBreaks => 'Pausas';

  @override
  String get pdfDiff => 'Dif.';

  @override
  String get pdfWeek => 'Semana';

  @override
  String get pdfExpectedSoFar => 'Esperado hasta hoy';

  @override
  String get pdfExpected => 'Esperado';

  @override
  String get pdfDifference => 'Diferencia';

  @override
  String get pdfOverTarget => 'Por encima del objetivo';

  @override
  String get pdfNoClockOut => 'sin salida';

  @override
  String get pdfFootnote =>
      'Trabajado = tiempo entre fichajes menos la pausa de comida. Los objetivos semanales siguen los objetivos diarios configurados; en las semanas con una ausencia o un festivo, la media semanal se reparte entre los días restantes.';

  @override
  String get pdfLunchEdited =>
      ' * Pausa de comida modificada manualmente ese día.';

  @override
  String pdfPage(String page, String total) {
    return 'Página $page / $total';
  }
}
