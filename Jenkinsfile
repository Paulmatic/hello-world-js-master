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
        GIT_CREDENTIALS_ID = 'github-credentials'
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
                    gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE --project=$PROJECT_ID
                    """
                }
            }
        }

        stage('Deploy with Ansible') {
            steps {
                sh '''
                cd ansible/playbooks
                ansible-playbook deploy-k8s.yml
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Deployment completed successfully!"
        }
        failure {
            echo "❌ Deployment failed!"
        }
    }
}
