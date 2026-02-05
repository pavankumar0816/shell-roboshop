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

dnf install python3 gcc python3-devel -y &>> $LOGS_FILE
validate $? "Installing Python3 and Build Tools"

id roboshop &>> $LOGS_FILE
   if [ $? -ne 0 ]; then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
        validate $? "Creating System User"
    else
        echo -e "Roboshop user already exists ... $Y Skipping $N"
    fi

mkdir /app 
validate $? "Creating Application Directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip 
validate $? "Downloading Payment App Content"

cd /app
validate $? "Moving to App Directory"

rm -rf /app/*
validate $? "Removing Existing Code"

unzip /tmp/payment.zip
validate $? "Extracting Payment App Content"

cd /app 
pip3 install -r requirements.txt &>> $LOGS_FILE
validate $? "Installing Python Dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>> $LOGS_FILE
validate $? "Copying Payment Service File"

systemctl daemon-reload
systemctl enable payment &>> $LOGS_FILE
systemctl start payment
validate $? "Enable and Started Payment Service"