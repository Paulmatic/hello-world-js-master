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
        FULL_IMAGE_PATH = "us-central1-docker.pkg.dev/${PROJECT_ID}/${REPO}/${IMAGE_NAME}:${IMAGE_TAG}"
        CLUSTER_NAME = "my-cluster"
        KUBE_CONFIG = credentials('gke-kubeconfig')  
        LOCAL_KUBECONFIG = '~/.kube/config'  
        GIT_CREDENTIALS_ID = 'github-credentials'
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', credentialsId: "${GIT_CREDENTIALS_ID}", url: "${REPO_URL}"
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

        stage('Build & Push Docker Image') {
            steps {
                withCredentials([file(credentialsId: 'gcp-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh """
                    set -e
                    echo "🔨 Building Docker image: ${FULL_IMAGE_PATH}"
                    docker build -t ${FULL_IMAGE_PATH} .

                    echo "🔑 Authenticating to Google Artifact Registry..."
                    gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}
                    gcloud auth configure-docker us-central1-docker.pkg.dev

                    echo "🚀 Pushing Docker image to Artifact Registry..."
                    docker push ${FULL_IMAGE_PATH}
                    """
                }
            }
        }

        stage('Authenticate with GKE') {
            steps {
                withCredentials([file(credentialsId: 'gcp-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh """
                    set -e
                    gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}
                    gcloud container clusters get-credentials ${CLUSTER_NAME} --zone=${ZONE} --project=${PROJECT_ID}
                    """
                }
            }
        }

        stage('Deploy & Update Image in Kubernetes') {
            steps {
                script {
                    def namespaces = ["testing", "staging", "production"]
                    for (ns in namespaces) {
                        def deploymentName = "hello-world-${ns}"
                        def containerName = "hello-world"

                        def exists = sh(script: "kubectl get deployment ${deploymentName} -n ${ns} --ignore-not-found", returnStdout: true).trim()
                        if (!exists) {
                            echo "🚀 Deployment '${deploymentName}' not found in '${ns}', applying YAML..."
                            sh "kubectl apply -f deployment/${ns}/deployment.yaml --namespace=${ns}"
                            sleep(10)
                        }

                        echo "🔄 Updating image for '${deploymentName}' in '${ns}'..."
                        sh """
                        set -e
                        kubectl set image deployment/${deploymentName} ${containerName}=${FULL_IMAGE_PATH} --namespace=${ns}
                        kubectl rollout status deployment/${deploymentName} --namespace=${ns}
                        """
                    }
                }
            }
        }

        stage('Deploy Services') {
            steps {
                script {
                    def namespaces = ["testing", "staging", "production"]
                    for (ns in namespaces) {
                        echo "🚀 Deploying service in ${ns}..."
                        sh """
                        set -e
                        kubectl apply -f deployment/${ns}/service.yaml --namespace=${ns}
                        """
                    }
                }
            }
        }

        stage('Apply ArgoCD Configuration') {
            steps {
                sh """
                set -e
                echo "🔄 Applying ArgoCD Configuration..."
                kubectl apply -f argocd/argocd.yaml -n argocd
                """
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
