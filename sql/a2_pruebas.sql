-- A2. Pruebas del procedimiento cerrar_solicitud.
-- Se ejecuta después de a2_datos_prueba.sql y de crear el procedimiento.

-- Ayuda: llama al procedimiento y muestra cómo quedó la solicitud.
CREATE OR REPLACE PROCEDURE probar(p_desc VARCHAR2, p_id NUMBER) AS
    v_estado VARCHAR2(20);
    v_aud    NUMBER;
    v_msg    VARCHAR2(300) := 'sin error';
BEGIN
    BEGIN
        cerrar_solicitud(p_id);
    EXCEPTION
        WHEN OTHERS THEN v_msg := SUBSTR(SQLERRM, 1, 150);
    END;
    BEGIN
        SELECT estado INTO v_estado FROM solicitud WHERE id_solicitud = p_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN v_estado := '(no existe)';
    END;
    SELECT COUNT(*) INTO v_aud FROM auditoria_solicitud WHERE id_solicitud = p_id;
    DBMS_OUTPUT.PUT_LINE(RPAD(p_desc, 28) || 'estado=' || RPAD(v_estado, 12) ||
                         ' auditorias=' || v_aud || ' | ' || v_msg);
END;
/

SET SERVEROUTPUT ON

-- 1. Caso normal: debe quedar PROCESADA con 1 auditoría.
EXEC probar('1. normal (id 1)', 1)
-- 2. Repetir la llamada: no debe duplicar la auditoría.
EXEC probar('2. repetir (id 1)', 1)
-- 3. Sin gestión aprobada: error -20002 y el estado no cambia.
EXEC probar('3. sin aprobadas (id 2)', 2)
-- 4. Ya procesada: sin error y sin auditoría nueva.
EXEC probar('4. ya procesada (id 3)', 3)
-- 5. Inexistente: error -20001.
EXEC probar('5. inexistente (id 99)', 99)

-- 6. Fallo forzado de la auditoría. Agrego una restricción que hace fallar
--    el INSERT. La solicitud 4 debe quedar en PENDIENTE y el error debe llegar.
--    NOVALIDATE para que no revise las filas que ya existen (las de la prueba 1).
ALTER TABLE auditoria_solicitud
  ADD CONSTRAINT chk_prueba CHECK (detalle <> 'Cierre automático') ENABLE NOVALIDATE;
EXEC probar('6. fallo forzado (id 4)', 4)
ALTER TABLE auditoria_solicitud DROP CONSTRAINT chk_prueba;

-- 7. Concurrencia (a mano, con dos sesiones sobre la misma solicitud):
--    Sesión 1:  SELECT * FROM solicitud WHERE id_solicitud = 4 FOR UPDATE;
--    Sesión 2:  EXEC cerrar_solicitud(4);   -- se queda esperando
--    Sesión 1:  EXEC cerrar_solicitud(4);  y luego COMMIT;
--    La sesión 2 termina al liberarse el bloqueo, ve PROCESADA y sale: debe
--    quedar una sola auditoría para la solicitud 4.

-- Control: solicitudes PROCESADA sin auditoría de cierre (solo candidatas a revisar).
SELECT s.id_solicitud
  FROM solicitud s
 WHERE s.estado = 'PROCESADA'
   AND NOT EXISTS (SELECT 1 FROM auditoria_solicitud a
                    WHERE a.id_solicitud = s.id_solicitud
                      AND a.estado_nuevo = 'PROCESADA');