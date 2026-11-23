import 'package:dpt_movil/domain/entities/diaSemana.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/alumnoEntidad.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/entities/ventanaAsistencia.dart';
import 'package:dpt_movil/domain/servicios/servicioAlumno.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/domain/servicios/servicio_instructor.dart';
import 'package:dpt_movil/domain/entities/instructorEntidad.dart';
import 'package:dpt_movil/presentation/viewmodels/estadoSeccion.dart';
import 'package:flutter/foundation.dart';

//los widgets de la pantalla de grupo leen EstadoSeccion importando este vm
export 'package:dpt_movil/presentation/viewmodels/estadoSeccion.dart'
    show EstadoSeccion;

//vm de la pantalla de un grupo (fase 4c): reune lo que antes pedia cada
//widget por su cuenta (curso, horarios, alumnos, clases). Lo crea la ruta
//grupo con el grupo de la pantalla y carga todo una sola vez al entrar
//NotificacionSegura (fase 8): la ruta lo desecha al salir y una peticion
//que llega despues no notifica
class DetalleGrupoViewModel with ChangeNotifier, NotificacionSegura {
  final Grupoentidad grupo;
  final ServicioCurso _servicioCurso;
  final Serviciohorario _servicioHorario;
  final Servicioalumno _servicioAlumno;
  final Servicioclase _servicioClase;
  //para el nombre del instructor del encabezado; opcional para no tocar las
  //pruebas que no pintan el encabezado (sin el, el nombre no se carga)
  final ServicioInstructor? _servicioInstructor;

  //hora actual para la ventana de asistencia (AS-13); las pruebas la fijan
  final DateTime Function() _reloj;

  DetalleGrupoViewModel(
    this.grupo,
    this._servicioCurso,
    this._servicioHorario,
    this._servicioAlumno,
    this._servicioClase, {
    DateTime Function()? reloj,
    ServicioInstructor? servicioInstructor,
  }) : _reloj = reloj ?? DateTime.now,
       _servicioInstructor = servicioInstructor,
       _instructor = EstadoSeccion(
         null,
         cargando: grupo.idInstructor != null && servicioInstructor != null,
       );

  //todas empiezan cargando: la ruta llama a cargar() al crear el vm
  EstadoSeccion<CursoEntidad?> _curso = const EstadoSeccion(null, cargando: true);
  EstadoSeccion<List<Horarioentidad>> _horarios = const EstadoSeccion(
    [],
    cargando: true,
  );
  EstadoSeccion<List<Alumnoentidad>> _alumnos = const EstadoSeccion(
    [],
    cargando: true,
  );
  EstadoSeccion<List<Claseentidad>> _clases = const EstadoSeccion(
    [],
    cargando: true,
  );

  //nombre del instructor del grupo. datos null sin cargando ni error: el grupo
  //no tiene instructor (o no se pidio)
  EstadoSeccion<String?> _instructor;

  EstadoSeccion<CursoEntidad?> get curso => _curso;
  EstadoSeccion<String?> get instructor => _instructor;
  EstadoSeccion<List<Horarioentidad>> get horarios => _horarios;
  EstadoSeccion<List<Alumnoentidad>> get alumnos => _alumnos;
  EstadoSeccion<List<Claseentidad>> get clases => _clases;

  //--- encabezado ---
  //el grupo termino segun su fecha de finalizacion (hoy, con el reloj del vm)
  bool get finalizado => grupo.finalizado(_reloj());

  //alumnos inscritos; null mientras carga la lista o si fallo
  int? get inscritos =>
      _alumnos.cargando || _alumnos.error != null
          ? null
          : _alumnos.datos.length;

  //cupos libres; nunca negativo
  int? get disponibles {
    final ocupados = inscritos;
    if (ocupados == null) return null;
    final libres = grupo.cupos - ocupados;
    return libres < 0 ? 0 : libres;
  }

  //las peticiones van en paralelo; cada seccion notifica al llegar
  Future<void> cargar() async {
    await Future.wait([
      _cargarInstructor(),
      _cargarCurso(),
      _cargarHorarios(),
      _cargarAlumnos(),
      cargarClases(),
    ]);
  }

