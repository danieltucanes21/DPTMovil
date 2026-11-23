class FormatDate {
  static String fechaACadena(DateTime fecha, String separador) {
    if (fecha == null || separador == null) {
      return '';
    }
    final year = fecha.year.toString();
    final month = fecha.month.toString().padLeft(2, '0'); // asegura dos dígitos
    final day = fecha.day.toString().padLeft(2, '0'); // asegura dos dígitos
    return '$year$separador$month$separador$day';
  }

  static const List<String> _meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
    'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  //'2025-08-04' -> '4 de agosto de 2025'. null si no hay fecha; una fecha que
  //no se puede leer se devuelve tal como llego
  static String? fechaLarga(String? texto) {
    if (texto == null || texto.trim().isEmpty) return null;
    final fecha = DateTime.tryParse(texto.trim());
    if (fecha == null) return texto;
    return '${fecha.day} de ${_meses[fecha.month - 1]} de ${fecha.year}';
  }

  static const List<String> _dias = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
  ];

  //'Martes, 19 de agosto' (sin el año: las clases son del semestre en curso)
  static String fechaConDia(DateTime fecha) =>
      '${_dias[fecha.weekday - 1]}, ${fecha.day} de ${_meses[fecha.month - 1]}';

  //'14:00:00' o '14:00' -> '2:00 p. m.'. Una hora ilegible se devuelve igual
  static String horaLegible(String hora) {
    final partes = hora.trim().split(':');
    final h = partes.length < 2 ? null : int.tryParse(partes[0]);
    final m = partes.length < 2 ? null : int.tryParse(partes[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return hora;
    }
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${m.toString().padLeft(2, '0')} ${h < 12 ? 'a. m.' : 'p. m.'}';
  }
}
