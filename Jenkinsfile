pipeline {
    agent none

    options {
        timestamps()
    }

    stages {
        stage('Checkout') {
            agent { label 'default' }
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

        stage('Deploy application') {
            agent { label 'default' }
            steps {
                sh 'docker version'
                sh 'docker compose version'
                sh 'echo IMAGE_TAG=$(date +%Y%m%d%H%M%S) > .deploy.env'
                sh 'cat .deploy.env'
                sh 'set -a && . ./.deploy.env && set +a && docker compose -f docker-compose.yaml build app'
                sh 'set -a && . ./.deploy.env && set +a && docker rollout -f docker-compose.yaml app'
            }
        }
    }
}