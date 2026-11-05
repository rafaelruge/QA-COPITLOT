#!/usr/bin/env bash
# Prueba de comunicación de ida y vuelta entre la API de NexusQA y SQL Server.
# 1) /health: la API consulta SQL Server.
# 2) Ida: registra un usuario (la API lo guarda en la tabla Users).
# 3) Vuelta: inicia sesión con ese usuario (la API lo lee y valida la contraseña).
# 4) El nombre "sqlserver" se resuelve por el DNS interno de Docker.
# 5) Consulta directa en SQL Server para ver el registro.
set -euo pipefail

URL="${URL:-http://localhost:${API_PORT:-5199}}"
EMAIL="prueba.$(date +%s)@ithealth.co"
CLAVE="Prueba123*"

echo "Esperando a que la API responda en $URL ..."
for i in $(seq 1 60); do
  curl -fsS "$URL/health" > /dev/null 2>&1 && break
  sleep 2
done

echo "== 1. Estado de la API y de SQL Server (GET /health) =="
curl -fsS "$URL/health"; echo

echo "== 2. Ida: registrar usuario $EMAIL (POST /api/auth/register) =="
curl -fsS -X POST "$URL/api/auth/register" -H "Content-Type: application/json" \
  -d "{\"fullName\":\"Usuario Docker\",\"email\":\"$EMAIL\",\"password\":\"$CLAVE\",\"role\":\"QAEngineer\"}" | cut -c1-200; echo

echo "== 3. Vuelta: iniciar sesión con ese usuario (POST /api/auth/login) =="
LOGIN=$(curl -fsS -X POST "$URL/api/auth/login" -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$CLAVE\"}")
echo "$LOGIN" | cut -c1-200; echo

echo "== 4. Resolución del nombre de servicio 'sqlserver' desde el contenedor api =="
docker compose exec -T api getent hosts sqlserver

echo "== 5. El usuario está en SQL Server (consulta directa en el contenedor sqlserver) =="
docker compose exec -T sqlserver sh -c "/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P \"\$MSSQL_SA_PASSWORD\" -C -d NexusQA -W -Q \"SELECT TOP 3 FullName, Email, Role, CreatedAt FROM Users ORDER BY CreatedAt DESC\""

if echo "$LOGIN" | grep -q accessToken; then
  echo "OK: la API guardó y leyó el usuario en SQL Server usando el servicio 'sqlserver'."
else
  echo "ERROR: el inicio de sesión no devolvió token." >&2
  exit 1
fi
