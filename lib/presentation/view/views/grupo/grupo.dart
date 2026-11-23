import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/presentation/view/views/grupo/encabezadoGrupo.dart';
import 'package:dpt_movil/presentation/view/views/grupo/widgetListaAlumnos.dart';
import 'package:dpt_movil/presentation/view/views/grupo/widgetListaClases.dart';
import 'package:dpt_movil/presentation/view/views/grupo/widgetListaHorarios.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:flutter/material.dart';

//pantalla de un grupo (rediseño del 2026-11-20, prototipo del cliente): el
//encabezado y, debajo, las secciones Horario, Asistencias y Alumnos con una
//barra de pestanas que queda fija arriba y lleva a cada una. La informacion
//del curso se omite por ahora (decision del 2026-11-20)
class Grupo extends StatelessWidget {
  Grupoentidad grupo;
  Grupo({super.key, required this.grupo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(),
      drawer: Builder(builder: (context) => Menulateral()),
      body: const SafeArea(child: _CuerpoGrupo()),
    );
  }
}

class _CuerpoGrupo extends StatefulWidget {
  const _CuerpoGrupo();

  @override
  State<_CuerpoGrupo> createState() => _CuerpoGrupoState();
}

class _CuerpoGrupoState extends State<_CuerpoGrupo> {
  static const double _altoPestanas = 52;

  final _desplazamiento = ScrollController();
  final _claveHorario = GlobalKey();
  final _claveAsistencias = GlobalKey();
  final _claveAlumnos = GlobalKey();

  @override
  void dispose() {
    _desplazamiento.dispose();
    super.dispose();
  }

  //lleva el titulo de la seccion justo debajo de la barra de pestanas (el
  //visor ya descuenta la barra fija al revelar)
  void _irA(GlobalKey clave) {
    final contexto = clave.currentContext;
    if (contexto == null) return;
    Scrollable.ensureVisible(
      contexto,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _desplazamiento,
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
          sliver: SliverToBoxAdapter(child: EncabezadoGrupo()),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _DelegadoPestanas(
            alto: _altoPestanas,
            pestanas: {
              'Horario': () => _irA(_claveHorario),
              'Asistencias': () => _irA(_claveAsistencias),
              'Alumnos': () => _irA(_claveAlumnos),
            },
          ),
        ),
        //las secciones van en un solo sliver: se construyen de una vez y las
        //pestanas encuentran su posicion. Mientras ese sliver no asoma en
        //pantalla, las pruebas lo buscan con skipOffstage: false
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Widgetlistahorarios(key: _claveHorario),
                const _Separador(),
                Widgetlistaclases(key: _claveAsistencias),
                const _Separador(),
                Widgetlistaalumnos(key: _claveAlumnos),
                const SizedBox(height: 24),
                const _BotonesCierre(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Separador extends StatelessWidget {
  const _Separador();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Divider(height: 1, color: ColorTheme.asistenciaBorde),
  );
}

//barra blanca con las pestanas; fija arriba al desplazar
class _DelegadoPestanas extends SliverPersistentHeaderDelegate {
  final double alto;
  final Map<String, VoidCallback> pestanas;

  _DelegadoPestanas({required this.alto, required this.pestanas});

  @override
  double get minExtent => alto;

  @override
  double get maxExtent => alto;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Colors.white,
      elevation: overlapsContent || shrinkOffset > 0 ? 2 : 0,
      shadowColor: ColorTheme.primary.withValues(alpha: 0.2),
      child: Row(
        children: [
          for (final pestana in pestanas.entries)
            Expanded(
              child: InkWell(
                onTap: pestana.value,
                child: Center(
                  child: Text(
                    pestana.key,
                    style: Tipografia.boton1(color: ColorTheme.primary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_DelegadoPestanas anterior) =>
      anterior.alto != alto || anterior.pestanas != pestanas;
}

//aun sin accion (O-02): se conservan al final de la pantalla
class _BotonesCierre extends StatelessWidget {
  const _BotonesCierre();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: ColorTheme.secondary,
            side: const BorderSide(color: ColorTheme.secondary),
          ),
          child: const Text('FINALIZAR GRUPO'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: ColorTheme.secondary,
          ),
          child: const Text('ELIMINAR GRUPO'),
        ),
      ],
    );
  }
}
