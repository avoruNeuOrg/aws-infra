#!/bin/bash
echo "####################"
echo "DB_USER=${DB_USER}"
echo "DB_NAME=${DB_NAME}"
echo "DB_PORT=${DB_PORT}"
echo "APP_PORT=4000"
echo "DB_HOSTNAME=${DB_HOSTNAME}"
echo "DB_PASSWORD=${DB_PASSWORD}"
echo "AWS_BUCKET_NAME=${AWS_BUCKET_NAME}"
echo "####################"

cd /home/ec2-user/webapp
touch .env

echo "DB_USER=${DB_USER}" >> .env
echo "DB_NAME=${DB_NAME}" >> .env
echo "DB_PORT=${DB_PORT}" >> .env

echo "APP_PORT=4000" >> .env
echo "DB_HOSTNAME=${DB_HOSTNAME}" >> .env
echo "DB_PASSWORD=${DB_PASSWORD}" >> .env
echo "AWS_BUCKET_NAME=${AWS_BUCKET_NAME}" >> .env
pm2 start src/mainServer.js
#npm run dev 
pm2 save
pm2 list

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config \
-m ec2 \
-c file:/opt/cloudwatch-config.json \
-s

systemctl enable amazon-cloudwatch-agent.service
systemctl start amazon-cloudwatch-agent.service