-- A1. Consulta de la pantalla de pendientes, versión mejorada.
--
-- Cambios respecto a la original:
--   * La columna fecha_creacion queda sin función (antes llevaba TRUNC).
--   * Se quita UPPER sobre estado. Solo es válido si estado siempre está en
--     mayúsculas; hay que comprobarlo antes (ver a1_evidencias.sql).
--   * activo = 'S' en lugar de NVL(activo, 'N') = 'S': mismo resultado.
--   * JOIN con cliente en lugar de IN (subconsulta).
--   * La última gestión se calcula en bloque con un LEFT JOIN, no una vez
--     por fila. El LEFT JOIN deja pasar solicitudes sin gestiones.

SELECT s.id_solicitud,
       s.documento,
       s.estado,
       s.fecha_creacion,
       g.ultima_gestion
  FROM solicitud s
  JOIN cliente c
    ON c.documento = s.documento
   AND c.activo = 'S'
  LEFT JOIN (SELECT id_solicitud,
                    MAX(fecha_gestion) AS ultima_gestion
               FROM gestion
              GROUP BY id_solicitud) g
    ON g.id_solicitud = s.id_solicitud
 WHERE s.fecha_creacion >= TRUNC(SYSDATE) - 30
   AND s.estado <> 'CERRADA'
 ORDER BY s.fecha_creacion DESC;

-- Si la pantalla solo muestra una página, se puede limitar agregando al final:
-- FETCH FIRST 100 ROWS ONLY;

