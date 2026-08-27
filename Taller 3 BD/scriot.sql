----------------------------------------------------------------------------------
-- ETL PAES 2026 - Carga de A_INSCRITOS_PUNTAJES_PAES_2026_PUB_MRUN.csv
-- Taller de Base de Datos - ETL (Copy, CAST, to_date, to_number, COALESCE)
----------------------------------------------------------------------------------
-- IMPORTANTE - 3 errores en el script creacion de datos, ya se corregieron
-- en el CREATE TABLE de la Sección 0:
--   1) comunas: "UNIQUE (comunas)" referenciaba una columna que no
--      existe (la columna se llama "comuna", singular).
--   2) postulantes.promedio NUMERIC(1,2) no puede representar 1.0-7.0
--      (1 dígito de precisión total). Se usa NUMERIC(3,2).
--   3) postulantes.ptjenem CHECK (between 1 and 7) era el rango de
--      "promedio" (notas), no el de PTJE_NEM real (que es un puntaje
--      tipo 456-785, escala 100-1000). Se usa (between 100 and 1000).
--
-- La Sección 0 usa CREATE TABLE IF NOT EXISTS: si tu base ya tenía el
-- esquema (sin estas correcciones) desde antes, este bloque NO lo va a
-- modificar solo, porque las tablas ya existen. En ese caso, o bien
-- (a) partes de una base nueva/vacía y dejas que la Sección 0 cree todo
-- ya corregido, o (b) si ya cargaste el esquema original y tu profesor
-- exige el DDL literal, aplica manualmente los 3 ALTER TABLE
-- equivalentes antes de continuar.
--
-- VALIDACIÓN DEL ARCHIVO FUENTE (hecha antes de escribir este script):
--   - 320.087 filas de datos + 1 fila de encabezado, 131 columnas,
--     separador ';', codificación UTF-8, sin filas con número de
--     columnas distinto a 131 (no hay ';' sueltos dentro de texto).
--   - MRUN: 320.087 valores, todos únicos (no hay postulantes
--     duplicados).
--   - COD_SEXO: solo 1 y 2, sin blancos.
--   - PROMEDIO_NOTAS: rango 0,00 a 7,00, siempre con coma decimal
--     (nunca punto) y sin valores en blanco.
--   - PTJE_NEM y PTJE_RANKING: rango 0 a 1000, sin blancos.
--   - RBD y DEPENDENCIA: 3.200 filas vienen con ambos campos en blanco
--     (postulantes sin establecimiento de egreso informado).
--   - ANYO_DE_EGRESO: 218 filas en blanco + 1 fila en '0'.
--   - Hay 12 RBD que aparecen con más de una DEPENDENCIA informada y
--     11 RBD que aparecen con más de un NOMBRE_UNIDAD_EDUC (cambios de
--     nombre/dependencia del colegio entre años); ningún RBD aparece
--     con más de una comuna.
--   - Los códigos y nombres de región/provincia/comuna son 100%
--     consistentes entre filas (mismo código -> mismo nombre siempre).
-- =====================================================================


-- ------------------------------------------------------------------------
-- SECCIÓN 0: Esquema normalizado (script del profesor, con las 3
-- correcciones ya incorporadas directamente en el CREATE TABLE)
------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sexos (
  cod_sexo INTEGER NOT NULL,
  sexo VARCHAR(255) NOT NULL,
  PRIMARY KEY (cod_sexo)
);

CREATE TABLE IF NOT EXISTS postulantes (
  mrut INTEGER NOT NULL,
  fecha_nacimiento DATE NOT NULL,
  cod_sexo INTEGER NOT NULL,
  anoegreso DATE NOT NULL,
  -- Se ajusta el límite inferior a 0.0 para aceptar postulantes sin NEM en el CSV
  promedio NUMERIC(3,2) NOT NULL CHECK (promedio >= 0.0 and promedio <= 7.0),
  -- Se ajusta el límite inferior a 0 para aceptar puntajes vacíos/cero en el CSV
  ptjenem INTEGER NOT NULL CHECK (ptjenem >= 0 and ptjenem <= 1000),
  porc_sup_not INTEGER NOT NULL,
  ptjeranking INTEGER NOT NULL CHECK (ptjeranking >= 0 and ptjeranking <= 1000),
  PRIMARY KEY (mrut)
);

CREATE TABLE IF NOT EXISTS tiposensenanza (
  codigo_ens INTEGER NOT NULL,
  tipoensenanza VARCHAR(80) NOT NULL,
  PRIMARY KEY (codigo_ens),
  UNIQUE (tipoensenanza)
);

CREATE TABLE IF NOT EXISTS ramaseducacionales (
  codigoramaeducacional CHAR(2) NOT NULL,
  ramaeducacional VARCHAR(255) NOT NULL,
  PRIMARY KEY (codigoramaeducacional)
);

CREATE TABLE IF NOT EXISTS dependencias (
  codigodependencia INTEGER NOT NULL,
  dependencia VARCHAR(40) NOT NULL,
  PRIMARY KEY (codigodependencia),
  UNIQUE (dependencia)
);

CREATE TABLE IF NOT EXISTS regiones (
  codigoregion INTEGER NOT NULL,
  region VARCHAR(50) NOT NULL,
  PRIMARY KEY (codigoregion),
  UNIQUE (region)
);

