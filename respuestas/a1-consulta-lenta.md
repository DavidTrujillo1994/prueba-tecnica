1. Identifique al menos cuatro aspectos que pueden afectar el rendimiento o la mantenibilidad de la consulta. No se limite a decir "falta un índice".

Identificación del problema:

1- Las funciones sobre columnas. En el WHERE se usa TRUNC(s.fecha_creacion), UPPER(s.estado) y NVL(c.activo, 'N'). Al aplicar una función a la columna, Oracle tiene que calcularla en cada fila antes de comparar, y por eso no puede usar los índices normales IDX_SOLICITUD_FECHA e IDX_SOLICITUD_ESTADO. Lo que impide el índice es el TRUNC sobre la columna; el TRUNC(SYSDATE - 30) de la derecha se calcula una sola vez y no es el problema.

2- La subconsulta correlacionada en el SELECT. El MAX(g.fecha_gestion) se evalúa una vez por cada solicitud que devuelve la consulta. Si salen 100.000 filas, son 100.000 búsquedas en gestion. Cada una usa IDX_GESTION_SOLICITUD, pero después tiene que ir a la tabla a leer fecha_gestion, porque el índice solo tiene id_solicitud.

3- El NVL(c.activo, 'N') = 'S' es innecesario: si activo es nulo, la comparación con 'S' tampoco se cumple, así que da el mismo resultado que activo = 'S'. Además de bloquear el índice, hace el código más difícil de leer. El IN (subconsulta) también es menos claro que un JOIN explícito.

4- <> 'CERRADA' es un filtro poco selectivo. Un "distinto de" casi nunca aprovecha un índice. No sé cuántas solicitudes están cerradas, así que esto es una hipótesis que habría que verificar con la distribución real de estado.

5- No hay límite de filas. La consulta ordena y trae todo el resultado (ORDER BY sobre una cantidad que puede ser de cientos de miles de filas), cuando una pantalla de analistas normalmente muestra una página.

6- Estadísticas. Si las estadísticas de las tablas están desactualizadas, el optimizador puede estimar mal y elegir un plan distinto según el momento. Podría explicar que la lentitud aparezca solo en algunas franjótesis que hay que comprobar.

2. Proponga una versión mejorada de la consulta y explique porte o más fácil de diagnosticar.

Script: sql/a1_consulta_mejorada.sql

Cambios que hice:

- TRUNC(s.fecha_creacion) >= TRUNC(SYSDATE - 30) pasó a s.fech - 30. Da el mismo resultado: pasamos de decir "el día de lafecha es mayor o igual a la medianoche de hace 30 días" a "la fecha es mayor o igual a esa medianoche". La columna queda sin función y permite usarIDX_SOLICITUD_FECHA.
- Eliminé el UPPER sobre estado. Esto solo es seguro si el estado siempre está guardado en mayúsculas, así que antes de aplicarlo lo verificaría con SELECT estado, COUNT(*) FROM solicitud GROUP BY estado. Si hmo 'Cerrada', usaría un índice basado en función o limpiaría los datos.
- Pasé de NVL(activo, 'N') = 'S' a activo = 'S'. El resultado los nulos igual quedan fuera.
- Cambié el IN con subconsulta por un JOIN con cliente. documento es la llave primaria de cliente, así que no duplica filas.
- Reemplacé la subconsulta que se ejecutaba por fila por un LEs últimas gestiones en bloque. El LEFT JOIN conserva lassolicitudes sin gestiones, igual que la original.

Lo que hay que tener en cuenta: el GROUP BY recorre todas las gestiones y puede ser costoso si la pantalla devuelve pocas solicitudes. Por eso no asumiría
que es mejor sin comparar los planes de las dos versiones. Si e añadir FETCH FIRST n ROWS ONLY al final.

3. Indique qué evidencias revisaría antes de aplicar el cambio plan de ejecución, volumen, cardinalidad, estadísticas, tiempos o lecturas.

(Script: sql/a1_evidencias.sql)                                                                                                                           
- Plan de ejecución de la consulta original, con EXPLAIN PLAN o DBMS_XPLAN.DISPLAY_CURSOR. Busco TABLE ACCESS FULL sobre SOLICITUD o GESTION.             Cardinalidad: comparo las filas que Oracle estima contra lasde indicaría estadísticas malas.
- Estadísticas de las tablas: la fecha de last_analyzed y el número de filas que Oracle cree que hay (user_tables). Si son muy antiguas, recolectaría     estadísticas antes de tocar la consulta.
- Distribución de estado y de activo, para saber cuántas filas cumplen cada filtro y si los valores están siempre en mayúsculas.                          Cuántas solicitudes devuelve de verdad la pantalla: 1.000 o falta paginar y qué tan costosa es la subconsulta por fila.
- Tiempos y lecturas lógicas y físicas antes y después, en un entorno de pruebas con volumen similar al de producción.                                    Comparar con MINUS, en las dos direcciones, que ambas versio mismo.
- Franjas horarias: revisar qué más corre a esa hora (cargas batch, otros procesos) por si la lentitud no viene de la consulta.                           
4. Si considera necesario un índice nuevo, propóngalo y explique el costo o riesgo operativo que introduciría.                                            
(Script: sql/a1_indice.sql)                                                                                                                               
Sí, el siguiente:                                                                                                                                         
CREATE INDEX idx_gestion_sol_fecha                                                                                                                          ON gestion (id_solicitud, fecha_gestion);
- Cada INSERT en gestion ahora actualiza también este índice, así que la escritura se vuelve algo más lenta.                                              Ocupa más espacio: un índice sobre 14 millones de filas ocup
- Para crearlo en producción hay que hacerlo en horario de baja carga y, si la edición lo permite, con ONLINE para no bloquear las escrituras.            Puede cambiar el plan de otras consultas que usen gestion.
- Como reversa, si el nuevo índice genera algún efecto negativo, basta con ejecutar DROP INDEX idx_gestion_sol_fecha, que elimina solo el índice y no los datos. No elimino el índice anterior en el mismo cambio: si la quedaría sin índice sobre id_solicitud y el rendimientoempeoraría.
- Si el plan muestra que el cuello de botella es otro (por ejedísticas), este índice no se justifica.