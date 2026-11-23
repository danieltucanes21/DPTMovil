import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/forma_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/alumnoEntidad.dart';
import 'package:dpt_movil/presentation/view/views/grupo/seccionGrupo.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//seccion «Alumnos» de la pantalla del grupo (rediseño del 2026-11-20): los
//inscritos en una sola tarjeta, con sus iniciales y su codigo
class Widgetlistaalumnos extends StatelessWidget {
  const Widgetlistaalumnos({super.key});

  @override
  Widget build(BuildContext context) {
    //solo se reconstruye cuando cambia la seccion de alumnos del vm
    final seccion = context
        .select<DetalleGrupoViewModel, EstadoSeccion<List<Alumnoentidad>>>(
          (vm) => vm.alumnos,
        );
    final listo = !seccion.cargando && seccion.error == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EncabezadoSeccion(
          titulo: 'Alumnos',
          subtitulo: listo ? _inscritos(seccion.datos.length) : null,
        ),
        const SizedBox(height: 16),
        if (seccion.cargando)
          const Center(child: CircularProgressIndicator())
        else if (seccion.error != null)
          AvisoSeccion(
            'No se pudo obtener la lista de alumnos: ${seccion.error}',
            esError: true,
          )
        else if (seccion.datos.isEmpty)
          const AvisoSeccion('Aún no hay alumnos inscritos')
        else
          _ListaAlumnos(seccion.datos),
      ],
    );
  }

  static String _inscritos(int n) => switch (n) {
    0 => 'Sin estudiantes inscritos',
    1 => '1 estudiante inscrito',
    _ => '$n estudiantes inscritos',
  };
}

class _ListaAlumnos extends StatelessWidget {
  final List<Alumnoentidad> alumnos;
  const _ListaAlumnos(this.alumnos);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: FormaTema.radioMedio,
        border: Border.all(color: ColorTheme.asistenciaBorde),
      ),
      child: Column(
        children: [
          for (var i = 0; i < alumnos.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: ColorTheme.asistenciaBorde),
            _FilaAlumno(alumnos[i]),
          ],
        ],
      ),
    );
  }
}

class _FilaAlumno extends StatelessWidget {
  final Alumnoentidad alumno;
  const _FilaAlumno(this.alumno);

  @override
  Widget build(BuildContext context) {
    final codigo = alumno.codigo;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: ColorTheme.tonal,
            child: Text(
              iniciales(alumno.nombre),
              style: Tipografia.boton1(color: ColorTheme.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alumno.nombre,
                  style: Tipografia.cuerpo1(color: ColorTheme.primaryDark),
                ),
                Text(
                  codigo != null && codigo.trim().isNotEmpty
                      ? 'Código $codigo'
                      : alumno.correo,
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

//'Ana Sofía Muñoz' -> 'AS': las dos primeras palabras
String iniciales(String nombre) {
  final palabras = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  return palabras.take(2).map((p) => p[0].toUpperCase()).join();
}
