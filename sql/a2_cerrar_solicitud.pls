-- A2. Procedimiento cerrar_solicitud corregido.
--
-- Qué corrige del original:
--   * El COMMIT estaba entre el UPDATE y el INSERT. Ahora se confirma una
--     sola vez al final, cuando ya se hicieron los dos.
--   * El WHEN OTHERS THEN NULL escondía cualquier error. Ahora se hace
--     ROLLBACK y el error le llega a quien llamó el procedimiento.
--   * El estado anterior de la auditoría ya no es siempre 'PENDIENTE': se
--     lee el estado real de la solicitud.
--   * Se valida que la solicitud exista y que no esté ya procesada.
--   * FOR UPDATE bloquea la fila, así dos ejecuciones al mismo tiempo no
--     duplican la auditoría.
--
-- Dejé el COMMIT dentro del procedimiento para no cambiar lo que la
-- aplicación espera de él; solo lo moví al lugar correcto.

CREATE OR REPLACE PROCEDURE cerrar_solicitud(p_id IN NUMBER) AS
    v_estado    solicitud.estado%TYPE;
    v_aprobadas NUMBER;
BEGIN
    -- Leo el estado real y bloqueo la fila.
    -- Si p_id no existe, Oracle lanza NO_DATA_FOUND.
    SELECT estado
      INTO v_estado
      FROM solicitud
     WHERE id_solicitud = p_id
       FOR UPDATE;

    -- Si ya está procesada no hago nada, así repetir la llamada es seguro.
    IF v_estado = 'PROCESADA' THEN
        ROLLBACK;  -- solo para soltar el bloqueo
        RETURN;
    END IF;

    -- Tiene que existir al menos una gestión aprobada.
    SELECT COUNT(*)
      INTO v_aprobadas
      FROM gestion
     WHERE id_solicitud = p_id
       AND resultado = 'APROBADA';

    IF v_aprobadas = 0 THEN
        RAISE_APPLICATION_ERROR(-20002,
            'Solicitud ' || p_id || ' sin gestiones APROBADA');
    END IF;

    -- Actualizo y audito; recién ahí confirmo las dos cosas juntas.
    UPDATE solicitud
       SET estado = 'PROCESADA',
           fecha_actualizacion = SYSDATE
     WHERE id_solicitud = p_id;

    INSERT INTO auditoria_solicitud(
        id, id_solicitud, estado_anterior, estado_nuevo, fecha, detalle
    ) VALUES (
        seq_auditoria.NEXTVAL, p_id, v_estado, 'PROCESADA', SYSDATE, 'Cierre automático'
    );

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'Solicitud ' || p_id || ' no existe');
    WHEN OTHERS THEN
        ROLLBACK;  -- deshace el UPDATE y el INSERT juntos
        IF SQLCODE BETWEEN -20999 AND -20000 THEN
            RAISE;  -- los errores propios (-20002) ya traen el id
        END IF;
        RAISE_APPLICATION_ERROR(-20099,
            'Error cerrando solicitud id=' || p_id || ' | ' || SQLERRM ||
            ' | ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END cerrar_solicitud;
/