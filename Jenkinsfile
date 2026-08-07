pipeline {
    agent any

    stages {
        stage('Build') {
            agent {
                docker {
                    image 'node:18-bookworm'image 'node:20-bookworm'
                }
            }
            steps {
                sh '''
                    mkdir -p /tmp/app
                    cp -a . /tmp/app
                    cd /tmp/app

                    npm ci
                    npm run build
                '''
            }
        }
    }
}