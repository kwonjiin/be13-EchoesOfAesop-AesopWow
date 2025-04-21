pipeline {
    agent {
        kubernetes {
            yaml '''
            apiVersion: v1
            kind: Pod
            metadata:
              name: jenkins-agent
            spec:
              containers:
              - name: maven
                image: gradle:8.5-jdk21-alpine
                command: ["cat"]
                tty: true
              - name: docker
                image: docker:27.2.0-alpine3.20
                command: ["cat"]
                tty: true
                resources:
                  requests:
                    memory: "2Gi"
                    cpu: "1"
                  limits:
                    memory: "4Gi"
                    cpu: "2"
                volumeMounts:
                - mountPath: "/var/run/docker.sock"
                  name: docker-socket
              volumes:
              - name: docker-socket
                hostPath:
                  path: "/var/run/docker.sock"
            '''
        }
    }

    environment {
        DOCKER_IMAGE_NAME = 'jimiin/aesop-api'
        DOCKER_CREDENTIALS_ID = 'dockerhub-access'
    }

    stages {
        stage('Gradle Build') {
            steps {
                container('gradle') {
                    sh './gradlew clean build -x test'
                    sh 'ls -al ./build/libs'
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                container('docker') {
                    script {
                        def dockerImageVersion = "${env.BUILD_NUMBER}"
                        sh 'docker logout'

                        withCredentials([usernamePassword(
                            credentialsId: "${DOCKER_CREDENTIALS_ID}",
                            usernameVariable: 'DOCKER_USERNAME',
                            passwordVariable: 'DOCKER_PASSWORD'
                        )]) {
                            sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                        }

                        withEnv(["DOCKER_IMAGE_VERSION=${dockerImageVersion}"]) {
                            sh 'cp ./build/libs/be13-2nd-AesopWow-EchoesOfAesop-0.0.1-SNAPSHOT.jar ./'
                            sh 'docker build --no-cache -f Docker/01_docker/Dockerfile -t $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_VERSION ./'
                            sh 'docker push $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_VERSION'
                        }
                    }
                }
            }
        }

        stage('Trigger aesop-k8s-manifests') {
            steps {
                script{
                    script {
                        def dockerImageVersion = "${env.BUILD_NUMBER}"

                        withEnv(["DOCKER_IMAGE_VERSION=${dockerImageVersion}"]) {
                            build job: 'aesop-k8s-manifests',
                                parameters: [
                                    string(name: "DOCKER_IMAGE_VERSION", value: "${DOCKER_IMAGE_VERSION}")
                                ],
                                wait: true
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            withCredentials([string(
                credentialsId: 'discord-webhook',
                variable: 'DISCORD_WEBHOOK_URL'
            )]) {
                discordSend description: """
                제목 : ${currentBuild.displayName}
                결과 : ${currentBuild.result}
                실행 시간 : ${currentBuild.duration / 1000}s
                """,
                result: currentBuild.currentResult,
                title: "${env.JOB_NAME} : ${currentBuild.displayName}",
                webhookURL: "${DISCORD_WEBHOOK_URL}"
            }
        }
    }
}
