import 'package:dpt_movil/domain/entities/estadoAsistencia.dart';
import 'package:dpt_movil/presentation/view/views/clase/claseView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

//ayudas para leer y tocar la toma de asistencia (rediseño del 2026-11-19):
//cada alumno tiene tres BotonEstadoAsistencia. No es un test: lo usan las
//pruebas de vista y de integracion

//el estado elegido de cada alumno, en el orden de la lista
List<EstadoAsistencia> estadosElegidos(WidgetTester tester) => [
  for (final boton in tester.widgetList<BotonEstadoAsistencia>(
    find.byType(BotonEstadoAsistencia),
  ))
    if (boton.elegido) boton.estado,
];

Finder botonEstado(EstadoAsistencia estado, int alumno) =>
    find
        .byWidgetPredicate(
          (w) => w is BotonEstadoAsistencia && w.estado == estado,
        )
        .at(alumno);

//elige un estado para el alumno de esa posicion
Future<void> marcar(
  WidgetTester tester,
  EstadoAsistencia estado,
  int alumno,
) async {
  final boton = botonEstado(estado, alumno);
  await tester.ensureVisible(boton);
  await tester.pumpAndSettle();
  await tester.tap(boton);
  await tester.pumpAndSettle();
}

Finder botonEnviar() => find.text('Enviar reporte de asistencia');

//atras de la barra (BackButton), que pasa por el PopScope como el del sistema
Finder botonAtras() => find.byType(BackButton);
