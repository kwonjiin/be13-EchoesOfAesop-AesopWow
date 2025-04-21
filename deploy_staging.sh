#!/bin/bash

echo "🚀 배포 시작..."

# EC2 정보
HOST=ubuntu@43.200.135.130
PEM_FILE=$HOME/aesop.pem
JAR_NAME=be13-2nd-AesopWow-EchoesOfAesop-0.0.1-SNAPSHOT.jar
TARGET_PATH=/home/ubuntu

# EC2에 접속해서 기존 앱 중지 (PID 기반 종료 또는 pkill)
ssh -i $PEM_FILE $HOST "pkill -f $JAR_NAME || echo '앱이 실행 중이지 않음'"

# 새 jar 파일 업로드
scp -i $PEM_FILE target/$JAR_NAME $HOST:$TARGET_PATH

# EC2에서 새 앱 실행 (백그라운드로 실행)
ssh -i $PEM_FILE $HOST "nohup java -jar $TARGET_PATH/$JAR_NAME > /dev/null 2>&1 &"

echo "✅ 배포 완료!"
