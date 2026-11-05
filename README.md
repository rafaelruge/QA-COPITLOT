# QA Copilot (NexusQA)

Repositorio del proyecto NexusQA / QA Copilot.

| Carpeta | Servicio |
|---------|----------|
| `QACopilot/` | API REST en ASP.NET Core (.NET 10) con Entity Framework y SQL Server |
| `QACopilot-AI/` | Servicio de IA en Python (FastAPI) |
| `qa-copilot-front/` | Frontend en Angular |

## Entrega proyecto 1: NexusQA con Docker (dos contenedores comunicados)

| Servicio | Contenedor | Papel | Imagen |
|----------|-----------|-------|--------|
| `api` | `nexusqa-api` | API de NexusQA (.NET 10) | Dockerfile propio: `dotnet/sdk:10.0.403-noble` → `dotnet/aspnet:10.0.14-noble` |
| `sqlserver` | `nexusqa-sqlserver` | Base de datos SQL Server con volumen | `mssql/server:2022-CU27-ubuntu-22.04` |

La API se conecta a la base de datos con `Server=sqlserver,1433`, es decir, con el
**nombre del servicio** dentro de la red `red-nexusqa`. No usa `localhost` ni una IP fija.
Al arrancar, la API aplica las migraciones de Entity Framework y crea las tablas.

```
          Navegador / Swagger / curl
                     │ http://localhost:5199
                     ▼
 ┌─────────────── red-nexusqa (bridge) ───────────────┐
 │  ┌──────────────┐  host "sqlserver":1433  ┌───────────────┐ │
 │  │ api          │ ──────────────────────▶ │ sqlserver     │ │
 │  │ nexusqa-api  │ ◀────────────────────── │ SQL Server    │ │
 │  │ .NET 10      │      filas (SQL)        │ 2022          │ │
 │  └──────────────┘                         └──────┬────────┘ │
 └──────────────────────────────────────────────────┼──────────┘
                                                    ▼
                                         volumen datos-sqlserver
```

### Requisitos

- Docker Desktop con Docker Compose v2 (SQL Server necesita unos 2 GB de RAM libres).

### Cómo levantar los contenedores

```bash
git clone https://github.com/rafaelruge/QA-COPITLOT.git
cd QA-COPITLOT

cp .env.example .env                 # PowerShell: Copy-Item .env.example .env
docker build -t nexusqa-api:1.0.0 ./QACopilot
docker compose up -d --build
docker ps
```

### Probar la comunicación

```bash
bash scripts/prueba-nexusqa.sh       # Linux, macOS o Git Bash
.\scripts\prueba-nexusqa.ps1         # Windows PowerShell
```

La prueba registra un usuario (la API lo **guarda** en SQL Server), inicia sesión con él
(la API lo **lee** y valida la contraseña), muestra que `sqlserver` se resuelve por el DNS de
Docker y consulta la tabla `Users` directamente en la base de datos.

Otras formas de verlo:

- Swagger: http://localhost:5199/swagger
- Estado de la conexión con SQL Server: http://localhost:5199/health
- Red: `docker network inspect red-nexusqa`

### Apagar

```bash
docker compose down        # conserva los datos en el volumen
docker compose down -v     # borra también el volumen
```

### Buenas prácticas aplicadas

- Imágenes oficiales con versión fija y construcción en dos etapas (la imagen final solo lleva el runtime).
- `QACopilot/.dockerignore` excluye `bin/`, `obj/`, logs y archivos `.env`.
- Contraseñas y claves solo en `.env` (ignorado por Git); en el repositorio va `.env.example`.
- La API corre con el usuario sin privilegios `app`.
- `healthcheck` en SQL Server y `depends_on: condition: service_healthy` en la API.
- Volumen `datos-sqlserver` para persistir la base de datos.

### Integración continua

`.github/workflows/nexusqa-ci.yml` se ejecuta en cada push y pull request: valida el
compose, construye la imagen con `docker build` y `docker compose build`, levanta los dos
servicios y ejecuta la prueba de registro e inicio de sesión.
