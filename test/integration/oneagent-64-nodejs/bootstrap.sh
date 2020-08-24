#!/bin/sh
curl -L https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo apt-get install -y nodejs psmisc

curl -L https://github.com/heroku/node-js-sample/archive/master.zip > /tmp/node-js-sample.zip
unzip /tmp/node-js-sample.zip -d /
mv /node-js-sample-master /app
cd /app; npm install