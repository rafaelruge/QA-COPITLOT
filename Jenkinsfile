// Pipeline de integración continua de NexusQA (va en la raíz del repositorio QA-COPITLOT)
pipeline {
    agent { label 'docker' }

    // Se dispara solo: Jenkins revisa GitHub cada 2 minutos y construye si hay commits nuevos
    triggers {
        pollSCM('H/2 * * * *')
    }

    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    environment {
        // Secretos guardados en Jenkins > Credentials; Jenkins los oculta (****) en el log
        MSSQL_SA_PASSWORD = credentials('nexusqa-mssql-sa-password')
        JWT_SECRET_KEY    = credentials('nexusqa-jwt-secret')
        ENCRYPTION_KEY    = credentials('nexusqa-encryption-key')
        API_PORT = '5199'
        // Con Docker-in-Docker los puertos se publican en el host "docker", no en localhost
        URL = 'http://docker:5199'
        COMPOSE_PROJECT_NAME = 'nexusqa-ci'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'git log -1 --oneline'
            }
        }
        stage('Build') {
            steps {
                // Valida el docker-compose.yml de la Entrega 1
                sh 'docker compose config --quiet'
                // Servicio 1: construye la imagen de la API con su Dockerfile
                sh 'docker compose build api'
                sh 'docker tag nexusqa-api:1.0.0 nexusqa-api:${BUILD_NUMBER}'
                // Servicio 2: descarga la imagen oficial de SQL Server con versión fija
                sh 'docker compose pull sqlserver'
                sh 'docker image ls --filter reference="nexusqa-api" --filter reference="mcr.microsoft.com/mssql/server"'
            }
        }
        stage('Test') {
            steps {
                // Levanta los dos contenedores y espera a que estén saludables
                sh 'docker compose up -d --wait'
                // Prueba de ida y vuelta: la API llega a SQL Server por el nombre del servicio "sqlserver".
                // Si cualquier paso falla, el script sale con error y el build queda en rojo.
                sh '''#!/bin/bash
                    set -o pipefail
                    bash scripts/prueba-nexusqa.sh 2>&1 | tee prueba-nexusqa.log
                '''
            }
        }
    }

    post {
        success {
            echo 'Build y pruebas en verde: los dos contenedores se comunican por el nombre del servicio.'
        }
        failure {
            echo 'El build falló: revisar docker-compose.log en los artefactos.'
            sh 'docker compose logs --no-color > docker-compose.log 2>&1 || true'
        }
        cleanup {
            archiveArtifacts artifacts: '*.log', allowEmptyArchive: true
            sh 'docker compose down -v || true'
            cleanWs()
        }
    }
}
