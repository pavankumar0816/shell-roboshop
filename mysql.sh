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

dnf install mysql-server -y &>> $LOGS_FILE
validate $? "Installing MySQL Server"

systemctl enable mysqld &>> $LOGS_FILE
systemctl start mysqld  
validate $? "Enable and start Mysql Server"

# get the password from the user
mysql_secure_installation --set-root-pass RoboShop@1
validate $? "Setup root password"
