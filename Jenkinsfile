pipeline {
    agent any

    environment {
        REPO_URL = 'https://github.com/Paulmatic/hello-world-js-master'
        IMAGE_NAME = 'paulmug/hello-world-js'
        GCP_KEY = credentials('gcp-key')  // GCP service account JSON
        PROJECT_ID = 'civic-network-453215-s8'  // GCP Project ID
        REGION = 'us-central1'  // Your GKE cluster region
        REPO = 'my-docker-repo'  // GCP Artifact Registry Repo
        IMAGE_TAG = "latest"
        FULL_IMAGE_PATH = "us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE_NAME:$IMAGE_TAG"
        CLUSTER_NAME = "your-cluster-name"  // Replace with your GKE cluster name
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
                sh 'npm install'
            }
        }

        stage('Run Unit Tests') {
            steps {
                sh 'mkdir -p reports && npm test -- --ci --reporters=default --reporters=jest-junit'
            }
            post {
                always {
                    junit 'reports/junit.xml'
                }
            }
        }

        stage('Code Review (Linting)') {
            steps {
                sh 'npx eslint . --ext .js --format checkstyle --output-file reports/eslint-report.xml || true'
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
                sh 'docker build -t $FULL_IMAGE_PATH .'
            }
        }

        stage('Push to GCP Artifact Registry') {
            steps {
                withCredentials([file(credentialsId: 'gcp-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh """
                    gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                    gcloud auth configure-docker us-central1-docker.pkg.dev
                    docker push $FULL_IMAGE_PATH
                    """
                }
            }
        }

        stage('Authenticate with GKE') {
            steps {
                withCredentials([file(credentialsId: 'gcp-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh """
                    gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                    gcloud container clusters get-credentials $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID
                    """
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

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    def namespaces = ["testing", "staging", "production"]
                    for (ns in namespaces) {
                        sh """
                        kubectl set image deployment/hello-world-js hello-world-js=$FULL_IMAGE_PATH --namespace=${ns}
                        kubectl rollout status deployment/hello-world-js --namespace=${ns}
                        """
                    }
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

    post {
        success {
            echo "✅ Deployment to all environments completed successfully!"
        }
        failure {
            echo "❌ Deployment failed!"
        }
    }
}