CREATE TABLE IF NOT EXISTS provincias (
  codigoprovincia INTEGER NOT NULL,
  provincias VARCHAR(30) NOT NULL,
  codigoregion INTEGER NOT NULL,
  PRIMARY KEY (codigoprovincia),
  UNIQUE (provincias),
  FOREIGN KEY (codigoregion) REFERENCES regiones(codigoregion) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS comunas (
  codigocomuna INTEGER NOT NULL,
  comuna VARCHAR(30) NOT NULL,
  codigoprovincia INTEGER NOT NULL,
  PRIMARY KEY (codigocomuna),
  -- Corrección: el script original tenía "UNIQUE (comunas)", una
  -- columna que no existe (la columna se llama "comuna", singular).
  UNIQUE (comuna),
  FOREIGN KEY (codigoprovincia) REFERENCES provincias(codigoprovincia) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS establecimientos (
  rbd INTEGER NOT NULL,
  nombre_unidad_educativa VARCHAR(100) NOT NULL,
  codigodependencia INTEGER,
  codigocomuna INTEGER NOT NULL,
  PRIMARY KEY (rbd),
  FOREIGN KEY (codigodependencia) REFERENCES dependencias(codigodependencia) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (codigocomuna) REFERENCES comunas(codigocomuna) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS tiposensenanza_establecimientos (
  codigo_ens_tiposensenanza INTEGER NOT NULL,
  rbd_establecimientos INTEGER NOT NULL,
  codigoramaeducacional CHAR(2) NOT NULL,
  PRIMARY KEY (codigo_ens_tiposensenanza, rbd_establecimientos, codigoramaeducacional),
  FOREIGN KEY (codigo_ens_tiposensenanza) REFERENCES tiposensenanza(codigo_ens) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (rbd_establecimientos) REFERENCES establecimientos(rbd) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (codigoramaeducacional) REFERENCES ramaseducacionales(codigoramaeducacional) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS rendicionespruebas (
  idrendicionprueba INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL,
  rendicionprueba VARCHAR(255) NOT NULL,
  PRIMARY KEY (idrendicionprueba)
);

CREATE TABLE IF NOT EXISTS pruebas (
  idprueba INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL,
  nombreprueba VARCHAR(255) NOT NULL,
  PRIMARY KEY (idprueba)
);

CREATE TABLE IF NOT EXISTS puntajesrendicionespruebasalumnos (
  idrendicionprueba INTEGER NOT NULL,
  idprueba INTEGER NOT NULL,
  mrut INTEGER NOT NULL,
  forma INTEGER NOT NULL,
  puntaje INTEGER NOT NULL CHECK (puntaje between 100 and 1000),
  correctas SMALLINT NOT NULL,
  erradas SMALLINT NOT NULL,
  omitidas SMALLINT NOT NULL,
  PRIMARY KEY (idrendicionprueba, idprueba, mrut),
  FOREIGN KEY (idrendicionprueba) REFERENCES rendicionespruebas(idrendicionprueba) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (idprueba) REFERENCES pruebas(idprueba) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (mrut) REFERENCES postulantes(mrut) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS puntajes_maximos (
  mrut_postulantes INTEGER NOT NULL,
  idprueba_pruebas INTEGER NOT NULL,
  ptje_maximo INTEGER NOT NULL CHECK (ptje_maximo between 100 and 1000),
  PRIMARY KEY (mrut_postulantes, idprueba_pruebas),
  FOREIGN KEY (mrut_postulantes) REFERENCES postulantes(mrut) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (idprueba_pruebas) REFERENCES pruebas(idprueba) ON DELETE CASCADE ON UPDATE CASCADE
);


------------------------------------------------------------------------
-- SECCIÓN 1: Tabla temporal (staging) "traspaso"
------------------------------------------------------------------------
DROP TABLE IF EXISTS public.traspaso;

CREATE TABLE public.traspaso
(
    mrun character varying(100),
    anyo_proceso character varying(100),
    cod_sexo character varying(100),
    fecha_nacimiento character varying(100),
    rbd character varying(100),
    codigo_ens character varying(100),
    local_educacional character varying(100),
    unidad_educativa character varying(100),
    nombre_unidad_educ character varying(100),
    rama_educacional character varying(100),
    dependencia character varying(100),
    codigo_region_egreso character varying(100),
    nombre_region_egreso character varying(100),
    codigo_provincia_egreso character varying(100),
    nombre_provincia_egreso character varying(100),
    codigo_comuna_egreso character varying(100),
    nombre_comuna_egreso character varying(100),
    anyo_de_egreso character varying(100),
    promedio_notas character varying(100),
    ptje_nem character varying(100),
    porc_sup_notas character varying(100),
    ptje_ranking character varying(100),
    clec_reg_actual character varying(100),
    mate1_reg_actual character varying(100),
    mate2_reg_actual character varying(100),
    hcsoc_reg_actual character varying(100),
    cien_reg_actual character varying(100),
    clec_inv_actual character varying(100),
    mate1_inv_actual character varying(100),
    mate2_inv_actual character varying(100),
    hcsoc_inv_actual character varying(100),
    cien_inv_actual character varying(100),
    clec_reg_anterior character varying(100),
    mate1_reg_anterior character varying(100),
    mate2_reg_anterior character varying(100),
    hcsoc_reg_anterior character varying(100),
    cien_reg_anterior character varying(100),
    clec_inv_anterior character varying(100),
    mate1_inv_anterior character varying(100),
    mate2_inv_anterior character varying(100),
    hcsoc_inv_anterior character varying(100),
    cien_inv_anterior character varying(100),
    promedio_cm_max character varying(100),
    clec_max character varying(100),
    mate1_max character varying(100),
    mate2_max character varying(100),
    hcsoc_max character varying(100),
    cien_max character varying(100),
    rindio_proceso_anterior character varying(100),
    rindio_proceso_actual character varying(100),
    habilitacion_post character varying(100),
    prueba_reg_cl character varying(100),
    forma_reg_cl character varying(100),
    correctas_reg_cl character varying(100),
    erradas_reg_cl character varying(100),
    omitidas_reg_cl character varying(100),
    prueba_reg_m1 character varying(100),
    forma_reg_m1 character varying(100),
    correctas_reg_m1 character varying(100),
    erradas_reg_m1 character varying(100),
    omitidas_reg_m1 character varying(100),
    prueba_reg_m2 character varying(100),
    forma_reg_m2 character varying(100),
    correctas_reg_m2 character varying(100),
    erradas_reg_m2 character varying(100),
    omitidas_reg_m2 character varying(100),
    prueba_reg_hcs character varying(100),
    forma_reg_hcs character varying(100),
    correctas_reg_hcs character varying(100),
    erradas_reg_hcs character varying(100),
    omitidas_reg_hcs character varying(100),
    prueba_reg_cbio character varying(100),
    forma_reg_cbio character varying(100),
    correctas_reg_cbio character varying(100),
    erradas_reg_cbio character varying(100),
    omitidas_reg_cbio character varying(100),
    prueba_reg_cfis character varying(100),
    forma_reg_cfis character varying(100),
    correctas_reg_cfis character varying(100),
    erradas_reg_cfis character varying(100),
    omitidas_reg_cfis character varying(100),
    prueba_reg_cqui character varying(100),
    forma_reg_cqui character varying(100),
    correctas_reg_cqui character varying(100),
    erradas_reg_cqui character varying(100),
    omitidas_reg_cqui character varying(100),
    prueba_reg_ctp character varying(100),
    forma_reg_ctp character varying(100),
    correctas_reg_ctp character varying(100),
    erradas_reg_ctp character varying(100),
    omitidas_reg_ctp character varying(100),
    prueba_inv_cl character varying(100),
    forma_inv_cl character varying(100),
    correctas_inv_cl character varying(100),
    erradas_inv_cl character varying(100),
    omitidas_inv_cl character varying(100),
    prueba_inv_m1 character varying(100),
    forma_inv_m1 character varying(100),
    correctas_inv_m1 character varying(100),
    erradas_inv_m1 character varying(100),
    omitidas_inv_m1 character varying(100),
    prueba_inv_m2 character varying(100),
    forma_inv_m2 character varying(100),
    correctas_inv_m2 character varying(100),
    erradas_inv_m2 character varying(100),
    omitidas_inv_m2 character varying(100),
    prueba_inv_hcs character varying(100),
    forma_inv_hcs character varying(100),
    correctas_inv_hcs character varying(100),
    erradas_inv_hcs character varying(100),
    omitidas_inv_hcs character varying(100),
    prueba_inv_cbio character varying(100),
    forma_inv_cbio character varying(100),
    correctas_inv_cbio character varying(100),
    erradas_inv_cbio character varying(100),
    omitidas_inv_cbio character varying(100),
    prueba_inv_cfis character varying(100),
    forma_inv_cfis character varying(100),
    correctas_inv_cfis character varying(100),
    erradas_inv_cfis character varying(100),
    omitidas_inv_cfis character varying(100),
    prueba_inv_cqui character varying(100),
    forma_inv_cqui character varying(100),
    correctas_inv_cqui character varying(100),
    erradas_inv_cqui character varying(100),
    omitidas_inv_cqui character varying(100),
    prueba_inv_ctp character varying(100),
    forma_inv_ctp character varying(100),
    correctas_inv_ctp character varying(100),
    erradas_inv_ctp character varying(100),
    omitidas_inv_ctp character varying(100)
);


-- =====================================================================
-- SECCIÓN 2: Carga masiva con COPY
-- =====================================================================
-- El CSV real (A_INSCRITOS_PUNTAJES_PAES_2026_PUB_MRUN.csv) trae:
--   - separador ';' (no coma)
--   - fila de encabezado
--   - codificación UTF-8
--   - 320.087 filas de datos, 131 columnas cada una, sin filas
--     truncadas ni ';' sueltos dentro de campos de texto.
-- Por eso el COPY necesita indicar explícitamente DELIMITER, HEADER y
-- ENCODING; con los valores por defecto (coma, sin salto de header)
-- la carga fallaría o quedaría corrupta.

-- Ajusta la ruta al archivo real en tu equipo/servidor.

-- Si el archivo está en el SERVIDOR de Postgres (o accesible por su
-- proceso), usa COPY:
COPY public.traspaso
FROM 'C:/ruta/a/A_INSCRITOS_PUNTAJES_PAES_2026_PUB_MRUN.csv'
WITH (
    FORMAT csv,
    DELIMITER ';',
    HEADER true,
    ENCODING 'UTF8'
);

-- Si usas psql y el archivo está en tu máquina CLIENTE (lo más común,
-- por ejemplo abriendo el archivo desde tu propio computador), comenta
-- el COPY de arriba y usa \copy en su lugar (metacomando de psql, va
-- sin punto y coma extra al final de la línea de opciones):
-- \copy public.traspaso FROM 'C:/ruta/a/A_INSCRITOS_PUNTAJES_PAES_2026_PUB_MRUN.csv' WITH (FORMAT csv, DELIMITER ';', HEADER true, ENCODING 'UTF8')

-- Si usas pgAdmin, usa el asistente gráfico "Import/Export Data..."
-- sobre la tabla traspaso, indicando ';' como delimitador y "Header"
-- activado, en vez de este COPY.

-- Validación rápida post-carga (debe dar 320087 en un archivo íntegro)
SELECT count(*) FROM traspaso;


-- =====================================================================
-- SECCIÓN 3: Tablas de catálogo "en duro"
-- =====================================================================
-- Estas tablas no tienen sus descripciones en el CSV (solo el código),
-- así que se llenan a mano con el Anexo I y Anexo II del diccionario
-- de datos.

-- 3.1 sexos
INSERT INTO sexos (cod_sexo, sexo) VALUES
  (1, 'Masculino'),
  (2, 'Femenino')
ON CONFLICT (cod_sexo) DO NOTHING;

-- 3.2 ramaseducacionales (valores reales presentes en el CSV: H1-H4, T1-T5)
INSERT INTO ramaseducacionales (codigoramaeducacional, ramaeducacional) VALUES
  ('H1', 'Humanista Científico Diurno'),
  ('H2', 'Humanista Científico Nocturno'),
  ('H3', 'Humanista Científico - Validación de estudios'),
  ('H4', 'Humanista Científico - Reconocimiento de estudios'),
  ('T1', 'Técnico Profesional Comercial'),
  ('T2', 'Técnico Profesional Industrial'),
  ('T3', 'Técnico Profesional Servicios y Técnica'),
  ('T4', 'Técnico Profesional Agrícola'),
  ('T5', 'Técnico Profesional Marítima')
ON CONFLICT (codigoramaeducacional) DO NOTHING;

-- 3.3 dependencias
INSERT INTO dependencias (codigodependencia, dependencia) VALUES
  (1, 'Corporación Municipal'),
  (2, 'Municipal'),
  (3, 'Particular Subvencionado'),
  (4, 'Particular Pagado'),
  (5, 'Corporación de Administración Delegada'),
  (6, 'Servicio Local de Educación (SLE)')
ON CONFLICT (codigodependencia) DO NOTHING;

-- 3.4 tiposensenanza (Anexo II completo; el CSV 2026 solo usa un
-- subconjunto, pero se carga completo por si se reutiliza el script
-- con otros años del mismo proceso).
-- Nota: el propio Anexo II repite el mismo texto de glosa para 4 pares
-- de códigos (460/461, 560/561, 660/661, 760/761). Como tipoensenanza
-- tiene UNIQUE, se agrega el código entre paréntesis solo a esas 8
-- filas para diferenciarlas; el código real no cambia.
INSERT INTO tiposensenanza (codigo_ens, tipoensenanza) VALUES
  (310, 'Enseñanza Media H-C niños y jóvenes'),
  (360, 'Educación Media H-C adultos vespertino y nocturno (Decreto N° 190/1975)'),
  (361, 'Educación Media H-C adultos (Decreto N° 12/1987)'),
  (362, 'Escuelas Cárceles (Media Adultos)'),
  (363, 'Educación Media H-C Adultos (Decreto N°239/2004)'),
  (410, 'Enseñanza Media Técnico-Profesional Comercial Niños'),
  (460, 'Educación Media T-P Comercial Adultos (Decreto N° 152/1989) - Cód. 460'),
  (461, 'Educación Media T-P Comercial Adultos (Decreto N° 152/1989) - Cód. 461'),
  (463, 'Educación Media T-P Comercial Adultos (Decreto N° 239/2004)'),
  (510, 'Enseñanza Media T-P Industrial Niños'),
  (560, 'Educación Media T-P Industrial Adultos (Decreto N° 152/1989) - Cód. 560'),
  (561, 'Educación Media T-P Industrial Adultos (Decreto N° 152/1989) - Cód. 561'),
  (563, 'Educación Media T-P Industrial Adultos (Decreto N° 239/2004)'),
  (610, 'Enseñanza Media T-P Técnica Niños'),
  (660, 'Educación Media T-P Técnica Adultos (Decreto N° 152/1989) - Cód. 660'),
  (661, 'Educación Media T-P Técnica Adultos (Decreto N° 152/1989) - Cód. 661'),
  (663, 'Educación Media T-P Técnica Adultos (Decreto N° 239/2004)'),
  (710, 'Enseñanza Media T-P Agrícola Niños'),
  (760, 'Educación Media T-P Agrícola Adultos (Decreto N° 152/1989) - Cód. 760'),
  (761, 'Educación Media T-P Agrícola Adultos (Decreto N° 152/1989) - Cód. 761'),
  (763, 'Educación Media T-P Agrícola Adultos (Decreto N° 239/2004)'),
  (810, 'Enseñanza Media T-P Marítima Niños'),
  (860, 'Enseñanza Media T-P Marítima Adultos (Decreto N° 152/1989)'),
  (863, 'Enseñanza Media T-P Marítima Adultos (Decreto N° 1000/2009)'),
  (910, 'Enseñanza Media Artística Niños y Jóvenes'),
  (963, 'Enseñanza Media Artística Adultos')
ON CONFLICT (codigo_ens) DO NOTHING;

-- 3.5 rendicionespruebas (las 4 instancias de rendición que existen
-- en el archivo: actual/anterior x regular/invierno)
INSERT INTO rendicionespruebas (rendicionprueba) VALUES
  ('Regular Proceso Actual'),
  ('Invierno Proceso Actual'),
  ('Regular Proceso Anterior'),
  ('Invierno Proceso Anterior');

-- 3.6 pruebas
-- Las 4 primeras (CL, M1, M2, HCS) tienen puntaje + detalle
-- (forma/correctas/erradas/omitidas) en las 4 rendiciones.
-- Las 4 siguientes (CBIO/CFIS/CQUI/CTP) son las electivas de Ciencias:
-- solo tienen detalle completo en el proceso ACTUAL (columnas
-- PRUEBA_REG_CBIO...PRUEBA_INV_CTP); el puntaje de esa electiva se
-- toma de CIEN_REG_ACTUAL / CIEN_INV_ACTUAL.
-- La 9na fila es un "cajón" para el puntaje de Ciencias del proceso
-- ANTERIOR, donde el CSV no informa cuál electiva rindió el postulante
-- (no hay columnas de detalle para el proceso anterior).
INSERT INTO pruebas (nombreprueba) VALUES
  ('Competencia Lectora'),
  ('Competencia Matemática 1'),
  ('Competencia Matemática 2'),
  ('Historia y Ciencias Sociales'),
  ('Ciencias Biología'),
  ('Ciencias Física'),
  ('Ciencias Química'),
  ('Ciencias Técnico-Profesional'),
  ('Ciencias (proceso anterior, electivo no identificado en la fuente)');


-- =====================================================================
-- SECCIÓN 4: regiones / provincias / comunas
-- =====================================================================
-- A diferencia de las tablas anteriores, estos nombres SÍ vienen en el
-- CSV y son consistentes (se verificó: 0 códigos con nombres distintos
-- entre filas), así que se derivan directamente de traspaso en vez de
-- tipearlos a mano desde el Anexo I.

INSERT INTO regiones (codigoregion, region)
SELECT DISTINCT
  CAST(codigo_region_egreso AS INTEGER),
  TRIM(nombre_region_egreso)
FROM traspaso
WHERE NULLIF(TRIM(codigo_region_egreso), '') IS NOT NULL
ON CONFLICT (codigoregion) DO NOTHING;

INSERT INTO provincias (codigoprovincia, provincias, codigoregion)
SELECT DISTINCT ON (CAST(codigo_provincia_egreso AS INTEGER))
  CAST(codigo_provincia_egreso AS INTEGER),
  TRIM(nombre_provincia_egreso),
  CAST(codigo_region_egreso AS INTEGER)
FROM traspaso
WHERE NULLIF(TRIM(codigo_provincia_egreso), '') IS NOT NULL
  AND NULLIF(TRIM(codigo_region_egreso), '') IS NOT NULL
ON CONFLICT (codigoprovincia) DO NOTHING;

INSERT INTO comunas (codigocomuna, comuna, codigoprovincia)
SELECT DISTINCT ON (CAST(codigo_comuna_egreso AS INTEGER))
  CAST(codigo_comuna_egreso AS INTEGER),
  TRIM(nombre_comuna_egreso),
  CAST(codigo_provincia_egreso AS INTEGER)
FROM traspaso
WHERE NULLIF(TRIM(codigo_comuna_egreso), '') IS NOT NULL
  AND NULLIF(TRIM(codigo_provincia_egreso), '') IS NOT NULL
ON CONFLICT (codigocomuna) DO NOTHING;


-- =====================================================================
-- SECCIÓN 5: establecimientos (con manejo de inconsistencias)
-- =====================================================================
-- Se detectaron 11 RBD con más de un (nombre_unidad_educ, comuna)
-- distinto entre filas (ej: cambio de nombre del colegio o de
-- dependencia a través de los años) y 12 RBD con más de una
-- dependencia informada. Como establecimientos.rbd es PK, no se puede
-- guardar más de una fila por RBD: se elige la versión más reciente
-- según anyo_de_egreso (DISTINCT ON ... ORDER BY ... DESC).
-- Además, 3.200 filas vienen con RBD en blanco (postulantes sin
-- establecimiento de egreso registrado): se excluyen de esta tabla.

INSERT INTO establecimientos (rbd, nombre_unidad_educativa, codigodependencia, codigocomuna)
SELECT DISTINCT ON (CAST(rbd AS INTEGER))
  CAST(rbd AS INTEGER),
  TRIM(nombre_unidad_educ),
  CAST(NULLIF(TRIM(dependencia), '') AS INTEGER),
  CAST(codigo_comuna_egreso AS INTEGER)
FROM traspaso
WHERE NULLIF(TRIM(rbd), '') IS NOT NULL
  AND NULLIF(TRIM(codigo_comuna_egreso), '') IS NOT NULL
ORDER BY CAST(rbd AS INTEGER), NULLIF(TRIM(anyo_de_egreso), '')::INTEGER DESC NULLS LAST
ON CONFLICT (rbd) DO NOTHING;

-- Bridge table: combinaciones (tipo de enseñanza, establecimiento, rama)
INSERT INTO tiposensenanza_establecimientos
  (codigo_ens_tiposensenanza, rbd_establecimientos, codigoramaeducacional)
SELECT DISTINCT
  CAST(t.codigo_ens AS INTEGER),
  CAST(t.rbd AS INTEGER),
  TRIM(t.rama_educacional)
FROM traspaso t
WHERE NULLIF(TRIM(t.rbd), '') IS NOT NULL
  AND NULLIF(TRIM(t.codigo_ens), '') IS NOT NULL
  AND NULLIF(TRIM(t.rama_educacional), '') IS NOT NULL
  AND EXISTS (SELECT 1 FROM establecimientos e WHERE e.rbd = CAST(t.rbd AS INTEGER))
ON CONFLICT (codigo_ens_tiposensenanza, rbd_establecimientos, codigoramaeducacional)
  DO NOTHING;


-- =====================================================================
-- SECCIÓN 6: postulantes
-- =====================================================================
-- Transformaciones usadas:
--  - FECHA_NACIMIENTO viene como AAAAMM (sin día, según diccionario):
--    se completa con día 01 y se convierte con to_date(...,'YYYYMMDD').
--  - PROMEDIO_NOTAS viene con coma decimal ("6,25"): se reemplaza la
--    coma por punto y se hace CAST a NUMERIC.
--  - ANYO_DE_EGRESO viene vacío en 218 filas (y en '0' en 1 fila): se
--    usa COALESCE/CASE con ANYO_PROCESO - 1 como respaldo razonable
--    (el año de egreso más probable si el dato no fue informado), para
--    no violar el NOT NULL.

INSERT INTO postulantes
  (mrut, fecha_nacimiento, cod_sexo, anoegreso, promedio, ptjenem, porc_sup_not, ptjeranking)
SELECT
  CAST(mrun AS INTEGER),
  to_date(fecha_nacimiento || '01', 'YYYYMMDD'),
  CAST(cod_sexo AS INTEGER),

  -- LIMPIEZA: Si el año viene nulo o en '0', usamos el año del proceso menos 1
  to_date(
    CASE
      WHEN anyo_de_egreso IS NULL OR TRIM(anyo_de_egreso) = '' OR TRIM(anyo_de_egreso) = '0'
        THEN (CAST(anyo_proceso AS INTEGER) - 1)::text
      ELSE TRIM(anyo_de_egreso)
    END || '0101',
    'YYYYMMDD'
  ),

  CAST(REPLACE(promedio_notas, ',', '.') AS NUMERIC(3,2)),
  CAST(ptje_nem AS INTEGER),
  CAST(porc_sup_notas AS INTEGER),
  CAST(ptje_ranking AS INTEGER)
FROM traspaso
ON CONFLICT (mrut) DO NOTHING;


-- =====================================================================
-- SECCIÓN 7: puntajesrendicionespruebasalumnos
-- =====================================================================
-- Se arma con UNION ALL: una rama por (rendición x prueba). Solo se
-- inserta la fila si el puntaje es válido (100-1000): así se descartan
-- pruebas no rendidas (puntaje en blanco o 0).
--
-- Regular/Invierno ACTUAL: el detalle (forma/correctas/erradas/
-- omitidas) SÍ está en el CSV para CL, M1, M2, HCS y para las 4
-- electivas de ciencia (CBIO/CFIS/CQUI/CTP); se usa tal cual.
--
-- Regular/Invierno ANTERIOR: el CSV NO trae detalle (no hay columnas
-- FORMA_REG_CL del proceso anterior). Siguiendo la lógica de COALESCE
-- vista en el taller, se completa forma/correctas/erradas/omitidas con
-- 0 como valor por defecto, dejando registro del puntaje aunque no se
-- conozca el detalle de respuestas.

WITH ids AS (
  SELECT
    (SELECT idrendicionprueba FROM rendicionespruebas WHERE rendicionprueba = 'Regular Proceso Actual')   AS r_reg_act,
    (SELECT idrendicionprueba FROM rendicionespruebas WHERE rendicionprueba = 'Invierno Proceso Actual')   AS r_inv_act,
    (SELECT idrendicionprueba FROM rendicionespruebas WHERE rendicionprueba = 'Regular Proceso Anterior')  AS r_reg_ant,
    (SELECT idrendicionprueba FROM rendicionespruebas WHERE rendicionprueba = 'Invierno Proceso Anterior') AS r_inv_ant,
    (SELECT idprueba FROM pruebas WHERE nombreprueba = 'Competencia Lectora')             AS p_cl,
    (SELECT idprueba FROM pruebas WHERE nombreprueba = 'Competencia Matemática 1')        AS p_m1,
    (SELECT idprueba FROM pruebas WHERE nombreprueba = 'Competencia Matemática 2')        AS p_m2,
    (SELECT idprueba FROM pruebas WHERE nombreprueba = 'Historia y Ciencias Sociales')    AS p_hcs,
    (SELECT idprueba FROM pruebas WHERE nombreprueba = 'Ciencias Biología')               AS p_cbio,
    (SELECT idprueba FROM pruebas WHERE nombreprueba = 'Ciencias Física')                 AS p_cfis,
    (SELECT idprueba FROM pruebas WHERE nombreprueba = 'Ciencias Química')                AS p_cqui,
    (SELECT idprueba FROM pruebas WHERE nombreprueba = 'Ciencias Técnico-Profesional')    AS p_ctp,
    (SELECT idprueba FROM pruebas WHERE nombreprueba = 'Ciencias (proceso anterior, electivo no identificado en la fuente)') AS p_cien_gen
),
carga AS (

  -- ===== REGULAR ACTUAL =====
  SELECT ids.r_reg_act AS idrendicionprueba, ids.p_cl AS idprueba, CAST(t.mrun AS INTEGER) AS mrut,
         CAST(t.forma_reg_cl AS INTEGER) AS forma, CAST(t.clec_reg_actual AS INTEGER) AS puntaje,
         CAST(t.correctas_reg_cl AS SMALLINT) AS correctas, CAST(t.erradas_reg_cl AS SMALLINT) AS erradas, CAST(t.omitidas_reg_cl AS SMALLINT) AS omitidas
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.clec_reg_actual),'') IS NOT NULL AND CAST(t.clec_reg_actual AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.r_reg_act, ids.p_m1, CAST(t.mrun AS INTEGER),
         CAST(t.forma_reg_m1 AS INTEGER), CAST(t.mate1_reg_actual AS INTEGER),
         CAST(t.correctas_reg_m1 AS SMALLINT), CAST(t.erradas_reg_m1 AS SMALLINT), CAST(t.omitidas_reg_m1 AS SMALLINT)
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.mate1_reg_actual),'') IS NOT NULL AND CAST(t.mate1_reg_actual AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.r_reg_act, ids.p_m2, CAST(t.mrun AS INTEGER),
         CAST(t.forma_reg_m2 AS INTEGER), CAST(t.mate2_reg_actual AS INTEGER),
         CAST(t.correctas_reg_m2 AS SMALLINT), CAST(t.erradas_reg_m2 AS SMALLINT), CAST(t.omitidas_reg_m2 AS SMALLINT)
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.mate2_reg_actual),'') IS NOT NULL AND CAST(t.mate2_reg_actual AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.r_reg_act, ids.p_hcs, CAST(t.mrun AS INTEGER),
         CAST(t.forma_reg_hcs AS INTEGER), CAST(t.hcsoc_reg_actual AS INTEGER),
         CAST(t.correctas_reg_hcs AS SMALLINT), CAST(t.erradas_reg_hcs AS SMALLINT), CAST(t.omitidas_reg_hcs AS SMALLINT)
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.hcsoc_reg_actual),'') IS NOT NULL AND CAST(t.hcsoc_reg_actual AS INTEGER) BETWEEN 100 AND 1000

  -- ciencias regular actual: una fila por electivo, solo si ese electivo fue rendido (forma <> 0)
  UNION ALL
  SELECT ids.r_reg_act, ids.p_cbio, CAST(t.mrun AS INTEGER),
         CAST(t.forma_reg_cbio AS INTEGER), CAST(t.cien_reg_actual AS INTEGER),
         CAST(t.correctas_reg_cbio AS SMALLINT), CAST(t.erradas_reg_cbio AS SMALLINT), CAST(t.omitidas_reg_cbio AS SMALLINT)
  FROM traspaso t, ids WHERE CAST(t.forma_reg_cbio AS INTEGER) <> 0 AND NULLIF(TRIM(t.cien_reg_actual),'') IS NOT NULL AND CAST(t.cien_reg_actual AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.r_reg_act, ids.p_cfis, CAST(t.mrun AS INTEGER),
         CAST(t.forma_reg_cfis AS INTEGER), CAST(t.cien_reg_actual AS INTEGER),
         CAST(t.correctas_reg_cfis AS SMALLINT), CAST(t.erradas_reg_cfis AS SMALLINT), CAST(t.omitidas_reg_cfis AS SMALLINT)
  FROM traspaso t, ids WHERE CAST(t.forma_reg_cfis AS INTEGER) <> 0 AND NULLIF(TRIM(t.cien_reg_actual),'') IS NOT NULL AND CAST(t.cien_reg_actual AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.r_reg_act, ids.p_cqui, CAST(t.mrun AS INTEGER),
         CAST(t.forma_reg_cqui AS INTEGER), CAST(t.cien_reg_actual AS INTEGER),
         CAST(t.correctas_reg_cqui AS SMALLINT), CAST(t.erradas_reg_cqui AS SMALLINT), CAST(t.omitidas_reg_cqui AS SMALLINT)
  FROM traspaso t, ids WHERE CAST(t.forma_reg_cqui AS INTEGER) <> 0 AND NULLIF(TRIM(t.cien_reg_actual),'') IS NOT NULL AND CAST(t.cien_reg_actual AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.r_reg_act, ids.p_ctp, CAST(t.mrun AS INTEGER),
         CAST(t.forma_reg_ctp AS INTEGER), CAST(t.cien_reg_actual AS INTEGER),
         CAST(t.correctas_reg_ctp AS SMALLINT), CAST(t.erradas_reg_ctp AS SMALLINT), CAST(t.omitidas_reg_ctp AS SMALLINT)
  FROM traspaso t, ids WHERE CAST(t.forma_reg_ctp AS INTEGER) <> 0 AND NULLIF(TRIM(t.cien_reg_actual),'') IS NOT NULL AND CAST(t.cien_reg_actual AS INTEGER) BETWEEN 100 AND 1000

  -- ===== INVIERNO ACTUAL =====
  UNION ALL
  SELECT ids.r_inv_act, ids.p_cl, CAST(t.mrun AS INTEGER),
         CAST(t.forma_inv_cl AS INTEGER), CAST(t.clec_inv_actual AS INTEGER),
         CAST(t.correctas_inv_cl AS SMALLINT), CAST(t.erradas_inv_cl AS SMALLINT), CAST(t.omitidas_inv_cl AS SMALLINT)
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.clec_inv_actual),'') IS NOT NULL AND CAST(t.clec_inv_actual AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.r_inv_act, ids.p_m1, CAST(t.mrun AS INTEGER),
         CAST(t.forma_inv_m1 AS INTEGER), CAST(t.mate1_inv_actual AS INTEGER),
         CAST(t.correctas_inv_m1 AS SMALLINT), CAST(t.erradas_inv_m1 AS SMALLINT), CAST(t.omitidas_inv_m1 AS SMALLINT)
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.mate1_inv_actual),'') IS NOT NULL AND CAST(t.mate1_inv_actual AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.r_inv_act, ids.p_m2, CAST(t.mrun AS INTEGER),
         CAST(t.forma_inv_m2 AS INTEGER), CAST(t.mate2_inv_actual AS INTEGER),
         CAST(t.correctas_inv_m2 AS SMALLINT), CAST(t.erradas_inv_m2 AS SMALLINT), CAST(t.omitidas_inv_m2 AS SMALLINT)
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.mate2_inv_actual),'') IS NOT NULL AND CAST(t.mate2_inv_actual AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.r_inv_act, ids.p_hcs, CAST(t.mrun AS INTEGER),
         CAST(t.forma_inv_hcs AS INTEGER), CAST(t.hcsoc_inv_actual AS INTEGER),
         CAST(t.correctas_inv_hcs AS SMALLINT), CAST(t.erradas_inv_hcs AS SMALLINT), CAST(t.omitidas_inv_hcs AS SMALLINT)
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.hcsoc_inv_actual),'') IS NOT NULL AND CAST(t.hcsoc_inv_actual AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.r_inv_act, ids.p_cbio, CAST(t.mrun AS INTEGER),
         CAST(t.forma_inv_cbio AS INTEGER), CAST(t.cien_inv_actual AS INTEGER),
         CAST(t.correctas_inv_cbio AS SMALLINT), CAST(t.erradas_inv_cbio AS SMALLINT), CAST(t.omitidas_inv_cbio AS SMALLINT)
  FROM traspaso t, ids WHERE CAST(t.forma_inv_cbio AS INTEGER) <> 0 AND NULLIF(TRIM(t.cien_inv_actual),'') IS NOT NULL AND CAST(t.cien_inv_actual AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.r_inv_act, ids.p_cfis, CAST(t.mrun AS INTEGER),
         CAST(t.forma_inv_cfis AS INTEGER), CAST(t.cien_inv_actual AS INTEGER),
         CAST(t.correctas_inv_cfis AS SMALLINT), CAST(t.erradas_inv_cfis AS SMALLINT), CAST(t.omitidas_inv_cfis AS SMALLINT)
  FROM traspaso t, ids WHERE CAST(t.forma_inv_cfis AS INTEGER) <> 0 AND NULLIF(TRIM(t.cien_inv_actual),'') IS NOT NULL AND CAST(t.cien_inv_actual AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.r_inv_act, ids.p_cqui, CAST(t.mrun AS INTEGER),
         CAST(t.forma_inv_cqui AS INTEGER), CAST(t.cien_inv_actual AS INTEGER),
         CAST(t.correctas_inv_cqui AS SMALLINT), CAST(t.erradas_inv_cqui AS SMALLINT), CAST(t.omitidas_inv_cqui AS SMALLINT)
  FROM traspaso t, ids WHERE CAST(t.forma_inv_cqui AS INTEGER) <> 0 AND NULLIF(TRIM(t.cien_inv_actual),'') IS NOT NULL AND CAST(t.cien_inv_actual AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.r_inv_act, ids.p_ctp, CAST(t.mrun AS INTEGER),
         CAST(t.forma_inv_ctp AS INTEGER), CAST(t.cien_inv_actual AS INTEGER),
         CAST(t.correctas_inv_ctp AS SMALLINT), CAST(t.erradas_inv_ctp AS SMALLINT), CAST(t.omitidas_inv_ctp AS SMALLINT)
  FROM traspaso t, ids WHERE CAST(t.forma_inv_ctp AS INTEGER) <> 0 AND NULLIF(TRIM(t.cien_inv_actual),'') IS NOT NULL AND CAST(t.cien_inv_actual AS INTEGER) BETWEEN 100 AND 1000

  -- ===== REGULAR ANTERIOR (sin detalle en la fuente -> valor por defecto 0) =====
  UNION ALL
  SELECT ids.r_reg_ant, ids.p_cl, CAST(t.mrun AS INTEGER),
         0, CAST(t.clec_reg_anterior AS INTEGER), 0, 0, 0
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.clec_reg_anterior),'') IS NOT NULL AND CAST(t.clec_reg_anterior AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.r_reg_ant, ids.p_m1, CAST(t.mrun AS INTEGER),
         0, CAST(t.mate1_reg_anterior AS INTEGER), 0, 0, 0
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.mate1_reg_anterior),'') IS NOT NULL AND CAST(t.mate1_reg_anterior AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.r_reg_ant, ids.p_m2, CAST(t.mrun AS INTEGER),
         0, CAST(t.mate2_reg_anterior AS INTEGER), 0, 0, 0
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.mate2_reg_anterior),'') IS NOT NULL AND CAST(t.mate2_reg_anterior AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.r_reg_ant, ids.p_hcs, CAST(t.mrun AS INTEGER),
         0, CAST(t.hcsoc_reg_anterior AS INTEGER), 0, 0, 0
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.hcsoc_reg_anterior),'') IS NOT NULL AND CAST(t.hcsoc_reg_anterior AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.r_reg_ant, ids.p_cien_gen, CAST(t.mrun AS INTEGER),
         0, CAST(t.cien_reg_anterior AS INTEGER), 0, 0, 0
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.cien_reg_anterior),'') IS NOT NULL AND CAST(t.cien_reg_anterior AS INTEGER) BETWEEN 100 AND 1000

  -- ===== INVIERNO ANTERIOR (sin detalle en la fuente -> valor por defecto 0) =====
  UNION ALL
  SELECT ids.r_inv_ant, ids.p_cl, CAST(t.mrun AS INTEGER),
         0, CAST(t.clec_inv_anterior AS INTEGER), 0, 0, 0
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.clec_inv_anterior),'') IS NOT NULL AND CAST(t.clec_inv_anterior AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.r_inv_ant, ids.p_m1, CAST(t.mrun AS INTEGER),
         0, CAST(t.mate1_inv_anterior AS INTEGER), 0, 0, 0
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.mate1_inv_anterior),'') IS NOT NULL AND CAST(t.mate1_inv_anterior AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.r_inv_ant, ids.p_m2, CAST(t.mrun AS INTEGER),
         0, CAST(t.mate2_inv_anterior AS INTEGER), 0, 0, 0
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.mate2_inv_anterior),'') IS NOT NULL AND CAST(t.mate2_inv_anterior AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.r_inv_ant, ids.p_hcs, CAST(t.mrun AS INTEGER),
         0, CAST(t.hcsoc_inv_anterior AS INTEGER), 0, 0, 0
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.hcsoc_inv_anterior),'') IS NOT NULL AND CAST(t.hcsoc_inv_anterior AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.r_inv_ant, ids.p_cien_gen, CAST(t.mrun AS INTEGER),
         0, CAST(t.cien_inv_anterior AS INTEGER), 0, 0, 0
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.cien_inv_anterior),'') IS NOT NULL AND CAST(t.cien_inv_anterior AS INTEGER) BETWEEN 100 AND 1000
)
INSERT INTO puntajesrendicionespruebasalumnos
  (idrendicionprueba, idprueba, mrut, forma, puntaje, correctas, erradas, omitidas)
