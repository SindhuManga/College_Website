pipeline {
    agent any

    environment {
        IMAGE_NAME = "college-website"
        ECR_REPO = "944731154859.dkr.ecr.eu-north-1.amazonaws.com/ecr-repo"
        REGION = "eu-north-1"
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo "📥 Checking out code from Git..."
                git url: 'https://github.com/SindhuManga/College_Website.git', branch: 'main'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image..."
                bat """
                docker build -t ${IMAGE_NAME}:latest .
                """
            }
        }

        stage('Login to ECR') {
            steps {
                echo "🔑 Logging into AWS ECR..."
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
                    credentialsId: 'your-aws-credentials-id'
                ]]) {
                    bat """
                    aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
                    """
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                echo "🚀 Pushing Docker image to ECR..."
                bat """
                docker tag ${IMAGE_NAME}:latest ${ECR_REPO}:latest
                docker push ${ECR_REPO}:latest
                """
            }
        }

        stage('Deploy to EC2 via SSM') {
            steps {
                echo "📦 Deploying Docker container to EC2..."
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
                    credentialsId: 'your-aws-credentials-id'
                ]]) {
                    retry(3) {
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

    }

    post {
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
