pipeline {
    agent any
    
    environment {
        // Docker registry configuration
        DOCKER_REGISTRY = 'your-registry.com'
        DOCKER_REPO = 'cloud-native-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        
        // Kubernetes configuration
        KUBECONFIG = credentials('kubeconfig')
        
        // Maven configuration
        MAVEN_OPTS = '-Dmaven.repo.local=.m2/repository'
    }
    
    tools {
        maven 'Maven-3.9.0'
        jdk 'JDK-17'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }
        
        stage('Build and Test') {
            steps {
                echo 'Building and testing application...'
                sh '''
                    # Clean and compile
                    mvn clean compile
                    
                    # Run unit tests
                    mvn test
                    
                    # Package application
                    mvn package -DskipTests
                '''
            }
            post {
                always {
                    // Publish test results
                    publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                    
                    // Archive artifacts
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }
        
        stage('Code Quality Analysis') {
            parallel {
                stage('SonarQube Analysis') {
                    when {
                        branch 'main'
                    }
                    steps {
                        echo 'Running SonarQube analysis...'
                        script {
                            try {
                                withSonarQubeEnv('SonarQube') {
                                    sh 'mvn sonar:sonar'
                                }
                            } catch (Exception e) {
                                echo "SonarQube analysis failed: ${e.getMessage()}"
                            }
                        }
                    }
                }
                
                stage('Security Scan') {
                    steps {
                        echo 'Running security scan...'
                        sh '''
                            # Run OWASP dependency check
                            mvn org.owasp:dependency-check-maven:check || true
                        '''
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                script {
                    def dockerImage = docker.build("${DOCKER_REPO}:${IMAGE_TAG}")
                    
                    // Tag with latest for main branch
                    if (env.BRANCH_NAME == 'main') {
                        dockerImage.tag('latest')
                    }
                    
                    env.DOCKER_IMAGE = "${DOCKER_REPO}:${IMAGE_TAG}"
                }
            }
        }
        
        stage('Push Docker Image') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                echo 'Pushing Docker image to registry...'
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-registry-credentials') {
                        def dockerImage = docker.image("${DOCKER_REPO}:${IMAGE_TAG}")
                        dockerImage.push()
                        
                        if (env.BRANCH_NAME == 'main') {
                            dockerImage.push('latest')
                        }
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            when {
                branch 'main'
            }
            steps {
                echo 'Deploying to Kubernetes...'
                script {
                    sh '''
                        # Update deployment image
                        kubectl set image deployment/cloud-native-app \
                            cloud-native-app=${DOCKER_REGISTRY}/${DOCKER_REPO}:${IMAGE_TAG} \
                            --namespace=default
                        
                        # Wait for rollout to complete
                        kubectl rollout status deployment/cloud-native-app --namespace=default --timeout=300s
                        
                        # Verify deployment
                        kubectl get pods -l app=cloud-native-app --namespace=default
                    '''
                }
            }
        }
        
        stage('Integration Tests') {
            when {
                branch 'main'
            }
            steps {
                echo 'Running integration tests...'
                script {
                    sh '''
                        # Wait for service to be ready
                        kubectl wait --for=condition=ready pod -l app=cloud-native-app --namespace=default --timeout=120s
                        
                        # Get service endpoint
                        SERVICE_IP=$(kubectl get service cloud-native-app-service --namespace=default -o jsonpath='{.spec.clusterIP}')
                        
                        # Run integration tests
                        curl -f http://$SERVICE_IP/api/health || exit 1
                        curl -f http://$SERVICE_IP/api/hello || exit 1
                        
                        echo "Integration tests passed!"
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo 'Cleaning up...'
            sh '''
                # Clean up local Docker images
                docker image prune -f || true
                
                # Clean up workspace
                mvn clean || true
            '''
        }
        
        success {
            echo 'Pipeline completed successfully!'
            // Send success notification
            slackSend(
                channel: '#deployments',
                color: 'good',
                message: "✅ Build ${BUILD_NUMBER} succeeded for ${JOB_NAME}"
            )
        }
        
        failure {
            echo 'Pipeline failed!'
            // Send failure notification
            slackSend(
                channel: '#deployments',
                color: 'danger',
                message: "❌ Build ${BUILD_NUMBER} failed for ${JOB_NAME}"
            )
        }
    }
}
