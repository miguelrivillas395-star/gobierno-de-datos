-- =========================================================
-- INSERTS COMPLETOS (Convención A1 / A1M01 / A1S01)
-- =========================================================
BEGIN;
SET search_path TO monitoreo_produccion, public;

-- Catálogos base
INSERT INTO turno (hora_ini, hora_fin) VALUES
  ('08:00','16:00'), ('16:00','24:00'), ('00:00','08:00');

INSERT INTO clasificacion_ppm (rango_min, rango_max, nivel, estado_alarma) VALUES
  (0.00, 0.50, 'Leve', 'Normal'),
  (0.50, 1.00, 'Permitida', 'Normal'),
  (1.00,10.00, 'Moderada', 'Precaución'),
  (10.00,50.00, 'Peligrosa', 'Crítica'),
  (50.00,500.00, 'Altamente peligrosa', 'Emergencia'),
  (500.00,99999.99,'Letal', 'Emergencia');

-- Fábricas y líneas
INSERT INTO fabrica (id_fabrica, nombre, ubicacion) VALUES
  ('A','Planta Principal','Medellín'),
  ('B','Planta Secundaria','Cali');

INSERT INTO linea (id_linea, id_fabrica, nombre) VALUES
  ('A1','A','Línea A1'), ('A2','A','Línea A2'), ('A3','A','Línea A3'), ('A4','A','Línea A4'),
  ('B1','B','Línea B1'), ('B2','B','Línea B2'), ('B3','B','Línea B3'), ('B4','B','Línea B4');

-- Productos y filtros
INSERT INTO producto (id_producto, nombre, riesgo) VALUES
  ('P01','Benceno','Alto'),
  ('P02','Tolueno','Medio');

INSERT INTO filtro (id_filtro, id_linea, id_producto, fecha_instalacion, vida_util_dias, costo_usd) VALUES
  ('F-A1-001','A1','P01','2025-09-01',180,300.00),
  ('F-A2-001','A2','P01','2025-09-01',180,300.00),
  ('F-B1-001','B1','P02','2025-09-10',200,250.00);

-- Microcontroladores y sensores
INSERT INTO microcontrolador (id_micro, id_linea, modelo, ip_local) VALUES
  ('A1M01','A1','ESP8266','192.168.10.11'),
  ('A2M01','A2','ESP8266','192.168.10.21'),
  ('B1M01','B1','ESP8266','192.168.20.11');

INSERT INTO sensor (id_sensor, id_micro, tipo, modelo, calibracion) VALUES
  ('A1S01','A1M01','MQ-135','AirQuality','2025-09-01'),
  ('A2S01','A2M01','MQ-135','AirQuality','2025-09-01'),
  ('B1S01','B1M01','MQ-135','AirQuality','2025-09-10');

-- Personal y turnos
INSERT INTO empleado (id_empleado, nombre, cargo) VALUES
  ('E001','Carlos Pérez','Supervisor'),
  ('E002','Ana Torres','Operaria');

INSERT INTO empleado_turno (id_empleado, id_turno, id_fabrica, fecha) VALUES
  ('E001',1,'A','2025-10-22'),
  ('E002',2,'B','2025-10-22');

-- Lecturas y alarma
WITH l1 AS (
  INSERT INTO lecturas (
    fecha, hora, id_sensor, id_micro, id_linea, id_fabrica, ppm_benceno,
    id_clasificacion, geo_latitud, geo_longitud, geo_altitud,
    temperatura, humedad, estado_transmision, timestamp_envio, observaciones
  )
  VALUES ('2025-10-23','08:00','A1S01','A1M01','A1','A',
          0.85, 2, 6.244, -75.574, 2450.0,
          25.4, 58.0, 'Enviado', now(), 'Sensor estabilizado')
  RETURNING id_lectura
),
l2 AS (
  INSERT INTO lecturas (
    fecha, hora, id_sensor, id_micro, id_linea, id_fabrica, ppm_benceno,
    id_clasificacion, geo_latitud, geo_longitud, geo_altitud,
    temperatura, humedad, estado_transmision, timestamp_envio, observaciones
  )
  VALUES ('2025-10-23','08:05','A1S01','A1M01','A1','A',
          12.30, 4, 6.244, -75.574, 2450.0,
          26.1, 56.0, 'Enviado', now(), 'Alerta crítica')
  RETURNING id_lectura
)
INSERT INTO alarma (id_lectura, id_clasificacion, accion)
SELECT l2.id_lectura, 4, 'Activar ventilación de emergencia' FROM l2;

-- Configuración por fábrica
INSERT INTO configuracion_fabrica (id_fabrica, parametros) VALUES
  ('A','{"limite_ppm_critico":10.0,"reintentos":3,"notificar_email":"soporte@sustanciaslocas.com"}');

COMMIT;