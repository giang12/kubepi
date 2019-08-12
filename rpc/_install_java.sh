#!/bin/bash -e

user=$1
address=$2

ssh $user@$address << EOF
if ! java -version; then

echo installing Java..

sudo apt-get install -y dirmngr

echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | sudo tee /etc/apt/sources.list.d/webupd8team-java.list
echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | sudo tee -a /etc/apt/sources.list.d/webupd8team-java.list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886

sudo apt-get update

sudo apt-get install -y oracle-java8-jdk

java -version

else
 echo "Java already installed"
 java -version
fi
EOF
