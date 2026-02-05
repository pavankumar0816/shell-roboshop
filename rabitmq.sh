#!/bin/bash

userid=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

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

dnf install rabbitmq-server -y &>> $LOGS_FILE
validate $? "Installing RabbitMQ Server"

systemctl enable rabbitmq-server &>> $LOGS_FILE
systemctl start rabbitmq-server

rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"