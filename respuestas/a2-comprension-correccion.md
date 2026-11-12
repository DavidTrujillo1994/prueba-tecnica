5. Explique paso a paso qué hace el procedimiento y señale los riesgos o defectos que encuentre.

Lo que hace el procedimiento original, paso a paso:

- Recibe el id de una solicitud.
- Cuenta cuántas gestiones de esa solicitud tienen resultado APROBADA.
- Si hay al menos una, pone la solicitud en PROCESADA y actualiza la fecha.
- Hace COMMIT: el cambio queda definitivo.
- Inserta una fila de auditoría diciendo que la solicitud pasó de PENDIENTE a PROCESADA.
- Si algo falla en cualquiera de esos pasos, el WHEN OTHERS THEN NULL lo ignora y no avisa a nadie.

Riesgos o defectos:

- El principal es el COMMIT entre el UPDATE y el INSERT. El estado se guarda de forma definitiva antes de insertar la auditoría. Si el INSERT falla (por ejemplo una secuencia inexistente, una columna muy corta, una restricción o falta de espacio), el estado ya no se puede deshacer y queda un cambio sin su registro. Es exactamente el síntoma que reporta soporte.
- El WHEN OTHERS THEN NULL esconde cualquier error sin dejar rastro. Quien llama cree que todo salió bien y soporte no recibe ningún mensaje. Junto con el defecto 1, el fallo del INSERT nunca se nota.
- El estado anterior de la auditoría está fijo en 'PENDIENTE'. No se lee de la solicitud, así que si estaba en otro estado, la auditoría dice algo que no es cierto.
- No valida la existencia ni el estado actual. Si p_id no existe, el conteo da 0 y no pasa nada, y quien llama no sabe si se hizo o no. Si la solicitud ya está PROCESADA, la actualiza otra vez, cambia fecha_actualizacion y duplica la auditoría con un "anterior" falso.
- No bloquea la fila. Entre contar las gestiones y actualizar, otra sesión puede cambiar los datos, y dos ejecuciones al mismo tiempo pueden duplicar la auditoría.
- Dos detalles menores: el COUNT(*) recorre todas las gestiones aprobadas cuando solo importa si existe una, y el COMMIT dentro del procedimiento le quita a quien llama el control de su transacción. En mi versión dejé los dos como están (ver punto 6).


6. Proponga una versión corregida que mantenga consistentes la actualización y la auditoría. No es obligatorio usar una única solución si justifica otra alternativa segura.

Script: sql/a2_cerrar_solicitud.pls

Qué corregí y cómo:

- El COMMIT ahora va una sola vez al final, después del UPDATE y del INSERT. Si el INSERT falla, el ROLLBACK deshace también el UPDATE, así que la actualización y la auditoría se guardan juntas o no se guardan.
- El WHEN OTHERS ahora hace ROLLBACK y relanza el error, en lugar de ignorarlo. Los errores propios (-20001 y -20002) ya traen el id; para los inesperados armé el error -20099 con el id, el mensaje de Oracle y la línea donde ocurrió.
- El estado anterior se lee de la solicitud y ese es el que se
- Con SELECT ... FOR UPDATE bloqueo la fila: si otra ejecución llega al mismo tiempo, espera, y cuando entra ya ve PROCESADA y sale.
- Valida que la solicitud exista, que no esté procesada y que tenga una gestión aprobada.

7. Explique cómo manejaría el caso en que p_id no exista, la sno exista ninguna gestión APROBADA.

Si p_id no existe, el procedimiento lanza el error -20001 con el id, porque quien lo llama debe saber que no se cerró nada. Si la solicitud ya está PROCESADA, sale sin hacer cambios y sin error: así no duplica la auditoría ni modifica la fecha, y repetir la llamada, por ejemplo por un reintento, es seguro. Si no existe ninguna gestión APROBADA, lanza el error -20002 con el id y deja el estado intacto, para no cerrar una solicitud sin sustento. Elegí que el caso "ya procesada" sea silencioso para no generar errores en reintentos legítimos; si la lógica del negocio prefiere que avise, bastaría cambiar el RETURN por un error. Queda pendiente confirmar con el negocio que el procedimiento acepte cerrar desde cualquier estado distinto de PROCESADA.

8. Indique cómo validaría que la corrección no deja transacciones parciales y que los errores siguen siendo diagnosticables por soporte.

Scripts: sql/a2_datos_prueba.sql y sql/a2_pruebas.sql

Para validar que no quedan transacciones parciales, forzaría el fallo de la auditoría agregando temporalmente una restricción CHECK que haga fallar el INSERT. Con el procedimiento original, la solicitud quedaba en PROCESADA sin auditoría y sin ningún error; con el corregido, vuelve a PENDIENTE y el error llega a quien llamó, así que la actualización y la auditoría se guardan juntas o no se guardan. También probé los casos de borde (inexistente, ya procesada y sin gestión aprobada), comprobando que el estado nditorías de más. Para la concurrencia, la prueba se hace condos sesiones sobre la misma solicitud: la segunda debe esperar el bloqueo y al final queda una sola auditoría (esta prueba está descrita en el script para hacerla a mano). Para que soporte pueda diagnosticar, los errores propios incluyen el id de la solicitud y el error inesperado (-20099) agrega el mensaje de Oracle y la línea donde ocurrió. Como control periódico, usaría una consulta que lista las solicitudes PROCESADA sin auditoría de cierre; sus resultados son solo candidatas a revisar, porque puede haber se que existiera la auditoría. Queda sin probar el efecto delROLLBACK sobre cambios pendientes de quien llama, que documento como riesgo aceptado.
