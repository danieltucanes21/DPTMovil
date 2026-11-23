import 'package:dpt_movil/config/theme/app_tema.dart';
import 'package:dpt_movil/config/theme/forma_tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

//escala de redondeado del Sistema de Diseño (2.4 Contenedores) en el tema
//global: lo que no fija su forma la toma de aqui
void main() {
  const String capa = "vista";
  const String tipo = "unitaria";

  final tema = AppTheme().theme();

  double radio(ShapeBorder? forma) =>
      ((forma as RoundedRectangleBorder).borderRadius as BorderRadius)
          .topLeft
          .x;

  group('Forma (tema global):', () {
    test('$capa - $tipo - Tema - la escala es la del manual', () {
      expect(
        [
          FormaTema.ninguno,
          FormaTema.extraPequeno,
          FormaTema.pequeno,
          FormaTema.medio,
          FormaTema.largo,
          FormaTema.extraGrande,
        ],
        [0, 4, 8, 12, 16, 28],
      );
    });

    test('$capa - $tipo - Tema - tarjetas medio, dialogos extra grande, FAB largo, snackbar extra pequeno', () {
      expect(radio(tema.cardTheme.shape), 12);
      expect(radio(tema.dialogTheme.shape), 28);
      expect(radio(tema.floatingActionButtonTheme.shape), 16);
      expect(radio(tema.snackBarTheme.shape), 4);
    });

    test('$capa - $tipo - Tema - los botones son llenos', () {
      for (final estilo in [
        tema.filledButtonTheme.style,
        tema.outlinedButtonTheme.style,
        tema.elevatedButtonTheme.style,
        tema.textButtonTheme.style,
      ]) {
        expect(estilo!.shape!.resolve({}), isA<StadiumBorder>());
      }
    });
  });
}
