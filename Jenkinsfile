pipeline {
    agent any
    environment {
        IMAGE_NAME = "sindhu2303/college-website"
        DOCKERHUB_USERNAME = "sindhu2303"
        DOCKERHUB_TOKEN = credentials('dockerhub-token')
        AWS_REGION = 'eu-north-1'
        ECR_REPO = '944731154859.dkr.ecr.eu-north-1.amazonaws.com/ecr-repo'
        TERRAFORM = 'C:\\terraform_1.13.3_windows_386\\terraform.exe'
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/SindhuManga/College_Website.git'
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                dir('Terraform') {
                    withCredentials([[ 
                        $class: 'AmazonWebServicesCredentialsBinding',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
                        credentialsId: 'aws-creds'
                    ]]) {
                        bat """
                            set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                            set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                            "%TERRAFORM%" init
                            "%TERRAFORM%" plan -out=tfplan
                            "%TERRAFORM%" apply -auto-approve tfplan
                        """
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image..."
                bat "docker build -t %IMAGE_NAME%:latest ."
            }
        }

        stage('Push Docker Image to Docker Hub') {
            steps {
                echo "Pushing image to Docker Hub..."
                withCredentials([string(credentialsId: 'dockerhub-token', variable: 'DOCKERHUB_TOKEN')]) {
                    bat """
                        echo %DOCKERHUB_TOKEN% | docker login -u %DOCKERHUB_USERNAME% --password-stdin
                        docker push %IMAGE_NAME%:latest
                    """
                }
            }
        }

        stage('Push Docker Image to AWS ECR') {
            steps {
                withCredentials([[ 
                    $class: 'AmazonWebServicesCredentialsBinding',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
                    credentialsId: 'aws-creds'
                ]]) {
                    bat """
                        aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %ECR_REPO%
                        docker tag %IMAGE_NAME%:latest %ECR_REPO%:latest
                        docker push %ECR_REPO%:latest
                    """
                }
            }
        }

        stage('Deploy to EC2 via SSM') {
            steps {
                script {
                    bat """
                        for /f %%i in ('"%TERRAFORM%" output -raw instance_public_ip') do set INSTANCE_IP=%%i
                        for /f %%j in ('"%TERRAFORM%" output -raw instance_id') do set INSTANCE_ID=%%j
                        echo Deploying to EC2: %INSTANCE_IP%
                        aws ssm send-command ^
                        --targets "Key=instanceIds,Values=%INSTANCE_ID%" ^
                        --document-name "AWS-RunShellScript" ^
                        --comment "Deploying Docker container" ^
                        --parameters "commands=[\\"docker run -d -p 80:80 %ECR_REPO%:latest\\"]" ^
                        --region %AWS_REGION%
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline Completed Successfully!"
        }
        failure {
            echo "❌ Pipeline Failed!"
        }
    }
}
