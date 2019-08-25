#!/bin/bash -e
# set up root users ssh access
# sync with public keys from github profile every 10 mins
# delete default root user
# 
user=$1
init_user=$2

DEL_INIT_USER=0
GITHUB_USER=giang12

while (( $# > 0 ))
do
  case "$1" in
    (--del-init-user)
      DEL_INIT_USER=1
      ;;
    (*)
      ;;
  esac
  shift
done

echo "Creating user $user"
useradd $user -d /home/$user -m -s /bin/bash
usermod -aG sudo $user
usermod -aG docker $user

mkdir -p /home/$user/.ssh
chown -R $user /home/$user

wget https://github.com/$GITHUB_USER.keys -O /home/$user/.ssh/authorized_keys
chown $user:$user /home/$user/.ssh/authorized_keys

echo "0 0 * * * /usr/bin/wget https://github.com/$GITHUB_USER.keys -O ~/.ssh/authorized_keys" >> /tmp/cronjobs
crontab -u $user /tmp/cronjobs

echo "$user ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/010_$user-nopasswd"

if  [ "$DEL_INIT_USER" == "1" ]; then
  
  echo "Deleting user $init_user"
  userdel -f $init_user
  rm -rf "/home/$init_user"
fi
