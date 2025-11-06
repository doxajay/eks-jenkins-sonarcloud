pipeline {
  agent any

  environment {
    AWS_DEFAULT_REGION = 'us-west-2'
    K8S_DIR = 'k8s'
    APP_DIR = 'app'
    REPO_NAME = 'acme-app-repo'
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Resolve AWS Account & ECR URL') {
      steps {
        sh '''
          ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
          echo "ACCOUNT_ID=$ACCOUNT_ID" > acct.env
          echo "ECR_URI=${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com" >> acct.env
          cat acct.env
        '''
        script {
          def props = readProperties file: 'acct.env'
          env.ACCOUNT_ID = props['ACCOUNT_ID']
          env.ECR_URI    = props['ECR_URI']
        }
      }
    }

    stage('Docker Login to ECR') {
      steps {
        sh '''
          aws ecr get-login-password --region $AWS_DEFAULT_REGION | \
          docker login --username AWS --password-stdin ${ECR_URI}
        '''
      }
    }

    stage('Build & Push Image') {
      steps {
        dir("${APP_DIR}") {
          sh '''
            docker build -t ${REPO_NAME}:latest .
            docker tag ${REPO_NAME}:latest ${ECR_URI}/${REPO_NAME}:latest
            docker push ${ECR_URI}/${REPO_NAME}:latest
          '''
        }
      }
    }

    stage('Update kubeconfig for EKS') {
      steps {
        sh '''
          # Dynamically find cluster name (matches Terraform output)
          CLUSTER_NAME=$(aws eks list-clusters --region ${AWS_DEFAULT_REGION} --query "clusters[0]" --output text)
          echo "Detected EKS cluster: $CLUSTER_NAME"

          aws eks update-kubeconfig --region ${AWS_DEFAULT_REGION} --name $CLUSTER_NAME
          kubectl get nodes
        '''
      }
    }

    stage('Deploy to EKS') {
      steps {
        sh '''
          # Replace image placeholder in deployment manifest
          sed -i "s|REPLACE_ECR_URI|${ECR_URI}|g" ${K8S_DIR}/deployment.yaml

          kubectl apply -f ${K8S_DIR}/deployment.yaml
          kubectl rollout status deployment/acme-flask-app
          kubectl get svc acme-flask-svc -o wide
        '''
      }
    }
  }

  post {
    success {
      echo '✅ Pipeline complete!'
    }
    failure {
      echo '❌ Build failed — check logs.'
    }
  }
}
