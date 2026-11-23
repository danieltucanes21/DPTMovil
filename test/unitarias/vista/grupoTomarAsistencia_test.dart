import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/data/api/sesion/almacenToken.dart';
import 'package:dpt_movil/data/models/claseModelo.dart';
import 'package:dpt_movil/data/models/cursoModelo.dart';
import 'package:dpt_movil/data/models/horarioModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/alumnosRepositorio.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/data/repositories/claseRepositorio.dart';
import 'package:dpt_movil/data/repositories/cursoRepositorio.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/domain/entities/entidadesRutas/clase_grupoArgumentos.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioAlumno.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/presentation/view/views/grupo/grupo.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../dobles/conexionCursoFalsa.dart';
import '../../dobles/conexionalumnosFalsa.dart';
import '../../dobles/conexionautenticacionFalsa.dart';
import '../../dobles/conexionclasesFalsa.dart';
import '../../dobles/conexionhorariosFalsa.dart';
import '../../dobles/googleSignInFalso.dart';

//«Tomar asistencia» y las clases en solo lectura en la pantalla del grupo
//(AS-13). El vm se crea como en la ruta grupo, pero con el reloj fijo: el
//2026-11-19 es jueves y el grupo tiene clase de 08:00 a 10:00
void main() {
  const String capa = "vista";
  const String tipo = "unitaria";

  final grupo = Grupoentidad(
    categoria: 'Deportes',
    curso: 'Iniciacion',
    anio: 2026,
    iterable: 1,
    idInstructor: 'ins1',
    cupos: 20,
    fechaCreacion: '2026-10-23',
  );

  late ConexionclasesFalsa conexionClases;
  late DateTime ahora;
  //argumentos con los que la pantalla abrio la ruta clase
  late List<ClaseGrupoargumentos> clasesAbiertas;

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

  setUp(() {
    ahora = DateTime(2026, 11, 19, 9);
    clasesAbiertas = [];
    conexionClases =
        ConexionclasesFalsa()
          ..respuestaClases = RespuestaModelo(
            codigoHttp: 200,
            datos: [clase(9, DateTime(2026, 11, 12))],
          );
  });

  Future<void> montar(WidgetTester tester, String rol) async {
    final sesion = AutenticacionViewModel(
      Servicioautenticacion(
        Autenticacionrepositorio(
          conexion: ConexionautenticacionFalsa(),
          almacenToken: AlmacenToken(),
        ),
      ),
      GoogleSignInFalso(),
    )..perfilSesion = PerfilEntidad(
      id: 'ins1',
      nombre: 'Persona',
      correo: 'ins1@unicauca.edu.co',
      tipoId: 'CC',
      sexo: 'F',
      role: rol,
    );
    final conexionHorarios =
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
    final conexionCurso =
        ConexionCursoFalsa()
          ..respuestaObtener = RespuestaModelo(
            codigoHttp: 200,
            datos: CursoModelo(
              nombreCurso: 'Iniciacion',
              nombreDeporte: 'Futbol',
              tituloCategoria: 'Deportes',
              descripcion: 'Desc',
            ),
          );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AutenticacionViewModel>.value(value: sesion),
          ChangeNotifierProvider(
            create:
                (_) => DetalleGrupoViewModel(
                  grupo,
                  ServicioCurso(CursoRepositorio(cliente: conexionCurso)),
                  Serviciohorario(
                    Horariorepositorio(conexion: conexionHorarios),
                  ),
                  Servicioalumno(
                    Alumnosrepositorio(
                      cliente:
                          ConexionalumnosFalsa()
                            ..respuestaAlumnos = RespuestaModelo(
                              codigoHttp: 406,
                            ),
                    ),
                  ),
                  Servicioclase(Claserepositorio(cliente: conexionClases)),
                  reloj: () => ahora,
                )..cargar(),
          ),
        ],
        child: MaterialApp(
          home: Grupo(grupo: grupo),
          onGenerateRoute: (settings) {
            if (settings.name == AppRutas.clase) {
              clasesAbiertas.add(settings.arguments as ClaseGrupoargumentos);
            }
            return MaterialPageRoute(
              builder: (_) => Text('ruta ${settings.name}'),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tocar(WidgetTester tester, Finder destino) async {
    await tester.ensureVisible(destino);
    await tester.pumpAndSettle();
    await tester.tap(destino);
    await tester.pumpAndSettle();
  }

  //FilledButton.icon es una subclase: se busca cualquier boton con ese texto
  Finder botonTomar() => find.ancestor(
    of: find.text('Tomar asistencia', skipOffstage: false),
    matching: find.byWidgetPredicate(
      (w) => w is ButtonStyleButton,
      skipOffstage: false,
    ),
  );

  group('Pantalla del grupo (AS-13):', () {
    testWidgets('$capa - $tipo - Tomar asistencia - en la ventana registra la clase de hoy y la abre para marcar', (
      tester,
    ) async {
      await montar(tester, Roles.instructor);
      //lo que devuelve la recarga despues del POST
      conexionClases.respuestaClases = RespuestaModelo(
        codigoHttp: 200,
        datos: [
          clase(9, DateTime(2026, 11, 12)),
          clase(300, DateTime(2026, 11, 19)),
        ],
      );

      await tocar(tester, botonTomar());

      expect(conexionClases.llamadasAgregar, 1);
      expect(conexionClases.ultimaAgregada!.fecha, DateTime(2026, 11, 19));
      expect(clasesAbiertas.single.clase.codigo, 300);
      expect(clasesAbiertas.single.soloLectura, isFalse);
      //el horario del dia viaja para mostrar dia y hora
      expect(clasesAbiertas.single.horario?.horaInicio, '08:00');
    });

    testWidgets('$capa - $tipo - Tomar asistencia - antes de la hora esta deshabilitado y dice desde cuando', (
      tester,
    ) async {
      ahora = DateTime(2026, 11, 19, 7, 30);
      await montar(tester, Roles.instructor);

      await tester.ensureVisible(botonTomar());
      expect(tester.widget<ButtonStyleButton>(botonTomar()).onPressed, isNull);
      expect(find.text('Disponible hoy desde las 08:00', skipOffstage: false), findsOneWidget);
    });

    testWidgets('$capa - $tipo - Tomar asistencia - un dia sin clase lo dice', (
      tester,
    ) async {
      ahora = DateTime(2026, 11, 20, 9);
      await montar(tester, Roles.coordinador);

      await tester.ensureVisible(botonTomar());
      expect(tester.widget<ButtonStyleButton>(botonTomar()).onPressed, isNull);
      expect(
        find.text(
          'Hoy no hay clase según el horario del grupo',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    });

    testWidgets('$capa - $tipo - Lista de clases - el instructor abre una clase pasada en solo lectura', (
      tester,
    ) async {
      await montar(tester, Roles.instructor);

      await tocar(tester, find.text('Jueves, 12 de noviembre', skipOffstage: false));

      expect(clasesAbiertas.single.clase.codigo, 9);
      expect(clasesAbiertas.single.soloLectura, isTrue);
    });

    testWidgets('$capa - $tipo - Lista de clases - el coordinador abre una clase pasada para corregirla', (
      tester,
    ) async {
      await montar(tester, Roles.coordinador);

      await tocar(tester, find.text('Jueves, 12 de noviembre', skipOffstage: false));

      expect(clasesAbiertas.single.soloLectura, isFalse);
    });
  });
}
