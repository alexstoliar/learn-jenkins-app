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
                   if test -e build/index.html; then echo "Exists"; fi
                   npm test
                '''
            }
        }
        stage('E2E Test') {
            agent { 
                docker {
                    image 'mcr.microsoft.com/playwright:v1.39.0-jammy'
                }
            }
            environment {
                NPM_CONFIG_CACHE = "${WORKSPACE}/.npm"
            }
            steps {
                sh '''
                    npm install serve
                    node_modules/.bin/serve -s build &
                    sleep 10
                    npx playwright test --reporter=html
                '''
            }
        }
    }
}