CREATE TABLE sexos (
  cod_sexo INTEGER NOT NULL,
  sexo VARCHAR(255) NOT NULL,
  PRIMARY KEY (cod_sexo)
);

CREATE TABLE postulantes (
  mrut INTEGER NOT NULL,
  fecha_nacimiento DATE NOT NULL,
  cod_sexo INTEGER NOT NULL,
  anoegreso DATE NOT NULL,
  promedio NUMERIC(1,2) NOT NULL CHECK (promedio between 1.0 and 7.0),
  ptjenem INTEGER NOT NULL CHECK (ptjenem between 1 and 7),
  porc_sup_not INTEGER NOT NULL,
  ptjeranking INTEGER NOT NULL CHECK (ptjeranking between 100 and 1000),
  PRIMARY KEY (mrut)
);

CREATE TABLE tiposensenanza (
  codigo_ens INTEGER NOT NULL,
  tipoensenanza VARCHAR(80) NOT NULL,
  PRIMARY KEY (codigo_ens),
  UNIQUE (tipoensenanza)
);

CREATE TABLE ramaseducacionales (
  codigoramaeducacional CHAR(2) NOT NULL,
  ramaeducacional VARCHAR(255) NOT NULL,
  PRIMARY KEY (codigoramaeducacional)
);

CREATE TABLE dependencias (
  codigodependencia INTEGER NOT NULL,
  dependencia VARCHAR(40) NOT NULL,
  PRIMARY KEY (codigodependencia),
  UNIQUE (dependencia)
);

CREATE TABLE regiones (
  codigoregion INTEGER NOT NULL,
  region VARCHAR(50) NOT NULL,
  PRIMARY KEY (codigoregion),
  UNIQUE (region)
);

CREATE TABLE provincias (
  codigoprovincia INTEGER NOT NULL,
  provincias VARCHAR(30) NOT NULL,
  codigoregion INTEGER NOT NULL,
  PRIMARY KEY (codigoprovincia),
  UNIQUE (provincias)
);

CREATE TABLE comunas (
  codigocomuna INTEGER NOT NULL,
  comuna VARCHAR(30) NOT NULL,
  codigoprovincia INTEGER NOT NULL,
  PRIMARY KEY (codigocomuna),
  UNIQUE (comunas)
);

CREATE TABLE establecimientos (
  rbd INTEGER NOT NULL,
  nombre_unidad_educativa VARCHAR(100) NOT NULL,
  codigodependencia INTEGER,
  codigocomuna INTEGER NOT NULL,
  PRIMARY KEY (rbd)
);

CREATE TABLE tiposensenanza_establecimientos (
  codigo_ens_tiposensenanza INTEGER NOT NULL,
  rbd_establecimientos INTEGER NOT NULL,
  codigoramaeducacional CHAR(2) NOT NULL,
  PRIMARY KEY (codigo_ens_tiposensenanza, rbd_establecimientos, codigoramaeducacional)
);

CREATE TABLE rendicionespruebas (
  idrendicionprueba INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL,
  rendicionprueba VARCHAR(255) NOT NULL,
  PRIMARY KEY (idrendicionprueba)
);

CREATE TABLE pruebas (
  idprueba INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL,
  nombreprueba VARCHAR(255) NOT NULL,
  PRIMARY KEY (idprueba)
);

CREATE TABLE puntajesrendicionespruebasalumnos (
  idrendicionprueba INTEGER NOT NULL,
  idprueba INTEGER NOT NULL,
  mrut INTEGER NOT NULL,
  forma INTEGER NOT NULL,
  puntaje INTEGER NOT NULL CHECK (puntaje between 100 and 1000),
  correctas SMALLINT NOT NULL,
  erradas SMALLINT NOT NULL,
  omitidas SMALLINT NOT NULL,
  PRIMARY KEY (idrendicionprueba, idprueba, mrut)
);

CREATE TABLE puntajes_maximos (
  mrut_postulantes INTEGER NOT NULL,
  idprueba_pruebas INTEGER NOT NULL,
  ptje_maximo INTEGER NOT NULL CHECK (ptje_maximo between 100 and 1000),
  PRIMARY KEY (mrut_postulantes, idprueba_pruebas)
);

-- Foreign Key Constraints
ALTER TABLE postulantes ADD CONSTRAINT fk_postulantes_cod_sexo FOREIGN KEY (cod_sexo) REFERENCES sexos(cod_sexo) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE provincias ADD CONSTRAINT fk_provincias_codigoregion FOREIGN KEY (codigoregion) REFERENCES regiones(codigoregion) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE comunas ADD CONSTRAINT fk_comunas_codigoprovincia FOREIGN KEY (codigoprovincia) REFERENCES provincias(codigoprovincia) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE establecimientos ADD CONSTRAINT fk_establecimientos_codigodependencia FOREIGN KEY (codigodependencia) REFERENCES dependencias(codigodependencia) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE establecimientos ADD CONSTRAINT fk_establecimientos_codigocomuna FOREIGN KEY (codigocomuna) REFERENCES comunas(codigocomuna) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE tiposensenanza_establecimientos ADD CONSTRAINT fk_tiposensenanza_establecimientos_codigo_ens_tiposensenanza FOREIGN KEY (codigo_ens_tiposensenanza) REFERENCES tiposensenanza(codigo_ens) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE tiposensenanza_establecimientos ADD CONSTRAINT fk_tiposensenanza_establecimientos_rbd_establecimientos FOREIGN KEY (rbd_establecimientos) REFERENCES establecimientos(rbd) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE tiposensenanza_establecimientos ADD CONSTRAINT fk_tiposensenanza_establecimientos_codigoramaeducacional FOREIGN KEY (codigoramaeducacional) REFERENCES ramaseducacionales(codigoramaeducacional) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE puntajesrendicionespruebasalumnos ADD CONSTRAINT fk_puntajesrendicionespruebasalumnos_idrendicionprueba FOREIGN KEY (idrendicionprueba) REFERENCES rendicionespruebas(idrendicionprueba) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE puntajesrendicionespruebasalumnos ADD CONSTRAINT fk_puntajesrendicionespruebasalumnos_idprueba FOREIGN KEY (idprueba) REFERENCES pruebas(idprueba) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE puntajesrendicionespruebasalumnos ADD CONSTRAINT fk_puntajesrendicionespruebasalumnos_mrut FOREIGN KEY (mrut) REFERENCES postulantes(mrut) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE puntajes_maximos ADD CONSTRAINT fk_puntajes_maximos_mrut_postulantes FOREIGN KEY (mrut_postulantes) REFERENCES postulantes(mrut) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE puntajes_maximos ADD CONSTRAINT fk_puntajes_maximos_idprueba_pruebas FOREIGN KEY (idprueba_pruebas) REFERENCES pruebas(idprueba) ON DELETE CASCADE ON UPDATE CASCADE;