  //no hay una ruta por id en la app: se busca en /instructores
  Future<void> _cargarInstructor() async {
    final id = grupo.idInstructor;
    final servicio = _servicioInstructor;
    if (id == null || servicio == null) return;
    try {
      final respuesta = await servicio.listarInstructores();
      if (respuesta.codigoHttp == 200 && respuesta.datos is List) {
        final encontrado = (respuesta.datos as List)
            .whereType<Instructorentidad>()
            .where((i) => i.id == id);
        final nombre =
            encontrado.isEmpty ? null : encontrado.first.nombre?.trim();
        _instructor =
            (nombre == null || nombre.isEmpty)
                ? EstadoSeccion(null, error: 'Instructor no encontrado')
                : EstadoSeccion(nombre);
      } else {
        _instructor = EstadoSeccion(null, error: _mensaje(respuesta));
      }
    } catch (e) {
      _instructor = EstadoSeccion(null, error: e.toString());
    }
    notifyListeners();
  }

  Future<void> _cargarCurso() async {
    try {
      final respuesta = await _servicioCurso.obtenerCurso(
        grupo.categoria,
        grupo.curso,
      );
      _curso =
          (respuesta.codigoHttp == 200 && respuesta.datos is CursoEntidad)
              ? EstadoSeccion(respuesta.datos as CursoEntidad)
              : EstadoSeccion(null, error: _mensaje(respuesta));
    } catch (e) {
      _curso = EstadoSeccion(null, error: e.toString());
    }
    notifyListeners();
  }

  //publica: se vuelve a llamar tras agregar o eliminar un horario
  Future<void> cargarHorarios() => _cargarHorarios();

  Future<void> _cargarHorarios() async {
    try {
      final respuesta = await _servicioHorario.listarHoariosGrupo(
        grupo.categoria,
        grupo.curso,
        grupo.anio,
        grupo.iterable,
      );
      _horarios = _seccionLista<Horarioentidad>(respuesta);
    } catch (e) {
      _horarios = EstadoSeccion([], error: e.toString());
    }
    notifyListeners();
  }

  Future<void> _cargarAlumnos() async {
    try {
      final respuesta = await _servicioAlumno.listarAlumnosGrupo(
        grupo.categoria,
        grupo.curso,
        grupo.anio,
        grupo.iterable,
      );
      _alumnos = _seccionLista<Alumnoentidad>(respuesta);
    } catch (e) {
      _alumnos = EstadoSeccion([], error: e.toString());
    }
    notifyListeners();
  }

  //publica: tomarAsistencia la vuelve a llamar tras registrar la clase de hoy,
  //y eliminarClase tras el exito
  Future<void> cargarClases() async {
    if (!_clases.cargando) {
      _clases = EstadoSeccion(_clases.datos, cargando: true);
      notifyListeners();
    }
    try {
      final respuesta = await _servicioClase.listarClasesGrupo(
        grupo.categoria,
        grupo.curso,
        grupo.anio,
        grupo.iterable,
      );
      _clases = _seccionLista<Claseentidad>(respuesta);
    } catch (e) {
      _clases = EstadoSeccion([], error: e.toString());
    }
    notifyListeners();
  }

