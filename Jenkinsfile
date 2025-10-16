pipeline {
    agent any

    environment {
        IMAGE_NAME = "sindhu2303/college-website"
        ECR_REPO = "944731154859.dkr.ecr.eu-north-1.amazonaws.com/ecr-repo"
        REGION = "eu-north-1"
        AWS_CLI = "C:\\Program Files\\Amazon\\AWSCLIV2\\aws.exe"
        INSTANCE_NAME = "Terraform-ec2-docker-host" 
        # Define the full ECR image URL here for clean use later
        ECR_IMAGE_URL = "${ECR_REPO}:latest"
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
                    bat """
                    docker login -u sindhu2303 -p %DOCKERHUB_TOKEN%
                    docker push %IMAGE_NAME%:latest
                    """
                }
            }
        }

        stage('Push to AWS ECR') {
            steps {
                echo '🚀 Pushing image to AWS ECR...'
                withCredentials([usernamePassword(credentialsId: 'aws-ecr-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    bat """
                    REM Set credentials for AWS CLI session
                    set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                    set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                    
                    REM ECR login and push
                    "%AWS_CLI%" ecr get-login-password --region %REGION% | docker login --username AWS --password-stdin %ECR_REPO%
                    docker tag %IMAGE_NAME%:latest %ECR_IMAGE_URL%
                    docker push %ECR_IMAGE_URL%
                    """
                }
            }
        }
        
        // --- THIS STAGE HAS THE CRITICAL BATCH SYNTAX FIX ---
        stage('Deploy to EC2 (via SSM)') {
            steps {
                echo '🌐 Deploying new image to EC2 via AWS Systems Manager (SSM)...'
                withCredentials([usernamePassword(credentialsId: 'aws-ecr-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    // This is the combined script that will run ON the EC2 instance
                    def deploymentScript = """
                        docker stop college-website || true && \\
                        docker rm college-website || true && \\
                        aws ecr get-login-password --region %REGION% | docker login --username AWS --password-stdin %ECR_REPO% && \\
                        docker pull %ECR_IMAGE_URL% && \\
                        docker run -d -p 80:80 --name college-website %ECR_IMAGE_URL%
                    """
                    
                    // We use bat and the ^ continuation character to pass the complex script correctly
                    bat """
                    REM Send the command to the EC2 instance
                    "%AWS_CLI%" ssm send-command ^
                        --targets "Key=tag:Name,Values=%INSTANCE_NAME%" ^
                        --document-name "AWS-RunShellScript" ^
                        --parameters commands="${deploymentScript}" ^
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
