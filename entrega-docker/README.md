# Entrega proyecto 1: Docker con dos contenedores comunicados

Proyecto de Integración Continua (Escenario 3). Dos contenedores que se comunican
dentro de una red propia de Docker:

| Servicio | Contenedor | Papel | Imagen |
|----------|-----------|-------|--------|
| `app` | `notas-app` | API REST de notas (Node.js 22 + Express) | `node:22.11.0-alpine3.20` (Dockerfile propio) |
| `db`  | `notas-db`  | Base de datos PostgreSQL con volumen persistente | `postgres:16.4-alpine3.20` |

La API se conecta a la base de datos con el **nombre del servicio `db`** (variable
`DB_HOST=db`), que el DNS interno de Docker resuelve dentro de la red `red-notas`.
No se usa `localhost` ni ninguna IP fija.

## Arquitectura

```
            Usuario / curl / navegador
                      │  http://localhost:3000
                      ▼
 ┌──────────────── red-notas (bridge) ────────────────┐
 │                                                    │
 │  ┌───────────────┐   host "db":5432   ┌──────────┐ │
 │  │  app          │ ─────────────────▶ │  db      │ │
 │  │  notas-app    │ ◀───────────────── │ notas-db │ │
 │  │  Node/Express │   filas (SQL)      │ Postgres │ │
 │  └───────────────┘                    └────┬─────┘ │
 └────────────────────────────────────────────┼───────┘
                                              ▼
                                   volumen datos-postgres
```

## Estructura del repositorio

```
.
├── app/                     # Contenedor 1: la aplicación
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── package.json
│   ├── package-lock.json
│   └── src/index.js
├── db/                      # Contenedor 2: la base de datos
│   └── init.sql             # crea la tabla "notas"
├── scripts/
│   ├── prueba-comunicacion.sh   # prueba ida y vuelta (Linux/macOS/Git Bash)
│   └── prueba-comunicacion.ps1  # prueba ida y vuelta (Windows PowerShell)
├── docker-compose.yml
├── .dockerignore
├── .env.example             # plantilla de variables (el .env real NO se sube)
├── .gitignore
├── docs/guia-evidencias.md # guía del PDF de evidencias
└── README.md
```

El pipeline de CI está en la raíz del repositorio: `.github/workflows/docker-ci.yml`.

## Requisitos

- Docker Desktop (o Docker Engine) con Docker Compose v2.
- Git.

## Cómo levantar los contenedores

```bash
# 1. Clonar el repositorio
git clone https://github.com/rafaelruge/QA-COPITLOT.git
cd QA-COPITLOT/entrega-docker

# 2. Crear el archivo de variables a partir de la plantilla y cambiar la contraseña
cp .env.example .env          # en PowerShell: Copy-Item .env.example .env

# 3. Construir la imagen de la aplicación
docker build -t notas-api:1.0.0 ./app

# 4. Levantar los dos servicios
docker compose up -d --build

# 5. Ver los contenedores
docker ps
```

## Probar la comunicación entre los contenedores

```bash
# Ida: guardar una nota (la app la inserta en PostgreSQL usando el host "db")
curl -X POST http://localhost:3000/notas -H "Content-Type: application/json" -d '{"texto":"Hola Docker"}'

# Vuelta: leer las notas desde la base de datos
curl http://localhost:3000/notas

# Estado de la conexión: muestra el host usado ("db") y la IP que Docker resolvió
curl http://localhost:3000/health

# Desde dentro del contenedor app, el nombre "db" se resuelve por el DNS de Docker
docker compose exec app getent hosts db

# Ver la red y los contenedores conectados
docker network inspect red-notas
```

O ejecutar la prueba completa automática:

```bash
bash scripts/prueba-comunicacion.sh          # Linux, macOS o Git Bash
.\scripts\prueba-comunicacion.ps1            # Windows PowerShell
```

## Endpoints de la API

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET  | `/health` | Estado de la app y de la conexión con `db` |
| POST | `/notas` | Guarda una nota. Cuerpo: `{"texto": "..."}` |
| GET  | `/notas` | Lista todas las notas |
| GET  | `/notas/:id` | Lee una nota por id |

## Apagar

```bash
docker compose down        # detiene y borra los contenedores (los datos se conservan en el volumen)
docker compose down -v     # además borra el volumen con los datos
```

## Buenas prácticas aplicadas

- Imágenes base oficiales con versión fija (nada de `latest`).
- `.dockerignore` para no copiar `node_modules`, `.env` ni archivos de Git a la imagen.
- Contraseñas solo en `.env`, que está en `.gitignore`; en el repositorio solo va `.env.example`.
- La app corre con el usuario sin privilegios `node`.
- `depends_on` con `condition: service_healthy`: la app espera a que PostgreSQL esté listo.
- Volumen `datos-postgres` para que los datos sobrevivan aunque se borre el contenedor.

## Integración continua

El workflow `.github/workflows/docker-ci.yml` (en la raíz del repo) se ejecuta en cada `push` y `pull request`:
valida el `docker-compose.yml`, construye la imagen con `docker build`, construye con
`docker compose build`, levanta los servicios, ejecuta la prueba de ida y vuelta y
apaga todo.