  //horaInicio y horaFin como HH:mm. Las reglas del cliente se aplican antes de
  //enviar; el backend las repite (rango de horas, formato)
  Future<Resultado<void>> agregarHorario({
    required String? dia,
    required String? horaInicio,
    required String? horaFin,
    required String escenario,
  }) async {
    if (dia == null || dia.isEmpty) {
      return Fallo(-1, 'Seleccione el dia', origen: 'ViewModel');
    }
    //el backend compara el dia sin tilde: 'Miércoles' no contaria (HO-06)
    final codigoDia = DiaSemana.codigo(dia);
    if (codigoDia == null) {
      return Fallo(-1, 'El dia "$dia" no es valido', origen: 'ViewModel');
    }
    if (horaInicio == null || horaFin == null) {
      return Fallo(
        -1,
        'Seleccione la hora de inicio y la de fin',
        origen: 'ViewModel',
      );
    }
    if (horaFin.compareTo(horaInicio) <= 0) {
      return Fallo(
        -1,
        'La hora de fin debe ser posterior a la de inicio',
        origen: 'ViewModel',
      );
    }
    if (escenario.trim().isEmpty) {
      return Fallo(-1, 'Ingrese el escenario', origen: 'ViewModel');
    }
    try {
      final respuesta = await _servicioHorario.agregarHorario(
        Horarioentidad(
          categoria: grupo.categoria,
          curso: grupo.curso,
          anio: grupo.anio,
          iterable: grupo.iterable,
          dia: codigoDia,
          horaInicio: horaInicio,
          horaFin: horaFin,
          escenario: escenario.trim(),
        ),
      );
      return _resultadoYRecarga(respuesta, 201);
    } catch (e) {
      return Fallo(-1, e.toString(), origen: 'ViewModel');
    }
  }

  Future<Resultado<void>> eliminarHorario(int id) async {
    try {
      final respuesta = await _servicioHorario.eliminarHorario(id);
      return _resultadoYRecarga(respuesta, 200);
    } catch (e) {
      return Fallo(-1, e.toString(), origen: 'ViewModel');
    }
  }

  Future<Resultado<void>> _resultadoYRecarga(
    RespuestaModelo respuesta,
    int exito,
  ) async {
    if (respuesta.codigoHttp == exito) {
      await _cargarHorarios();
      return Exito();
    }
    return Fallo(
      respuesta.codigoHttp,
      respuesta.error?.mensaje ?? 'Error desconocido',
      origen:
          respuesta.error == null
              ? null
              : '${respuesta.error!.metodo} ${respuesta.error!.url}',
    );
  }

  //--- toma de asistencia (AS-13) ---
  //las clases las define el horario: «Tomar asistencia» crea la clase de hoy
  //con las horas del horario y la abre. Ventana: VentanaAsistencia

  //hay un registro de la clase de hoy en camino: un segundo toque no lo repite
  bool _tomandoAsistencia = false;
  bool get tomandoAsistencia => _tomandoAsistencia;

  //null: se puede tomar la asistencia de hoy. Si no, por que no, para
  //mostrarlo debajo del boton. sinLimite: coordinador
  String? motivoSinAsistencia({required bool sinLimite}) {
    if (_horarios.cargando) return 'Cargando el horario del grupo...';
    if (_horarios.error != null) {
      return 'No se pudo cargar el horario del grupo';
    }
    final ahora = _reloj();
    final delDia = VentanaAsistencia.horariosDelDia(_horarios.datos, ahora);
    if (delDia.isEmpty) return 'Hoy no hay clase según el horario del grupo';
    if (VentanaAsistencia.horarioVigente(
          _horarios.datos,
          ahora,
          sinLimite: sinLimite,
        ) ==
        null) {
      return 'Disponible hoy desde las '
          '${VentanaAsistencia.horaCorta(delDia.first.horaInicio)}';
    }
    return null;
  }

  //el primer horario del dia de la semana de esa fecha, para mostrar dia y
  //hora en la toma de asistencia; null si ese dia no hay horario
  Horarioentidad? horarioDe(DateTime? fecha) {
    if (fecha == null) return null;
    final delDia = VentanaAsistencia.horariosDelDia(_horarios.datos, fecha);
    return delDia.isEmpty ? null : delDia.first;
  }

  //la clase de la lista se abre para marcar (true) o solo para consultar
  bool puedeEditarClase(Claseentidad clase, {required bool sinLimite}) =>
      VentanaAsistencia.puedeEditar(
        clase,
        _horarios.datos,
        _reloj(),
        sinLimite: sinLimite,
      );

