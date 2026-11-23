import 'package:flutter/material.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/forma_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';

class AppTheme {
  final ColorScheme _colorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: ColorTheme.primary, // Fondo principal
      onPrimary: ColorTheme.tonal, // Texto sobre fondo principal
      secondary: ColorTheme.secondary, // Fondo secundario
      onSecondary: ColorTheme.tonal, // Texto sobre fondo secundario
      error: ColorTheme.error, // Fondo para errores
      onError: ColorTheme.tonal, // Texto sobre fondo de errores
      surface: Colors.white, // Fondo de superficie
      onSurface: Colors.black); // Texto sobre superficie

  ThemeData theme() {
    return ThemeData(
      colorScheme: _colorScheme,
      elevatedButtonTheme: _elevatedButton(),
      filledButtonTheme: _filledButton(),
      outlinedButtonTheme: _outLinedButton(),
      textButtonTheme: _textButton(),
      dropdownMenuTheme: _dropdownMenu(),
      chipTheme: _chipTheme(),
      //escala de redondeado del manual (FormaTema): los componentes que no
      //fijan su forma la toman de aqui
      cardTheme: const CardThemeData(shape: FormaTema.tarjeta),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: FormaTema.radioExtraGrande),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(FormaTema.extraGrande),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: FormaTema.radioLargo),
      ),
      snackBarTheme: const SnackBarThemeData(
        shape: RoundedRectangleBorder(borderRadius: FormaTema.radioExtraPequeno),
      ),
      drawerTheme: const DrawerThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(FormaTema.largo),
          ),
        ),
      ),
      //Tipo de letra usado para el cuerpo, en caso de necesitar titulo, definir especificamente
      fontFamily: 'OpenSans',
      //tipografia usado para titulos, usar solo particularmente y no generalmente
      //fontFamily: 'TitiliumWeb',
      useMaterial3: true,
    );
  }

  DropdownMenuThemeData _dropdownMenu() {
    return DropdownMenuThemeData(
        textStyle: Tipografia.boton2(),
        inputDecorationTheme: InputDecorationTheme(
          /*filled: true,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: BorderSide.none),
            fillColor: ColorTheme.tonal,*/
          border: UnderlineInputBorder(),
          contentPadding: EdgeInsets.all(0),
          constraints: BoxConstraints(maxHeight: 40),
          isDense: true,
        ));
  }

  TextButtonThemeData _textButton() {
    return TextButtonThemeData(
        style: TextButton.styleFrom(
            shape: FormaTema.lleno, textStyle: Tipografia.boton1()));
  }

  ChipThemeData _chipTheme() {
    return ChipThemeData(
        side: BorderSide(color: ColorTheme.secondary),
        labelStyle: Tipografia.leyendaNegrita(color: ColorTheme.secondary));
  }

  ElevatedButtonThemeData _elevatedButton() {
    return ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            shape: FormaTema.lleno,
            backgroundColor: ColorTheme.primary,
            foregroundColor: Colors.white,
            textStyle: Tipografia.boton1()));
  }

  FilledButtonThemeData _filledButton() {
    return FilledButtonThemeData(
        style: FilledButton.styleFrom(
            shape: FormaTema.lleno,
            textStyle: Tipografia.boton1(),
            backgroundColor: ColorTheme.primary,
            foregroundColor: Colors.white));
  }

  OutlinedButtonThemeData _outLinedButton() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
          shape: FormaTema.lleno,
          foregroundColor: ColorTheme.primary,
          side: BorderSide(color: ColorTheme.primary),
          textStyle: Tipografia.boton1()),
    );
  }
}
