pipeline {
    agent any

    environment {
        REPO_URL = 'https://github.com/Paulmatic/hello-world-js-master'
        IMAGE_NAME = 'paulmug/hello-world-js'
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: "$REPO_URL"
            }
        }

        stage('Install Dependencies') {
            steps {
                script {
                    sh '''
                        npm install
                        npm install eslint --save-dev  # Ensure ESLint is installed
                    '''
                }
            }
        }

        stage('Code Review (Linting)') {
    steps {
        script {
            sh '''
                mkdir -p reports  # Ensure reports/ exists
                npx eslint . --ext .js --format checkstyle --output-file reports/eslint-report.xml || true
                echo "Checking if eslint-report.xml was created..."
                ls -l reports/    # Debugging: List files in reports/
                cat reports/eslint-report.xml || echo "eslint-report.xml NOT FOUND"
            '''
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'reports/eslint-report.xml', fingerprint: true
            recordIssues tools: [checkStyle(pattern: 'reports/eslint-report.xml')]
        }
    }
}

        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker build -t $IMAGE_NAME:latest .'
                }
            }
        }

        stage('Test Docker Image') {
            steps {
                script {
                    sh 'docker run --rm $IMAGE_NAME:latest node -v'
                }
            }
        }

        stage('Login to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKERHUB_USERNAME', passwordVariable: 'DOCKERHUB_PASSWORD')]) {
                        sh '''
                            echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
                        '''
                    }
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    sh 'docker push $IMAGE_NAME:latest'
                }
            }
        }
    }
}
