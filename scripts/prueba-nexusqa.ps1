# Prueba de comunicación de ida y vuelta entre la API de NexusQA y SQL Server (Windows PowerShell).
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$url = "http://localhost:5199"
$email = "prueba.$(Get-Date -Format 'yyyyMMddHHmmss')@ithealth.co"
$clave = "Prueba123*"

Write-Host "== 1. Estado de la API y de SQL Server (GET /health) =="
Invoke-RestMethod "$url/health" | ConvertTo-Json -Depth 5

Write-Host "== 2. Ida: registrar usuario $email (POST /api/auth/register) =="
$registro = @{ fullName = "Usuario Docker"; email = $email; password = $clave; role = "QAEngineer" } | ConvertTo-Json
$r = Invoke-RestMethod -Method Post -Uri "$url/api/auth/register" -ContentType "application/json" -Body $registro
Write-Host ("accessToken: " + $r.accessToken.Substring(0, 40) + "...")

Write-Host "== 3. Vuelta: iniciar sesión con ese usuario (POST /api/auth/login) =="
$login = @{ email = $email; password = $clave } | ConvertTo-Json
$l = Invoke-RestMethod -Method Post -Uri "$url/api/auth/login" -ContentType "application/json" -Body $login
Write-Host ("accessToken: " + $l.accessToken.Substring(0, 40) + "...")

Write-Host "== 4. Resolución del nombre de servicio 'sqlserver' desde el contenedor api =="
docker compose exec -T api getent hosts sqlserver

Write-Host "== 5. El usuario está en SQL Server (consulta directa en el contenedor sqlserver) =="
docker compose exec -T sqlserver sh -c "/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P `$MSSQL_SA_PASSWORD -C -d NexusQA -W -Q 'SELECT TOP 3 FullName, Email, Role, CreatedAt FROM Users ORDER BY CreatedAt DESC'"

if ($l.accessToken) {
  Write-Host "OK: la API guardó y leyó el usuario en SQL Server usando el servicio 'sqlserver'." -ForegroundColor Green
} else {
  Write-Error "El inicio de sesión no devolvió token."
}
