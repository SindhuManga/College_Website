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
                        // Confirm Terraform path
                        bat 'where terraform'
                        echo "Running Terraform from ${TERRAFORM}"

                        // Run using full path
                        bat "\"${TERRAFORM}\" init"
                        bat "\"${TERRAFORM}\" plan -out=tfplan"
                        bat "\"${TERRAFORM}\" apply -auto-approve tfplan"
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image..."
                bat "docker build -t ${IMAGE_NAME}:latest ."
            }
        }

        stage('Push Docker Image to Docker Hub') {
            steps {
                echo "Pushing image to Docker Hub..."
                withCredentials([string(credentialsId: 'dockerhub-token', variable: 'DOCKERHUB_TOKEN')]) {
                    bat "echo %DOCKERHUB_TOKEN% | docker login -u %DOCKERHUB_USERNAME% --password-stdin"
                    retry(3) {
                        bat "docker push ${IMAGE_NAME}:latest"
                    }
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
                    bat "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}"
                    bat "docker tag ${IMAGE_NAME}:latest ${ECR_REPO}:latest"
                    bat "docker push ${ECR_REPO}:latest"
                }
            }
        }

        stage('Deploy to EC2 via SSM') {
            steps {
                script {
                    def instanceIp = bat(script: 'terraform output -raw instance_public_ip', returnStdout: true).trim()
                    echo "Deploying to EC2: ${instanceIp}"
                    bat """
                        aws ssm send-command ^
                        --targets "Key=instanceIds,Values=$(terraform output -raw instance_id)" ^
                        --document-name "AWS-RunShellScript" ^
                        --comment "Deploying Docker container" ^
                        --parameters "commands=[\\"docker run -d -p 80:80 ${ECR_REPO}:latest\\"]" ^
                        --region ${AWS_REGION}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline Completed Successfully!"
        }
        failure {
            echo "Pipeline Failed!"
        }
    }
}
