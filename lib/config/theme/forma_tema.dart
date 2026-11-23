import 'package:flutter/material.dart';

///Escala de redondeado del Sistema de Diseño de la Universidad del Cauca
///(2.4 Contenedores). El manual la da en px para la web; en Flutter se usan los
///mismos numeros en pixeles logicos (dp), que tambien son independientes de la
///densidad de la pantalla. Es la escala de formas de Material 3.
class FormaTema {
  FormaTema._();

  ///0: pancartas, barras superiores e inferiores, listas, menu estandar,
  ///pestanas, hojas laterales ancladas
  static const double ninguno = 0;

  ///4: campos de texto, menu autocompletar, seleccionar menu, snackbars
  static const double extraPequeno = 4;

  ///8: informacion sobre herramientas ricas en fichas
  static const double pequeno = 8;

  ///12: tarjetas, FAB pequenos, barra de busqueda
  static const double medio = 12;

  ///16: FAB, FAB extendidos, cajones de navegacion
  static const double largo = 16;

  ///28: dialogos, hojas inferiores y flotantes, selector de tiempo
  static const double extraGrande = 28;

  static const BorderRadius radioExtraPequeno = BorderRadius.all(
    Radius.circular(extraPequeno),
  );
  static const BorderRadius radioPequeno = BorderRadius.all(
    Radius.circular(pequeno),
  );
  static const BorderRadius radioMedio = BorderRadius.all(
    Radius.circular(medio),
  );
  static const BorderRadius radioLargo = BorderRadius.all(
    Radius.circular(largo),
  );
  static const BorderRadius radioExtraGrande = BorderRadius.all(
    Radius.circular(extraGrande),
  );

  ///100 %: botones primarios, secundarios y terciarios, insignias,
  ///interruptores. Redondea los extremos por completo sea cual sea la altura
  static const OutlinedBorder lleno = StadiumBorder();

  ///tarjetas (medio)
  static const ShapeBorder tarjeta = RoundedRectangleBorder(
    borderRadius: radioMedio,
  );
}
