pipeline {
    agent any

    stages {
        stage('Install and Build') {
            agent {
                docker {
                    image 'node:20-bookworm'
                    reuseNode true
                }
            }

            steps {
                sh '''
                    npm ci
                    npm run build
                '''

                stash name: 'app',
                      includes: 'build/**,package.json,package-lock.json,src/**,public/**,playwright.config.*,tests/**'
            }
        }

        stage('Run Tests') {
            parallel {

                stage('Unit Tests') {
                    agent {
                        docker {
                            image 'node:20-bookworm'
                        }
                    }

                    environment {
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
                            junit allowEmptyResults: true,
                                  testResults: 'test-results/junit.xml'
                        }
                    }
                }

                stage('E2E Tests') {
                    agent {
                        docker {
                            image 'mcr.microsoft.com/playwright:v1.39.0-jammy'
                        }
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
    }
}