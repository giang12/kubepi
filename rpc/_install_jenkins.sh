#!/bin/bash -e

user=$1
address=$2

echo "Checking java version.."
cd "$(dirname "$0")"
./_install_java.sh $user $address

echo "installing Jenkins.."

ssh $user@$address << EOF
if ! jenkins -v; then

wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get -y install jenkins


sudo sed -i 's/\<update-center.json\>/&./' /etc/default/jenkins
sudo sed -ri 's/^(\s*)(HTTP_PORT\s*=\s*8080\s*$)/\HTTP_PORT=18888/' /etc/default/jenkins

sudo usermod -a -G docker jenkins && sudo service jenkins restart



else
 echo "Jenkins already installed"
 jenkins version
fi

sudo cat /var/lib/jenkins/secrets/initialAdminPassword

EOF
