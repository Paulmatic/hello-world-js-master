pipeline {
    agent any

    environment {
        REPO_URL = 'https://github.com/Paulmatic/hello-world-js-master'
        IMAGE_NAME = 'paulmug/hello-world-js'
        GCP_KEY = credentials('gcp-key')  // GCP service account JSON
        PROJECT_ID = 'civic-network-453215-s8'  // GCP Project ID
        REGION = 'us-central1'
        REPO = 'my-docker-repo'  // GCP Artifact Registry Repo
        IMAGE_TAG = "latest"
        FULL_IMAGE_PATH = "us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE_NAME:$IMAGE_TAG"
        KUBE_CONFIG = credentials('gke-kubeconfig')  // Kubernetes config
        GIT_CREDENTIALS_ID = 'github-credentials'  // Jenkins GitHub credentials
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', credentialsId: 'github-credentials', url: "$REPO_URL"
            }
        }

        stage('Install Dependencies') {
            steps {
                script {
                    sh 'npm install'
                }
            }
        }

        stage('Run Unit Tests') {
            steps {
                script {
                    sh 'mkdir -p reports && npm test -- --ci --reporters=default --reporters=jest-junit'
                }
            }
            post {
                always {
                    junit 'reports/junit.xml'
                }
            }
        }

        stage('Code Review (Linting)') {
            steps {
                script {
                    sh 'npx eslint . --ext .js --format checkstyle --output-file reports/eslint-report.xml || true'
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
                    sh 'docker build -t $FULL_IMAGE_PATH .'
                }
            }
        }

        stage('Login & Push to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKERHUB_USERNAME', passwordVariable: 'DOCKERHUB_PASSWORD')]) {
                        sh 'echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin'
                        sh 'docker push $IMAGE_NAME:latest'
                    }
                }
            }
        }

        stage('Push to GCP Artifact Registry') {
            steps {
                withEnv(["GOOGLE_APPLICATION_CREDENTIALS=${GCP_KEY}"]) {
                    sh 'gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS'
                    sh 'gcloud auth configure-docker us-central1-docker.pkg.dev'
                    sh 'docker push $FULL_IMAGE_PATH'
                }
            }
        }

        stage('Update Kubernetes Deployment YAML') {
            steps {
                sh """
                sed -i 's|image: .*|image: $FULL_IMAGE_PATH|' deployment/testing/deployment.yaml
                sed -i 's|image: .*|image: $FULL_IMAGE_PATH|' deployment/staging/deployment.yaml
                sed -i 's|image: .*|image: $FULL_IMAGE_PATH|' deployment/production/deployment.yaml
                """
            }
        }

        stage('Commit and Push Updated Deployment YAML') {
            steps {
        withCredentials([usernamePassword(credentialsId: 'github-credentials', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
            sh """
            git config --global user.email "jenkins@automation.com"
            git config --global user.name "Jenkins"
            git add deployment/testing/deployment.yaml deployment/staging/deployment.yaml deployment/production/deployment.yaml
            git commit -m 'Updated deployment image to latest'

            # Use credential helper to avoid exposing secrets in logs
            git remote set-url origin https://$GIT_USER:$GIT_PASS@github.com/Paulmatic/hello-world-js-master.git
            git push origin main
            """
        }
    }
}

        stage('Deploy to Test Environment') {
            steps {
                withKubeConfig([credentialsId: 'gke-kubeconfig']) {
                    sh 'kubectl apply -f deployment/testing/deployment.yaml'
                    sh 'kubectl apply -f deployment/testing/service.yaml'
                }
            }
        }

        stage('Deploy to Staging Environment') {
            steps {
                withKubeConfig([credentialsId: 'gke-kubeconfig']) {
                    sh 'kubectl apply -f deployment/staging/deployment.yaml'
                    sh 'kubectl apply -f deployment/staging/service.yaml'
                }
            }
        }

        stage('Deploy to Production Environment') {
            steps {
                withKubeConfig([credentialsId: 'gke-kubeconfig']) {
                    sh 'kubectl apply -f deployment/production/deployment.yaml'
                    sh 'kubectl apply -f deployment/production/service.yaml'
                }
            }
        }
    }
}
