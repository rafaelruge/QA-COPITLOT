# Contenedor 1: API de NexusQA (ASP.NET Core / .NET 10)
# Construcción en dos etapas con imágenes oficiales de Microsoft y versión fija.

# ---------- Etapa 1: compilar y publicar ----------
FROM mcr.microsoft.com/dotnet/sdk:10.0.403-noble AS build
WORKDIR /src

# Copiar primero los proyectos para aprovechar la caché al restaurar dependencias
COPY Directory.Build.props ./
COPY src/QACopilot.Domain/QACopilot.Domain.csproj src/QACopilot.Domain/
COPY src/QACopilot.Application/QACopilot.Application.csproj src/QACopilot.Application/
COPY src/QACopilot.Infrastructure/QACopilot.Infrastructure.csproj src/QACopilot.Infrastructure/
COPY src/QACopilot.API/QACopilot.API.csproj src/QACopilot.API/
RUN dotnet restore src/QACopilot.API/QACopilot.API.csproj

# Copiar el código y publicar en modo Release
COPY src/ src/
RUN dotnet publish src/QACopilot.API/QACopilot.API.csproj -c Release -o /app/publish --no-restore

# ---------- Etapa 2: imagen final solo con el runtime ----------
FROM mcr.microsoft.com/dotnet/aspnet:10.0.14-noble AS final
WORKDIR /app

COPY --from=build /app/publish .

# Carpeta de logs con permisos para el usuario sin privilegios "app" de la imagen oficial
RUN mkdir -p /app/logs && chown -R app:app /app/logs
USER app

ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "QACopilot.API.dll"]
