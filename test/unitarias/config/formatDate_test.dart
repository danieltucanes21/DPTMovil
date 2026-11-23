import 'package:dpt_movil/config/formatDate.dart';
import 'package:flutter_test/flutter_test.dart';

//fechas en palabras para el encabezado del grupo
void main() {
  const String capa = "config";
  const String tipo = "unitaria";

  test('$capa - $tipo - fechaLarga - yyyy-MM-dd en palabras', () {
    expect(FormatDate.fechaLarga('2025-08-04'), '4 de agosto de 2025');
    expect(FormatDate.fechaLarga('2025-12-28'), '28 de diciembre de 2025');
    expect(FormatDate.fechaLarga('2026-01-01'), '1 de enero de 2026');
  });

  test('$capa - $tipo - fechaLarga - sin fecha da null', () {
    expect(FormatDate.fechaLarga(null), isNull);
    expect(FormatDate.fechaLarga('  '), isNull);
  });

  test('$capa - $tipo - fechaLarga - una fecha ilegible se devuelve igual', () {
    expect(FormatDate.fechaLarga('pronto'), 'pronto');
  });

  test('$capa - $tipo - fechaConDia - dia de la semana, dia y mes', () {
    expect(FormatDate.fechaConDia(DateTime(2025, 8, 19)), 'Martes, 19 de agosto');
    expect(FormatDate.fechaConDia(DateTime(2026, 11, 22)), 'Domingo, 22 de noviembre');
  });

  test('$capa - $tipo - horaLegible - reloj de 12 horas', () {
    expect(FormatDate.horaLegible('16:00'), '4:00 p. m.');
    expect(FormatDate.horaLegible('08:05:00'), '8:05 a. m.');
    expect(FormatDate.horaLegible('00:30'), '12:30 a. m.');
    expect(FormatDate.horaLegible('12:00'), '12:00 p. m.');
  });

  test('$capa - $tipo - horaLegible - una hora ilegible se devuelve igual', () {
    expect(FormatDate.horaLegible('tarde'), 'tarde');
    expect(FormatDate.horaLegible('25:00'), '25:00');
  });
}
