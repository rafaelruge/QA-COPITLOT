# Contenedor 2: base de datos de NexusQA (SQL Server 2022)
# Imagen propia a partir de la oficial de Microsoft con versión fija, para que el
# pipeline construya las dos imágenes del proyecto (api y sqlserver).
FROM mcr.microsoft.com/mssql/server:2022-CU27-ubuntu-22.04

LABEL org.opencontainers.image.title="nexusqa-sqlserver" \
      org.opencontainers.image.description="SQL Server para NexusQA" \
      org.opencontainers.image.source="https://github.com/rafaelruge/qa-copitlot"

# Configuración fija del motor. La contraseña de "sa" NO va en la imagen:
# llega en tiempo de ejecución (MSSQL_SA_PASSWORD, desde .env o Jenkins Credentials).
ENV ACCEPT_EULA=Y \
    MSSQL_PID=Developer \
    MSSQL_COLLATION=SQL_Latin1_General_CP1_CI_AS \
    MSSQL_TCP_PORT=1433

EXPOSE 1433

# Salud del contenedor: responde cuando SQL Server ya acepta consultas
HEALTHCHECK --interval=10s --timeout=5s --start-period=20s --retries=15 \
  CMD /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -Q "SELECT 1" -b -o /dev/null || exit 1
