//estado de un alumno en la toma de asistencia (rediseño del 2026-11-19).
//El backend solo guarda PRESENTE y AUSENTE: «justificada» se muestra pero no
//se puede elegir hasta que el backend la soporte
enum EstadoAsistencia {
  presente('Presente'),
  ausente('Ausente'),
  justificada('Justificada');

  final String etiqueta;
  const EstadoAsistencia(this.etiqueta);

  //false mientras el backend no tenga el estado JUSTIFICADA: la pantalla
  //pinta el boton deshabilitado y el vm no la acepta
  static const bool justificadaDisponible = false;
}
