import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/domain/entities/diaSemana.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/utils/Utilidades.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/view/views/grupo/seccionGrupo.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Widgetlistahorarios extends StatelessWidget {
  const Widgetlistahorarios({super.key});

  @override
  Widget build(BuildContext context) {
    //solo se reconstruye cuando cambia la seccion de horarios del vm
    final seccion = context
        .select<DetalleGrupoViewModel, EstadoSeccion<List<Horarioentidad>>>(
          (vm) => vm.horarios,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EncabezadoSeccion(
          titulo: 'Horario',
          subtitulo: seccion.cargando || seccion.error != null
              ? null
              : _sesiones(seccion.datos.length),
          accion: BotonSeccion(
            texto: 'Agregar horario',
            icono: Icons.add,
            alPresionar: () => _agregar(context),
          ),
        ),
        const SizedBox(height: 16),
        if (seccion.cargando)
          const Center(child: CircularProgressIndicator())
        else if (seccion.error != null)
          AvisoSeccion(
            'No se pudo obtener el horario: ${seccion.error}',
            esError: true,
          )
        else if (seccion.datos.isEmpty)
          const AvisoSeccion('El grupo aún no tiene horario')
        else
          for (final horario in seccion.datos)
            _TarjetaHorario(
              horario,
              alEliminar: () => _eliminar(context, horario),
            ),
      ],
    );
  }

  static String _sesiones(int n) => switch (n) {
    0 => 'Sin sesiones semanales',
    1 => '1 sesión semanal',
    _ => '$n sesiones semanales',
  };

  //el formulario es un dialogo que devuelve los datos; el vm valida, envia y
  //recarga la seccion, y la vista solo muestra el error si lo hay
  Future<void> _agregar(BuildContext context) async {
    final vm = context.read<DetalleGrupoViewModel>();
    final datos = await showDialog<_DatosHorario>(
      context: context,
      builder: (_) => const _DialogoHorario(),
    );
    if (datos == null) return;
    final resultado = await vm.agregarHorario(
      dia: datos.dia,
      horaInicio: datos.horaInicio,
      horaFin: datos.horaFin,
      escenario: datos.escenario,
    );
    if (!context.mounted) return;
    await _mostrarFallo(context, resultado, 'Error al guardar el horario');
  }

  Future<void> _eliminar(BuildContext context, Horarioentidad horario) async {
    final vm = context.read<DetalleGrupoViewModel>();
    final confirmado = await Utilidades.mostrarDialogoConfirmacion(
      context,
      '¿Esta seguro de eliminar el horario ${DiaSemana.etiqueta(horario.dia)} ${horario.horaInicio} - ${horario.horaFin} en ${horario.escenario}?',
      'Eliminar horario',
    );
    if (!confirmado || horario.id == null) return;
    final resultado = await vm.eliminarHorario(horario.id!);
    if (!context.mounted) return;
    await _mostrarFallo(context, resultado, 'Error al eliminar el horario');
  }

  Future<void> _mostrarFallo(
    BuildContext context,
    Resultado<void> resultado,
    String titulo,
  ) async {
    if (resultado case Fallo(:final codigo, :final mensaje)) {
      await showDialog(
        context: context,
        builder:
            (_) => DialogError(titulo: titulo, codigo: codigo, mensaje: mensaje),
      );
    }
  }
}

//dia, horas y escenario de un horario; el boton de la derecha lo elimina
class _TarjetaHorario extends StatelessWidget {
  final Horarioentidad horario;
  final VoidCallback alEliminar;

  const _TarjetaHorario(this.horario, {required this.alEliminar});

  @override
  Widget build(BuildContext context) {
    return TarjetaSeccion(
      child: Row(
        children: [
          const CajaIcono(Icons.calendar_month_outlined, lado: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DiaSemana.etiqueta(horario.dia),
                  style: Tipografia.subtitulo1(color: ColorTheme.primary),
                ),
                const SizedBox(height: 4),
                _Detalle(
                  Icons.schedule,
                  '${FormatDate.horaLegible(horario.horaInicio)} – '
                  '${FormatDate.horaLegible(horario.horaFin)}',
                ),
                const SizedBox(height: 2),
                _Detalle(Icons.home_outlined, horario.escenario),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Eliminar horario',
            onPressed: alEliminar,
            icon: const Icon(Icons.delete_outline, color: ColorTheme.neutral),
          ),
        ],
      ),
    );
  }
}

class _Detalle extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _Detalle(this.icono, this.texto);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 16, color: ColorTheme.primaryLight),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: Tipografia.leyenda(color: ColorTheme.neutral),
          ),
        ),
      ],
    );
  }
}

class _DatosHorario {
  final String dia;
  final String? horaInicio;
  final String? horaFin;
  final String escenario;
  _DatosHorario(this.dia, this.horaInicio, this.horaFin, this.escenario);
}

class _DialogoHorario extends StatefulWidget {
  const _DialogoHorario();

  @override
  State<_DialogoHorario> createState() => _DialogoHorarioState();
}

class _DialogoHorarioState extends State<_DialogoHorario> {
  //se elige por la etiqueta y se envia el codigo del backend (HO-06)
  static const _dias = DiaSemana.codigos;
  final _escenario = TextEditingController();
  String _dia = _dias.first;
  TimeOfDay? _inicio;
  TimeOfDay? _fin;

  @override
  void dispose() {
    _escenario.dispose();
    super.dispose();
  }

  String? _texto(TimeOfDay? hora) =>
      hora == null
          ? null
          : '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';

  Future<void> _elegir(bool inicio) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: (inicio ? _inicio : _fin) ?? TimeOfDay.now(),
    );
    if (hora == null) return;
    setState(() => inicio ? _inicio = hora : _fin = hora);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar horario'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _dia,
              decoration: const InputDecoration(labelText: 'Dia'),
              items: [
                for (final d in _dias)
                  DropdownMenuItem(value: d, child: Text(DiaSemana.etiqueta(d))),
              ],
              onChanged: (d) => setState(() => _dia = d ?? _dia),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _elegir(true),
              child: Text('Hora de inicio: ${_texto(_inicio) ?? "elegir"}'),
            ),
            OutlinedButton(
              onPressed: () => _elegir(false),
              child: Text('Hora de fin: ${_texto(_fin) ?? "elegir"}'),
            ),
            TextField(
              controller: _escenario,
              decoration: const InputDecoration(labelText: 'Escenario'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        TextButton(
          onPressed:
              () => Navigator.pop(
                context,
                _DatosHorario(_dia, _texto(_inicio), _texto(_fin), _escenario.text),
              ),
          child: const Text('GUARDAR'),
        ),
      ],
    );
  }
}
