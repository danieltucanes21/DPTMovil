import 'package:flutter/material.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';

//barra de todas las pantallas (2026-11-19, tomando como referencia la de
//categorias): el logo de la U y el nombre de la aplicacion siempre a la
//vista, el boton de atras cuando se puede volver y el del menu lateral a la
//derecha. El titulo de la pantalla, si lo hay, va debajo con la linea de
//titulo del manual de marca
class Bar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  const Bar({super.key, this.title});

  static const double _alturaMarca = 58;
  static const double _alturaTitulo = 44;

  @override
  Widget build(BuildContext context) {
    final puedeVolver = ModalRoute.of(context)?.canPop == true;
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      toolbarHeight: _alturaMarca,
      leading:
          puedeVolver
              ? const BackButton(color: ColorTheme.menuAcento)
              : null,
      titleSpacing: puedeVolver ? 0 : 16,
      title: const MarcaAplicacion(),
      actions: [
        IconButton(
          tooltip: 'Menú',
          color: ColorTheme.menuAcento,
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: const Icon(Icons.menu),
        ),
      ],
      bottom:
          title == null
              ? null
              : PreferredSize(
                preferredSize: const Size.fromHeight(_alturaTitulo),
                child: _TituloPagina(title!),
              ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    _alturaMarca + (title == null ? 0 : _alturaTitulo),
  );
}

//logo de la U y nombre de la aplicacion
class MarcaAplicacion extends StatelessWidget {
  const MarcaAplicacion({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 34,
          decoration: BoxDecoration(
            color: ColorTheme.menuAcento,
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.center,
          child: const Text(
            'U',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 21,
            ),
          ),
        ),
        const SizedBox(width: 9),
        const Flexible(
          child: Text(
            'Deporte Para Todos',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: ColorTheme.menuAcento,
            ),
          ),
        ),
      ],
    );
  }
}

class _TituloPagina extends StatelessWidget {
  final String titulo;
  const _TituloPagina(this.titulo);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Tipografia.h6(
              color: ColorTheme.primary,
            ).copyWith(fontWeight: FontWeight.w800),
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
      ),
    );
  }
}
