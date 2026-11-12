-- A2. Tablas y datos de prueba (ficticios) para probar cerrar_solicitud.
--
-- OJO: este script BORRA y vuelve a crear las tablas solicitud, gestion y
-- auditoria_solicitud. Úsalo solo en un esquema de pruebas.
--
-- Orden de ejecución:
--   1. a2_datos_prueba.sql        (este archivo)
--   2. a2_cerrar_solicitud.pls    (crea el procedimiento)
--   3. a2_pruebas.sql             (lo prueba)
-- Para repetir las pruebas hay que volver a ejecutar este archivo primero,
-- porque las pruebas modifican los datos.

BEGIN EXECUTE IMMEDIATE 'DROP TABLE auditoria_solicitud'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE gestion'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE solicitud'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_auditoria'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE solicitud (
    id_solicitud NUMBER PRIMARY KEY, documento VARCHAR2(20), estado VARCHAR2(20),
    fecha_creacion DATE, fecha_actualizacion DATE, canal VARCHAR2(20));
CREATE TABLE gestion (
    id_gestion NUMBER PRIMARY KEY, id_solicitud NUMBER, tipo VARCHAR2(20),
    resultado VARCHAR2(20), fecha_gestion DATE, usuario VARCHAR2(20));
CREATE TABLE auditoria_solicitud (
    id NUMBER PRIMARY KEY, id_solicitud NUMBER, estado_anterior VARCHAR2(20),
    estado_nuevo VARCHAR2(20), fecha DATE, detalle VARCHAR2(100));
CREATE SEQUENCE seq_auditoria;

-- Datos de prueba:
--   1 PENDIENTE con gestión aprobada       (caso normal)
--   2 PENDIENTE solo con gestión rechazada (sin aprobadas)
--   3 PROCESADA con gestión aprobada       (ya procesada)
--   4 PENDIENTE con gestión aprobada       (para forzar el fallo de la auditoría)
INSERT INTO solicitud VALUES (1, 'D1', 'PENDIENTE', SYSDATE, NULL, 'WEB');
INSERT INTO solicitud VALUES (2, 'D2', 'PENDIENTE', SYSDATE, NULL, 'WEB');
INSERT INTO solicitud VALUES (3, 'D3', 'PROCESADA', SYSDATE, NULL, 'WEB');
INSERT INTO solicitud VALUES (4, 'D4', 'PENDIENTE', SYSDATE, NULL, 'WEB');
INSERT INTO gestion VALUES (1, 1, 'LLAMADA', 'APROBADA',  SYSDATE, 'u1');
INSERT INTO gestion VALUES (2, 2, 'LLAMADA', 'RECHAZADA', SYSDATE, 'u1');
INSERT INTO gestion VALUES (3, 3, 'LLAMADA', 'APROBADA',  SYSDATE, 'u1');
INSERT INTO gestion VALUES (4, 4, 'LLAMADA', 'APROBADA',  SYSDATE, 'u1');
COMMIT;