pipeline {
    agent any

    environment {
        IMAGE_NAME = "sindhu2303/college-website"
        ECR_REPO = "944731154859.dkr.ecr.eu-north-1.amazonaws.com/ecr-repo"
        REGION = "eu-north-1"
        AWS_CREDENTIALS_ID = "your-aws-credentials-id"
        DOCKERHUB_TOKEN_ID = "dockerhub-token"
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo "📥 Checking out code from GitHub..."
                git url: 'https://github.com/SindhuManga/College_Website.git', branch: 'main'
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                echo "🌱 Running Terraform to create AWS resources..."
                dir('Terraform') {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
                        credentialsId: "${AWS_CREDENTIALS_ID}"
                    ]]) {
                        bat 'terraform init'
                        bat 'terraform plan -out=tfplan'
                        bat 'terraform apply -auto-approve tfplan'
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🛠️ Building Docker image..."
                bat 'docker build -t %IMAGE_NAME%:latest .'
            }
        }

        stage('Push Image to Docker Hub') {
            steps {
                echo "📤 Pushing image to Docker Hub..."
                withCredentials([string(credentialsId: "${DOCKERHUB_TOKEN_ID}", variable: 'DOCKERHUB_TOKEN')]) {
                    bat 'docker login -u sindhu2303 -p %DOCKERHUB_TOKEN%'
                    bat 'docker push %IMAGE_NAME%:latest'
                }
            }
        }

        stage('Push Image to AWS ECR') {
            steps {
                echo "🚀 Pushing image to AWS ECR..."
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
                    credentialsId: "${AWS_CREDENTIALS_ID}"
                ]]) {
                    retry(3) {
                        bat 'aws ecr get-login-password --region %REGION% | docker login --username AWS --password-stdin %ECR_REPO%'
                        bat 'docker tag %IMAGE_NAME%:latest %ECR_REPO%:latest'
                        bat 'docker push %ECR_REPO%:latest'
                    }
                }
            }
        }

        stage('Get EC2 Instance ID') {
            steps {
                echo "🔍 Fetching EC2 instance ID from Terraform output..."
                script {
                    // Store Terraform instance ID in a Windows environment variable
                    def instanceId = bat(returnStdout: true, script: 'terraform output -raw instance_id').trim()
                    env.INSTANCE_ID = instanceId
                    echo "EC2 Instance ID: ${env.INSTANCE_ID}"
                }
            }
        }

        stage('Deploy to EC2 via SSM') {
            steps {
                echo "🚢 Deploying Docker container to EC2 via SSM..."
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
                    credentialsId: "${AWS_CREDENTIALS_ID}"
                ]]) {
                    retry(3) {
                        bat """
aws ssm send-command ^
    --targets "Key=instanceIds,Values=%INSTANCE_ID%" ^
    --document-name "AWS-RunShellScript" ^
    --comment "Deploy Docker container" ^
    --parameters "commands=[\\"docker pull %ECR_REPO%:latest\\",\\"docker stop college-website || true\\",\\"docker rm college-website || true\\",\\"docker run -d --name college-website -p 80:80 %ECR_REPO%:latest\\"]" ^
    --region %REGION%
"""
                    }
                }
            }
        }

        stage('Fetch EC2 Public IP & DNS') {
            steps {
                echo "🌐 Fetching EC2 Public IP & DNS..."
                bat 'terraform output'
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline Succeeded!"
        }
        failure {
            echo "❌ Pipeline Failed!"
        }
    }
}
