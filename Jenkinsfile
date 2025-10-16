pipeline {
    agent any
    environment {
        IMAGE_NAME = "college-website"
        AWS_REGION = 'eu-north-1'
        ECR_REPO = '944731154859.dkr.ecr.eu-north-1.amazonaws.com/college-website'
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
                        bat 'terraform init'
                        bat 'terraform plan -out=tfplan'
                        bat 'terraform apply -auto-approve tfplan'
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                bat "docker build -t ${IMAGE_NAME}:latest ."
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
                    bat "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}"
                    bat "docker tag ${IMAGE_NAME}:latest ${ECR_REPO}:latest"
                    retry(3) { bat "docker push ${ECR_REPO}:latest" }
                }
            }
        }

        stage('Deploy to EC2 via SSM') {
            steps {
                script {
                    // Fetch Terraform outputs
                    def instanceId = bat(script: "terraform output -raw instance_id", returnStdout: true).trim()
                    echo "Deploying Docker container to EC2 instance: ${instanceId}"

                    // Run container on EC2 via SSM
                    bat """
                        aws ssm send-command ^
                        --targets "Key=InstanceIds,Values=${instanceId}" ^
                        --document-name "AWS-RunShellScript" ^
                        --comment "Deploy Docker container" ^
                        --parameters "commands=[\\"docker run -d -p 80:80 ${ECR_REPO}:latest\\"]"
                    """
                }
            }
        }
    }

    post {
        success { echo "Pipeline completed successfully!" }
        failure { echo "Pipeline failed!" }
    }
}
