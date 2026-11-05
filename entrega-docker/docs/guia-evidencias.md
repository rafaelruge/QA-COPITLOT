# Guía para el PDF de evidencias (paso 8)

Esta carpeta `docs/` es solo de apoyo; el PDF final lo armas en Word o Google Docs
con tus propias capturas. Estructura sugerida:

## Portada
Nombre del proyecto, tu nombre, curso (Integración Continua), docente (John Olarte),
fecha y **enlace al repositorio de GitHub**.

## 1. Introducción (3 a 5 líneas)
Qué hace el proyecto: una API de notas (contenedor 1) que guarda y lee datos en
PostgreSQL (contenedor 2), orquestados con Docker Compose en una red propia.

## 2. Diagrama de arquitectura
Copia el diagrama del README o dibújalo en draw.io / Excalidraw: usuario → puerto
3000 → `app` → (host `db`:5432 dentro de `red-notas`) → `db` → volumen `datos-postgres`.

## 3. Capturas (una por comando, con una línea que explique qué demuestra)

| # | Comando | Qué debe verse en la captura |
|---|---------|------------------------------|
| 1 | `docker build -t notas-api:1.0.0 ./app` | Termina sin errores (`naming to ... notas-api:1.0.0`) |
| 2 | `docker compose up -d --build` | Red `red-notas`, volumen y los dos contenedores creados / `Healthy` |
| 3 | `docker ps` | `notas-app` y `notas-db` en estado `Up (healthy)` y el puerto `0.0.0.0:3000->3000` |
| 4 | `docker network inspect red-notas` | Los dos contenedores dentro de la misma red con sus IP |
| 5 | `bash scripts/prueba-comunicacion.sh` (o `.ps1`) | `POST /notas` guarda, `GET /notas/id` devuelve el mismo texto, `getent hosts db` resuelve el nombre y la consulta `SELECT` en PostgreSQL muestra la fila |
| 6 | `docker compose logs app` | `Conectando a PostgreSQL en el host "db"` |
| 7 | Pestaña **Actions** de GitHub | El workflow `CI - Docker` con el check en verde |
| 8 | Repositorio en GitHub | Estructura de carpetas, historial de commits y que **no** aparece el `.env` |

Consejo: en la captura 5 resalta `"db_host_usado":"db"`; es la prueba de que no se usa
`localhost` ni una IP fija (el punto que vale 35 pts).

## 4. Buenas prácticas y seguridad
Explica brevemente: versiones fijas, `.dockerignore`, `.env` fuera del repo con
`.env.example`, usuario no root, `healthcheck` + `depends_on`, volumen persistente.

## 5. Conclusiones (borrador para adaptar con tus palabras)
- Docker Compose permite levantar una aplicación de varios servicios con un solo comando
  y de forma reproducible en cualquier máquina.
- La red definida por el usuario incluye un DNS interno, por eso la aplicación encuentra a
  la base de datos por el nombre del servicio (`db`) aunque cambie su IP.
- Separar la configuración sensible en variables de entorno evita exponer contraseñas en el
  código y en el repositorio.
- Integrar la construcción de las imágenes y una prueba de comunicación en GitHub Actions
  detecta errores en cada push, antes de que lleguen a otros entornos.

## 6. Referencias (APA 7)

Docker Inc. (2024). *Dockerfile reference*. Docker Docs. https://docs.docker.com/reference/dockerfile/

Docker Inc. (2024). *Networking in Compose*. Docker Docs. https://docs.docker.com/compose/how-tos/networking/

Docker Inc. (2024). *Compose file reference*. Docker Docs. https://docs.docker.com/reference/compose-file/

Docker Inc. (2024). *Build context: .dockerignore files*. Docker Docs. https://docs.docker.com/build/concepts/context/

GitHub. (2024). *Understanding GitHub Actions*. GitHub Docs. https://docs.github.com/en/actions/about-github-actions/understanding-github-actions

The PostgreSQL Global Development Group. (2024). *PostgreSQL 16 documentation*. https://www.postgresql.org/docs/16/

Docker Hub. (2024). *postgres: Docker Official Image*. https://hub.docker.com/_/postgres

Fowler, M. (2006). *Continuous integration*. martinfowler.com. https://martinfowler.com/articles/continuousIntegration.html
