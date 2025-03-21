pipeline {
    agent any

    environment {
        REPO_URL = 'https://github.com/Paulmatic/hello-world-js-master'
        IMAGE_NAME = 'your-dockerhub-username/hello-world-js'
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: "$REPO_URL"
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

        stage('Push to Docker Hub') {
            steps {
                script {
                    withDockerRegistry([credentialsId: 'docker-hub-credentials', url: '']) {
                        sh 'docker login -u your-dockerhub-username -p your-dockerhub-password'
                        sh 'docker push $IMAGE_NAME:latest'
                    }
                }
            }
        }
    }
}