  //la clase de hoy: la que ya esta en la lista o una nueva con las horas del
  //horario. El Exito trae la clase con su codigo, lista para abrir
  Future<Resultado<Claseentidad>> tomarAsistencia({
    required bool sinLimite,
  }) async {
    if (_tomandoAsistencia) {
      return Fallo(0, 'Ya se está abriendo la clase de hoy', origen: 'ViewModel');
    }
    final motivo = motivoSinAsistencia(sinLimite: sinLimite);
    if (motivo != null) return Fallo(0, motivo, origen: 'ViewModel');
    final ahora = _reloj();
    final existente = _claseDelDia(ahora);
    if (existente != null) return Exito(existente);
    final idInstructor = grupo.idInstructor;
    if (idInstructor == null) {
      return Fallo(
        0,
        'El grupo no tiene instructor asignado',
        origen: 'ViewModel',
      );
    }
    final horario =
        VentanaAsistencia.horarioVigente(
          _horarios.datos,
          ahora,
          sinLimite: sinLimite,
        )!;
    final duracion = VentanaAsistencia.duracion(horario);
    _tomandoAsistencia = true;
    notifyListeners();
    try {
      final respuesta = await _servicioClase.guardarClaseGrupo(
        Claseentidad(
          idGrupoCategoria: grupo.categoria,
          idGrupoCurso: grupo.curso,
          idGrupoAnio: grupo.anio,
          idGrupoIterable: grupo.iterable,
          idInstructor: idInstructor,
          fecha: DateTime(ahora.year, ahora.month, ahora.day),
          horas: duracion.horas,
          minutos: duracion.minutos,
          eliminado: 0,
        ),
      );
      //201: nueva; 200: ya existia (BK-08). En los dos casos se lee de la
      //lista, que trae el codigo
      if (respuesta.codigoHttp != 201 && respuesta.codigoHttp != 200) {
        return Fallo(
          respuesta.codigoHttp,
          respuesta.error?.mensaje ?? 'Error desconocido',
          origen:
              respuesta.error == null
                  ? null
                  : '${respuesta.error!.metodo} ${respuesta.error!.url}',
        );
      }
      await cargarClases();
      final clase = _claseDelDia(ahora);
      if (clase == null) {
        return Fallo(
          0,
          'La clase de hoy se registró, pero no aparece en la lista de clases',
          origen: 'ViewModel',
        );
      }
      return Exito(clase);
    } catch (e) {
      return Fallo(-1, e.toString(), origen: 'ViewModel');
    } finally {
      _tomandoAsistencia = false;
      notifyListeners();
    }
  }

  Claseentidad? _claseDelDia(DateTime dia) {
    for (final clase in _clases.datos) {
      if (VentanaAsistencia.esDelDia(clase, dia)) return clase;
    }
    return null;
  }

  //sin uso en la pantalla desde AS-13 (eliminar clase ya no se ofrece); lo
  //siguen usando las pruebas remotas que fijan DELETE /clase (CL-01)
  Future<Resultado<void>> eliminarClase(int codigo) async {
    try {
      final respuesta = await _servicioClase.eliminarClase(codigo);
      if (respuesta.codigoHttp == 200) {
        await cargarClases();
        return Exito();
      }
      return Fallo(
        respuesta.codigoHttp,
        _mensaje(respuesta),
        origen:
            respuesta.error == null
                ? null
                : '${respuesta.error!.metodo} ${respuesta.error!.url}',
      );
    } catch (e) {
      return Fallo(-1, e.toString(), origen: 'ViewModel');
    }
  }

  //una lista vacia no es un error. /alumnosGrupo y /clasesGrupo responden
  //200 con un objeto (GC-0002 "listado vacio") y la conexion lo devuelve
  //como 406; /horarios responde 200 con []
  EstadoSeccion<List<T>> _seccionLista<T>(RespuestaModelo respuesta) {
    if (respuesta.codigoHttp == 406) {
      return EstadoSeccion(<T>[]);
    }
    if (respuesta.codigoHttp == 200 && respuesta.datos is List) {
      return EstadoSeccion((respuesta.datos as List).cast<T>());
    }
    return EstadoSeccion(<T>[], error: _mensaje(respuesta));
  }

  String _mensaje(RespuestaModelo respuesta) =>
      'Código: ${respuesta.codigoHttp} - ${respuesta.error?.mensaje ?? "Error desconocido"}';
}