SELECT DISTINCT ON (idrendicionprueba, idprueba, mrut)
  idrendicionprueba, idprueba, mrut, forma, puntaje, correctas, erradas, omitidas
FROM carga
WHERE EXISTS (SELECT 1 FROM postulantes p WHERE p.mrut = carga.mrut)
ON CONFLICT (idrendicionprueba, idprueba, mrut) DO NOTHING;


-- =====================================================================
-- SECCIÓN 8: puntajes_maximos
-- =====================================================================
-- CLEC_MAX / MATE1_MAX / MATE2_MAX / HCSOC_MAX / CIEN_MAX: el máximo
-- puntaje de cada prueba entre todas las rendiciones. Se usa la misma
-- clasificación de 4 pruebas + "Ciencias (proceso anterior...)" para
-- CIEN_MAX, ya que aquí tampoco se identifica el electivo.

WITH ids AS (
  SELECT
    (SELECT idprueba FROM pruebas WHERE nombreprueba = 'Competencia Lectora')          AS p_cl,
    (SELECT idprueba FROM pruebas WHERE nombreprueba = 'Competencia Matemática 1')     AS p_m1,
    (SELECT idprueba FROM pruebas WHERE nombreprueba = 'Competencia Matemática 2')     AS p_m2,
    (SELECT idprueba FROM pruebas WHERE nombreprueba = 'Historia y Ciencias Sociales') AS p_hcs,
    (SELECT idprueba FROM pruebas WHERE nombreprueba = 'Ciencias (proceso anterior, electivo no identificado en la fuente)') AS p_cien
),
carga AS (
  SELECT ids.p_cl AS idprueba, CAST(t.mrun AS INTEGER) AS mrut, CAST(t.clec_max AS INTEGER) AS ptje_maximo
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.clec_max),'') IS NOT NULL AND CAST(t.clec_max AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.p_m1, CAST(t.mrun AS INTEGER), CAST(t.mate1_max AS INTEGER)
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.mate1_max),'') IS NOT NULL AND CAST(t.mate1_max AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.p_m2, CAST(t.mrun AS INTEGER), CAST(t.mate2_max AS INTEGER)
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.mate2_max),'') IS NOT NULL AND CAST(t.mate2_max AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.p_hcs, CAST(t.mrun AS INTEGER), CAST(t.hcsoc_max AS INTEGER)
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.hcsoc_max),'') IS NOT NULL AND CAST(t.hcsoc_max AS INTEGER) BETWEEN 100 AND 1000

  UNION ALL
  SELECT ids.p_cien, CAST(t.mrun AS INTEGER), CAST(t.cien_max AS INTEGER)
  FROM traspaso t, ids WHERE NULLIF(TRIM(t.cien_max),'') IS NOT NULL AND CAST(t.cien_max AS INTEGER) BETWEEN 100 AND 1000
)
INSERT INTO puntajes_maximos (mrut_postulantes, idprueba_pruebas, ptje_maximo)
SELECT mrut, idprueba, ptje_maximo
FROM carga
WHERE EXISTS (SELECT 1 FROM postulantes p WHERE p.mrut = carga.mrut)
ON CONFLICT (mrut_postulantes, idprueba_pruebas) DO NOTHING;


