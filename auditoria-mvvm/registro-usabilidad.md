# Registro de usabilidad (heurísticas de NN/g)

Revisión de la app móvil con las 10 heurísticas de usabilidad de Nielsen Norman Group, una a la vez. Este registro va aparte de [registro-bugs.md](registro-bugs.md): allí cada fila es un fallo funcional, aquí es una falla de usabilidad.

## Cómo se lee

- **ID:** `UX-H<heurística>-<nn>`. Por ejemplo, `UX-H1-03` es el hallazgo 3 de la heurística 1.
- **Estados:** **hipótesis** → **confirmado** (prueba de widget en rojo u observación en el emulador) → **corregido**, o bien **descartado**. Es la misma regla que en el registro de bugs: lo que sale solo de leer el código queda como hipótesis hasta que una prueba o el emulador lo muestre.
- **Severidad (NN/g, 0 a 4):** 4 = catástrofe, hay que corregirla antes de entregar; 3 = mayor, prioridad alta; 2 = menor, prioridad baja; 1 = cosmética; 0 = no es un problema de usabilidad. Es una estimación por lo leído y sube o baja al confirmarse.
- **Origen de la evidencia:** Código (solo lectura), Prueba (prueba de widget en rojo) o Emulador (lo observó el usuario).
- **Cómo confirmarlo:** para las esperas basta una prueba de widget con `AdaptadorHttpFalso.retener(...)`. Se retiene la respuesta, se toca el botón y se espera ver un indicador de progreso (`CircularProgressIndicator` o un texto como «Enviando…»). Mientras falte el indicador, la prueba sale en rojo.

## Heurística 1: visibilidad del estado del sistema (revisión del 2026-11-20)

> El sistema debe mantener informado al usuario de lo que está pasando, con una respuesta apropiada y en un tiempo razonable.

Todos los hallazgos salen de leer el código del 2026-11-20 (rama `refactor/inyeccion-dependencias`, con cambios sin commit). Todavía no hay pruebas ni observaciones en el emulador.

### Hallazgos

#### Envíos al backend sin indicador de progreso

En los cuatro casos el botón se deshabilita mientras la petición está en camino, así que el doble envío ya está evitado. Lo que falta es mostrar al usuario que la acción está en curso: no hay spinner ni cambia el texto, y el botón deshabilitado se ve igual que uno no disponible.

| ID | Escenario | Dónde | Qué pasa hoy | Sev. | Origen | Estado |
|---|---|---|---|---|---|---|
| UX-H1-01 | Enviar el reporte de asistencia | [claseView.dart:345](../lib/presentation/view/views/clase/claseView.dart) | `puedeRegistrar` apaga el botón durante el envío sin decir «Enviando…». Es la tarea principal del instructor y suele hacerse en la cancha con datos móviles | 3 | Código | hipótesis |
| UX-H1-02 | Iniciar sesión (Google y luego `POST /auth/token`) | [menuLateral.dart:380](../lib/presentation/view/widgets/menuLateral.dart) | No hay ningún indicador entre elegir el método y el SnackBar final. El intercambio de token tiene un timeout de 1 minuto, el menú lateral sigue abierto y la opción se puede volver a tocar | 3 | Código | hipótesis |
| UX-H1-03 | «Tomar asistencia» desde la pantalla del grupo | [widgetListaClases.dart:160](../lib/presentation/view/views/grupo/widgetListaClases.dart) | Hace dos peticiones (POST de la clase y recarga de `/clasesGrupo`). Mientras tanto `tomandoAsistencia` deja el botón deshabilitado, igual que cuando está fuera de la ventana; en ese momento no hay motivo que lo explique | 3 | Código | hipótesis |
| UX-H1-04 | Matricular, quitar matrícula o salir de la lista de espera | [GruposInscripcion.dart:183](../lib/presentation/view/views/grupos/GruposInscripcion.dart) | `procesando(grupo)` deshabilita el botón sin indicador | 2 | Código | hipótesis |

#### Esperas o resultados que no se ven

