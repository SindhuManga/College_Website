pipeline {
    agent any

    environment {
        REGION = "eu-north-1"
        IMAGE_NAME = "sindhu2303/college-website"
        ECR_REPO = "944731154859.dkr.ecr.eu-north-1.amazonaws.com/ecr-repo"
        INSTANCE_NAME = "Terraform-ec2-docker-host"
        AWS_CLI = "aws"
        ECR_IMAGE_URL = "${ECR_REPO}:latest"
        DEPLOY_COMMANDS = 'docker stop college-website || true && docker rm college-website || true && aws ecr get-login-password --region eu-north-1 | docker login --username AWS --password-stdin 944731154859.dkr.ecr.eu-north-1.amazonaws.com/ecr-repo && docker pull 944731154859.dkr.ecr.eu-north-1.amazonaws.com/ecr-repo:latest && docker run -d -p 80:80 --name college-website 944731154859.dkr.ecr.eu-north-1.amazonaws.com/ecr-repo:latest'
    }

    stages {

        stage('Clone Repository') {
            steps {
                echo '📦 Cloning Repository...'
                git branch: 'main', url: 'https://github.com/SindhuManga/College_Website.git'
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                echo '🌍 Running Terraform to create AWS resources...'
                withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    dir('Terraform') {
                        bat 'terraform init'
                        bat 'terraform plan -out=tfplan'
                        bat 'terraform apply -auto-approve tfplan'
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                bat 'docker build -t %IMAGE_NAME%:latest .'
            }
        }

        stage('Push Image to Docker Hub') {
            steps {
                echo '🚢 Pushing image to Docker Hub...'
                withCredentials([string(credentialsId: 'dockerhub-token', variable: 'DOCKERHUB_TOKEN')]) {
                    bat 'docker login -u sindhu2303 -p %DOCKERHUB_TOKEN% && docker push %IMAGE_NAME%:latest'
                }
            }
        }

        stage('Push Image to AWS ECR') {
            steps {
                echo '🚀 Pushing image to AWS ECR...'
                withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
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

        stage('Deploy to EC2 via SSM') {
            steps {
                echo '🌐 Deploying new Docker image to EC2 via SSM...'
                withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    bat """
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

        stage('Fetch EC2 Public IP & DNS') {
            steps {
                echo '🔎 Fetching EC2 Public IP and DNS...'
                withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        def ip = bat(script: '"%AWS_CLI%" ec2 describe-instances --filters "Name=tag:Name,Values=%INSTANCE_NAME%" --query "Reservations[*].Instances[*].PublicIpAddress" --output text --region %REGION%', returnStdout: true).trim()
                        def dns = bat(script: '"%AWS_CLI%" ec2 describe-instances --filters "Name=tag:Name,Values=%INSTANCE_NAME%" --query "Reservations[*].Instances[*].PublicDnsName" --output text --region %REGION%', returnStdout: true).trim()

                        echo "✅ EC2 Instance Deployed Successfully!"
                        echo "🌍 Public IP: ${ip}"
                        echo "🧭 Public DNS: ${dns}"
                        echo "💡 Access your app at: http://${ip}"
                    }
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline Completed Successfully!'
        }
        failure {
            echo '❌ Pipeline Failed!'
        }
    }
}
