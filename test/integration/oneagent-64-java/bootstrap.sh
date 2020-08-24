#!/bin/sh
sudo apt-get update
sudo apt-get install -y git openjdk-8-jdk-headless

git clone https://github.com/spring-projects/spring-petclinic.git
mv /spring-petclinic /app
cd /app; ./mvnw package