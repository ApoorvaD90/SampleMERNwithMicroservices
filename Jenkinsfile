pipeline {
  agent any
  environment {
    AWS_REGION       = 'us-east-1'
    ECR_REGISTRY     = "024757002386.dkr.ecr.us-east-1.amazonaws.com"
    EKS_CLUSTER_NAME = 'streaming-app-cluster'
    IMAGE_TAG        = "${env.BUILD_NUMBER}"
    HELLO_REPO       = 'streaming-app/helloservice'
    PROFILE_REPO     = 'streaming-app/profileservice'
    FRONTEND_REPO    = 'streaming-app/frontend'
    SNS_TOPIC_ARN    = 'arn:aws:sns:us-east-1:024757002386:streaming-app-deployments'
  }
  stages {
    stage('Checkout') { steps { checkout scm } }
    stage('Build Docker Images') {
      parallel {
        stage('helloService') { steps {
          sh "docker build -t ${ECR_REGISTRY}/${HELLO_REPO}:${IMAGE_TAG} ./backend/helloService"
        }}
        stage('profileService') { steps {
          sh "docker build -t ${ECR_REGISTRY}/${PROFILE_REPO}:${IMAGE_TAG} ./backend/profileService"
        }}
        stage('Frontend') { steps {
          withCredentials([string(credentialsId: 'INGRESS_HOST', variable: 'INGRESS_HOST')]) {
            sh """
              docker build \\
                --build-arg REACT_APP_HELLO_URL=http://${INGRESS_HOST}/api/hello \\
                --build-arg REACT_APP_PROFILE_URL=http://${INGRESS_HOST}/api/profile \\
                -t ${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG} ./frontend
            """
          }
        }}
      }
    }
    stage('Push to ECR') { steps {
      withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials-apoorva']]) {
        sh """
          aws ecr get-login-password --region ${AWS_REGION} | \\
            docker login --username AWS --password-stdin ${ECR_REGISTRY}
          docker push ${ECR_REGISTRY}/${HELLO_REPO}:${IMAGE_TAG}
          docker push ${ECR_REGISTRY}/${PROFILE_REPO}:${IMAGE_TAG}
          docker push ${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG}
          docker tag ${ECR_REGISTRY}/${HELLO_REPO}:${IMAGE_TAG} ${ECR_REGISTRY}/${HELLO_REPO}:latest
          docker push ${ECR_REGISTRY}/${HELLO_REPO}:latest
        """
      }
    }}
    stage('Deploy to EKS') { steps {
      withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials-apoorva']]) {
        withCredentials([string(credentialsId: 'INGRESS_HOST', variable: 'INGRESS_HOST')]) {
          sh """
            aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
            helm upgrade --install streaming-app ./helm/streaming-app \\
              --namespace streaming-app --create-namespace \\
              --set global.imageRegistry=${ECR_REGISTRY} \\
              --set helloService.image.tag=${IMAGE_TAG} \\
              --set profileService.image.tag=${IMAGE_TAG} \\
              --set frontend.image.tag=${IMAGE_TAG} \\
              --set ingress.host=\${INGRESS_HOST} \\
              --set mongodb.persistence.enabled=false \\
              --wait --timeout 5m
          """
        }
      }
    }}
  }

  post {
    success {
      withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials-apoorva']]) {
        sh """
          aws sns publish --region ${AWS_REGION} \
            --topic-arn ${SNS_TOPIC_ARN_APOORVA} \
            --subject 'Jenkins Build SUCCESS' \
            --message 'Build ${IMAGE_TAG} deployed successfully to EKS.'
        """
      }
      echo "Build ${IMAGE_TAG} deployed successfully."
    }
    failure {
      withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials-apoorva']]) {
        sh """
          aws sns publish --region ${AWS_REGION} \
            --topic-arn ${SNS_TOPIC_ARN_APOORVA} \
            --subject 'Jenkins Build FAILED' \
            --message 'Build ${IMAGE_TAG} FAILED. Check Jenkins console for details.'
        """
      }
      echo "Build ${IMAGE_TAG} FAILED."
    }
    always  { sh "docker system prune -f || true" }
  }
}