import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

//estado del grupo para el encabezado: el backend no lo manda, se deduce de la
//fecha de finalizacion (el dia de la finalizacion aun cuenta como activo)
void main() {
  const String capa = "dominio";
  const String tipo = "unitaria";

  Grupoentidad grupo(String? fin) => Grupoentidad(
    categoria: 'Deportes',
    curso: 'Iniciacion',
    anio: 2026,
    iterable: 1,
    cupos: 20,
    fechaCreacion: '2026-08-04',
    fechaFinalizacion: fin,
  );

  final hoy = DateTime(2026, 11, 20, 23, 59);

  test('$capa - $tipo - finalizado - una fecha pasada lo finaliza', () {
    expect(grupo('2026-11-19').finalizado(hoy), isTrue);
  });

  test('$capa - $tipo - finalizado - el mismo dia sigue activo', () {
    expect(grupo('2026-11-20').finalizado(hoy), isFalse);
  });

  test('$capa - $tipo - finalizado - una fecha futura sigue activo', () {
    expect(grupo('2026-12-01').finalizado(hoy), isFalse);
  });

  test('$capa - $tipo - finalizado - sin fecha o ilegible sigue activo', () {
    expect(grupo(null).finalizado(hoy), isFalse);
    expect(grupo('pronto').finalizado(hoy), isFalse);
  });
}
