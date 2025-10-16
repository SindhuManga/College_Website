pipeline {
    agent any

    environment {
        IMAGE_NAME = "sindhu2303/college-website"
        ECR_REPO = "944731154859.dkr.ecr.eu-north-1.amazonaws.com/ecr-repo"
        REGION = "eu-north-1"
    }

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/SindhuManga/College_Website.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                bat """
                docker build -t ${IMAGE_NAME}:latest .
                """
            }
        }

        stage('Login to ECR') {
            steps {
                bat """
                aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
                """
            }
        }

        stage('Tag & Push to ECR') {
            steps {
                bat """
                docker tag ${IMAGE_NAME}:latest ${ECR_REPO}:latest
                docker push ${ECR_REPO}:latest
                """
            }
        }

        stage('Deploy on EC2 via SSM') {
            steps {
                bat """
                aws ssm send-command ^
                    --targets "Key=instanceIds,Values=$$(terraform output -raw instance_id)" ^
                    --document-name "AWS-RunShellScript" ^
                    --comment "Deploy Docker container" ^
                    --parameters "commands=[
                        \\"docker pull ${ECR_REPO}:latest\\",
                        \\"docker stop ${IMAGE_NAME} || true\\",
                        \\"docker rm ${IMAGE_NAME} || true\\",
                        \\"docker run -d --name ${IMAGE_NAME} -p 80:80 ${ECR_REPO}:latest\\"
                    ]" ^
                    --region ${REGION}
                """
            }
        }
    }
}
