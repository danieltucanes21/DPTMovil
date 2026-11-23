import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/forma_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:flutter/material.dart';

//piezas comunes de las secciones de la pantalla del grupo (Horario,
//Asistencias, Alumnos; rediseño del 2026-11-20)

//titulo de la seccion, la linea de abajo y, a la derecha, su accion
class EncabezadoSeccion extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget? accion;

  const EncabezadoSeccion({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: Tipografia.h5(color: ColorTheme.primary),
              ),
              if (subtitulo != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitulo!,
                    style: Tipografia.cuerpo2(color: ColorTheme.neutral),
                  ),
                ),
            ],
          ),
        ),
        if (accion != null) ...[const SizedBox(width: 12), accion!],
      ],
    );
  }
}

//boton relleno de la seccion («Agregar horario», «Tomar asistencia»)
class BotonSeccion extends StatelessWidget {
  final String texto;
  final IconData icono;
  final VoidCallback? alPresionar;

  const BotonSeccion({
    super.key,
    required this.texto,
    required this.icono,
    required this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: alPresionar,
      style: FilledButton.styleFrom(
        backgroundColor: ColorTheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: Tipografia.boton1(),
      ),
      icon: Icon(icono, size: 18),
      label: Text(texto),
    );
  }
}

//cuadro claro con un icono, a la izquierda de cada tarjeta
class CajaIcono extends StatelessWidget {
  final IconData icono;
  final double lado;

  const CajaIcono(this.icono, {super.key, this.lado = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: lado,
      height: lado,
      decoration: const BoxDecoration(
        color: ColorTheme.tonal,
        borderRadius: FormaTema.radioMedio,
      ),
      child: Icon(icono, color: ColorTheme.primary, size: lado / 2),
    );
  }
}

//tarjeta con borde de las listas de la pantalla del grupo
class TarjetaSeccion extends StatelessWidget {
  final Widget child;
  final VoidCallback? alTocar;
  final EdgeInsetsGeometry relleno;

  const TarjetaSeccion({
    super.key,
    required this.child,
    this.alTocar,
    this.relleno = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: FormaTema.radioMedio,
          side: BorderSide(color: ColorTheme.asistenciaBorde),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: alTocar,
          child: Padding(padding: relleno, child: child),
        ),
      ),
    );
  }
}

//texto de una seccion vacia o con error
class AvisoSeccion extends StatelessWidget {
  final String texto;
  final bool esError;

  const AvisoSeccion(this.texto, {super.key, this.esError = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        texto,
        style: Tipografia.cuerpo2(
          color: esError ? ColorTheme.error : ColorTheme.neutral,
        ),
      ),
    );
  }
}
