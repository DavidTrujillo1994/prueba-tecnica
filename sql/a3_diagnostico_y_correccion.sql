-- A3. Solicitudes en PROCESADA que no tienen ninguna gestión APROBADA
--
-- Lo ejecuto por pasos y miro el resultado de cada uno antes de seguir.
-- No se confirma nada (COMMIT) hasta el paso 6.
--
-- Supuestos que estoy tomando, y que confirmaría con el negocio:
--   1. Una solicitud PROCESADA debería tener al menos una gestión APROBADA.
--   2. Si existe una auditoría de cierre, uso su estado_anterior como el
--      estado al que hay que volver. Ojo: el procedimiento viejo siempre
--      guardaba 'PENDIENTE' ahí, así que es razonable pero no es seguro.
--   3. Si no hay auditoría no sé a qué estado devolverla, así que no la
--      toco: queda para revisión manual.
--   4. Las PROCESADA que sí tienen una gestión aprobada no entran aquí.


-- PASO 1. Diagnóstico
-- Solo miro, no modifico nada. Primero cuántas hay por grupo y después
-- el detalle de las sospechosas.

PROMPT 1a. Resumen por categoría
SELECT categoria, COUNT(*) AS cantidad
  FROM (SELECT CASE
                 WHEN EXISTS (SELECT 1 FROM gestion g
                               WHERE g.id_solicitud = s.id_solicitud
                                 AND g.resultado = 'APROBADA')
                      THEN 'OK_CON_APROBADA'
                 WHEN EXISTS (SELECT 1 FROM auditoria_solicitud a
                               WHERE a.id_solicitud = s.id_solicitud
                                 AND a.estado_nuevo = 'PROCESADA')
                      THEN 'A_CORREGIR (tiene auditoria)'
                 ELSE 'REVISION_MANUAL (sin auditoria)'
               END AS categoria
          FROM solicitud s
         WHERE s.estado = 'PROCESADA')
 GROUP BY categoria
 ORDER BY categoria;

PROMPT 1b. Detalle de las que parecen inconsistentes
SELECT s.id_solicitud, s.estado, s.fecha_actualizacion,
       (SELECT COUNT(*) FROM gestion g WHERE g.id_solicitud = s.id_solicitud) AS total_gestiones,
       (SELECT COUNT(*) FROM auditoria_solicitud a
         WHERE a.id_solicitud = s.id_solicitud AND a.estado_nuevo = 'PROCESADA') AS auditorias_cierre
  FROM solicitud s
 WHERE s.estado = 'PROCESADA'
   AND NOT EXISTS (SELECT 1 FROM gestion g
                    WHERE g.id_solicitud = s.id_solicitud
                      AND g.resultado = 'APROBADA')
 ORDER BY s.id_solicitud;


-- PASO 2. Respaldo
-- Antes de cambiar algo guardo cómo están hoy estas solicitudes. Si la tabla
-- ya existe esto falla, y está bien así: no quiero pisar un respaldo anterior.

CREATE TABLE solicitud_a3_respaldo AS
SELECT x.id_solicitud,
       x.estado_original,
       x.fecha_act_original,
       x.estado_propuesto,
       CASE WHEN x.estado_propuesto IS NOT NULL
             AND x.estado_propuesto <> 'PROCESADA'
            THEN 'CORREGIR' ELSE 'REVISION_MANUAL' END AS accion,
       SYSDATE AS fecha_respaldo
  FROM (SELECT s.id_solicitud,
               s.estado              AS estado_original,
               s.fecha_actualizacion AS fecha_act_original,
               (SELECT a.estado_anterior
                  FROM auditoria_solicitud a
                 WHERE a.id = (SELECT MAX(a2.id)
                                 FROM auditoria_solicitud a2
                                WHERE a2.id_solicitud = s.id_solicitud
                                  AND a2.estado_nuevo = 'PROCESADA')) AS estado_propuesto
          FROM solicitud s
         WHERE s.estado = 'PROCESADA'
           AND NOT EXISTS (SELECT 1 FROM gestion g
                            WHERE g.id_solicitud = s.id_solicitud
                              AND g.resultado = 'APROBADA')) x;


-- PASO 3. Revisar qué se haría
-- Todavía no se cambia nada. Es para ver, solicitud por solicitud, qué
-- voy a hacer con cada una antes de ejecutar la corrección.

PROMPT 3. Qué se haría con cada registro
SELECT accion, id_solicitud, estado_original, estado_propuesto
  FROM solicitud_a3_respaldo
 ORDER BY accion, id_solicitud;


-- PASO 4. Corrección
-- Solo toco las marcadas como CORREGIR y no hago COMMIT. Si la cantidad de
-- filas actualizadas no es la que esperaba, hago ROLLBACK y paro.

