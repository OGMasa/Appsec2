pipeline {
    agent any

    stages {

        stage('Unit Tests') {
            steps {
                sh '''
                    echo "Node version:"
                    node --version

                    echo "NPM version:"
                    npm --version

                    echo "Installing dependencies..."
                    npm ci

                    echo "Running tests..."
                    npm test
                '''
            }
        }

        stage('Build') {
            steps {
                sh '''
                    docker build \
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
                        --format table \
                        --output "$WORKSPACE/trivy-report.txt" \
                        blog:latest

                    echo "Trivy scan completed."
                    cat "$WORKSPACE/trivy-report.txt"
                '''
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                dependencyCheck(
                    odcInstallation: 'OWASP-DC',
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
                        --name blog \
                        -p 3000:3000 \
                        blog:latest

                    echo "Waiting for application..."
                    sleep 5

                    docker ps
                '''
            }
        }

        stage('Nikto Scan') {
            steps {
                sh '''
                    docker run --rm \
                        --network host \
                        sullo/nikto \
                        -h http://127.0.0.1:3000
                '''
            }
        }
    }

    post {
        always {
            sh '''
                docker stop blog 2>/dev/null || true
                docker rm blog 2>/dev/null || true
            '''
        }

        success {
            echo 'Pipeline completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Check the stage that reported the error.'
        }
    }
}
