pipeline {
    agent any

    options {
        timestamps()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            agent {
                docker {
                    image 'node:22.21.1-alpine'
                }
            }
            steps {
                sh 'npm install'
            }
        }

        stage('Docker Rollout') {
            steps {
                sh 'docker version'
                sh 'docker compose version'
                sh 'echo image tag: $(date +%Y%m%d%H%M%S)'
                sh 'export IMAGE_TAG=$(date +%Y%m%d%H%M%S) && docker compose -f docker-compose.yaml up -d --build --force-recreate'
            }
        }
    }
}