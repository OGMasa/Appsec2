
pipeline {
    agent any

    stages {
        stage('Unit Tests') {
            steps {
                sh '''
                    set -eu

                    TEST_VOLUME="blog-test-node-modules-${BUILD_NUMBER}"

                    trap 'docker volume rm "$TEST_VOLUME" >/dev/null 2>&1 || true' EXIT

                    docker volume create "$TEST_VOLUME"

                    docker run --rm \
                        -u 0 \
                        -v "$TEST_VOLUME":/app/node_modules \
                        node:20-bookworm \
                        sh -c "chown -R $(id -u):$(id -g) /app/node_modules"

                    docker run --rm \
                        -u "$(id -u):$(id -g)" \
                        -e HOME=/tmp \
                        -v "$WORKSPACE":/app \
                        -v "$TEST_VOLUME":/app/node_modules \
                        -w /app \
                        node:20-bookworm \
                        sh -c "npm ci && npm test"
                '''
            }
        }

        stage('Build') {
            steps {
                sh '''
                    DOCKER_BUILDKIT=0 docker build \
                        --pull \
                        --rm \
                        -f Dockerfile \
                        -t blog:latest .
                '''
            }
        }

        stage('Trivy Scan') {
            steps {
                sh '''
                    rm -f "$WORKSPACE/trivy-report.txt"

                    trivy image \
                        --timeout 15m \
                        --format table \
                        --output "$WORKSPACE/trivy-report.txt" \
                        blog:latest
                '''
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                dependencyCheck(
                    odcInstallation: 'OWASP-DC',
                    nvdCredentialsId: 'nvd-api-key',
                    additionalArguments: '--scan .'
                )

                dependencyCheckPublisher(
                    pattern: '**/dependency-check-report.xml'
                )
            }
        }

        stage('Run') {
            steps {
                sh '''
                    docker stop blog || true
                    docker rm blog || true

                    docker run -d \
                        -p 3000:3000 \
                        --name blog \
                        blog:latest

                    sleep 5

                    docker ps --filter "name=blog"
                '''
            }
        }

        stage('Nikto Scan') {
            steps {
                sh '''
                    docker run --rm \
                        --network host \
                        hackllc/nikto:latest \
                        -h http://127.0.0.1:3000
                '''
            }
        }
    }

    post {
        always {
            sh '''
                docker stop blog || true
                docker rm blog || true
            '''
        }

        success {
            echo 'Pipeline completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Check the stage logs for details.'
        }
    }
}
