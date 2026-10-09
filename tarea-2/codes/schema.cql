-- Datacenter confirmado con SELECT data_center FROM system.local.
-- No crear los indices todavia: primero realizar la Parte 2.2 sin indices.
CREATE KEYSPACE IF NOT EXISTS actors
WITH replication = {'class': 'NetworkTopologyStrategy', 'datacenter1': 3};
USE actors;

CREATE TABLE IF NOT EXISTS actores_por_id (
    actor_id uuid PRIMARY KEY,
    nombre text,
    nacionalidad text,
    fecha_nacimiento date,
    edad int,
    patrimonio decimal,
    idiomas set<text>
);

CREATE TABLE IF NOT EXISTS actores_por_nacionalidad (
    nacionalidad text,
    edad int,
    actor_id uuid,
    nombre text,
    fecha_nacimiento date,
    patrimonio decimal,
    idiomas set<text>,
    PRIMARY KEY ((nacionalidad), edad, actor_id)
) WITH CLUSTERING ORDER BY (edad ASC, actor_id ASC);

CREATE TABLE IF NOT EXISTS personajes_por_actor (
    actor_id uuid,
    rol text,
    apariciones int,
    personaje_id uuid,
    nombre_personaje text,
    produccion text,
    tipo_produccion text,
    generos set<text>,
    PRIMARY KEY ((actor_id), rol, apariciones, personaje_id)
) WITH CLUSTERING ORDER BY (rol ASC, apariciones DESC, personaje_id ASC);

-- Tabla auxiliar: escrituras de prueba, sin agregar actores incompletos al conjunto.
CREATE TABLE IF NOT EXISTS pruebas_disponibilidad (
    prueba_id text PRIMARY KEY,
    detalle text
);
