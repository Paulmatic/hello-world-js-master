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
                    sh 'npm install'
                }
            }
        }

        stage('Code Review (Linting)') {
    steps {
        script {
            sh '''
                npm install
                mkdir -p reports  # Ensure the directory exists
                npx eslint . --format checkstyle --output-file reports/eslint-report.xml || true
                ls -l reports/  # Debugging step to check if the file exists
            '''
        }
    }
    post {
        always {
            recordIssues tools: [checkStyle(pattern: 'reports/eslint-report.xml')]
            archiveArtifacts artifacts: 'reports/eslint-report.xml', fingerprint: true
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
                        sh 'echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin'
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

    post {
        always {
            archiveArtifacts artifacts: 'eslint-report.xml', fingerprint: true
        }
    }
}


