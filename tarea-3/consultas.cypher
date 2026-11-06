 // ==========================================
 // TAREA 3 - NEO4J Y ANALISIS DE GRAFOS
 // ==========================================

 // CONFIGURACION Y VERIFICACION

 // Verificar version de GDS
 RETURN gds.version() AS versionGDS;

 // Verificar cantidad de estudiantes
 MATCH (e:Estudiante)
 RETURN count(e) AS estudiantes;

 // Verificar cantidad de casas
 MATCH (c:Casa)
 RETURN count(c) AS casas;

 // Verificar cantidad de visitas
 MATCH (:Estudiante)-[r:PIDIO_DULCES]->(:Casa)
 RETURN count(r) AS visitas;


 // ==========================================
 // PARTE 1: EXPLORACION Y CONSULTAS CYPHER
 // ==========================================

 // EJERCICIO 1: Visualizacion del grafo

 MATCH (e:Estudiante)-[r:PIDIO_DULCES]->(c:Casa)
 RETURN e, r, c;

// EJERCICIO 2: Ranking de casas e identificacion de maximos

// Ranking de casas
MATCH (c:Casa)
OPTIONAL MATCH (:Estudiante)-[r:PIDIO_DULCES]->(c)
RETURN
    c.id AS id,
    c.direccion AS direccion,
    count(r) AS visitas
ORDER BY visitas DESC, id ASC;

// EJERCICIO 3: Ranking de estudiantes por cantidad total de dulces
MATCH (e:Estudiante)
OPTIONAL MATCH (e)-[r:PIDIO_DULCES]->(:Casa)
RETURN
    e.id AS estudiante,
    count(r) AS visitas,
    coalesce(sum(r.cantidad), 0) AS total_dulces
ORDER BY total_dulces DESC, estudiante ASC;

// EJERCICIO 4: Visitas sin dulces

// Relaciones donde la cantidad es 0
MATCH (e:Estudiante)-[r:PIDIO_DULCES]->(c:Casa)
WHERE r.cantidad = 0
RETURN
    e.id AS estudiante,
    c.direccion AS direccion,
    r.tipo AS tipo
ORDER BY estudiante ASC, direccion ASC;

// Cantidad y porcentaje
MATCH (:Estudiante)-[r:PIDIO_DULCES]->(:Casa)
RETURN
    count(r) AS total_visitas,
    count(CASE WHEN r.cantidad = 0 THEN 1 END) AS visitas_sin_dulces,
    round(
        100.0 * count(CASE WHEN r.cantidad = 0 THEN 1 END) / count(r),
        2
    ) AS porcentaje_sin_dulces;


// ==========================================
// PARTE 2: ANALISIS CON GRAPH DATA SCIENCE
// ==========================================

 // EJERCICIO 1: Proyeccion del grafo en memoria

 // Crear proyeccion halloween
 CALL gds.graph.project(
     'halloween',
     ['Estudiante', 'Casa'],
     {
         PIDIO_DULCES: {
             orientation: 'NATURAL'
         }
     }
 )
 YIELD graphName, nodeCount, relationshipCount
 RETURN graphName, nodeCount, relationshipCount;


// EJERCICIO 2: Centralidad de grado

// Calcular grado de entrada de las casas con GDS
CALL gds.degree.stream('halloween', {
    orientation: 'REVERSE'
})
YIELD nodeId, score
WITH gds.util.asNode(nodeId) AS nodo, score
WHERE nodo:Casa
RETURN
    nodo.id AS id,
    nodo.direccion AS direccion,
    score AS grado_entrada
ORDER BY grado_entrada DESC, id ASC;


// EJERCICIO 3: Similitud de Jaccard entre estudiantes

CALL gds.nodeSimilarity.stream('halloween', {
    similarityMetric: 'JACCARD',
    topK: 14,
    similarityCutoff: 0.0001
})
YIELD node1, node2, similarity
WITH
    gds.util.asNode(node1) AS a,
    gds.util.asNode(node2) AS b,
    similarity
WHERE a:Estudiante AND b:Estudiante
WITH
    CASE WHEN a.id < b.id THEN a.id ELSE b.id END AS estudiante1,
    CASE WHEN a.id < b.id THEN b.id ELSE a.id END AS estudiante2,
    similarity
RETURN DISTINCT
    estudiante1,
    estudiante2,
    similarity AS jaccard
ORDER BY jaccard DESC, estudiante1 ASC, estudiante2 ASC
LIMIT 5;

// Verificar las casas visitadas por Isidora y Nicolas
MATCH (e:Estudiante)-[:PIDIO_DULCES]->(c:Casa)
WHERE e.id IN ['Isidora', 'Nicolás']
RETURN
    c.id AS casa_id,
    c.direccion AS direccion,
    collect(e.id) AS estudiantes
ORDER BY casa_id;


// ==========================================
// PARTE 3: CAMINOS EN EL GRAFO
// ==========================================

// EJERCICIO 1: Caminos entre estudiantes

// Visualizar las casas compartidas por Isidora y Nicolas
MATCH (a:Estudiante {id: 'Isidora'})
      -[r1:PIDIO_DULCES]->
      (c:Casa)
      <-[r2:PIDIO_DULCES]-
      (b:Estudiante {id: 'Nicolás'})
RETURN a, r1, c, r2, b;


// EJERCICIO 2: Camino mas corto

// Obtener el camino minimo entre Isidora y Nicolas
MATCH (a:Estudiante {id: 'Isidora'})
WITH a
MATCH (b:Estudiante {id: 'Nicolás'})
OPTIONAL MATCH p = shortestPath(
    (a)-[:PIDIO_DULCES*1..24]-(b)
)
RETURN
    p,
    length(p) AS longitud,
    nodes(p) AS recorrido;


// ==========================================
// PARTE 4: CIERRE
// ==========================================

// EJERCICIO 2: Liberar la proyeccion

// Eliminar la proyeccion halloween de memoria
CALL gds.graph.drop('halloween', false)
YIELD graphName
RETURN graphName;

// Verificar que la proyeccion ya no existe
CALL gds.graph.exists('halloween')
YIELD exists
RETURN exists;




