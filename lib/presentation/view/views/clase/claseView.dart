import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/forma_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/atencionEntidad.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/diaSemana.dart';
import 'package:dpt_movil/domain/entities/estadoAsistencia.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogExito.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/viewmodels/atencionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//toma de asistencia de una clase, con el diseño del prototipo del
//2026-11-19: datos de la clase, resumen (presentes, ausentes, justificadas),
//la lista con un estado por alumno y «Enviar reporte de asistencia».
//El Atencionviewmodel lo provee la ruta AppRutas.clase, uno por pantalla, y
//ya empieza a cargar al crearse: esta vista solo pinta y registra
class Claseview extends StatefulWidget {
  final Grupoentidad grupo;
  final Claseentidad clase;
  //fuera de la ventana de asistencia (AS-13): se ven las marcas guardadas,
  //sin poder cambiarlas ni enviar
  final bool soloLectura;
  //horario del dia de la clase: dia y hora en la tarjeta de arriba
  final Horarioentidad? horario;

  const Claseview({
    super.key,
    required this.grupo,
    required this.clase,
    this.soloLectura = false,
    this.horario,
  });

  @override
  State<Claseview> createState() => _ClaseviewState();
}

class _ClaseviewState extends State<Claseview> {
  @override
  Widget build(BuildContext context) {
    //con marcas sin guardar, atras pregunta antes de salir (AS-10). El pop
    //tras un registro exitoso no pasa por aqui: Navigator.pop no consulta el
    //PopScope
    final hayCambios = context.select<Atencionviewmodel, bool>(
      (vm) => vm.hayCambiosSinGuardar,
    );
    return PopScope(
      canPop: !hayCambios,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navegador = Navigator.of(context);
        if (await _confirmarSalida() && mounted) navegador.pop();
      },
      child: Scaffold(
        //el titulo de la pantalla va en el cuerpo, con su antetitulo
        appBar: const Bar(),
        drawer: Builder(builder: (context) => Menulateral()),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _encabezadoPagina(),
                      const SizedBox(height: 16),
                      _datosClase(),
                      const SizedBox(height: 12),
                      const _Resumen(),
                      const SizedBox(height: 20),
                      _encabezadoLista(),
                      const SizedBox(height: 12),
                      _busqueda(),
                      const SizedBox(height: 12),
                      _listado(),
                    ],
                  ),
                ),
              ),
              _acciones(),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmarSalida() async {
    final salir = await showDialog<bool>(
      context: context,
      builder:
          (dialogo) => AlertDialog(
            title: const Text('Cambios sin guardar'),
            content: const Text(
              'Hay marcas de asistencia sin guardar. Si sales ahora, se perderán.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogo, false),
                child: const Text('SEGUIR EDITANDO'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogo, true),
                child: const Text('SALIR SIN GUARDAR'),
              ),
            ],
          ),
    );
    return salir ?? false;
  }

  //titulo de la pantalla, con la linea roja del titulo principal (prototipo
  //del 2026-11-19, sin el boton de atras: ya esta en la barra)
  Widget _encabezadoPagina() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.soloLectura ? 'Asistencia de la clase' : 'Tomar asistencia',
          style: Tipografia.h5(
            color: ColorTheme.primary,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: ColorTheme.secondaryLight,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ],
    );
  }

  //curso y grupo, y el dia y la hora del horario de la clase
  Widget _datosClase() {
    final grupo = widget.grupo;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: FormaTema.radioMedio,
        gradient: const LinearGradient(
          colors: [ColorTheme.primary, ColorTheme.primaryLight],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: FormaTema.radioPequeno,
            ),
            child: const Icon(Icons.calendar_today, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${grupo.curso} · Grupo ${grupo.anio}.${grupo.iterable}',
                  style: Tipografia.subtitulo2(
                    color: Colors.white,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  _cuandoEsLaClase(),
                  style: Tipografia.leyenda(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                if (widget.soloLectura)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Solo lectura: el plazo para tomar asistencia de esta clase terminó',
                      style: Tipografia.leyenda(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //'Sábados · 9:00 a. m.'. Sin horario ese dia, solo el dia de la clase
  String _cuandoEsLaClase() {
    final fecha = widget.clase.fecha;
    final horario = widget.horario;
    final dia =
        horario != null
            ? DiaSemana.etiqueta(horario.dia)
            : fecha != null
            ? DiaSemana.etiqueta(DiaSemana.codigos[fecha.weekday - 1])
            : null;
    final partes = [
      if (dia != null) dia.endsWith('s') ? dia : '${dia}s',
      if (horario != null) FormatDate.horaLegible(horario.horaInicio),
    ];
    return partes.isEmpty ? 'Sin horario' : partes.join(' · ');
  }

  Widget _encabezadoLista() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //subtitulo: sin la linea roja, que es solo de los titulos principales
        Text(
          'Lista de estudiantes',
          style: Tipografia.h6(color: ColorTheme.primaryDark).copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          widget.soloLectura
              ? 'Estado registrado de cada estudiante'
              : 'Registre el estado de cada estudiante',
          style: Tipografia.cuerpo2(color: ColorTheme.neutral),
        ),
      ],
    );
  }

  //filtra la lista por nombre o codigo; el resumen no cambia
  Widget _busqueda() {
    return TextField(
      key: const ValueKey('busqueda-estudiantes'),
      onChanged: context.read<Atencionviewmodel>().filtrar,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre o código',
        hintStyle: Tipografia.cuerpo2(color: ColorTheme.neutral),
        prefixIcon: const Icon(Icons.search, color: ColorTheme.primaryLight),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: FormaTema.radioMedio,
          borderSide: const BorderSide(color: ColorTheme.asistenciaBorde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: FormaTema.radioMedio,
          borderSide: const BorderSide(color: ColorTheme.primaryLight),
        ),
      ),
    );
  }

  Widget _listado() {
    return Consumer<Atencionviewmodel>(
      builder: (context, vm, _) {
        //antes de la primera carga la lista aun no existe: tambien es espera
        if (vm.cargando || vm.atenciones == null && vm.error == null) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (vm.error != null) {
          return Text(
            vm.error!,
            style: Tipografia.cuerpo1(color: ColorTheme.error),
          );
        }
        if (vm.atenciones!.isEmpty) {
          return Text(
            '¡No hay alumnos aún!',
            style: Tipografia.cuerpo1(color: ColorTheme.secondaryDark),
          );
        }
        final lista = vm.atenciones!;
        final visibles = vm.indicesVisibles;
        if (visibles.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Ningún estudiante coincide con «${vm.filtro.trim()}»',
              textAlign: TextAlign.center,
              style: Tipografia.cuerpo2(color: ColorTheme.neutral),
            ),
          );
        }
        //cada tarjeta marca con su posicion en la lista completa
        return Column(
          children: [
            for (final i in visibles)
              _TarjetaAlumno(
                key: ValueKey(lista[i].alumno.id),
                atencion: lista[i],
                soloLectura: widget.soloLectura,
                alElegir: (estado) => vm.marcarEstado(i, estado),
              ),
          ],
        );
      },
    );
  }

  Widget _acciones() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child:
          widget.soloLectura
              ? SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: const Text('Volver'),
                ),
              )
              : Builder(
                builder: (context) {
                  //deshabilitado mientras carga, si la carga fallo, si no hay
                  //alumnos o si ya hay un envio en camino
                  final puede = context.select<Atencionviewmodel, bool>(
                    (vm) => vm.puedeRegistrar,
                  );
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: ColorTheme.primary,
                            shape: FormaTema.lleno,
                          ),
                          onPressed: puede ? _guardar : null,
                          icon: const Icon(Icons.check),
                          label: const Text('Enviar reporte de asistencia'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      //maybePop pasa por el PopScope: con cambios, pregunta
                      //antes de salir (AS-10)
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ColorTheme.primary,
                            side: const BorderSide(color: ColorTheme.primary),
                            shape: FormaTema.lleno,
                          ),
                          onPressed: () => Navigator.maybePop(context),
                          child: const Text('Cancelar'),
                        ),
                      ),
                    ],
                  );
                },
              ),
    );
  }

  Future<void> _guardar() async {
    final resultado =
        await context.read<Atencionviewmodel>().registrarAtenciones();
    await _mostrarResultado(resultado);
  }

  //el vm ya interpreto la respuesta: la vista solo decide que mostrar. El
  //dialogo va antes del pop: despues de cerrar la pantalla su context ya no
  //sirve para mostrar nada
  Future<void> _mostrarResultado(Resultado<void> resultado) async {
    if (!mounted) return;
    switch (resultado) {
      case Exito():
        await showDialog(
          context: context,
          builder:
              (_) => DialogExito(
                titulo: 'Atenciones registradas',
                mensaje: 'Se ha registrado la asistencia de la clase.',
              ),
        );
        if (mounted) Navigator.pop(context);
      case Fallo(:final codigo, :final mensaje):
        await showDialog(
          context: context,
          builder:
              (_) => DialogError(
                titulo: 'Error al registrar atenciones',
                codigo: codigo,
                mensaje: mensaje,
              ),
        );
    }
  }
}