DECLARE
    v_esperadas NUMBER;
    v_filas     NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_esperadas
      FROM solicitud_a3_respaldo WHERE accion = 'CORREGIR';

    UPDATE solicitud s
       SET s.estado = (SELECT b.estado_propuesto FROM solicitud_a3_respaldo b
                        WHERE b.id_solicitud = s.id_solicitud),
           s.fecha_actualizacion = SYSDATE
     WHERE s.estado = 'PROCESADA'                 -- que siga como cuando hice el respaldo
       AND s.id_solicitud IN (SELECT id_solicitud FROM solicitud_a3_respaldo
                               WHERE accion = 'CORREGIR');
    v_filas := SQL%ROWCOUNT;

    IF v_filas <> v_esperadas THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010,
            'Filas actualizadas (' || v_filas || ') distinto de lo esperado ('
            || v_esperadas || '). Se hizo ROLLBACK.');
    END IF;

    INSERT INTO auditoria_solicitud (id, id_solicitud, estado_anterior, estado_nuevo, fecha, detalle)
    SELECT seq_auditoria.NEXTVAL, b.id_solicitud, 'PROCESADA', b.estado_propuesto, SYSDATE,
           'Correccion A3: PROCESADA sin gestion APROBADA'
      FROM solicitud_a3_respaldo b
     WHERE b.accion = 'CORREGIR';

    DBMS_OUTPUT.PUT_LINE('Corregidas (pendientes de COMMIT): ' || v_filas);
END;
/


-- PASO 5. Validación
-- Antes de confirmar compruebo tres cosas: que no quede ninguna de las
-- corregidas en PROCESADA, que cada una tenga su auditoría de corrección y
-- que las de revisión manual no se hayan movido.

PROMPT 5a. Debe dar 0: corregidas que siguen en PROCESADA
SELECT COUNT(*) AS quedan_sin_corregir
  FROM solicitud s JOIN solicitud_a3_respaldo b ON b.id_solicitud = s.id_solicitud
 WHERE b.accion = 'CORREGIR' AND s.estado = 'PROCESADA';

PROMPT 5b. Cada corregida debe tener su auditoría de corrección
SELECT b.id_solicitud, s.estado AS estado_ahora,
       (SELECT COUNT(*) FROM auditoria_solicitud a
         WHERE a.id_solicitud = b.id_solicitud
           AND a.detalle LIKE 'Correccion A3%') AS auditorias_correccion
  FROM solicitud_a3_respaldo b JOIN solicitud s ON s.id_solicitud = b.id_solicitud
 WHERE b.accion = 'CORREGIR';

PROMPT 5c. Las de revisión manual deben seguir igual
SELECT b.id_solicitud, s.estado AS estado_ahora
  FROM solicitud_a3_respaldo b JOIN solicitud s ON s.id_solicitud = b.id_solicitud
 WHERE b.accion = 'REVISION_MANUAL';


-- PASO 6. Decisión
-- Si 5a, 5b y 5c salen bien hago COMMIT. Si algo no cuadra, ROLLBACK.
-- Lo dejo comentado a propósito para decidirlo yo a mano.

-- COMMIT;
-- ROLLBACK;


-- PASO 7. Reversa solo si ya se hizo COMMIT y hay que deshacer
-- Devuelvo las solicitudes a su estado original, pero solo las que no hayan
-- vuelto a cambiar desde mi corrección. La auditoría no la borro: agrego un
-- registro nuevo que deja constancia de la reversa.

-- UPDATE solicitud s
--    SET s.estado = (SELECT b.estado_original FROM solicitud_a3_respaldo b
--                     WHERE b.id_solicitud = s.id_solicitud),
--        s.fecha_actualizacion = (SELECT b.fecha_act_original FROM solicitud_a3_respaldo b
--                                  WHERE b.id_solicitud = s.id_solicitud)
--  WHERE s.id_solicitud IN (SELECT id_solicitud FROM solicitud_a3_respaldo WHERE accion = 'CORREGIR')
--    AND s.estado = (SELECT b.estado_propuesto FROM solicitud_a3_respaldo b
--                     WHERE b.id_solicitud = s.id_solicitud);
-- INSERT INTO auditoria_solicitud (id, id_solicitud, estado_anterior, estado_nuevo, fecha, detalle)
-- SELECT seq_auditoria.NEXTVAL, b.id_solicitud, b.estado_propuesto, 'PROCESADA', SYSDATE,
--        'Reversa de Correccion A3'
--   FROM solicitud_a3_respaldo b WHERE b.accion = 'CORREGIR';
-- COMMIT;


-- PASO 8. El respaldo se queda hasta que se cierre el incidente.