import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';

class ClaseGrupoargumentos {
  Claseentidad clase;
  Grupoentidad grupo;
  //fuera de la ventana de asistencia la clase solo se consulta (AS-13)
  bool soloLectura;
  //horario del dia de la clase, para mostrar dia y hora; null si el grupo no
  //tiene horario ese dia o no se pudo cargar
  Horarioentidad? horario;
  ClaseGrupoargumentos({
    required this.clase,
    required this.grupo,
    this.soloLectura = false,
    this.horario,
  });
}
