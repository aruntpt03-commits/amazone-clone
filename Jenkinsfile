pipeline {
  agents any

  tools{
    jdk 'JDK'
    nodejs 'NodeJS'
  }

  parameters {
    string(name: 'ECR_REPO_NAME', defaultValue: 'amazon-prime', description: 'Enter the name of the ECR repository')
    string(name: 'AWS_ACCOUNT_ID', defaultValue: '', description: 'Enter the AWS Account ID')
  }
  environment {
    SCANNER_HOME = tool 'SonarQube Scanner'

  }
   stages {
        stage('1.Git Checkout') {
            steps {
               git branch: 'main', url: 'https://github.com/aruntpt03-commits/amazone-clone.git'
            }
        }

        stage('2. SonarQube Analysis') {
            steps {
               withSonarQubeEnv(sonar-server) {
                 $SCANNER_HOME/bin/sonar-scanner \
                 -Dsonar.projectName=amazon-prime \
                 -Dsonar.projectKey=amazon-prime 
                }
            }
        }

         stage('3. SonarQube Quality Gate') {
            steps {
               waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
                }
            }
        stage('4. NPM Install') {
            steps {
               sh 'npm install'
                }
            }

         stage('5. Trivy Scan') {
             steps { 
                sh 'trivy fs > trivy_report.txt'
             }
        }
        stage('6. Docker Image Build') {
             steps {
                sh 'docker build -t ${params.ECR_REPO_NAME} .'
             }
        }
        stage('7. Create ECR Repository') {
             steps {
                withCredentials([string(credentialsId: 'access-key', variable: 'AWS_ACCESS_KEY'), string(credentialsId: 'secret-key', variable: 'AWS_SECRET_KEY')]) {
                 sh """
                 aws configure set aws_access_key_id $AWS_ACCESS_KEY
                 aws configure set aws_secret_access_key $AWS_SECRET_KEY
                 aws ecr describe-repositories --repository-names ${params.ECR_REPO_NAME} --region us-east-1 || \
                 aws ecr create-repository --repository-name ${params.ECR_REPO_NAME} --region us-east-1
                    """
                   }
             }
        }
        stage('8. Login to ECR & Tag Image') {
             steps {
                withCredentials([string(credentialsId: 'access-key', variable: 'AWS_ACCESS_KEY'), string(credentialsId: 'secret-key', variable: 'AWS_SECRET_KEY')]) {
                 sh """
                  aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${params.AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com
                  docker tag ${params.ECR_REPO_NAME} ${params.AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/${params.ECR_REPO_NAME}:$BUILD_NUMBER      
                  docker tag ${params.ECR_REPO_NAME} ${params.AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/${params.ECR_REPO_NAME}:latest       
                    """
                   }
             }
        }
        stage('9. Push Image to ECR') {
             steps {
                withCredentials([string(credentialsId: 'access-key', variable: 'AWS_ACCESS_KEY'), string(credentialsId: 'secret-key', variable: 'AWS_SECRET_KEY')]) {
                 sh """
                 docker push ${params.AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/${params.ECR_REPO_NAME}:$BUILD_NUMBER
                  docker push ${params.AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/${params.ECR_REPO_NAME}:latest
                  """
                   }
             }
        }
         stage('10. Cleanup images from jenkins server') {
             steps {
                sh """
                  docker rmi ${params.AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/${params.ECR_REPO_NAME}:$BUILD_NUMBER
                  docker rmi ${params.AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/${params.ECR_REPO_NAME}:latest
                """
                   }
             }
        }
        
        }

