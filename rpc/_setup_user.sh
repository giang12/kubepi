#!/bin/bash -e
# set up root users ssh access
# sync with public keys from github profile every 10 mins
# delete default root user
# 
user=$1
address=$2
init_user=$3

DEL_INIT_USER=1
GITHUB_USER=giang12

while (( $# > 0 ))
do
  case "$1" in
    (--del-init-user)
      DEL_INIT_USER=0
      ;;
    (*)
      ;;
  esac
  shift
done


echo "Connecting to $address with $init_user"
conf=~/.ssh/known_hosts

# if [[ $(grep "$address" $conf ) ]] ; then
#   echo "SSH User already configured"
# else
# ssh-keyscan -t ecdsa-sha2-nistp256 $address >> $conf

ssh $init_user@$address << EOF
  echo "Creating user $user"
  sudo useradd $user -d /home/$user -m -s /bin/bash
  sudo usermod -aG sudo $user
  sudo mkdir -p /home/$user/.ssh
  sudo chown -R $user /home/$user

  sudo wget https://github.com/$GITHUB_USER.keys -O /home/$user/.ssh/authorized_keys
  sudo chown $user:$user /home/$user/.ssh/authorized_keys

  echo "*/10 * * * * /usr/bin/wget https://github.com/$GITHUB_USER.keys -O ~/.ssh/authorized_keys" >> /tmp/cronjobs
  sudo crontab -u $user /tmp/cronjobs

  sudo sh -c 'echo "$user ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/010_$user-nopasswd'
EOF

echo $DEL_INIT_USER
if  [ "$DEL_INIT_USER" == "0" ]; then

ssh $user@$address << EOF
  echo "Deleting user $init_user"
  sudo userdel -f $init_user

EOF
else 
  echo $DEL_INIT_USER
fi
# fi
