pipeline {
    agent any

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
            }
        }
        stage('Test') {
            agent {
                docker {
                    image 'node:20-bookworm'
                    reuseNode true
                }
            }
            environment {
                NPM_CONFIG_CACHE = "${WORKSPACE}/.npm"
                JEST_JUNIT_OUTPUT_DIR = 'test-results'
                JEST_JUNIT_OUTPUT_NAME = 'junit.xml'
            }
            steps {
                sh '''
                   echo "Running tests..."

                    rm -rf test-results
                    mkdir -p test-results

                    npm test

                    echo "===== JUnit files ====="
                    find . -type f -name "*.xml" -print

                    echo "===== test-results ====="
                    ls -la test-results

                    echo "===== PACKAGE JEST-JUNIT ====="
                    npm list jest-junit

                    echo "===== JUNIT FILE ====="
                    if [ -f test-results/junit.xml ]; then
                        echo "FOUND: test-results/junit.xml"
                        wc -c test-results/junit.xml
                        head -20 test-results/junit.xml
                    else
                        echo "ERROR: test-results/junit.xml NOT FOUND"
                        exit 1
                    fi
                '''
            }
        }
        stage('E2E Test') {
            agent { 
                docker {
                    image 'mcr.microsoft.com/playwright:v1.39.0-jammy'
                    reuseNode true
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
    post {
        always {
            junit 'test-results/junit.xml'
            publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, icon: '', keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'HTML Report', reportTitles: '', useWrapperFileDirectly: true])
        }
    }
}