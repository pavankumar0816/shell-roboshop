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

dnf module disable nginx -y
dnf module enable nginx:1.24 -y &>> $LOGS_FILE
validate $? "Enabling Nginx 1.24 Version"

dnf install nginx -y &>> $LOGS_FILE
validate $? "Installing Nginx Web Server"

systemctl enable nginx &>> $LOGS_FILE 
systemctl start nginx 
validate $? "Enabled and Started Nginx Service"

rm -rf /usr/share/nginx/html/* &>> $LOGS_FILE
validate $? "Removing Default Nginx Content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> $LOGS_FILE
cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>> $LOGS_FILE
validate $? "Downloaded and Extracted Frontend App Content"

rm -rf /etc/nginx/nginx.conf

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>> $LOGS_FILE
validate $? "Copying Nginx Configuration File"

systemctl restart nginx
validate $? "Restarting Nginx Service"


