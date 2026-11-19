import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/config/routes/accesoRutas.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/entidadesRutas/clase_grupoArgumentos.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//las clases las carga el vm de la pantalla al entrar (ruta grupo). Desde
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
    if (seccion.cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (seccion.error != null) {
      return Center(
        child: Text(
          seccion.error!,
          style: Tipografia.cuerpo1(color: ColorTheme.error),
        ),
      );
    }
    //tomar y consultar asistencia solo para quien dicta la clase (AS-01); la
    //ruta tambien lo comprueba (AccesoRutas)
    final dicta = context.select<AutenticacionViewModel, bool>(
      (vm) => AccesoRutas.dictaClase(vm.perfilSesion?.role),
    );
    return mostrarClases(context, seccion.datos, dicta);
  }

  Widget mostrarClases(
    BuildContext context,
    List<Claseentidad> lista,
    bool dicta,
  ) {
    return Column(
      children: [
        Text('Clases', style: Tipografia.h6()),
        if (dicta) const _BotonTomarAsistencia(),
        (lista.isEmpty)
            ? Text(
              'No hay clases aún!',
              style: Tipografia.cuerpo1(color: ColorTheme.secondaryDark),
            )
            : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lista.length,
              itemBuilder: (context, index) {
                Claseentidad clase = lista[index];
                return mostrarTarjeta(context, clase, dicta);
              },
            ),
      ],
    );
  }

  Widget mostrarTarjeta(BuildContext context, Claseentidad clase, bool dicta) {
    return InkWell(
      onTap: !dicta ? null : () => _abrirClase(context, clase),
      child: MiniTarjeta(
        atrTitulo: 'Fecha clase: ${FormatDate.fechaACadena(clase.fecha!, "-")}',
        atrSubTitulo: 'Tiempo: ${clase.horas}h:${clase.minutos}m',
        existeBotonCierre: false,
        existeCampoImagen: false,
      ),
    );
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
      ),
    );
  }
}

//el coordinador no tiene limite de ventana (decision del 2026-11-19)
bool _esCoordinador(BuildContext context) =>
    context.read<AutenticacionViewModel>().perfilSesion?.role ==
    Roles.coordinador;

//habilitado solo dentro de la ventana; si no, dice por que. El vm vuelve a
//comprobar la ventana al tocar, por si la pantalla quedo abierta
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
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed:
              motivo == null && !tomando
                  ? () => _tomarAsistencia(context, sinLimite)
                  : null,
          label: const Text('TOMAR ASISTENCIA'),
          icon: const Icon(Icons.fact_check),
        ),
        if (motivo != null)
          Text(
            motivo,
            textAlign: TextAlign.center,
            style: Tipografia.cuerpo2(color: ColorTheme.secondaryDark),
          ),
      ],
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
          arguments: ClaseGrupoargumentos(clase: datos!, grupo: vm.grupo),
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
