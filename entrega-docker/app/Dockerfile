# Contenedor 1: API de notas (Node.js + Express)
# Imagen base oficial con versión fija (no "latest").
FROM node:22.11.0-alpine3.20

# Directorio de trabajo dentro del contenedor
WORKDIR /usr/src/app

# Instalar dependencias primero para aprovechar la caché de capas
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Copiar el código fuente
COPY src ./src

# Ejecutar como usuario sin privilegios (incluido en la imagen oficial)
USER node

ENV NODE_ENV=production

# Puerto en el que escucha la API
EXPOSE 3000

# Comando de inicio
CMD ["node", "src/index.js"]
