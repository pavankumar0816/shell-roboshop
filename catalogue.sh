#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE=""$LOGS_FOLDER/$0.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.pmpkdev.online

if [ $USERID -ne 0 ]; then
      echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
      exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
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
dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "Disabling Nodejs Default Version"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "Enabling Nodejs 20 version"

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Installing Nodejs"
fi

id roboshop &>>$LOGS_FILE
  if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $? "Creating System user"
  else
    echo -e "Roboshop user alrwady eixts ... $Y Skipping $N"
fi

mkdir -p /app 
VALIDATE $? "Creating Directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading Catalogue App Content"

cd /app
VALIDATE $? "Moving to App Directory"

rm -rf /app/*
VALIDATE $? "Removing Existing Code"

unzip /tmp/catalogue.zip &>>$LOGS_FILE
VALIDATE $? "Extracting Catalogue App Content"

npm install &>>$LOGS_FILE
VALIDATE $? "Installing Nodejs Dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOGS_FILE
VALIDATE $? "Created systemctl Service File"

systemctl daemon-reload
systemctl enable catalogue  &>>$LOGS_FILE
systemctl start catalogue
VALIDATE $? "Enabling And Starting Catalogue Service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y

mongosh --host $MONGODB_HOST </app/db/master-data.js
