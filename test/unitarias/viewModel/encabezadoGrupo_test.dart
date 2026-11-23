import 'package:dpt_movil/data/models/alumnoModelo.dart';
import 'package:dpt_movil/data/models/instructorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/alumnosRepositorio.dart';
import 'package:dpt_movil/data/repositories/claseRepositorio.dart';
import 'package:dpt_movil/data/repositories/cursoRepositorio.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/data/repositories/instructoresRepositorio.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioAlumno.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/domain/servicios/servicio_instructor.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';
import '../../dobles/conexionCursoFalsa.dart';
import '../../dobles/conexionalumnosFalsa.dart';
import '../../dobles/conexionclasesFalsa.dart';
import '../../dobles/conexionhorariosFalsa.dart';
import '../../dobles/conexioninstructoresFalsa.dart';

//datos del encabezado de la pantalla del grupo (rediseño del 2026-11-20):
//nombre del instructor, inscritos, disponibles y estado
void main() {
  const String capa = "viewModel";
  const String tipo = "unitaria";

  late ConexionalumnosFalsa conexionAlumnos;
  late ConexioninstructoresFalsa conexionInstructores;

  Grupoentidad grupo({String? idInstructor = '2', int cupos = 3, String? fin}) =>
      Grupoentidad(
        categoria: 'Deportes',
        curso: 'Voleibol mixto',
        anio: 2026,
        iterable: 1,
        idInstructor: idInstructor,
        cupos: cupos,
        fechaCreacion: '2026-08-04',
        fechaFinalizacion: fin,
      );

  Alumnomodelo alumno(String id) => Alumnomodelo(
    id: id,
    tipo: 'Estudiante',
    nombre: 'Alumno $id',
    correo: '$id@x.co',
    sexo: 'F',
    tipoid: 'CC',
  );

  DetalleGrupoViewModel crearVm(
    Grupoentidad g, {
    bool conInstructores = true,
    DateTime? hoy,
  }) => DetalleGrupoViewModel(
    g,
    ServicioCurso(CursoRepositorio(cliente: ConexionCursoFalsa())),
    Serviciohorario(Horariorepositorio(conexion: ConexionhorariosFalsa())),
    Servicioalumno(Alumnosrepositorio(cliente: conexionAlumnos)),
    Servicioclase(Claserepositorio(cliente: ConexionclasesFalsa())),
    reloj: hoy == null ? null : () => hoy,
    servicioInstructor:
        conInstructores
            ? ServicioInstructor(
              Instructoresrepositorio(conexion: conexionInstructores),
            )
            : null,
  );

  setUp(() {
    conexionAlumnos = ConexionalumnosFalsa()
      ..respuestaAlumnos = RespuestaModelo(codigoHttp: 406);
    conexionInstructores = ConexioninstructoresFalsa()
      ..respuestaInstructores = RespuestaModelo(
        codigoHttp: 200,
        datos:
            (leerContrato('instructores', 'instructores_200') as List)
                .map(Instructormodelo.fromJson)
                .toList(),
      );
  });

  group('Encabezado del grupo:', () {
    test('$capa - $tipo - Cargar instructor - 200 da el nombre del instructor del grupo', () async {
      final vm = crearVm(grupo());
      expect(vm.instructor.cargando, isTrue);

      await vm.cargar();

      expect(conexionInstructores.llamadasInstructores, 1);
      expect(vm.instructor.datos, 'edynson muñoz jimenez');
      expect(vm.instructor.error, isNull);
    });

    test('$capa - $tipo - Cargar instructor - un id que no esta en la lista da error', () async {
      final vm = crearVm(grupo(idInstructor: '99'));

      await vm.cargar();

      expect(vm.instructor.datos, isNull);
      expect(vm.instructor.error, isNotNull);
    });

    test('$capa - $tipo - Cargar instructor - un fallo de la conexion queda como error', () async {
      conexionInstructores.respuestaInstructores = RespuestaModelo(codigoHttp: 500);
      final vm = crearVm(grupo());

      await vm.cargar();

      expect(vm.instructor.cargando, isFalse);
      expect(vm.instructor.error, contains('500'));
    });

    test('$capa - $tipo - Cargar instructor - un grupo sin instructor no pide la lista', () async {
      final vm = crearVm(grupo(idInstructor: null));
      expect(vm.instructor.cargando, isFalse);

      await vm.cargar();

      expect(conexionInstructores.llamadasInstructores, 0);
      expect(vm.instructor.datos, isNull);
      expect(vm.instructor.error, isNull);
    });

    test('$capa - $tipo - Cupos - inscritos y disponibles salen de la lista de alumnos', () async {
      conexionAlumnos.respuestaAlumnos = RespuestaModelo(
        codigoHttp: 200,
        datos: [alumno('a1'), alumno('a2')],
      );
      final vm = crearVm(grupo(cupos: 3));
      expect(vm.inscritos, isNull, reason: 'mientras carga no hay cifra');

      await vm.cargar();

      expect(vm.inscritos, 2);
      expect(vm.disponibles, 1);
    });

    test('$capa - $tipo - Cupos - sin alumnos (GC-0002) todos los cupos estan libres', () async {
      final vm = crearVm(grupo(cupos: 3));

      await vm.cargar();

      expect(vm.inscritos, 0);
      expect(vm.disponibles, 3);
    });

    test('$capa - $tipo - Cupos - mas inscritos que cupos no da disponibles negativos', () async {
      conexionAlumnos.respuestaAlumnos = RespuestaModelo(
        codigoHttp: 200,
        datos: [alumno('a1'), alumno('a2')],
      );
      final vm = crearVm(grupo(cupos: 1));

      await vm.cargar();

      expect(vm.disponibles, 0);
    });

    test('$capa - $tipo - Cupos - si falla la lista de alumnos no hay cifras', () async {
      conexionAlumnos.respuestaAlumnos = RespuestaModelo(codigoHttp: 500);
      final vm = crearVm(grupo());

      await vm.cargar();

      expect(vm.inscritos, isNull);
      expect(vm.disponibles, isNull);
    });

    test('$capa - $tipo - Estado - finalizado segun la fecha de finalizacion y el reloj', () {
      final hoy = DateTime(2026, 11, 20, 10);
      expect(crearVm(grupo(fin: '2026-11-19'), hoy: hoy).finalizado, isTrue);
      expect(crearVm(grupo(fin: '2026-11-20'), hoy: hoy).finalizado, isFalse);
      expect(crearVm(grupo(), hoy: hoy).finalizado, isFalse);
    });
  });
}
