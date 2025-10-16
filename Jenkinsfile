pipeline {
    agent any

    environment {
        IMAGE_NAME = "sindhu2303/college-website"
        ECR_REPO = "944731154859.dkr.ecr.eu-north-1.amazonaws.com/ecr-repo"
        REGION = "eu-north-1"
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
                        credentialsId: 'your-aws-credentials-id'
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
                bat "docker build -t ${IMAGE_NAME}:latest ."
            }
        }

        stage('Push Image to Docker Hub') {
            steps {
                echo "📤 Pushing image to Docker Hub..."
                withCredentials([string(credentialsId: 'dockerhub-token', variable: 'DOCKERHUB_TOKEN')]) {
                    bat """
                    docker login -u sindhu2303 -p %DOCKERHUB_TOKEN%
                    docker push ${IMAGE_NAME}:latest
                    """
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
                    credentialsId: 'your-aws-credentials-id'
                ]]) {
                    retry(3) { // Retry on failure
                        bat """
                        aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
                        docker tag ${IMAGE_NAME}:latest ${ECR_REPO}:latest
                        docker push ${ECR_REPO}:latest
                        """
                    }
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
                    credentialsId: 'your-aws-credentials-id'
                ]]) {
                    retry(3) {
                        bat """
                        aws ssm send-command \
                            --targets "Key=instanceIds,Values=$(terraform output -raw instance_id)" \
                            --document-name "AWS-RunShellScript" \
                            --comment "Deploy Docker container" \
                            --parameters 'commands=[
                                "docker pull ${ECR_REPO}:latest",
                                "docker stop college-website || true",
                                "docker rm college-website || true",
                                "docker run -d --name college-website -p 80:80 ${ECR_REPO}:latest"
                            ]' \
                            --region ${REGION}
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
