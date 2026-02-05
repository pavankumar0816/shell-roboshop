#!/bin/bash

userid=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
MYSQL_HOST=mysql.pmpkdev.online

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

dnf install maven -y &>>LOGS_FILE
validate $? "Installing Maven"

id roboshop &>> $LOGS_FILE
   if [ $? -ne 0 ]; then
      useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
      validate $? "Creating System User"
    else
       echo -e "Roboshop user already exists ... $Y Skipping $N"
    fi
mkdir -p /app 
validate $? "Creating Application Directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>> $LOGS_FILE
validate $? "Downloading Shipping App Content"

cd /app 
validate $? "Moving to App Directory"

rm -rf /app/*
validate $? "Removing Existing Code"

unzip /tmp/shipping.zip &>> $LOGS_FILE
validate $? "Extracting Shipping App Content"

cd /app 
mvn clean package  &>> $LOGS_FILE
validate $? "Installing and Building Shipping App"

mv target/shipping-1.0.jar shipping.jar 
validate $? "Moving and Renaming Shipping App Jar File"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>> $LOGS_FILE
validate $? "Copying Shipping Service File"

dnf install mysql -y 
validate $? "Installing Mysql Client"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>> $LOGS_FILE
validate $? "Loading Shipping Schema"
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>> $LOGS_FILE
validate $? "Loading Shipping Schema and User Data"
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>> $LOGS_FILE
validate $? "Loading Shipping Master Data"

systemctl enable shipping &>> $LOGS_FILE
systemctl start shipping
validate $? "Enable and Started Shipping service"