# Imagen de Jenkins para NexusQA: LTS con Java 21, cliente de Docker y plugins preinstalados.
FROM jenkins/jenkins:2.580.2-lts-jdk21

# Cliente de Docker, Buildx y Compose tomados de la imagen oficial (binarios estáticos, versión fija).
# El motor de Docker no corre aquí: corre en el contenedor "docker" (Docker-in-Docker).
COPY --from=docker:29.10.0-cli /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker:29.10.0-cli /usr/local/libexec/docker/cli-plugins/ /usr/local/libexec/docker/cli-plugins/

# Plugins (versión resuelta al construir la imagen)
COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Configuración como código (JCasC); se omite el asistente inicial porque la seguridad ya viene configurada
COPY --chown=jenkins:jenkins casc/ /var/jenkins_home/casc/
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/casc \
    JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