//contenedor blanco con borde suave, como las tarjetas del prototipo
class _Tarjeta extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Tarjeta({required this.child, this.padding = const EdgeInsets.all(14)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: FormaTema.radioMedio,
        border: Border.all(color: ColorTheme.asistenciaBorde),
      ),
      child: child,
    );
  }
}

//presentes, ausentes y justificadas; se reconstruye solo cuando cambian
class _Resumen extends StatelessWidget {
  const _Resumen();

  @override
  Widget build(BuildContext context) {
    final cuentas = context.select<Atencionviewmodel, (int, int, int)>(
      (vm) => (
        vm.contar(EstadoAsistencia.presente),
        vm.contar(EstadoAsistencia.ausente),
        vm.contar(EstadoAsistencia.justificada),
      ),
    );
    return _Tarjeta(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _contador(cuentas.$1, 'Presentes', 'resumen-presentes'),
            const VerticalDivider(color: ColorTheme.asistenciaBorde),
            _contador(cuentas.$2, 'Ausentes', 'resumen-ausentes'),
            const VerticalDivider(color: ColorTheme.asistenciaBorde),
            _contador(cuentas.$3, 'Justificadas', 'resumen-justificadas'),
          ],
        ),
      ),
    );
  }

  Widget _contador(int valor, String etiqueta, String clave) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$valor',
            key: ValueKey(clave),
            style: Tipografia.h5(color: ColorTheme.primary),
          ),
          Text(etiqueta, style: Tipografia.leyenda(color: ColorTheme.neutral)),
        ],
      ),
    );
  }
}

