pipeline {
    agent { label 'default' }

    options {
        timestamps()
        skipDefaultCheckout(true)
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
                sh 'npm ci'
                script {
                    def appVersion = sh(script: 'node -p "require(\'./package.json\').version"', returnStdout: true).trim()
                    env.IMAGE_TAG = "${appVersion}-${BUILD_NUMBER}"
                    echo "IMAGE_TAG: ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Build and Scan Image') {
            steps {
                script {
                    if (!env.IMAGE_TAG) {
                        error('IMAGE_TAG is empty')
                    }
                    echo "image tag: ${env.IMAGE_TAG}"
                }
                sh "docker build -f Dockerfile -t node-js-sample:${env.IMAGE_TAG} ."
                sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.57.1 image --severity HIGH,CRITICAL --no-progress --exit-code 1 node-js-sample:${env.IMAGE_TAG}"
            }
        }

        stage('Deploy application') {
            steps {
                sh '''
                    set -eu
                    test -n "$IMAGE_TAG"
                    echo "deploying image tag: $IMAGE_TAG"
                    docker rollout -f docker-compose.yaml app
                '''
            }
        }
    }
}