pipeline {
    agent any

    environment {
        REACT_APP_VERSION = "1.2.$BUILD_ID"
        AWS_DEFAULT_REGION = 'us-east-1'
    }

    stages {

            stage('AWS') {
            agent {
                docker {
                    image 'amazon/aws-cli'
                    reuseNode true
                    args "--entrypoint=''"
                }
            }
            steps {
            withCredentials([usernamePassword(credentialsId: 'my-aws', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                sh '''
                    aws --version
                    aws --version
                    aws ecs register-task-definition --cli-input-json aws/task-definition-prod.json
            }

            }

        stage('Build') {
            agent {
                docker {
                    image 'myapp-builder'
                    reuseNode true
                }
            }

            environment {
                NPM_CONFIG_CACHE = "${WORKSPACE}/.npm"
            }

            steps {
                sh '''
                    npm ci
                    npm run build
                '''

                stash(
                    name: 'app',
                    includes: 'package.json,package-lock.json,src/**,public/**,build/**,tests/**,playwright.config.*'
                )
            }
        }

        }
    }
}
