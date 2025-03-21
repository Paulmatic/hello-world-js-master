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
                        npm install eslint --save-dev  # Ensure eslint is installed
                    '''
                }
            }
        }

        stage('Code Review (Linting)') {
            steps {
                script {
                    sh '''
                        mkdir -p reports  # Ensure reports directory exists
                        npx eslint . --ext .js --format checkstyle --output-file reports/eslint-report.xml || true
                        ls -l reports/  # Debugging step: Check if the file exists
                    '''
                }
            }
            post {
                always {
                    script {
                        sh 'ls -l reports/'  # Extra debug step
                    }
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
