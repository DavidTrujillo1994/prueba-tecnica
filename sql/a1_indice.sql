-- A1. Índice propuesto para resolver MAX(fecha_gestion) sin visitar la tabla.
-- Con id_solicitud primero, también cubre las búsquedas que hoy hace
-- IDX_GESTION_SOLICITUD, que quedaría redundante.
--
-- Crearlo en horario de baja carga. ONLINE evita bloquear escrituras, si la
-- edición de Oracle lo permite.

CREATE INDEX idx_gestion_sol_fecha
    ON gestion (id_solicitud, fecha_gestion)
    ONLINE;

-- Reversa: solo elimina el índice, no los datos.
-- DROP INDEX idx_gestion_sol_fecha;

-- No borro IDX_GESTION_SOLICITUD en este mismo cambio: si hubiera que revertir,
-- la tabla se quedaría sin índice por id_solicitud.
