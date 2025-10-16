pipeline {
    agent any

    environment {
        // --- AWS / IMAGE CONFIG ---
        IMAGE_NAME = "sindhu2303/college-website"
        ECR_REPO = "944731154859.dkr.ecr.eu-north-1.amazonaws.com/ecr-repo"
        REGION = "eu-north-1"
        INSTANCE_NAME = "Terraform-ec2-docker-host" 
        AWS_CLI = "C:\\Program Files\\Amazon\\AWSCLIV2\\aws.exe"

        // Construct the full ECR image URL
        ECR_IMAGE_URL = "${ECR_REPO}:latest"

        // --- DEPLOYMENT SCRIPT DEFINITION ---
        // Define the entire deployment script as a single JSON string for guaranteed passing to SSM
        DEPLOY_COMMANDS = 'docker stop college-website || true; docker rm college-website || true; aws ecr get-login-password --region eu-north-1 | docker login --username AWS --password-stdin 944731154859.dkr.ecr.eu-north-1.amazonaws.com/ecr-repo; docker pull 944731154859.dkr.ecr.eu-north-1.amazonaws.com/ecr-repo:latest; docker run -d -p 80:80 --name college-website 944731154859.dkr.ecr.eu-north-1.amazonaws.com/ecr-repo:latest'
    }

    stages {
        stage('Clone Repository') {
            steps {
                echo '📦 Cloning repository...'
                git branch: 'main', url: 'https://github.com/SindhuManga/College_Website.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                bat 'docker build -t %IMAGE_NAME%:latest .'
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo '🚢 Pushing image to Docker Hub...'
                withCredentials([string(credentialsId: 'dockerhub-token', variable: 'DOCKERHUB_TOKEN')]) {
                    bat 'docker login -u sindhu2303 -p %DOCKERHUB_TOKEN% && docker push %IMAGE_NAME%:latest'
                }
            }
        }

        stage('Push to AWS ECR') {
            steps {
                echo '🚀 Pushing image to AWS ECR...'
                withCredentials([usernamePassword(credentialsId: 'aws-ecr-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    bat """
                    set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                    set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                    
                    "%AWS_CLI%" ecr get-login-password --region %REGION% | docker login --username AWS --password-stdin %ECR_REPO%
                    docker tag %IMAGE_NAME%:latest %ECR_IMAGE_URL%
                    docker push %ECR_IMAGE_URL%
                    """
                }
            }
        }
        
        stage('Deploy to EC2 (via SSM)') {
            steps {
                echo '🌐 Deploying new image to EC2 via AWS Systems Manager (SSM)...'
                withCredentials([usernamePassword(credentialsId: 'aws-ecr-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    
                    // The DEPLOY_COMMANDS variable contains the entire script string, 
                    // which is now passed cleanly to the SSM send-command parameter.
                    bat """
                    REM The AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are automatically used by the AWS CLI.
                    "%AWS_CLI%" ssm send-command ^
                        --targets "Key=tag:Name,Values=%INSTANCE_NAME%" ^
                        --document-name "AWS-RunShellScript" ^
                        --parameters commands="%DEPLOY_COMMANDS%" ^
                        --timeout-seconds 600 ^
                        --region %REGION%
                    """
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline complete! Image built and deployed to EC2 successfully!'
        }
        failure {
            echo '❌ Build and deployment failed!'
        }
    }
}