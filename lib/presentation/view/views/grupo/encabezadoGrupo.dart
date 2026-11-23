import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/forma_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//encabezado de la pantalla del grupo (rediseño del 2026-11-20, prototipo del
//cliente): franja azul con curso, grupo y estado; debajo el instructor, las
//fechas y los cupos. Lee del vm de la ruta solo lo que pinta
class EncabezadoGrupo extends StatelessWidget {
  const EncabezadoGrupo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: FormaTema.radioLargo,
        border: Border.all(color: ColorTheme.asistenciaBorde),
        boxShadow: [
          BoxShadow(
            color: ColorTheme.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: FormaTema.radioLargo,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Franja(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  _Instructor(),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1, color: ColorTheme.asistenciaBorde),
                  ),
                  _Fechas(),
                  SizedBox(height: 12),
                  _Cupos(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//curso, «Grupo 2026.1» con la linea roja del titulo y el estado
class _Franja extends StatelessWidget {
  const _Franja();

  @override
  Widget build(BuildContext context) {
    final vm = context.read<DetalleGrupoViewModel>();
    final grupo = vm.grupo;
    final finalizado = context.select<DetalleGrupoViewModel, bool>(
      (vm) => vm.finalizado,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColorTheme.primary, ColorTheme.primaryLight],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            grupo.curso,
            style: Tipografia.subtitulo2(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Grupo ${grupo.anio}.${grupo.iterable}',
            style: Tipografia.h4(color: Colors.white),
          ),
          Container(
            margin: const EdgeInsets.only(top: 6, bottom: 16),
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: ColorTheme.secondaryLight,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: ShapeDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: FormaTema.lleno,
            ),
            child: Text(
              finalizado ? 'Finalizado' : 'Activo',
              style: Tipografia.boton1(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _Instructor extends StatelessWidget {
  const _Instructor();

  @override
  Widget build(BuildContext context) {
    final sinInstructor = context.select<DetalleGrupoViewModel, bool>(
      (vm) => vm.grupo.idInstructor == null,
    );
    final seccion = context.select<DetalleGrupoViewModel, EstadoSeccion<String?>>(
      (vm) => vm.instructor,
    );
    final String nombre;
    if (sinInstructor) {
      nombre = 'Sin instructor asignado';
    } else if (seccion.cargando) {
      nombre = 'Cargando...';
    } else if (seccion.datos != null) {
      nombre = _capitalizar(seccion.datos!);
    } else {
      nombre = 'No se pudo obtener el instructor';
    }
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: ColorTheme.tonal,
            borderRadius: FormaTema.radioMedio,
          ),
          child: const Icon(
            Icons.person_outline,
            color: ColorTheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('INSTRUCTOR', style: _estiloEtiqueta),
              const SizedBox(height: 2),
              Text(
                nombre,
                style: Tipografia.subtitulo1(color: ColorTheme.neutral),
              ),
            ],
          ),
        ),
      ],
    );
  }

  //'edynson muñoz jimenez' -> 'Edynson Muñoz Jimenez' (el backend los guarda
  //como los escribio cada quien)
  static String _capitalizar(String texto) => texto
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
      .join(' ');
}

class _Fechas extends StatelessWidget {
  const _Fechas();

  @override
  Widget build(BuildContext context) {
    final grupo = context.read<DetalleGrupoViewModel>().grupo;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Dato(
              'FECHA DE CREACIÓN',
              FormatDate.fechaLarga(grupo.fechaCreacion) ?? 'Sin fecha',

            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Dato(
              'FECHA DE FINALIZACIÓN',
              FormatDate.fechaLarga(grupo.fechaFinalizacion) ?? 'Sin definir',
            ),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;
  const _Dato(this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cajaBorde,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: _estiloEtiqueta),
          const SizedBox(height: 6),
          Text(valor, style: Tipografia.cuerpo1(color: ColorTheme.primary)),
        ],
      ),
    );
  }
}

//inscritos, cupos y disponibles; los que dependen de la lista de alumnos
//muestran «–» mientras carga o si fallo
class _Cupos extends StatelessWidget {
  const _Cupos();

  @override
  Widget build(BuildContext context) {
    final cupos = context.read<DetalleGrupoViewModel>().grupo.cupos;
    final inscritos = context.select<DetalleGrupoViewModel, int?>(
      (vm) => vm.inscritos,
    );
    final disponibles = context.select<DetalleGrupoViewModel, int?>(
      (vm) => vm.disponibles,
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: _cajaBorde,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _Cifra('${inscritos ?? '–'}', 'Inscritos')),
            const VerticalDivider(width: 1, color: ColorTheme.asistenciaBorde),
            Expanded(child: _Cifra('$cupos', 'Cupos totales')),
            const VerticalDivider(width: 1, color: ColorTheme.asistenciaBorde),
            Expanded(child: _Cifra('${disponibles ?? '–'}', 'Disponibles')),
          ],
        ),
      ),
    );
  }
}

class _Cifra extends StatelessWidget {
  final String valor;
  final String etiqueta;
  const _Cifra(this.valor, this.etiqueta);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(valor, style: Tipografia.h4(color: ColorTheme.primary)),
        const SizedBox(height: 2),
        Text(
          etiqueta,
          textAlign: TextAlign.center,
          style: Tipografia.leyenda(color: ColorTheme.neutral),
        ),
      ],
    );
  }
}

final TextStyle _estiloEtiqueta = Tipografia.leyenda(
  color: ColorTheme.neutral,
).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6);

const BoxDecoration _cajaBorde = BoxDecoration(
  borderRadius: FormaTema.radioMedio,
  border: Border.fromBorderSide(BorderSide(color: ColorTheme.asistenciaBorde)),
);
