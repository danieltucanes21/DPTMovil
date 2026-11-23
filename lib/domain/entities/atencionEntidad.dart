import 'package:dpt_movil/domain/entities/alumnoEntidad.dart';
import 'package:dpt_movil/domain/entities/estadoAsistencia.dart';

class Atencionentidad {
  Alumnoentidad alumno;
  int idClase;
  EstadoAsistencia estado;
  //el backend ya tenia una marca de este alumno en la clase. Sin marca, la
  //pantalla lo muestra como presente (rediseño del 2026-11-19)
  bool marcada;
  Atencionentidad({
    required this.alumno,
    required this.idClase,
    required this.estado,
    this.marcada = true,
  });

  //lo que viaja al backend, que solo distingue presente de ausente
  bool get estaAtendido => estado == EstadoAsistencia.presente;
  set estaAtendido(bool valor) =>
      estado = valor ? EstadoAsistencia.presente : EstadoAsistencia.ausente;
}
