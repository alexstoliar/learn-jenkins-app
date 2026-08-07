pipeline {
    agent any

    stages {
        stage('Build') {
            agent {
                docker {
                    image 'node:18-bookworm'
                    args '-v /var/jenkins/npm-cache:/root/.npm'
                }
            }
            steps {
                sh '''
                    ls -la
                    node --version
                    npm --version
                    rm -rf node_modules
                    npm ci
                    npm run build
                    ls -la
                '''
            }
        }
    }
}