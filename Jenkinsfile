pipeline {
    agent any

    environment {
        REACT_APP_VERSION = "1.2.${BUILD_ID}"
        AWS_DEFAULT_REGION = 'us-east-1'
    }

    stages {

        stage('AWS') {
            agent {
                docker {
                    image 'amazon/aws-cli'
                    reuseNode true
                    args "-u root --entrypoint=''"
                }
            }

            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'my-aws',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY',
                        usernameVariable: 'AWS_ACCESS_KEY_ID'
                    )
                ]) {
                    sh '''
                        aws --version
                        yum install -y jq
                        LATEST_TD_REVISION=$(aws ecs register-task-definition \
                            --cli-input-json file://aws/task-definition-prod.json | jq '.taskDefinition.revision')
                            echo "Latest task definition revision: $LATEST_TD_REVISION"
                        aws ecs update-service \
                            --cluster LearnJenkinsApp-Cluster-Prod \
                            --service LearnJenkinsApp-TaskDefinition-Prod-service-gtynrp5p \
                            --task-definition LearnJenkinsApp-TaskDefinition-Prod:$LATEST_TD_REVISION \
                    '''
                }
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