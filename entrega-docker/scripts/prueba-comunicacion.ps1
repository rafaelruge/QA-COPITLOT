# Prueba de comunicación de ida y vuelta (versión para Windows PowerShell).
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$url = "http://localhost:3000"
$texto = "Hola desde la app - $(Get-Date -Format 'yyyyMMddHHmmss')"

Write-Host "== 1. Estado de la conexión (GET /health) =="
Invoke-RestMethod "$url/health" | ConvertTo-Json

Write-Host "== 2. Ida: guardar una nota (POST /notas) =="
$body = @{ texto = $texto } | ConvertTo-Json
$nota = Invoke-RestMethod -Method Post -Uri "$url/notas" -ContentType "application/json" -Body $body
$nota | ConvertTo-Json

Write-Host "== 3. Vuelta: leer la nota guardada (GET /notas/$($nota.id)) =="
$leida = Invoke-RestMethod "$url/notas/$($nota.id)"
$leida | ConvertTo-Json

Write-Host "== 4. Resolución del nombre de servicio 'db' desde el contenedor app =="
docker compose exec -T app getent hosts db

Write-Host "== 5. El dato está en PostgreSQL (consulta directa en el contenedor db) =="
# PowerShell 5.1 quita las comillas dobles internas al llamar a programas externos,
# por eso la consulta va entre comillas simples dentro de una cadena con comillas dobles.
docker compose exec -T db sh -c "psql -U `$POSTGRES_USER -d `$POSTGRES_DB -c 'SELECT id, texto, creada_en FROM notas ORDER BY id DESC LIMIT 3;'"

if ($leida.texto -eq $texto) {
  Write-Host "OK: la app guardó y leyó el dato en la base de datos usando el servicio 'db'." -ForegroundColor Green
} else {
  Write-Error "El dato leído no coincide."
}
