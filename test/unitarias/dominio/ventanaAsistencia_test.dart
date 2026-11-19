import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';
import 'package:dpt_movil/domain/entities/ventanaAsistencia.dart';
import 'package:flutter_test/flutter_test.dart';

//regla de la ventana de asistencia (AS-13): desde la hora de inicio del
//horario hasta las 23:59 del dia de clase; el coordinador sin limite. El
//2026-11-19 es jueves
void main() {
  const String capa = "dominio";
  const String tipo = "unitaria";

  Horarioentidad horario(String dia, String inicio, String fin) =>
      Horarioentidad(
        categoria: 'Deportes',
        curso: 'Iniciacion',
        anio: 2026,
        iterable: 1,
        dia: dia,
        horaInicio: inicio,
        horaFin: fin,
        escenario: 'Coliseo',
      );

  Claseentidad clase(DateTime fecha) => Claseentidad(
    codigo: 300,
    idGrupoCategoria: 'Deportes',
    idGrupoCurso: 'Iniciacion',
    idGrupoAnio: 2026,
    idGrupoIterable: 1,
    idInstructor: 'ins1',
    fecha: fecha,
    eliminado: 0,
  );

  final jueves = [horario('JUEVES', '08:00', '10:00')];

  group('Ventana de asistencia:', () {
    test('$capa - $tipo - Hora - lee HH:mm y HH:mm:ss', () {
      expect(VentanaAsistencia.minutosDelDia('08:00'), 480);
      expect(VentanaAsistencia.minutosDelDia('14:30:00'), 870);
      expect(VentanaAsistencia.minutosDelDia('ocho'), isNull);
      expect(VentanaAsistencia.horaCorta('14:30:00'), '14:30');
    });

    test('$capa - $tipo - Horarios del dia - ordenados y con la regla del backend', () {
      final horarios = [
        horario('JUEVES', '14:00:00', '16:00:00'),
        horario('jueves', '08:00', '10:00'),
        horario('VIERNES', '06:00', '07:00'),
        //con tilde el backend no lo cuenta (HO-06)
        horario('Miércoles', '06:00', '07:00'),
      ];

      final delDia = VentanaAsistencia.horariosDelDia(
        horarios,
        DateTime(2026, 11, 19),
      );

      expect(delDia.map((h) => h.horaInicio), ['08:00', '14:00:00']);
      expect(
        VentanaAsistencia.horariosDelDia(horarios, DateTime(2026, 11, 18)),
        isEmpty,
      );
    });

    test('$capa - $tipo - Horario vigente - abre a la hora de inicio', () {
      expect(
        VentanaAsistencia.horarioVigente(jueves, DateTime(2026, 11, 19, 7, 59)),
        isNull,
      );
      expect(
        VentanaAsistencia.horarioVigente(jueves, DateTime(2026, 11, 19, 8)),
        isNotNull,
      );
      //sigue abierta despues de la hora de fin, hasta el final del dia
      expect(
        VentanaAsistencia.horarioVigente(
          jueves,
          DateTime(2026, 11, 19, 23, 59),
        ),
        isNotNull,
      );
    });

    test('$capa - $tipo - Horario vigente - el coordinador no espera la hora', () {
      expect(
        VentanaAsistencia.horarioVigente(
          jueves,
          DateTime(2026, 11, 19, 6),
          sinLimite: true,
        ),
        isNotNull,
      );
      //pero sin clase ese dia no hay horario que usar
      expect(
        VentanaAsistencia.horarioVigente(
          jueves,
          DateTime(2026, 11, 20, 9),
          sinLimite: true,
        ),
        isNull,
      );
    });

    test('$capa - $tipo - Puede editar - solo la clase de hoy dentro de la ventana', () {
      final hoy = clase(DateTime(2026, 11, 19));

      expect(
        VentanaAsistencia.puedeEditar(hoy, jueves, DateTime(2026, 11, 19, 9)),
        isTrue,
      );
      expect(
        VentanaAsistencia.puedeEditar(hoy, jueves, DateTime(2026, 11, 19, 7)),
        isFalse,
      );
      //al dia siguiente ya no se corrige
      expect(
        VentanaAsistencia.puedeEditar(hoy, jueves, DateTime(2026, 11, 20, 0)),
        isFalse,
      );
      //una clase de otro dia, aunque hoy haya clase
      expect(
        VentanaAsistencia.puedeEditar(
          clase(DateTime(2026, 11, 12)),
          jueves,
          DateTime(2026, 11, 19, 9),
        ),
        isFalse,
      );
    });

    test('$capa - $tipo - Puede editar - el coordinador corrige cualquier clase', () {
      expect(
        VentanaAsistencia.puedeEditar(
          clase(DateTime(2026, 11, 12)),
          jueves,
          DateTime(2026, 11, 20, 6),
          sinLimite: true,
        ),
        isTrue,
      );
    });

    test('$capa - $tipo - Duracion - sale del horario', () {
      expect(
        VentanaAsistencia.duracion(horario('JUEVES', '08:00', '10:30:00')),
        (horas: 2, minutos: 30),
      );
      //un horario mal formado no da duracion negativa
      expect(
        VentanaAsistencia.duracion(horario('JUEVES', '10:00', '08:00')),
        (horas: 0, minutos: 0),
      );
    });
  });
}
