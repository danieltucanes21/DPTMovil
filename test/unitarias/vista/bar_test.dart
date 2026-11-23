import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

//barra comun de la aplicacion (2026-11-19): logo y nombre siempre, atras solo
//si se puede volver, el menu lateral a la derecha y el titulo de la pantalla
//debajo
void main() {
  const String capa = "vista";
  const String tipo = "widget";

  Widget pantalla({String? titulo}) => Scaffold(
    drawer: const Drawer(child: Text('menu lateral')),
    appBar: Bar(title: titulo),
    body: const SizedBox.shrink(),
  );

  group('Barra de la aplicacion:', () {
    testWidgets('$capa - $tipo - Bar - en la raiz muestra la marca y el menu, sin atras', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: pantalla()));

      expect(find.text('U'), findsOneWidget);
      expect(find.text('Deporte Para Todos'), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('$capa - $tipo - Bar - en una pantalla interna agrega atras y el titulo', (
      tester,
    ) async {
      final navegador = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(navigatorKey: navegador, home: pantalla()),
      );
      navegador.currentState!.push(
        MaterialPageRoute(builder: (_) => pantalla(titulo: 'Grupos asignados')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Deporte Para Todos'), findsOneWidget);
      expect(find.text('Grupos asignados'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Grupos asignados'), findsNothing);
    });

    testWidgets('$capa - $tipo - Bar - el boton de menu abre el menu lateral', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: pantalla()));

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.text('menu lateral'), findsOneWidget);
    });
  });
}
