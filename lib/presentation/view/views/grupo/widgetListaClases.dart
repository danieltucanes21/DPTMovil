import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/config/routes/accesoRutas.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/entidadesRutas/clase_grupoArgumentos.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/view/views/grupo/seccionGrupo.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//seccion «Asistencias» de la pantalla del grupo (rediseño del 2026-11-20).
//Las clases las carga el vm de la pantalla al entrar (ruta grupo). Desde
//AS-13 no se agregan ni se eliminan a mano: las define el horario del grupo, y
//«Tomar asistencia» abre la de hoy. Las demas se consultan en solo lectura
class Widgetlistaclases extends StatelessWidget {
  const Widgetlistaclases({super.key});

  @override
  Widget build(BuildContext context) {
    //solo se reconstruye cuando cambia la seccion de clases del vm
    final seccion = context
        .select<DetalleGrupoViewModel, EstadoSeccion<List<Claseentidad>>>(
          (vm) => vm.clases,
        );
    //tomar y consultar asistencia solo para quien dicta la clase (AS-01); la
    //ruta tambien lo comprueba (AccesoRutas)
    final dicta = context.select<AutenticacionViewModel, bool>(
      (vm) => AccesoRutas.dictaClase(vm.perfilSesion?.role),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EncabezadoSeccion(
          titulo: 'Asistencias',
          subtitulo: 'Seguimiento de las clases realizadas',
          accion: dicta ? const _BotonTomarAsistencia() : null,
        ),
        if (dicta) const _MotivoSinAsistencia(),
        const SizedBox(height: 16),
        if (seccion.cargando)
          const Center(child: CircularProgressIndicator())
        else if (seccion.error != null)
          AvisoSeccion(seccion.error!, esError: true)
        else if (seccion.datos.isEmpty)
          const AvisoSeccion('Aún no hay clases registradas')
        else
          for (final clase in _recientesPrimero(seccion.datos))
            _TarjetaClase(
              clase,
              alTocar: dicta ? () => _abrirClase(context, clase) : null,
            ),
      ],
    );
  }

  //la mas reciente arriba; una clase sin fecha va al final
  static List<Claseentidad> _recientesPrimero(List<Claseentidad> lista) {
    final copia = [...lista];
    copia.sort((a, b) {
      if (a.fecha == null) return 1;
      if (b.fecha == null) return -1;
      return b.fecha!.compareTo(a.fecha!);
    });
    return copia;
  }

  //dentro de la ventana se marca; fuera, solo se consulta (AS-13)
  void _abrirClase(BuildContext context, Claseentidad clase) {
    final vm = context.read<DetalleGrupoViewModel>();
    final editable = vm.puedeEditarClase(
      clase,
      sinLimite: _esCoordinador(context),
    );
    Navigator.pushNamed(
      context,
      AppRutas.clase,
      arguments: ClaseGrupoargumentos(
        clase: clase,
        grupo: vm.grupo,
        soloLectura: !editable,
        horario: vm.horarioDe(clase.fecha),
      ),
    );
  }
}

//fecha de la clase y, si ese dia hay horario, la hora y el escenario
class _TarjetaClase extends StatelessWidget {
  final Claseentidad clase;
  final VoidCallback? alTocar;

  const _TarjetaClase(this.clase, {required this.alTocar});

  @override
  Widget build(BuildContext context) {
    final horario = context.read<DetalleGrupoViewModel>().horarioDe(
      clase.fecha,
    );
    final fecha = clase.fecha;
    return TarjetaSeccion(
      alTocar: alTocar,
      child: Row(
        children: [
          const CajaIcono(Icons.check),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fecha == null ? 'Clase sin fecha' : FormatDate.fechaConDia(fecha),
                  style: Tipografia.cuerpo1(color: ColorTheme.primaryDark),
                ),
                const SizedBox(height: 2),
                Text(
                  horario == null
                      ? 'Sin horario ese día'
                      : '${FormatDate.horaLegible(horario.horaInicio)} · '
                          '${horario.escenario}',
                  style: Tipografia.leyenda(color: ColorTheme.neutral),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//el coordinador no tiene limite de ventana (decision del 2026-11-19)
bool _esCoordinador(BuildContext context) =>
    context.read<AutenticacionViewModel>().perfilSesion?.role ==
    Roles.coordinador;

//habilitado solo dentro de la ventana; si no, _MotivoSinAsistencia dice por
//que. El vm vuelve a comprobar la ventana al tocar, por si la pantalla quedo
//abierta
class _BotonTomarAsistencia extends StatelessWidget {
  const _BotonTomarAsistencia();

  @override
  Widget build(BuildContext context) {
    final sinLimite = context.select<AutenticacionViewModel, bool>(
      (vm) => vm.perfilSesion?.role == Roles.coordinador,
    );
    final motivo = context.select<DetalleGrupoViewModel, String?>(
      (vm) => vm.motivoSinAsistencia(sinLimite: sinLimite),
    );
    final tomando = context.select<DetalleGrupoViewModel, bool>(
      (vm) => vm.tomandoAsistencia,
    );
    return BotonSeccion(
      texto: 'Tomar asistencia',
      icono: Icons.check,
      alPresionar:
          motivo == null && !tomando
              ? () => _tomarAsistencia(context, sinLimite)
              : null,
    );
  }

  Future<void> _tomarAsistencia(BuildContext context, bool sinLimite) async {
    final vm = context.read<DetalleGrupoViewModel>();
    final resultado = await vm.tomarAsistencia(sinLimite: sinLimite);
    if (!context.mounted) return;
    switch (resultado) {
      case Exito(:final datos):
        Navigator.pushNamed(
          context,
          AppRutas.clase,
          arguments: ClaseGrupoargumentos(
            clase: datos!,
            grupo: vm.grupo,
            horario: vm.horarioDe(datos.fecha),
          ),
        );
      case Fallo(:final codigo, :final mensaje):
        await showDialog(
          context: context,
          builder:
              (_) => DialogError(
                titulo: 'No se pudo abrir la clase de hoy',
                codigo: codigo,
                mensaje: mensaje,
              ),
        );
    }
  }
}

//por que no se puede tomar la asistencia de hoy, debajo del titulo
class _MotivoSinAsistencia extends StatelessWidget {
  const _MotivoSinAsistencia();

  @override
  Widget build(BuildContext context) {
    final sinLimite = context.select<AutenticacionViewModel, bool>(
      (vm) => vm.perfilSesion?.role == Roles.coordinador,
    );
    final motivo = context.select<DetalleGrupoViewModel, String?>(
      (vm) => vm.motivoSinAsistencia(sinLimite: sinLimite),
    );
    if (motivo == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        motivo,
        style: Tipografia.leyenda(color: ColorTheme.secondaryDark),
      ),
    );
  }
}