| ID | Escenario | Dónde | Qué pasa hoy | Sev. | Origen | Estado |
|---|---|---|---|---|---|---|
| UX-H1-05 | Eliminar una categoría | [CategoriasView.dart:300](../lib/presentation/view/views/categorias/CategoriasView.dart) | Al confirmar, el diálogo se cierra y no se ve nada hasta que llega el SnackBar de éxito o el diálogo de error | 2 | Código | hipótesis |
| UX-H1-06 | Agregar o eliminar un horario | [widgetListaHorarios.dart](../lib/presentation/view/views/grupo/widgetListaHorarios.dart) (`_agregar`, `_eliminar`) | No hay indicador mientras se guarda, y un éxito no muestra mensaje: solo se nota porque la lista se recarga. Solo los fallos tienen diálogo | 2 | Código | hipótesis |
| UX-H1-07 | Exportar las estadísticas a Excel | [estadisticasGeneralesView.dart:228](../lib/presentation/view/views/estadisticas/estadisticasGeneralesView.dart) | No hay progreso mientras se genera el archivo y el botón sigue activo. Al final sí aparece un SnackBar con el resultado | 2 | Código | hipótesis |
| UX-H1-08 | GUARDAR en el formulario de clase | [claseFormulario.dart:216](../lib/presentation/view/views/clase/claseFormulario.dart) | El botón no se deshabilita ni muestra carga, a diferencia de los formularios de categoría, curso y grupo (`_guardando`). Permite enviar dos veces. Hoy la ruta no se puede abrir (AS-13); la severidad sube si el cliente la reactiva | 1 | Código | hipótesis |

#### Estado comunicado de forma engañosa

| ID | Escenario | Dónde | Qué pasa hoy | Sev. | Origen | Estado |
|---|---|---|---|---|---|---|
| UX-H1-09 | Listas vacías pintadas como error | [CategoriasView.dart:192](../lib/presentation/view/views/categorias/CategoriasView.dart), [cursos.dart:156](../lib/presentation/view/views/curso/cursos.dart), [widgetListaGrupos.dart:65](../lib/presentation/view/views/curso/widgetListaGrupos.dart), [GruposAsignados.dart:67](../lib/presentation/view/views/grupos/GruposAsignados.dart), [GruposInscripcion.dart:75](../lib/presentation/view/views/grupos/GruposInscripcion.dart) | Una lista vacía se muestra con `ColorTheme.error`, como si algo hubiera fallado. «No hay datos aun, lista vacia» además no dice qué falta ni qué puede hacer el usuario | 2 | Código | hipótesis |
| UX-H1-10 | Botones que no responden | [AlumnosView.dart:60](../lib/presentation/view/views/alumnos/AlumnosView.dart) (AGREGAR ALUMNO), [AlumnoView.dart:218](../lib/presentation/view/views/alumnos/AlumnoView.dart) (ELIMINAR ALUMNO), [InstructorView.dart:206](../lib/presentation/view/views/instructores/InstructorView.dart) (DESHABILITAR y ELIMINAR INSTRUCTOR), [curso.dart:80](../lib/presentation/view/views/curso/curso.dart) (DESHABILITAR y ELIMINAR CURSO) | `onPressed: () {}`: el botón se ve activo, anima el toque y no pasa nada. Es el mismo patrón que la observación O-01 del registro de bugs (tocar un curso sin ser coordinador). Opciones: ocultarlos o mostrarlos deshabilitados con «Próximamente» | 2 | Código | hipótesis |
| UX-H1-11 | Diálogo «Control inscripciones» | [inscripcionesParticulares.dart:183](../lib/presentation/view/views/inscripciones/inscripcionesParticulares.dart) | `ocupado` y el estado del grupo se leen una sola vez, al abrir el diálogo; si cambian mientras está abierto, el diálogo no lo refleja. Falta comprobar en el emulador si en la práctica se puede ver un estado viejo | 1 | Código | hipótesis |

### Lo que ya cumple la heurística

Sirve de referencia para corregir los hallazgos con el mismo estilo:

- **Pantalla del grupo:** cada sección (horario, clases, alumnos) carga con su propio spinner y su propio error (`EstadoSeccion`), y el instructor muestra «Cargando…».
- **Motivo sin asistencia:** cuando no se puede tomar asistencia, el motivo se muestra bajo el botón (`_MotivoSinAsistencia`).
- **Toma de asistencia:** resumen de presentes y ausentes, y advertencia de cambios sin guardar al salir (AS-10).
- **Inscripción del alumno:** muestra «En lista de espera», y si falla la consulta muestra «No se pudo consultar tu inscripción» con «Reintentar».
- **Formulario de categoría:** spinner dentro del botón mientras guarda (`_guardando`). Es el patrón a reutilizar en UX-H1-01 a 04 y 08.
- **Menú lateral:** muestra el nombre y el rol de la sesión, o «Invitado».

### Propuesta de corrección (sin hacer)

Un botón con estado de carga reutilizable en `widgets/`: recibe `cargando` y muestra spinner y un texto como «Enviando…». Cubre UX-H1-01 a 04 y 08 con un solo cambio de patrón. Antes de corregir, cada hallazgo debería tener su prueba de widget en rojo (ver «Cómo confirmarlo»).
