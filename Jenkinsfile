pipeline {
    agent none

    options {
        timestamps()
    }

    environment {
        IMAGE_TAG = ''
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

        stage('Build and Scan Image') {
            agent { label 'default' }
            steps {
                sh 'docker version'
                sh 'docker compose version'
                script {
                    env.IMAGE_TAG = sh(script: 'date +%Y%m%d%H%M%S', returnStdout: true).trim()
                    echo "image tag: ${env.IMAGE_TAG}"
                }
                sh "docker build -f Dockerfile -t node-js-sample:${env.IMAGE_TAG} ."
                sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.57.1 image --severity HIGH,CRITICAL --no-progress --exit-code 1 node-js-sample:${env.IMAGE_TAG}"
            }
        }

        stage('Deploy application') {
            agent { label 'default' }
            steps {
                sh 'docker version'
                sh 'docker compose version'
                sh "echo deploying image tag: ${env.IMAGE_TAG}"
                sh "IMAGE_TAG=${env.IMAGE_TAG} docker rollout -f docker-compose.yaml app"
            }
        }
    }
}