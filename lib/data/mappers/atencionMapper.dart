import 'package:dpt_movil/data/mappers/alumnoMapper.dart';
import 'package:dpt_movil/data/models/atencionModelo.dart';
import 'package:dpt_movil/domain/entities/atencionEntidad.dart';
import 'package:dpt_movil/domain/entities/estadoAsistencia.dart';

//conversion modelo <-> entidad de asistencias; el alumno de cada una pasa
//por AlumnoMapper
class AtencionMapper {
  static Atencionentidad aEntidad(Atencionmodelo modelo) {
    return Atencionentidad(
      alumno: AlumnoMapper.aEntidad(modelo.alumno),
      idClase: modelo.idClase,
      estado:
          modelo.estaAtendido
              ? EstadoAsistencia.presente
              : EstadoAsistencia.ausente,
      marcada: modelo.marcada,
    );
  }

  //el backend solo distingue presente de ausente (estaAtendido)
  static Atencionmodelo aModelo(Atencionentidad entidad) {
    return Atencionmodelo(
      alumno: AlumnoMapper.aModelo(entidad.alumno),
      idClase: entidad.idClase,
      estaAtendido: entidad.estaAtendido,
      marcada: entidad.marcada,
    );
  }
}
