#!/usr/bin/env bash
# Prueba de comunicación de ida y vuelta entre los dos contenedores.
# 1) Guarda una nota a través de la API (contenedor app -> contenedor db).
# 2) La lee de nuevo y comprueba que el dato volvió.
# 3) Muestra que, DENTRO del contenedor app, el nombre "db" se resuelve por DNS de Docker.
set -euo pipefail

URL="${URL:-http://localhost:${APP_PORT:-3000}}"
TEXTO="Hola desde la app - $(date +%s)"

echo "Esperando a que la API responda en $URL ..."
for i in $(seq 1 30); do
  curl -fsS "$URL/health" > /dev/null 2>&1 && break
  sleep 1
done

echo "== 1. Estado de la conexión (GET /health) =="
curl -fsS "$URL/health"; echo

echo "== 2. Ida: guardar una nota (POST /notas) =="
RESP=$(curl -fsS -X POST "$URL/notas" -H "Content-Type: application/json" \
  -d "{\"texto\": \"$TEXTO\"}")
echo "$RESP"
ID=$(echo "$RESP" | sed -E 's/.*"id":([0-9]+).*/\1/')

echo "== 3. Vuelta: leer la nota guardada (GET /notas/$ID) =="
LEIDA=$(curl -fsS "$URL/notas/$ID")
echo "$LEIDA"

echo "== 4. Resolución del nombre de servicio 'db' desde el contenedor app =="
docker compose exec -T app getent hosts db

echo "== 5. El dato está realmente en PostgreSQL (consulta directa en el contenedor db) =="
docker compose exec -T db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT * FROM notas ORDER BY id DESC LIMIT 3;"'

if echo "$LEIDA" | grep -q "$TEXTO"; then
  echo "OK: la app guardó y leyó el dato en la base de datos usando el servicio 'db'."
else
  echo "ERROR: el dato leído no coincide." >&2
  exit 1
fi
