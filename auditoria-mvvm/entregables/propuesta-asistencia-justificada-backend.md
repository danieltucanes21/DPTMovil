# Propuesta: inasistencia justificada en la toma de asistencia

**Para:** equipo del backend · **Fecha:** 2026-11-19 · **Estado:** propuesta, sin acordar

El cliente pidió que la toma de asistencia tenga tres estados por alumno: **Presente**, **Ausente** y **Justificada**. Así aparece en el prototipo del rediseño. La app ya muestra los tres, pero el botón «Justificada» está deshabilitado porque hoy el backend solo guarda `PRESENTE` y `AUSENTE`.

## Qué hay hoy (leído en el código del backend, 2026-11-19)

- `asi_estado` guarda `PRESENTE` o `AUSENTE` (`AsistenciaGateway.upsertEstado`).
- `PUT /clase/{codigo}/asistencia` recibe `{asistencias: [{idPerfil, estaAtendido}], confirmaTodosAusentes}`. Marca `PRESENTE` a quien llega con `estaAtendido: true` y `AUSENTE` al resto del grupo.
- `GET /atencionesporclase?claseid=` devuelve `[{idClase, idPerfil, estaAtendido}]`, con `estaAtendido` verdadero solo para `PRESENTE`.
- Las faltas acumuladas cuentan las filas `AUSENTE` (`IAsistenciaRepositorio`).

Si la app enviara una justificada como `estaAtendido: false`, contaría como falta. Por eso no se envía.

## Propuesta

1. **Nuevo estado** `JUSTIFICADA` en `asi_estado`.
2. **`PUT /clase/{codigo}/asistencia`:** cada ítem acepta un campo opcional `estado` (`PRESENTE`, `AUSENTE` o `JUSTIFICADA`). Si llega, manda sobre `estaAtendido`; si no llega, todo sigue como hoy. Así la app actual y la nueva conviven.

   ```json
   {
     "asistencias": [
       { "idPerfil": "1061001", "estado": "PRESENTE" },
       { "idPerfil": "1061002", "estado": "JUSTIFICADA" },
       { "idPerfil": "1061003", "estado": "AUSENTE" }
     ],
     "confirmaTodosAusentes": false
   }
   ```

3. **`GET /atencionesporclase`:** cada fila agrega `estado`, sin quitar `estaAtendido` (que sigue siendo verdadero solo para `PRESENTE`).
4. **Respuesta del `PUT`:** agrega `justificadas` junto a `presentes` y `ausentes`.
5. **Faltas acumuladas:** una `JUSTIFICADA` **no** cuenta como falta.

## Preguntas para el backend y el cliente

1. ¿La justificada necesita un motivo o un soporte (texto, archivo)? El prototipo no muestra ninguno.
2. ¿`confirmaTodosAusentes` debe exigirse también cuando todos están justificados?
3. ¿Las estadísticas de asistencia deben mostrar las justificadas aparte?

## Qué cambia en la app cuando esté

- `EstadoAsistencia.justificadaDisponible` pasa a `true` (`lib/domain/entities/estadoAsistencia.dart`).
- `Atencionmodelo` lee y envía `estado`, y `AtencionMapper` deja de reducirlo a `estaAtendido`.
- Los contratos de `test/contratos/atenciones/` agregan el campo.
