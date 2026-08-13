pipeline {
    agent any

    environment {
        NETLIFY_SITE_ID = '1ee19704-eb90-441e-b220-a367c070e9b3'
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
    }

    stages {
        stage('Build') {
            agent {
                docker {
                    image 'node:20-bookworm'
                    reuseNode true
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
                            image 'node:20-bookworm'
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
                    image 'node:22-bookworm'
                    reuseNode true
                }
            }

            environment {
                NPM_CONFIG_CACHE = "${WORKSPACE}/.npm"
                HOME = "${WORKSPACE}"
                XDG_CONFIG_HOME = "${WORKSPACE}/.config"
            }

            steps {
                sh '''
                    mkdir -p "$NPM_CONFIG_CACHE"
                    mkdir -p "$XDG_CONFIG_HOME"

                    npm install --no-save netlify-cli

                    npm install node-jq

                    npx netlify --version

                    echo "Deploying to staging... Site ID: $NETLIFY_SITE_ID: $NETLIFY_SITE_ID"

                    npx netlify status

                    npx netlify deploy --dir=build --json > deploy-output.json

                    node -e "const fs=require('fs'); const d=JSON.parse(fs.readFileSync('deploy-output.json')); console.log(d.deploy_url)"
                '''
            }
        }

        stage('Approval') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                input message: 'Do you wish to deploy to production?', ok: 'Yes, I am sure!'}
            }
        }

        stage('Deploy production') {
            agent {
                docker {
                    image 'node:22-bookworm'
                    reuseNode true
                }
            }

            environment {
                NPM_CONFIG_CACHE = "${WORKSPACE}/.npm"
                HOME = "${WORKSPACE}"
                XDG_CONFIG_HOME = "${WORKSPACE}/.config"
            }

            steps {
                sh '''
                    mkdir -p "$NPM_CONFIG_CACHE"
                    mkdir -p "$XDG_CONFIG_HOME"

                    npm install --no-save netlify-cli

                    npx netlify --version

                    echo "Deploying to Netlify... Site ID: $NETLIFY_SITE_ID: $NETLIFY_SITE_ID"

                    npx netlify status

                    npx netlify deploy --dir=build --site=$NETLIFY_SITE_ID --prod
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