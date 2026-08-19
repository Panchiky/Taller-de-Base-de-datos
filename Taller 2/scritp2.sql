CREATE TABLE REGIONES
(
  codigoregion INT NOT NULL,
  region VARCHAR(255) NOT NULL UNIQUE,
  PRIMARY KEY (codigoregion)
);
CREATE TABLE PROVINCIAS
(
  codigoprovincia INT NOT NULL,
  provincias VARCHAR(255) NOT NULL UNIQUE,
  codigoregion INT NOT NULL,
  PRIMARY KEY (codigoprovincia),
  FOREIGN KEY (codigoregion) REFERENCES REGIONES(codigoregion)
);
CREATE TABLE COMUNAS
(
  codigocomuna INT NOT NULL,
  comunas VARCHAR(255) NOT NULL UNIQUE,
  codigoprovincia INT NOT NULL,
  PRIMARY KEY (codigocomuna),
  FOREIGN KEY (codigoprovincia) REFERENCES PROVINCIAS(codigoprovincia)
);
CREATE TABLE DEPENDENCIAS
(
  codigodependencia INT NOT NULL,
  dependencia VARCHAR(255) NOT NULL UNIQUE,
  PRIMARY KEY (codigodependencia)
);
CREATE TABLE RAMASEDUCACIONALES
(
  codigoramaeducacional CHAR(2) NOT NULL,
  ramaeducacional VARCHAR(255) NOT NULL UNIQUE,
  PRIMARY KEY (codigoramaeducacional)
);
CREATE TABLE SEXOS
(
  cod_sexo INT NOT NULL,
  sexo VARCHAR(255) NOT NULL UNIQUE,
  PRIMARY KEY (cod_sexo)
);
CREATE TABLE RENDICIONESPRUEBAS
(
  idrendicionprueba SERIAL,
  rendicionprueba VARCHAR(255) NOT NULL UNIQUE,
  PRIMARY KEY (idrendicionprueba)
);
CREATE TABLE ESTABLECIMIENTOS
(
  rbd INT NOT NULL,
  nombre_unidad_educativa VARCHAR(255) NOT NULL,
  codigocomuna INT NOT NULL,
  codigodependencia INT NOT NULL,
  PRIMARY KEY (rbd),
  FOREIGN KEY (codigocomuna) REFERENCES COMUNAS(codigocomuna),
  FOREIGN KEY (codigodependencia) REFERENCES DEPENDENCIAS(codigodependencia)
);
CREATE TABLE TIPOSENSENANZA
(
  codigo_ens INT NOT NULL,
  tipoensenanza VARCHAR(255) NOT NULL UNIQUE,
  PRIMARY KEY (codigo_ens)
);
CREATE TABLE TIPOSENSENANZA_ESTABLECIMIENTOS
(
  codigo_ens_tiposensenanza INT NOT NULL,
  codigoramaeducacional CHAR(2) NOT NULL,
  rbd_establecimientos INT NOT NULL,
  PRIMARY KEY (codigo_ens_tiposensenanza, codigoramaeducacional, rbd_establecimientos),
  FOREIGN KEY (codigo_ens_tiposensenanza) REFERENCES TIPOSENSENANZA(codigo_ens),
  FOREIGN KEY (codigoramaeducacional) REFERENCES RAMASEDUCACIONALES(codigoramaeducacional),
  FOREIGN KEY (rbd_establecimientos) REFERENCES ESTABLECIMIENTOS(rbd)
);
CREATE TABLE POSTULANTES
(
  mrut INT NOT NULL,
  fecha_nacimiento DATE NOT NULL,
  anoegreso DATE NOT NULL,
  promedio FLOAT NOT NULL CHECK (promedio >= 1.0 AND promedio <= 7.0), 
  ptjenem INT NOT NULL CHECK (ptjenem >= 0),
  porc_sup_not INT NOT NULL CHECK (porc_sup_not >= 0 AND porc_sup_not <= 100),
  ptjeranking INT NOT NULL CHECK (ptjeranking >= 0),
  codigo_ens INT NOT NULL,
  codigoramaeducacional CHAR(2) NOT NULL,
  rbd_establecimientos INT NOT NULL,
  cod_sexo INT NOT NULL,
  PRIMARY KEY (mrut),
  FOREIGN KEY (codigo_ens, codigoramaeducacional, rbd_establecimientos) REFERENCES TIPOSENSENANZA_ESTABLECIMIENTOS(codigo_ens_tiposensenanza, codigoramaeducacional, rbd_establecimientos),
  FOREIGN KEY (cod_sexo) REFERENCES SEXOS(cod_sexo)
);
CREATE TABLE PRUEBAS
(
  idprueba SERIAL,
  nombreprueba VARCHAR(255) NOT NULL,
  PRIMARY KEY (idprueba)
);
CREATE TABLE PUNTAJESRENDICIONESPRUEBASALUMNOS
(
  f_prueba_reg_cl VARCHAR(255) NOT NULL,
  forma INT NOT NULL,
  puntaje INT NOT NULL CHECK (puntaje >= 0),
  correctas SMALLINT NOT NULL CHECK (correctas >= 0),
  erradas SMALLINT NOT NULL CHECK (erradas >= 0),
  omitidas SMALLINT NOT NULL CHECK (omitidas >= 0),
  idrendicionprueba INT NOT NULL,
  mrut INT NOT NULL,
  idprueba INT NOT NULL,
  PRIMARY KEY (idrendicionprueba, mrut, idprueba),
  FOREIGN KEY (idrendicionprueba) REFERENCES RENDICIONESPRUEBAS(idrendicionprueba),
  FOREIGN KEY (mrut) REFERENCES POSTULANTES(mrut),
  FOREIGN KEY (idprueba) REFERENCES PRUEBAS(idprueba)
);
CREATE TABLE PUNTAJES_MAXIMOS
(
  ptje_maximo INT NOT NULL CHECK (ptje_maximo >= 0),
  idprueba_pruebas INT NOT NULL,
  mrut_postulantes INT NOT NULL,
  PRIMARY KEY (idprueba_pruebas, mrut_postulantes),
  FOREIGN KEY (idprueba_pruebas) REFERENCES PRUEBAS(idprueba),
  FOREIGN KEY (mrut_postulantes) REFERENCES POSTULANTES(mrut)
);
