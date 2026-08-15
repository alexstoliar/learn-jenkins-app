pipeline {
    agent any

    environment {
        NETLIFY_SITE_ID = '1ee19704-eb90-441e-b220-a367c070e9b3'
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')

        REACT_APP_VERSION = "1.2.${BUILD_ID}"

        CI_IMAGE = 'learn-jenkins-app-ci'
    }

    stages {

        // =====================================================
        // Build Docker CI image
        // =====================================================

        stage('Build CI Image') {
            steps {
                sh '''
                    echo "=========================================="
                    echo "Building CI Docker image"
                    echo "=========================================="

                    docker build \
                        -t "$CI_IMAGE" \
                        .

                    echo "Docker image built successfully:"
                    docker images "$CI_IMAGE"
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
                    echo "=========================================="
                    echo "Building application"
                    echo "Version: $REACT_APP_VERSION"
                    echo "=========================================="

                    mkdir -p "$XDG_CONFIG_HOME"

                    npm run build

                    echo "Build completed."

                    ls -lah build
                '''

                stash(
                    name: 'app',
                    includes: 'package.json,package-lock.json,src/**,public/**,build/**,tests/**,e2e/**,playwright.config.*'
                )
            }
        }


        // =====================================================
        // Unit + local E2E tests
        // =====================================================

        stage('Run Tests') {
            parallel {

                // =================================================
                // Unit Tests
                // =================================================

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
                            echo "=========================================="
                            echo "Running Unit Tests"
                            echo "=========================================="

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


                // =================================================
                // Local E2E Tests
                // =================================================

                stage('E2E Tests') {
                    agent {
                        docker {
                            image 'learn-jenkins-app-ci'
                            reuseNode true
                        }
                    }

                    environment {
                        CI_ENVIRONMENT_URL = 'http://127.0.0.1:3000'
                    }

                    steps {
                        sh '''
                            echo "=========================================="
                            echo "Running Local E2E Tests"
                            echo "=========================================="

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
                                reportName: 'Local HTML Report',
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
                        echo "=========================================="
                        echo "Deploying to Staging"
                        echo "=========================================="

                        mkdir -p "$XDG_CONFIG_HOME"

                        echo "Netlify CLI:"
                        npx netlify --version

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

                                if (!data.deploy_url) {
                                    console.error('ERROR: deploy_url not found');
                                    process.exit(1);
                                }

                                console.log(data.deploy_url);
                            "
                        ''',
                        returnStdout: true
                    ).trim()

                    echo "=========================================="
                    echo "Staging URL:"
                    echo "${env.STAGING_URL}"
                    echo "=========================================="
                }
            }
        }


        // =====================================================
        // Staging E2E Tests
        // =====================================================

        stage('Staging E2E Tests') {
            agent {
                docker {
                    image 'learn-jenkins-app-ci'
                    reuseNode true
                }
            }

            environment {
                CI_ENVIRONMENT_URL = "${env.STAGING_URL}"
            }

            steps {
                sh '''
                    echo "=========================================="
                    echo "Running Staging E2E Tests"
                    echo "=========================================="

                    echo "Testing:"
                    echo "$CI_ENVIRONMENT_URL"

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
                    echo "=========================================="
                    echo "Deploying to Production"
                    echo "=========================================="

                    mkdir -p "$XDG_CONFIG_HOME"

                    echo "Netlify CLI:"
                    npx netlify --version

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
        // Production E2E Tests
        // =====================================================

        stage('Prod E2E Tests') {
            agent {
                docker {
                    image 'learn-jenkins-app-ci'
                    reuseNode true
                }
            }

            environment {
                CI_ENVIRONMENT_URL = 'https://mellow-starburst-50aafc.netlify.app'
            }

            steps {
                sh '''
                    echo "=========================================="
                    echo "Running Production E2E Tests"
                    echo "=========================================="

                    echo "Testing:"
                    echo "$CI_ENVIRONMENT_URL"

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


    // =========================================================
    // Pipeline summary
    // =========================================================

    post {

        success {
            echo '''
==========================================
PIPELINE SUCCESS
==========================================
'''

            echo "Application version: ${env.REACT_APP_VERSION}"
            echo "Staging URL: ${env.STAGING_URL ?: 'N/A'}"
            echo "Production URL: https://mellow-starburst-50aafc.netlify.app"
        }

        failure {
            echo '''
==========================================
PIPELINE FAILED
==========================================
'''
        }

        always {
            echo "Build ${env.BUILD_ID} finished."
        }
    }
}