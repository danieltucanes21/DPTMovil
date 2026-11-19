import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';

class ClaseGrupoargumentos {
  Claseentidad clase;
  Grupoentidad grupo;
  //fuera de la ventana de asistencia la clase solo se consulta (AS-13)
  bool soloLectura;
  ClaseGrupoargumentos({
    required this.clase,
    required this.grupo,
    this.soloLectura = false,
  });
}
