pipeline {
  agents any

  parameters {
    string(name: 'ACR_REPO_NAME', defaultValue: 'amazon-clone', description: 'Azure Container Registry Repository Name')
  }
  environment {
    SCANNER_HOME = tool 'Sonarqube Scanner'
  
   stages {
        stage('1.Git Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/aruntpt03-commits/amazon-clone.git'
            }
        }

        stage('2. SonarQube Analysis') {
            steps {
               withSonarQubeEnv(sonarqube) {
                 $SCANNER_HOME/bin/sonar-scanner \
                 -Dsonar.projectName=Amazon-Clone \
                 -Dsonar.projectKey=Amazon-Clone 
                 
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
                sh 'docker build -t ${ACR_REPO_NAME} .'
             }
        }
        stage('7. Create ACR Repository') {
             steps {
                withCredentials([string(credentialsId: 'azure-app', variable: 'AZURE_ACCESS_KEY'), string(credentialsId: 'azure-secret', variable: 'AZURE_SECRET_KEY')]) {
                   // some block
                 }
             }
        }
        
        }

    }

}
