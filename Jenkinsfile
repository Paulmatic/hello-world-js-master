pipeline {
    agent any

    environment {
        REPO_URL = 'https://github.com/Paulmatic/hello-world-js-master'
        IMAGE_NAME = 'paulmug/hello-world-js'
        GCP_KEY = credentials('gcp-key')  // GCP service account JSON
        PROJECT_ID = 'civic-network-453215-s8'  // GCP Project ID
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

        stage('Ensure Deployment Exists Before Updating Image') {
            steps {
                script {
                    def namespaces = ["testing", "staging", "production"]
                    for (ns in namespaces) {
                        def deploymentName = ns == "testing" ? "hello-world-test" : "hello-world-js"
                        def containerName = "hello-world"

                        def exists = sh(script: "kubectl get deployment ${deploymentName} -n ${ns} --ignore-not-found", returnStdout: true).trim()
                        if (!exists) {
                            echo "Deployment '${deploymentName}' not found in namespace '${ns}'. Creating it now..."
                            sh "kubectl apply -f deployment/${ns}/deployment.yaml --namespace=${ns}"
                            sleep(10)
                        }
                        sh """
                        kubectl set image deployment/${deploymentName} ${containerName}=$FULL_IMAGE_PATH --namespace=${ns}
                        kubectl rollout status deployment/${deploymentName} --namespace=${ns}
                        """
                    }
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