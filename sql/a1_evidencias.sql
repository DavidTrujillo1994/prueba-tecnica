-- 1. Plan de ejecución de la consulta original (no ejecuta la consulta).
EXPLAIN PLAN FOR
SELECT s.id_solicitud, s.documento, s.estado, s.fecha_creacion,
       (SELECT MAX(g.fecha_gestion)
          FROM gestion g
         WHERE g.id_solicitud = s.id_solicitud) AS ultima_gestion
  FROM solicitud s
 WHERE TRUNC(s.fecha_creacion) >= TRUNC(SYSDATE - 30)
   AND UPPER(s.estado) <> 'CERRADA'
   AND s.documento IN (SELECT c.documento FROM cliente c
                        WHERE NVL(c.activo, 'N') = 'S');

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- Busco TABLE ACCESS FULL sobre SOLICITUD o GESTION.

-- 2. Estadísticas: cuándo se calcularon por última vez.
SELECT table_name, num_rows, last_analyzed
  FROM user_tables
 WHERE table_name IN ('SOLICITUD', 'GESTION', 'CLIENTE');

-- 3. Distribución de estado y de activo.
SELECT estado, COUNT(*) FROM solicitud GROUP BY estado;
SELECT activo, COUNT(*) FROM cliente GROUP BY activo;

-- 4. Cuántas filas devuelve de verdad la pantalla.
SELECT COUNT(*)
  FROM solicitud s
 WHERE TRUNC(s.fecha_creacion) >= TRUNC(SYSDATE - 30)
   AND UPPER(s.estado) <> 'CERRADA'
   AND s.documento IN (SELECT c.documento FROM cliente c
                        WHERE NVL(c.activo, 'N') = 'S');

-- 5. Misma salida entre la original y la mejorada: las dos diferencias
--    deben dar 0 filas.
SELECT COUNT(*) FROM (
  (SELECT s.id_solicitud, s.documento, s.estado, s.fecha_creacion,
          (SELECT MAX(g.fecha_gestion) FROM gestion g
            WHERE g.id_solicitud = s.id_solicitud) AS ultima_gestion
     FROM solicitud s
    WHERE TRUNC(s.fecha_creacion) >= TRUNC(SYSDATE - 30)
      AND UPPER(s.estado) <> 'CERRADA'
      AND s.documento IN (SELECT c.documento FROM cliente c
                           WHERE NVL(c.activo, 'N') = 'S'))
  MINUS
  (SELECT s.id_solicitud, s.documento, s.estado, s.fecha_creacion, g.ultima_gestion
     FROM solicitud s
     JOIN cliente c ON c.documento = s.documento AND c.activo = 'S'
     LEFT JOIN (SELECT id_solicitud, MAX(fecha_gestion) AS ultima_gestion
                  FROM gestion GROUP BY id_solicitud) g
       ON g.id_solicitud = s.id_solicitud
    WHERE s.fecha_creacion >= TRUNC(SYSDATE) - 30
      AND s.estado <> 'CERRADA'));
-- Para la otra dirección, se intercambian las dos consultas.