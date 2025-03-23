pipeline {
    agent any

    environment {
        REPO_URL = 'https://github.com/Paulmatic/hello-world-js-master'
        IMAGE_NAME = 'paulmug/hello-world-js'
        GCP_KEY = credentials('gcp-key')  
        PROJECT_ID = 'civic-network-453215-s8'
        REGION = 'us-central1'
        ZONE = 'us-central1-a'
        REPO = 'my-docker-repo'
        IMAGE_TAG = "latest"
        FULL_IMAGE_PATH = "us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE_NAME:$IMAGE_TAG"
        CLUSTER_NAME = "my-cluster"
        KUBE_CONFIG = credentials('gke-kubeconfig')  
        LOCAL_KUBECONFIG = '~/.kube/config'  
        GIT_CREDENTIALS_ID = 'github-credentials'
    }

    stages {
        stage('Apply ArgoCD Configuration') {
            steps {
                echo "🚀 Applying ArgoCD configuration..."
                sh 'kubectl apply -f argocd/argocd.yaml -n argocd'
                sh 'kubectl rollout status deployment/argocd-server -n argocd'
            }
        }

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
                    gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE --project=$PROJECT_ID
                    """
                }
            }
        }

        stage('Update Image in Kubernetes Manifests') {
            steps {
                script {
                    sh """
                    sed -i 's|image: .*$|image: $FULL_IMAGE_PATH|' deployment/testing/deployment.yaml
                    sed -i 's|image: .*$|image: $FULL_IMAGE_PATH|' deployment/staging/deployment.yaml
                    sed -i 's|image: .*$|image: $FULL_IMAGE_PATH|' deployment/production/deployment.yaml
                    """
                }
            }
        }

        stage('Push Updated Manifests to Git') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-credentials', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                    sh """
                    git config --global user.email "jenkins@pipeline.com"
                    git config --global user.name "Jenkins Pipeline"
                    git add deployment/testing/deployment.yaml deployment/staging/deployment.yaml deployment/production/deployment.yaml
                    git commit -m "Updated image to $FULL_IMAGE_PATH"
                    git push https://$GIT_USER:$GIT_PASS@github.com/Paulmatic/hello-world-js-master.git main
                    """
                }
            }
        }

        stage('Trigger ArgoCD Sync') {
            steps {
                sh 'argocd app sync hello-world-app'
                sh 'argocd app wait hello-world-app --timeout 300'
            }
        }
    }

    post {
        success {
            echo "✅ Image pushed & deployed via ArgoCD successfully!"
        }
        failure {
            echo "❌ Deployment failed!"
        }
    }
}
