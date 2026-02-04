#!/bin/bash

userid=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD

if [ $userid -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1
fi
mkdir -p $LOGS_FOLDER

validate(){
    if [ $1 -ne 0 ]; then
       echo -e "$2 ... $R Failure $N" | tee -a $LOGS_FILE
       exit 1
    else
        echo -e "$2 ... $G Success $N" | tee -a $LOGS_FILE
    fi
}

if command -v node &>/dev/null && node -v | grep -q "^v20"; then
    echo -e "Nodejs 20 is already installed ... $Y Skipping $N" | tee -a $LOGS_FILE
else
    dnf module disable nodejs -y &>> $LOGS_FILE
    dnf module enable nodejs:20 -y &>> $LOGS_FILE 
    validate $? "Enabling Nodejs 20 Version"
    dnf install nodejs -y &>> $LOGS_FILE
    validate $? "Installing Nodejs"
fi 

id roboshop &>> $LOGS_FILE
   if [ $? -ne 0 ]; then
      useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
      validate $? "Creating System User"
    else
       echo -e "Roboshop user already exists ... $Y Skipping $N"
    fi
mkdir -p /app 
validate $? "Creating Application Directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>> $LOGS_FILE
validate $? "Downloading User App Content"

cd /app 
validate $? "Moving to App Directory"

rm -rf /app/*
VALIDATE $? "Removing Existing Code"

unzip /tmp/user.zip &>> $LOGS_FILE
validate $? "Extracting User App Content"

npm install &>> $LOGS_FILE
validate $? "Installing Nodejs Dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service &>> $LOGS_FILE
validate $? "Copying User Service File"

systemctl daemon-reload
systemctl enable user &>> $LOGS_FILE
systemctl start user
validate $? "Enabled and Started User Service"

