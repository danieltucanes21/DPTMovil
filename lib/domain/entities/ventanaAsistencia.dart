import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/diaSemana.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';

//regla del cliente para la toma de asistencia (AS-13, 2026-11-19): las clases
//las define el horario del grupo, y la asistencia de un dia con clase se toma
//desde la hora de inicio de ese horario hasta las 23:59 del mismo dia. El
//coordinador no tiene limite (decision del equipo, como el backend, que lo
//exime de su plazo). Todo recibe "ahora" como parametro: nada lee el reloj
class VentanaAsistencia {
  VentanaAsistencia._();

  //minutos desde la medianoche de 'HH:mm' o 'HH:mm:ss' (el backend devuelve
  //las horas como se enviaron); null si no se entiende
  static int? minutosDelDia(String hora) {
    final partes = hora.trim().split(':');
    if (partes.length < 2) return null;
    final h = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return h * 60 + m;
  }

  //'08:00' para mostrar, sin los segundos
  static String horaCorta(String hora) {
    final minutos = minutosDelDia(hora);
    if (minutos == null) return hora;
    final h = (minutos ~/ 60).toString().padLeft(2, '0');
    final m = (minutos % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  //horarios del dia de la semana de "dia", del que empieza antes al que
  //empieza despues. Los dias se leen con la regla del backend (HO-06)
  static List<Horarioentidad> horariosDelDia(
    List<Horarioentidad> horarios,
    DateTime dia,
  ) {
    final delDia =
        horarios
            .where(
              (h) =>
                  DiaSemana.numero(h.dia) == dia.weekday &&
                  minutosDelDia(h.horaInicio) != null,
            )
            .toList();
    delDia.sort(
      (a, b) =>
          minutosDelDia(a.horaInicio)!.compareTo(minutosDelDia(b.horaInicio)!),
    );
    return delDia;
  }

  //el horario con el que se toma la asistencia de hoy: el primero del dia que
  //ya empezo. Sin limite (coordinador) basta con que hoy haya clase. null: hoy
  //no se puede tomar asistencia
  static Horarioentidad? horarioVigente(
    List<Horarioentidad> horarios,
    DateTime ahora, {
    bool sinLimite = false,
  }) {
    final delDia = horariosDelDia(horarios, ahora);
    if (delDia.isEmpty) return null;
    if (sinLimite) return delDia.first;
    final minutoActual = ahora.hour * 60 + ahora.minute;
    return minutosDelDia(delDia.first.horaInicio)! <= minutoActual
        ? delDia.first
        : null;
  }

  //el dia de la clase tal como lo envio el backend (yyyy-MM-dd), sin pasarlo
  //a hora local: asi no se corre de dia (CL-06)
  static bool esDelDia(Claseentidad clase, DateTime dia) {
    final fecha = clase.fecha;
    return fecha != null &&
        fecha.year == dia.year &&
        fecha.month == dia.month &&
        fecha.day == dia.day;
  }

  //se puede marcar o corregir la asistencia de esta clase. Fuera de la
  //ventana solo se consulta
  static bool puedeEditar(
    Claseentidad clase,
    List<Horarioentidad> horarios,
    DateTime ahora, {
    bool sinLimite = false,
  }) {
    if (sinLimite) return true;
    return esDelDia(clase, ahora) && horarioVigente(horarios, ahora) != null;
  }

  //duracion del horario en horas y minutos, para registrar la clase. Con
  //horario ese dia el backend calcula la duracion por su cuenta (BK-04)
  static ({int horas, int minutos}) duracion(Horarioentidad horario) {
    final inicio = minutosDelDia(horario.horaInicio) ?? 0;
    final fin = minutosDelDia(horario.horaFin) ?? inicio;
    final total = fin > inicio ? fin - inicio : 0;
    return (horas: total ~/ 60, minutos: total % 60);
  }
}
