import 'package:dpt_movil/data/models/claseModelo.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/horarioModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/alumnosRepositorio.dart';
import 'package:dpt_movil/data/repositories/claseRepositorio.dart';
import 'package:dpt_movil/data/repositories/cursoRepositorio.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioAlumno.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionCursoFalsa.dart';
import '../../dobles/conexionalumnosFalsa.dart';
import '../../dobles/conexionclasesFalsa.dart';
import '../../dobles/conexionhorariosFalsa.dart';

//«Tomar asistencia» en la pantalla del grupo (AS-13): la clase de hoy sale del
//horario, dentro de la ventana (desde la hora de inicio hasta las 23:59). El
//reloj se fija: el 2026-11-19 es jueves y el grupo tiene clase de 08:00 a 10:00
void main() {
  const String capa = "viewModel";
  const String tipo = "unitaria";

  late ConexionhorariosFalsa conexionHorarios;
  late ConexionclasesFalsa conexionClases;
  late DateTime ahora;

  final grupo = Grupoentidad(
    categoria: 'Deportes',
    curso: 'Iniciacion',
    anio: 2026,
    iterable: 1,
    idInstructor: 'ins1',
    cupos: 20,
    fechaCreacion: '2026-10-23',
  );

  Clasemodelo clase(int codigo, DateTime fecha) => Clasemodelo(
    codigo: codigo,
    idGrupoCategoria: 'Deportes',
    idGrupoCurso: 'Iniciacion',
    idGrupoAnio: 2026,
    idGrupoIterable: 1,
    idInstructor: 'ins1',
    fecha: fecha,
    horas: 2,
    minutos: 0,
    eliminado: 0,
  );

  //el repositorio escribe sobre respuesta.datos: cada carga lleva su propia
  //respuesta
  void responderClases(List<Clasemodelo> clases) {
    conexionClases.respuestaClases = RespuestaModelo(
      codigoHttp: 200,
      datos: clases,
    );
  }

  setUp(() {
    ahora = DateTime(2026, 11, 19, 9);
    conexionHorarios =
        ConexionhorariosFalsa()
          ..respuestaHorarios = RespuestaModelo(
            codigoHttp: 200,
            datos: [
              HorarioModelo(
                categoria: 'Deportes',
                curso: 'Iniciacion',
                anio: 2026,
                iterable: 1,
                dia: 'JUEVES',
                horaInicio: '08:00',
                horaFin: '10:00',
                escenario: 'Coliseo',
              ),
            ],
          );
    conexionClases = ConexionclasesFalsa();
    responderClases([clase(9, DateTime(2026, 11, 12))]);
  });

  //como la ruta grupo, pero con el reloj fijo
  Future<DetalleGrupoViewModel> crearVm() async {
    final vm = DetalleGrupoViewModel(
      grupo,
      ServicioCurso(CursoRepositorio(cliente: ConexionCursoFalsa())),
      Serviciohorario(Horariorepositorio(conexion: conexionHorarios)),
      Servicioalumno(Alumnosrepositorio(cliente: ConexionalumnosFalsa())),
      Servicioclase(Claserepositorio(cliente: conexionClases)),
      reloj: () => ahora,
    );
    await vm.cargar();
    return vm;
  }

  group('Tomar asistencia (vm con dobles):', () {
    test('$capa - $tipo - Tomar asistencia - en la ventana crea la clase de hoy con las horas del horario', () async {
      final vm = await crearVm();
      responderClases([
        clase(9, DateTime(2026, 11, 12)),
        clase(300, DateTime(2026, 11, 19)),
      ]);

      expect(vm.motivoSinAsistencia(sinLimite: false), isNull);
      final resultado = await vm.tomarAsistencia(sinLimite: false);

      expect(resultado, isA<Exito<Claseentidad>>());
      expect((resultado as Exito<Claseentidad>).datos!.codigo, 300);
      final enviada = conexionClases.ultimaAgregada!;
      expect(enviada.fecha, DateTime(2026, 11, 19));
      expect([enviada.horas, enviada.minutos], [2, 0]);
      expect(enviada.idInstructor, 'ins1');
      expect(enviada.justificacion, isNull);
      //la lista se recargo con la clase nueva
      expect(vm.clases.datos.map((c) => c.codigo), [9, 300]);
      expect(vm.tomandoAsistencia, isFalse);
    });

    test('$capa - $tipo - Tomar asistencia - antes de la hora de inicio no se abre', () async {
      ahora = DateTime(2026, 11, 19, 7, 30);
      final vm = await crearVm();

      expect(
        vm.motivoSinAsistencia(sinLimite: false),
        'Disponible hoy desde las 08:00',
      );
      final resultado = await vm.tomarAsistencia(sinLimite: false);

      expect(resultado, isA<Fallo>());
      expect(conexionClases.llamadasAgregar, 0);
    });

    test('$capa - $tipo - Tomar asistencia - el coordinador no espera la hora de inicio', () async {
      ahora = DateTime(2026, 11, 19, 7, 30);
      final vm = await crearVm();

      expect(vm.motivoSinAsistencia(sinLimite: true), isNull);
    });

    test('$capa - $tipo - Tomar asistencia - un dia sin horario no se abre, tampoco al coordinador', () async {
      ahora = DateTime(2026, 11, 20, 9);
      final vm = await crearVm();

      const motivo = 'Hoy no hay clase según el horario del grupo';
      expect(vm.motivoSinAsistencia(sinLimite: false), motivo);
      expect(vm.motivoSinAsistencia(sinLimite: true), motivo);
      expect(await vm.tomarAsistencia(sinLimite: true), isA<Fallo>());
      expect(conexionClases.llamadasAgregar, 0);
    });

    test('$capa - $tipo - Tomar asistencia - si la clase de hoy ya esta, la abre sin registrar', () async {
      responderClases([clase(300, DateTime(2026, 11, 19))]);
      final vm = await crearVm();

      final resultado = await vm.tomarAsistencia(sinLimite: false);

      expect((resultado as Exito<Claseentidad>).datos!.codigo, 300);
      expect(conexionClases.llamadasAgregar, 0);
    });

    test('$capa - $tipo - Tomar asistencia - un rechazo del backend es Fallo y no recarga', () async {
      final vm = await crearVm();
      final cargas = conexionClases.llamadasClases;
      conexionClases.respuestaAgregar = RespuestaModelo(
        codigoHttp: 422,
        error: ErrorModelo(
          codigoHttp: 422,
          mensaje: 'La fecha de la clase no puede ser futura',
          url: '/claseGrupo',
          metodo: 'POST',
        ),
      );

      final resultado = await vm.tomarAsistencia(sinLimite: false);

      expect(resultado, isA<Fallo>());
      final fallo = resultado as Fallo;
      expect(fallo.codigo, 422);
      expect(fallo.mensaje, 'La fecha de la clase no puede ser futura');
      expect(conexionClases.llamadasClases, cargas);
    });

    test('$capa - $tipo - Tomar asistencia - sin horario cargado no se abre', () async {
      conexionHorarios.respuestaHorarios = RespuestaModelo(codigoHttp: 500);
      final vm = await crearVm();

      expect(
        vm.motivoSinAsistencia(sinLimite: true),
        'No se pudo cargar el horario del grupo',
      );
    });

    test('$capa - $tipo - Puede editar clase - solo la de hoy en la ventana, salvo el coordinador', () async {
      final vm = await crearVm();
      final pasada = vm.clases.datos.single;
      final hoy = Claseentidad(
        codigo: 300,
        idGrupoCategoria: 'Deportes',
        idGrupoCurso: 'Iniciacion',
        idGrupoAnio: 2026,
        idGrupoIterable: 1,
        idInstructor: 'ins1',
        fecha: DateTime(2026, 11, 19),
        eliminado: 0,
      );

      expect(vm.puedeEditarClase(hoy, sinLimite: false), isTrue);
      expect(vm.puedeEditarClase(pasada, sinLimite: false), isFalse);
      expect(vm.puedeEditarClase(pasada, sinLimite: true), isTrue);
    });
  });
}
