# Tarea 1 — MongoDB

Este directorio contiene la configuración necesaria para ejecutar la base de datos MongoDB utilizada en la Tarea 1.

La infraestructura utiliza **Docker Compose** para levantar un Replica Set de MongoDB compuesto por tres nodos.

## Requisitos

Para ejecutar el proyecto se requiere:

- Docker Desktop
- Docker Compose
- MongoDB Compass
- `make` (opcional, recomendado)

En Windows se recomienda utilizar Docker Desktop con WSL2.

## Estructura

```text
tarea-1/
├── data/
│   └── voice_actors.json
├── evidence/
├── docker-compose.yml
├── Makefile
└── README.md
```

El archivo `data/voice_actors.json` contiene los documentos utilizados para crear la colección de actores y actrices de voz.

## 1. Levantar MongoDB

Desde el directorio `tarea-1` ejecutar:

```bash
make up
```

Equivalentemente:

```bash
docker compose up -d
```

Esto levanta tres nodos MongoDB:

| Nodo | Puerto |
|---|---:|
| `mongo1` | `30001` |
| `mongo2` | `30002` |
| `mongo3` | `30003` |

Los tres nodos forman el Replica Set:

```text
my-replica-set
```

Para comprobar el estado de los contenedores:

```bash
make ps
```

También puede revisarse el estado del Replica Set mediante:

```bash
make status
```

## 2. Configuración adicional en Windows

El Replica Set identifica internamente sus miembros mediante los nombres:

```text
mongo1
mongo2
mongo3
```

Docker puede resolver estos nombres dentro de su propia red. Sin embargo, al conectarse desde MongoDB Compass en Windows puede producirse un error similar a:

```text
getaddrinfo ENOTFOUND mongo1
```

Esto ocurre porque Windows no conoce inicialmente los nombres utilizados internamente por el Replica Set.

### Solución

Abrir como administrador el archivo:

```text
C:\Windows\System32\drivers\etc\hosts
```

y agregar:

```text
# MongoDB local replica set
127.0.0.1 mongo1
127.0.0.1 mongo2
127.0.0.1 mongo3
```

Guardar el archivo.

De esta manera, Windows puede resolver los nombres anunciados por el Replica Set hacia `localhost`, donde Docker Desktop expone los respectivos puertos.

## 3. Conexión mediante MongoDB Compass

Con los contenedores ejecutándose, utilizar la siguiente cadena de conexión:

```text
mongodb://localhost:30001,localhost:30002,localhost:30003/?replicaSet=my-replica-set
```

MongoDB Compass debería detectar automáticamente el nodo primario y los nodos secundarios.

## 4. Crear la base de datos y colección

Abrir una sesión de `mongosh` en uno de los nodos. Por ejemplo:

```bash
make shell1
```

Luego ejecutar:

```javascript
use Actors
db.createCollection("Voice-actors")
```

Para comprobar la creación:

```javascript
show collections
```

## 5. Importar los datos

El archivo:

```text
data/voice_actors.json
```

contiene los datos iniciales de la colección.

Primero copiar el archivo al contenedor:

```bash
docker cp data/voice_actors.json mongo1:/tmp/voice_actors.json
```

Luego importar los documentos:

```bash
docker exec -it mongo1 mongoimport \
  --port 30001 \
  --db Actors \
  --collection Voice-actors \
  --file /tmp/voice_actors.json \
  --jsonArray
```

Para verificar la importación:

```bash
make shell1
```

y posteriormente:

```javascript
use Actors
db["Voice-actors"].countDocuments()
```

El resultado esperado es:

```text
24
```

## 6. Comandos disponibles

El `Makefile` proporciona comandos para facilitar la administración del entorno.

### Iniciar los contenedores

```bash
make up
```

### Detener los contenedores

```bash
make down
```

### Reiniciar

```bash
make restart
```

### Ver estado

```bash
make ps
```

### Abrir `mongosh` en cada nodo

```bash
make shell1
make shell2
make shell3
```

### Revisar el Replica Set

```bash
make status
```

### Ver logs

```bash
make logs
```

También pueden revisarse individualmente:

```bash
make logs-mongo1
make logs-mongo2
make logs-mongo3
```

## 7. Prueba de tolerancia a fallos

Para identificar el nodo primario, conectarse a cualquiera de los nodos:

```bash
docker exec -it mongo1 mongosh --port 30001
```

y ejecutar:

```javascript
db.hello()
```

El nodo que muestre:

```text
isWritablePrimary: true
```

corresponde al primario actual.

Para simular su caída, detener el contenedor correspondiente. Por ejemplo:

```bash
docker stop mongo2
```

Los dos nodos restantes conservan la mayoría necesaria para realizar una nueva elección, permitiendo que uno de los secundarios se convierta en el nuevo primario.

El nodo detenido puede reincorporarse posteriormente mediante:

```bash
docker start mongo2
```

## 8. Detener el entorno

Al terminar:

```bash
make down
```

Los datos almacenados en los volúmenes de Docker se conservan.

Para eliminar también los volúmenes:

```bash
make clean
```

> **Advertencia:** `make clean` elimina los volúmenes de MongoDB y, por lo tanto, los datos almacenados en ellos.

## Nota sobre almacenamiento en Windows/WSL2

Inicialmente se utilizaron bind mounts hacia directorios ubicados bajo `/mnt/c/...`. Esto produjo errores de permisos de WiredTiger al intentar crear archivos de la base de datos.

Para evitar este problema, la configuración utiliza **volúmenes administrados por Docker** para `/data/db` en cada nodo. De esta forma, el código y el dataset pueden permanecer en el sistema de archivos de Windows mientras que los archivos internos de MongoDB son administrados por Docker.