//un alumno: iniciales, nombre, codigo y los tres estados
class _TarjetaAlumno extends StatelessWidget {
  final Atencionentidad atencion;
  final bool soloLectura;
  final ValueChanged<EstadoAsistencia> alElegir;

  const _TarjetaAlumno({
    super.key,
    required this.atencion,
    required this.soloLectura,
    required this.alElegir,
  });

  @override
  Widget build(BuildContext context) {
    final alumno = atencion.alumno;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Tarjeta(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: ColorTheme.tonal,
                  child: Text(
                    _iniciales(alumno.nombre),
                    style: Tipografia.leyendaNegrita(color: ColorTheme.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alumno.nombre,
                        style: Tipografia.subtitulo2(
                          color: ColorTheme.primaryDark,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      //sin codigo (docentes, administrativos) no se muestra
                      //el id del perfil en su lugar
                      if (alumno.codigo != null && alumno.codigo!.isNotEmpty)
                        Text(
                          'Código ${alumno.codigo}',
                          style: Tipografia.leyenda(color: ColorTheme.primaryDark),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final estado in EstadoAsistencia.values) ...[
                  if (estado != EstadoAsistencia.values.first)
                    const SizedBox(width: 6),
                  Expanded(
                    child: BotonEstadoAsistencia(
                      estado: estado,
                      elegido: atencion.estado == estado,
                      habilitado:
                          !soloLectura &&
                          (estado != EstadoAsistencia.justificada ||
                              EstadoAsistencia.justificadaDisponible),
                      alElegir: () => alElegir(estado),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  //'Ana Sofía Muñoz' -> 'AS'
  static String _iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    return partes
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
  }
}

//uno de los tres estados de un alumno. Publico para que las pruebas lean
//cual esta elegido (estado y elegido) sin depender de colores
class BotonEstadoAsistencia extends StatelessWidget {
  final EstadoAsistencia estado;
  final bool elegido;
  final bool habilitado;
  final VoidCallback alElegir;

  const BotonEstadoAsistencia({
    super.key,
    required this.estado,
    required this.elegido,
    required this.habilitado,
    required this.alElegir,
  });

  @override
  Widget build(BuildContext context) {
    final (fondo, texto) = switch (estado) {
      EstadoAsistencia.presente => (
        ColorTheme.asistenciaPresenteFondo,
        ColorTheme.asistenciaPresente,
      ),
      EstadoAsistencia.ausente => (
        ColorTheme.asistenciaAusenteFondo,
        ColorTheme.asistenciaAusente,
      ),
      EstadoAsistencia.justificada => (
        ColorTheme.asistenciaJustificadaFondo,
        ColorTheme.asistenciaJustificada,
      ),
    };
    final colorTexto =
        elegido
            ? texto
            : habilitado
            ? ColorTheme.neutral
            : ColorTheme.neutral.withValues(alpha: 0.4);
    return Semantics(
      selected: elegido,
      button: true,
      child: OutlinedButton(
        onPressed: habilitado ? alElegir : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          minimumSize: const Size(0, 36),
          backgroundColor: elegido ? fondo : Colors.white,
          disabledBackgroundColor: elegido ? fondo : Colors.white,
          side: BorderSide(
            color: elegido ? texto : ColorTheme.asistenciaBorde,
          ),
          shape: FormaTema.lleno,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            estado.etiqueta,
            style: Tipografia.leyendaNegrita(color: colorTexto),
          ),
        ),
      ),
    );
  }

}
