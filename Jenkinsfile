pipeline {
    agent any

    environment {
        NETLIFY_SITE_ID = '1ee19704-eb90-441e-b220-a367c070e9b3'
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')

        REACT_APP_VERSION = "1.2.${BUILD_ID}"

        CI_IMAGE = 'learn-jenkins-app-ci'
        PLAYWRIGHT_IMAGE = 'learn-jenkins-app-playwright'
    }

    stages {

        // =====================================================
        // Build Docker images
        // =====================================================

        stage('Build CI Images') {
            steps {
                sh '''
                    echo "Building CI image..."

                    docker build \
                        --target ci \
                        -t "$CI_IMAGE" \
                        .

                    echo "Building Playwright image..."

                    docker build \
                        --target playwright \
                        -t "$PLAYWRIGHT_IMAGE" \
                        .
                '''
            }
        }


        // =====================================================
        // Build application
        // =====================================================

        stage('Build') {
            agent {
                docker {
                    image 'learn-jenkins-app-ci'
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

                    echo "Building application..."
                    echo "Application version: $REACT_APP_VERSION"

                    npm run build

                    echo "Checking generated version..."

                    grep -R "Application version" build || true
                '''

                stash(
                    name: 'app',
                    includes: 'package.json,package-lock.json,src/**,public/**,build/**,tests/**,e2e/**,playwright.config.*'
                )
            }
        }


        // =====================================================
        // Tests
        // =====================================================

        stage('Run Tests') {
            parallel {

                // -------------------------------------------------
                // Unit tests
                // -------------------------------------------------

                stage('Unit Tests') {
                    agent {
                        docker {
                            image 'learn-jenkins-app-ci'
                            reuseNode true
                        }
                    }

                    environment {
                        JEST_JUNIT_OUTPUT_DIR = 'test-results'
                        JEST_JUNIT_OUTPUT_NAME = 'junit.xml'
                    }

                    steps {
                        sh '''
                            echo "Running unit tests..."

                            mkdir -p test-results

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


                // -------------------------------------------------
                // Local E2E tests
                // -------------------------------------------------

                stage('E2E Tests') {
                    agent {
                        docker {
                            image 'learn-jenkins-app-playwright'
                            reuseNode true
                        }
                    }

                    environment {
                        CI_ENVIRONMENT_URL = 'http://127.0.0.1:3000'
                    }

                    steps {
                        sh '''
                            echo "Running local E2E tests..."

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


        // =====================================================
        // Deploy staging
        // =====================================================

        stage('Deploy staging') {
            agent {
                docker {
                    image 'learn-jenkins-app-ci'
                    reuseNode true
                }
            }

            environment {
                HOME = "${WORKSPACE}"
                XDG_CONFIG_HOME = "${WORKSPACE}/.config"
            }

            steps {
                script {
                    sh '''
                        mkdir -p "$XDG_CONFIG_HOME"

                        echo "Netlify CLI:"
                        npx netlify --version

                        echo "Deploying to staging..."
                        echo "Site ID: $NETLIFY_SITE_ID"

                        npx netlify status

                        npx netlify deploy \
                            --dir=build \
                            --json > deploy-output.json

                        echo "Deployment response:"
                        cat deploy-output.json
                    '''

                    env.STAGING_URL = sh(
                        script: '''
                            node -e "
                                const fs = require('fs');

                                const data = JSON.parse(
                                    fs.readFileSync('deploy-output.json', 'utf8')
                                );

                                console.log(data.deploy_url);
                            "
                        ''',
                        returnStdout: true
                    ).trim()

                    echo "Staging URL: ${env.STAGING_URL}"
                }
            }
        }


        // =====================================================
        // Staging E2E
        // =====================================================

        stage('Staging E2E Tests') {
            agent {
                docker {
                    image 'learn-jenkins-app-playwright'
                    reuseNode true
                }
            }

            environment {
                CI_ENVIRONMENT_URL = "${env.STAGING_URL}"
            }

            steps {
                sh '''
                    echo "Running E2E tests against staging..."
                    echo "URL: $CI_ENVIRONMENT_URL"

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


        // =====================================================
        // Deploy production
        // =====================================================

        stage('Deploy production') {
            agent {
                docker {
                    image 'learn-jenkins-app-ci'
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

                    echo "Deploying to production..."
                    echo "Site ID: $NETLIFY_SITE_ID"

                    npx netlify status

                    npx netlify deploy \
                        --dir=build \
                        --site="$NETLIFY_SITE_ID" \
                        --prod
                '''
            }
        }


        // =====================================================
        // Production E2E
        // =====================================================

        stage('Prod E2E Tests') {
            agent {
                docker {
                    image 'learn-jenkins-app-playwright'
                    reuseNode true
                }
            }

            environment {
                CI_ENVIRONMENT_URL = 'https://mellow-starburst-50aafc.netlify.app'
            }

            steps {
                sh '''
                    echo "Running production E2E tests..."
                    echo "URL: $CI_ENVIRONMENT_URL"

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
                        reportName: 'Production HTML Report',
                        reportTitles: '',
                        useWrapperFileDirectly: true
                    ])
                }
            }
        }
    }

    post {
        success {
            echo '=========================================='
            echo 'PIPELINE SUCCESS'
            echo '=========================================='
            echo "Application version: ${env.REACT_APP_VERSION}"
            echo "Staging URL: ${env.STAGING_URL ?: 'N/A'}"
            echo "Production URL: https://mellow-starburst-50aafc.netlify.app"
        }

        failure {
            echo '=========================================='
            echo 'PIPELINE FAILED'
            echo '=========================================='
        }

        always {
            echo "Build ${env.BUILD_ID} finished."
        }
    }
}