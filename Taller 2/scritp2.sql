CREATE TABLE REGIONES
(
  codigoregion INT NOT NULL,
  region VARCHAR(255) NOT NULL UNIQUE,
  CONSTRAINT pk_region PRIMARY KEY (codigoregion)
);
CREATE TABLE PROVINCIAS
(
  codigoprovincia INT NOT NULL,
  provincias VARCHAR(255) NOT NULL UNIQUE,
  codigoregion INT NOT NULL,
  CONSTRAINT pk_provincias PRIMARY KEY (codigoprovincia),
  CONSTRAINT fk_provincias_regiones FOREIGN KEY (codigoregion) REFERENCES REGIONES(codigoregion)
);
CREATE TABLE COMUNAS
(
  codigocomuna INT NOT NULL,
  comunas VARCHAR(255) NOT NULL UNIQUE,
  codigoprovincia INT NOT NULL,
  CONSTRAINT pk_comunas PRIMARY KEY (codigocomuna),
  CONSTRAINT fk_comunas_provincias FOREIGN KEY (codigoprovincia) REFERENCES PROVINCIAS(codigoprovincia)
);
CREATE TABLE DEPENDENCIAS
(
  codigodependencia INT NOT NULL,
  dependencia VARCHAR(255) NOT NULL UNIQUE,
  CONSTRAINT pk_dependencias PRIMARY KEY (codigodependencia)
);
CREATE TABLE RAMASEDUCACIONALES
(
  codigoramaeducacional CHAR(2) NOT NULL,
  ramaeducacional VARCHAR(255) NOT NULL UNIQUE,
  CONSTRAINT pk_ramaseducacionales PRIMARY KEY (codigoramaeducacional)
);
CREATE TABLE SEXOS
(
  cod_sexo INT NOT NULL,
  sexo VARCHAR(255) NOT NULL UNIQUE,
  CONSTRAINT pk_sexos PRIMARY KEY (cod_sexo)
);
CREATE TABLE RENDICIONESPRUEBAS
(
  idrendicionprueba SERIAL NOT NULL,
  rendicionprueba VARCHAR(255) NOT NULL UNIQUE,
  CONSTRAINT pk_rendicionespruebas PRIMARY KEY (idrendicionprueba)
);
CREATE TABLE ESTABLECIMIENTOS
(
  rbd INT NOT NULL,
  nombre_unidad_educativa VARCHAR(255) NOT NULL,
  codigocomuna INT NOT NULL,
  codigodependencia INT NOT NULL,
  CONSTRAINT pk_establecimiento PRIMARY KEY (rbd),
  CONSTRAINT fk_establecimientos_comunas FOREIGN KEY (codigocomuna) REFERENCES COMUNAS(codigocomuna),
  CONSTRAINT fk_establecimientos_dependencia FOREIGN KEY (codigodependencia) REFERENCES DEPENDENCIAS(codigodependencia)
);
CREATE TABLE TIPOSENSENANZA
(
  codigo_ens INT NOT NULL,
  tipoensenanza VARCHAR(255) NOT NULL UNIQUE,
  CONSTRAINT pk_tipoensenanza PRIMARY KEY (codigo_ens)
);
CREATE TABLE TIPOSENSENANZA_ESTABLECIMIENTOS
(
  codigo_ens_tiposensenanza INT NOT NULL,
  codigoramaeducacional CHAR(2) NOT NULL,
  rbd_establecimientos INT NOT NULL,
  CONSTRAINT pk_tipoensenanza_establecimientos PRIMARY KEY (codigo_ens_tiposensenanza, codigoramaeducacional, rbd_establecimientos),
  CONSTRAINT fk_tiposensenanza_establecimientos_tipos FOREIGN KEY (codigo_ens_tiposensenanza) REFERENCES TIPOSENSENANZA(codigo_ens),
  CONSTRAINT fk_tiposensenanza_establecimientos_ramas FOREIGN KEY (codigoramaeducacional) REFERENCES RAMASEDUCACIONALES(codigoramaeducacional),
  CONSTRAINT fk_tiposensenanza_establecimientos_establecimientos FOREIGN KEY (rbd_establecimientos) REFERENCES ESTABLECIMIENTOS(rbd)
);
CREATE TABLE POSTULANTES
(
  mrut INT NOT NULL,
  fecha_nacimiento DATE NOT NULL,
  anoegreso DATE NOT NULL,
  promedio FLOAT NOT NULL, 
  ptjenem INT NOT NULL, 
  porc_sup_not INT NOT NULL, 
  ptjeranking INT NOT NULL,
  codigo_ens INT NOT NULL,
  codigoramaeducacional CHAR(2) NOT NULL,
  rbd_establecimientos INT NOT NULL,
  cod_sexo INT NOT NULL,
  CONSTRAINT pk_postulantes PRIMARY KEY (mrut),
  CONSTRAINT fk_postulantes_tiposensenanza_establecimientos FOREIGN KEY (codigo_ens, codigoramaeducacional, rbd_establecimientos) REFERENCES TIPOSENSENANZA_ESTABLECIMIENTOS(codigo_ens_tiposensenanza, codigoramaeducacional, rbd_establecimientos),
  CONSTRAINT fk_postulantes_sexos FOREIGN KEY (cod_sexo) REFERENCES SEXOS(cod_sexo),
  CONSTRAINT chk_postulantes_ptjenem CHECK (ptjenem >= 0),
  CONSTRAINT chk_postulantes_porc_sup_not CHECK (porc_sup_not >= 0 AND porc_sup_not <= 100),
  CONSTRAINT chk_postulantes_ptjeranking CHECK (ptjeranking >= 0)
);
CREATE TABLE PRUEBAS
(
  idprueba SERIAL NOT NULL,
  nombreprueba VARCHAR(255) NOT NULL,
  CONSTRAINT pk_puebas PRIMARY KEY (idprueba)
);
CREATE TABLE PUNTAJESRENDICIONESPRUEBASALUMNOS
(
  f_prueba_reg_cl VARCHAR(255) NOT NULL,
  forma INT NOT NULL,
  puntaje INT NOT NULL, 
  correctas SMALLINT NOT NULL,
  erradas SMALLINT NOT NULL,
  omitidas SMALLINT NOT NULL, 
  idrendicionprueba INT NOT NULL,
  mrut INT NOT NULL,
  idprueba INT NOT NULL,
  CONSTRAINT pk_puntajes_rendiciones_pruebas_alumnos PRIMARY KEY (idrendicionprueba, mrut, idprueba),
  CONSTRAINT fk_puntajes_rendiciones FOREIGN KEY (idrendicionprueba) REFERENCES RENDICIONESPRUEBAS(idrendicionprueba),
  CONSTRAINT fk_puntajes_postulantes FOREIGN KEY (mrut) REFERENCES POSTULANTES(mrut),
  CONSTRAINT fk_puntajes_pruebas FOREIGN KEY (idprueba) REFERENCES PRUEBAS(idprueba)
  CONSTRAINT chk_puntajes_puntaje CHECK (puntaje >= 0),
  CONSTRAINT chk_puntajes_correctas CHECK (correctas >= 0),
  CONSTRAINT chk_puntajes_erradas CHECK (erradas >= 0),
  CONSTRAINT chk_puntajes_omitidas CHECK (omitidas >= 0)
);
CREATE TABLE PUNTAJES_MAXIMOS
(
  ptje_maximo INT NOT NULL,
  idprueba_pruebas INT NOT NULL,
  mrut_postulantes INT NOT NULL,
  CONSTRAINT pk_puntajes_maximos PRIMARY KEY (idprueba_pruebas, mrut_postulantes),
  CONSTRAINT fk_puntajes_maximos_pruebas FOREIGN KEY (idprueba_pruebas) REFERENCES PRUEBAS(idprueba),
  CONSTRAINT fk_puntajes_maximos_postulantes FOREIGN KEY (mrut_postulantes) REFERENCES POSTULANTES(mrut),
  CONSTRAINT chk_puntajes_maximos CHECK (ptje_maximo >= 0)
);
