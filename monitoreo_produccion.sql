-- ============================================================
-- Base de Datos:  monitoreo_produccion
-- Propósito:     Monitoreo y control de emisiones (benceno)
-- Motor:         PostgreSQL 13+ (recomendado)
-- ============================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS monitoreo_produccion AUTHORIZATION CURRENT_USER;
SET search_path TO monitoreo_produccion, public;

CREATE TABLE fabrica (
  id_fabrica CHAR(1) PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL,
  ubicacion VARCHAR(100)
);

CREATE TABLE linea (
  id_linea VARCHAR(5) PRIMARY KEY,
  id_fabrica CHAR(1) NOT NULL REFERENCES fabrica(id_fabrica) ON UPDATE CASCADE ON DELETE RESTRICT,
  nombre VARCHAR(50)
);

CREATE TABLE microcontrolador (
  id_micro VARCHAR(10) PRIMARY KEY,
  id_linea VARCHAR(5) NOT NULL REFERENCES linea(id_linea) ON UPDATE CASCADE ON DELETE RESTRICT,
  modelo VARCHAR(30),
  ip_local INET
);

CREATE TABLE sensor (
  id_sensor VARCHAR(10) PRIMARY KEY,
  id_micro VARCHAR(10) NOT NULL REFERENCES microcontrolador(id_micro) ON UPDATE CASCADE ON DELETE RESTRICT,
  tipo VARCHAR(30),
  modelo VARCHAR(30),
  calibracion DATE
);

CREATE TABLE producto (
  id_producto VARCHAR(30) PRIMARY KEY,
  nombre VARCHAR(80) NOT NULL,
  riesgo VARCHAR(30)
);

CREATE TABLE filtro (
  id_filtro VARCHAR(20) PRIMARY KEY,
  id_linea VARCHAR(5) NOT NULL REFERENCES linea(id_linea) ON UPDATE CASCADE ON DELETE RESTRICT,
  id_producto VARCHAR(30) NOT NULL REFERENCES producto(id_producto) ON UPDATE CASCADE ON DELETE RESTRICT,
  fecha_instalacion DATE,
  vida_util_dias INT CHECK (vida_util_dias IS NULL OR vida_util_dias > 0),
  costo_usd NUMERIC(10,2) CHECK (costo_usd IS NULL OR costo_usd >= 0)
);

CREATE TABLE clasificacion_ppm (
  id_clasificacion INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  rango_min NUMERIC(8,2) NOT NULL,
  rango_max NUMERIC(8,2) NOT NULL,
  nivel VARCHAR(30) NOT NULL,
  estado_alarma VARCHAR(30) NOT NULL,
  CONSTRAINT ck_rangos_ppm CHECK (rango_min >= 0 AND rango_max > rango_min)
);

CREATE TABLE turno (
  id_turno INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  hora_ini TIME NOT NULL,
  hora_fin TIME NOT NULL
);

CREATE TABLE empleado (
  id_empleado VARCHAR(10) PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL,
  cargo VARCHAR(30)
);

CREATE TABLE empleado_turno (
  id_emp_turno INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_empleado VARCHAR(10) NOT NULL REFERENCES empleado(id_empleado) ON UPDATE CASCADE ON DELETE RESTRICT,
  id_turno INT NOT NULL REFERENCES turno(id_turno) ON UPDATE CASCADE ON DELETE RESTRICT,
  id_fabrica CHAR(1) NOT NULL REFERENCES fabrica(id_fabrica) ON UPDATE CASCADE ON DELETE RESTRICT,
  fecha DATE NOT NULL,
  CONSTRAINT uq_empleado_turno UNIQUE (id_empleado, id_turno, id_fabrica, fecha)
);

CREATE TABLE lecturas (
  id_lectura INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  fecha DATE NOT NULL,
  hora TIME NOT NULL,
  id_sensor VARCHAR(10) NOT NULL REFERENCES sensor(id_sensor) ON UPDATE CASCADE ON DELETE RESTRICT,
  id_micro VARCHAR(10) NOT NULL REFERENCES microcontrolador(id_micro) ON UPDATE CASCADE ON DELETE RESTRICT,
  id_linea VARCHAR(30) NOT NULL REFERENCES linea(id_linea) ON UPDATE CASCADE ON DELETE RESTRICT,
  id_fabrica CHAR(1) NOT NULL REFERENCES fabrica(id_fabrica) ON UPDATE CASCADE ON DELETE RESTRICT,
  ppm_benceno NUMERIC(8,2) NOT NULL CHECK (ppm_benceno >= 0),
  id_clasificacion INT REFERENCES clasificacion_ppm(id_clasificacion) ON UPDATE CASCADE ON DELETE SET NULL,
  geo_latitud DOUBLE PRECISION,
  geo_longitud DOUBLE PRECISION,
  geo_altitud DOUBLE PRECISION,
  temperatura NUMERIC(8,1),
  humedad NUMERIC(8,1),
  estado_transmision VARCHAR(30),
  timestamp_envio TIMESTAMP,
  observaciones VARCHAR(100),
  hash_integridad CHAR(64),
  origen_formato VARCHAR(10)
);

CREATE TABLE alarma (
  id_alarma INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_lectura INT NOT NULL REFERENCES lecturas(id_lectura) ON UPDATE CASCADE ON DELETE CASCADE,
  id_clasificacion INT NOT NULL REFERENCES clasificacion_ppm(id_clasificacion) ON UPDATE CASCADE ON DELETE RESTRICT,
  accion VARCHAR(100),
  timestamp TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE configuracion_fabrica (
  id_config INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_fabrica CHAR(1) NOT NULL REFERENCES fabrica(id_fabrica) ON UPDATE CASCADE ON DELETE CASCADE,
  parametros JSONB
);

CREATE INDEX idx_lecturas_fecha_hora ON lecturas (fecha, hora);
CREATE INDEX idx_lecturas_sensor ON lecturas (id_sensor);
CREATE INDEX idx_lecturas_fabrica ON lecturas (id_fabrica);
CREATE INDEX idx_lecturas_linea ON lecturas (id_linea);
CREATE INDEX idx_lecturas_clasificacion ON lecturas (id_clasificacion);
CREATE INDEX idx_alarma_lectura ON alarma (id_lectura);
CREATE INDEX idx_empleado_turno_fecha ON empleado_turno (fecha);

INSERT INTO turno (hora_ini, hora_fin) VALUES
  ('08:00','16:00'),
  ('16:00','23:59:59'),
  ('00:00','08:00');

INSERT INTO clasificacion_ppm (rango_min, rango_max, nivel, estado_alarma) VALUES
  (0.00, 0.50, 'Leve', 'Normal'),
  (0.50, 1.00, 'Permitida', 'Normal'),
  (1.00, 10.00, 'Moderada', 'Precaución'),
  (10.00, 50.00, 'Peligrosa', 'Crítica'),
  (50.00, 500.0, 'Altamente peligrosa', 'Emergencia'),
  (500.0, 99999.99, 'Letal', 'Emergencia');

COMMIT;