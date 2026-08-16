pipeline {
    agent any

    environment {
        NETLIFY_SITE_ID = '1ee19704-eb90-441e-b220-a367c070e9b3'
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
        REACT_APP_VERSION = "1.2.$BUILD_ID"
    }

    stages {

        stage('AWS') {
            agent {
                docker {
                    image 'amazon/aws-cli'
                    args "--entrypoint=''"
                }
            }
            steps {
                sh '''
                    aws --version
                '''
            }
        }

        stage('Build Docker Images') {
            steps {
                sh 'docker build -t myapp-builder -f Dockerfile.builder .'
                sh 'docker build -t myapp-deployer -f Dockerfile.deployer .'
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

        stage('Run Tests') {
            parallel {

                stage('Unit Tests') {
                    agent {
                        docker {
                            image 'myapp-builder'
                        }
                    }

                    environment {
                        NPM_CONFIG_CACHE = "${WORKSPACE}/.npm"
                        JEST_JUNIT_OUTPUT_DIR = 'test-results'
                        JEST_JUNIT_OUTPUT_NAME = 'junit.xml'
                    }

                    steps {
                        unstash 'app'

                        sh '''
                            npm ci
                            npm test
                        '''
                    }

                    post {
                        always {
                            junit(
                                allowEmptyResults: true,
                                testResults: 'test-results/junit.xml'
                            )
                        }
                    }
                }

                stage('E2E Tests') {
                    agent {
                        docker {
                            image 'mcr.microsoft.com/playwright:v1.39.0-jammy'
                        }
                    }

                    environment {
                        NPM_CONFIG_CACHE = "${WORKSPACE}/.npm"
                    }

                    steps {
                        unstash 'app'

                        sh '''
                            npm ci
                            npx serve -s build &
                            sleep 10
                            npx playwright test --reporter=html
                        '''
                    }

                    post {
                        always {
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: false,
                                icon: '',
                                keepAll: false,
                                reportDir: 'playwright-report',
                                reportFiles: 'index.html',
                                reportName: 'HTML Report',
                                reportTitles: '',
                                useWrapperFileDirectly: true
                            ])
                        }
                    }
                }
            }
        }

        stage('Deploy staging') {
            agent {
                docker {
                    image 'myapp-deployer'
                    reuseNode true
                }
            }

            environment {
                HOME = "${WORKSPACE}"
                XDG_CONFIG_HOME = "${WORKSPACE}/.config"
            }

            steps {
                sh '''
                    mkdir -p "$XDG_CONFIG_HOME"

                    netlify --version

                    echo "Deploying to staging... Site ID: $NETLIFY_SITE_ID"

                    netlify status

                    netlify deploy --dir=build --json > deploy-output.json

                    jq -r '.deploy_url' deploy-output.json
                '''
                script {
                    env.STAGING_URL = sh(script: "jq -r '.deploy_url' deploy-output.json", returnStdout: true).trim()
                }
            }
        }

        stage('Staging E2E Tests') {
            agent {
                docker {
                    image 'mcr.microsoft.com/playwright:v1.39.0-jammy'
                }
            }

            environment {
                NPM_CONFIG_CACHE = "${WORKSPACE}/.npm"
                CI_ENVIRONMENT_URL = "${env.STAGING_URL}"
            }

            steps {
                unstash 'app'

                sh '''
                    npx playwright test --reporter=html
                '''
            }

            post {
                always {
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: false,
                        icon: '',
                        keepAll: false,
                        reportDir: 'playwright-report',
                        reportFiles: 'index.html',
                        reportName: 'Staging HTML Report',
                        reportTitles: '',
                        useWrapperFileDirectly: true
                    ])
                }
            }
        }

        stage('Deploy production') {
            agent {
                docker {
                    image 'myapp-deployer'
                    reuseNode true
                }
            }

            environment {
                HOME = "${WORKSPACE}"
                XDG_CONFIG_HOME = "${WORKSPACE}/.config"
            }

            steps {
                sh '''
                    mkdir -p "$XDG_CONFIG_HOME"

                    netlify --version

                    echo "Deploying to Netlify... Site ID: $NETLIFY_SITE_ID"

                    netlify status

                    netlify deploy --dir=build --site=$NETLIFY_SITE_ID --prod
                '''
            }
        }

        stage('Prod E2E Tests') {
            agent {
                docker {
                    image 'mcr.microsoft.com/playwright:v1.39.0-jammy'
                }
            }

            environment {
                NPM_CONFIG_CACHE = "${WORKSPACE}/.npm"
                CI_ENVIRONMENT_URL = "https://mellow-starburst-50aafc.netlify.app"
            }

            steps {
                unstash 'app'

                sh '''
                    npx playwright test --reporter=html
                '''
            }

            post {
                always {
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: false,
                        icon: '',
                        keepAll: false,
                        reportDir: 'playwright-report',
                        reportFiles: 'index.html',
                        reportName: 'Prod HTML Report',
                        reportTitles: '',
                        useWrapperFileDirectly: true
                    ])
                }
            }
        }
    }
}
