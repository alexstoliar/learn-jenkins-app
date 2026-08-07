pipeline {
    agent any

    stages {
        stage('Build') {
            agent {
                docker {
                    image 'node:20-bookworm'
                }
            }
            environment {
                NPM_CONFIG_CACHE = "${WORKSPACE}/.npm"
            }
            steps {
                sh '''
                    rm -rf node_modules
                    npm ci
                    npm run build
                '''
            }
        }
        stage('Test') {
            agent {
                docker {
                    image 'node:20-bookworm'
                }
            }
            environment {
                NPM_CONFIG_CACHE = "${WORKSPACE}/.npm"
            }
            steps {
                sh '''
                   echo "Running tests..."
                   if test -e /build/index.html; then echo "Exists"; fi
                '''
            }
        }
    }
}