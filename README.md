# QA Copilot (NexusQA)

Repositorio del proyecto QA Copilot: API .NET (`QACopilot/`), servicio de IA en Python
(`QACopilot-AI/`) y frontend Angular (`qa-copilot-front/`).

## Entrega proyecto 1: Docker con dos contenedores

La entrega de Docker está en la carpeta [`entrega-docker/`](entrega-docker/README.md):
una API (contenedor 1) que guarda y lee datos en PostgreSQL (contenedor 2) usando el
nombre del servicio `db` dentro de una red propia de Docker.

```bash
cd entrega-docker
cp .env.example .env
docker compose up -d --build
bash scripts/prueba-comunicacion.sh
```

El pipeline de GitHub Actions está en `.github/workflows/docker-ci.yml`.
