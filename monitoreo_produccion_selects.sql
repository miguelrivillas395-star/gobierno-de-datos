-- =========================================================
-- CONSULTAS DE VALIDACIÓN (SELECTS)
-- =========================================================
SET search_path TO monitoreo_produccion, public;

-- General
SELECT * FROM fabrica;
SELECT * FROM linea;
SELECT * FROM microcontrolador;
SELECT * FROM sensor;
SELECT * FROM producto;
SELECT * FROM filtro;
SELECT * FROM clasificacion_ppm;
SELECT * FROM turno;
SELECT * FROM empleado;
SELECT * FROM empleado_turno;
SELECT * FROM lecturas;
SELECT * FROM alarma;
SELECT * FROM configuracion_fabrica;

-- Joins útiles
SELECT l.id_lectura, l.fecha, l.hora, l.ppm_benceno, c.nivel, c.estado_alarma
FROM lecturas l
LEFT JOIN clasificacion_ppm c ON l.id_clasificacion = c.id_clasificacion;

SELECT a.id_alarma, a.accion, c.nivel, c.estado_alarma, l.ppm_benceno
FROM alarma a
JOIN lecturas l ON a.id_lectura = l.id_lectura
JOIN clasificacion_ppm c ON c.id_clasificacion = a.id_clasificacion;

-- Resumen por línea
SELECT id_fabrica, id_linea, ROUND(AVG(ppm_benceno)::numeric,2) AS ppm_promedio
FROM lecturas
GROUP BY id_fabrica, id_linea
ORDER BY id_fabrica, id_linea;