-- =====================================================================
-- SECCIÓN 9: Validaciones finales
-- =====================================================================
-- Conteos por tabla: traspaso debe dar 320087; postulantes también
-- debería quedar en 320087 (ningún mrun es NULL/duplicado); las demás
-- deberían quedar acotadas por el número de valores distintos reales
-- (ej: regiones = 16, dependencias = 6, sexos = 2).

SELECT 'traspaso' AS tabla, count(*) AS filas FROM traspaso
UNION ALL SELECT 'postulantes', count(*) FROM postulantes
UNION ALL SELECT 'sexos', count(*) FROM sexos
UNION ALL SELECT 'ramaseducacionales', count(*) FROM ramaseducacionales
UNION ALL SELECT 'dependencias', count(*) FROM dependencias
UNION ALL SELECT 'tiposensenanza', count(*) FROM tiposensenanza
UNION ALL SELECT 'regiones', count(*) FROM regiones
UNION ALL SELECT 'provincias', count(*) FROM provincias
UNION ALL SELECT 'comunas', count(*) FROM comunas
UNION ALL SELECT 'establecimientos', count(*) FROM establecimientos
UNION ALL SELECT 'tiposensenanza_establecimientos', count(*) FROM tiposensenanza_establecimientos
UNION ALL SELECT 'rendicionespruebas', count(*) FROM rendicionespruebas
UNION ALL SELECT 'pruebas', count(*) FROM pruebas
UNION ALL SELECT 'puntajesrendicionespruebasalumnos', count(*) FROM puntajesrendicionespruebasalumnos
UNION ALL SELECT 'puntajes_maximos', count(*) FROM puntajes_maximos;

-- Chequeos de calidad adicionales, útiles para justificar el manejo
-- de inconsistencias en el informe:

-- (a) Postulantes sin establecimiento informado (RBD vacío en el CSV):
--     deben ser 3.200 y no deben tener fila en tiposensenanza_establecimientos.
SELECT count(*) AS postulantes_sin_rbd
FROM traspaso
WHERE NULLIF(TRIM(rbd), '') IS NULL;

-- (b) RBD con más de un nombre/dependencia distinto en el CSV
--     (para documentar en el informe cómo se resolvió: se tomó el
--     registro con el ANYO_DE_EGRESO más reciente).
SELECT rbd, count(DISTINCT TRIM(nombre_unidad_educ)) AS nombres_distintos,
       count(DISTINCT NULLIF(TRIM(dependencia), '')) AS dependencias_distintas
FROM traspaso
WHERE NULLIF(TRIM(rbd), '') IS NOT NULL
GROUP BY rbd
HAVING count(DISTINCT TRIM(nombre_unidad_educ)) > 1
    OR count(DISTINCT NULLIF(TRIM(dependencia), '')) > 1;
