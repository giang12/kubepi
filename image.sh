#!/bin/bash -e
IMG=raspbian_lite/images/raspbian_lite-2018-11-15/2018-11-13-raspbian-stretch-lite.zip
LATEST_IMG=raspbian_lite_latest

isWifi=0

while (( $# > 0 ))
do
  case "$1" in
    (--wifi)
      isWifi=1
      ;;
    (*)
      ;;
  esac
  shift
done

if [ ! -f /tmp/raspbian/.setup ]; then
  echo "Fetching $IMG"
  mkdir -p /tmp/raspbian

  curl -L https://downloads.raspberrypi.org/"$IMG" > /tmp/raspbian/image.zip
  unzip /tmp/raspbian/image.zip -d /tmp/raspbian
  touch /tmp/raspbian/.setup
fi

image=`find /tmp/raspbian/*.img`

# Figure out our OS
if [[ -z "${OSTYPE}" ]]; then
  OSTYPE=$(uname -s)
fi

case "${OSTYPE}" in
  darwin*)
    alias grep="grep --color=never"
    size_opt="-f %z"
    bs_size=1m

    # Check that the system has all the needed binaries/requirements in place
    check_requirements() {
      ## NO-OP in Darwin
      true
    }

    # Try to identify the most likely device that the user will use to
    # write an image to.
    #
    # return _RET: the name of the device to use
    autodetect_device() {
      set +e
      _RET=/dev/$(diskutil list | grep --color=never FDisk_partition_scheme | awk 'NF>1{print $NF}')

      if [ "${_RET}" == "" ] || [ "${_RET}" == "/dev/" ]; then
        echo "No SD card found. Please insert SD card, I'll wait for it..."
        while [ "${_RET}" == "" ] || [ "${_RET}" == "/dev/" ]; do
          sleep 1
          _RET=/dev/$(diskutil list | grep --color=never FDisk_partition_scheme | awk 'NF>1{print $NF}')
        done
      fi
      set -e
    }

    # Show in the standard output the devices that are a likely
    # destination for the tool to write an image to.
    show_devices() {
      diskutil list | grep FDisk_partition_scheme | awk 'NF>1{print $NF}'
    }

    # Check that the target device can be written. It will return 0 in
    # this case and 1 if it is not writable
    #
    # @param arg1 device name to check
    check_device_is_writable() {
      disk=$1
      if [[ "$disk" == *.dmg ]]; then
        # CI helper
        _RET=1
        return
      fi
      readonlymedia=$(diskutil info "$disk" | grep "Read-Only Media" | awk 'NF>1{print $NF}')
      if [[ $readonlymedia == "No" ]] ; then
        _RET=1
      else
        _RET=0
      fi
    }

    # Convert the device name into a raw device name that is suitable for
    # use by dd
    #
    # @param arg1 device name
    # @return _RET the raw device name
    get_raw_device_filename() {
      _RET="${1//\/dev\///dev/r}"
    }

    # Get the directory where the boot volume will be mounted.
    #
    # @param arg1 the name of the device holding the volume to be mounted
    # @return _RET mount point name
    get_boot_mount_point() {
      _RET=$(df | grep --color=never "${1}s1" | /usr/bin/sed 's,.*/Volumes,/Volumes,')
    }

    # Wait for the new created disk to be available
    #
    # @param arg1 device name to check
    wait_for_disk() {
      # helper for macOS CI
      rawdisk="$1"
      if [[ "$rawdisk" == *.dmg ]]; then
        mv "$rawdisk" "${rawdisk}.readonly.dmg"
        hdiutil convert "${rawdisk}.readonly.dmg" -format UDRW -o "$rawdisk"
        rm -f "${rawdisk}.readonly.dmg"
        disk=$(hdiutil attach "$rawdisk" | grep FAT | sed 's/s1 .*$//')
        echo mounted FAT partition to "$disk"
        if [ "$disk" == "" ]; then
          echo Failed attaching "$rawdisk"
          exit 5
        fi
      fi

      set +e
      find_boot_dev_name "$rawdisk"
      boot=$_RET
      if [ "${boot}" == "" ]; then
        COUNTER=0
        while [ $COUNTER -lt 5 ]; do
          sleep 1
          find_boot_dev_name "$rawdisk"
          boot=$_RET
          if [ "${boot}" != "" ]; then
            break
          fi
          (( COUNTER=COUNTER+1 ))
        done
      fi
      set -e
    }

    # Find the device name of the boot partition
    #
    # @param arg1 the disk name containing the partition
    find_boot_dev_name() {
      _RET=$(df | grep --color=never "${disk}s1" | /usr/bin/sed 's,.*/Volumes,/Volumes,')
    }

    # Unmount a disk
    #
    # @param arg1 the disk to unmount
    umount_disk() {
      disk=$1
      if [[ "$disk" == *.dmg ]]; then
        return
      fi
      set +e
      diskutil unmountDisk "${disk}s1"
      set -e
      diskutil unmountDisk "${disk}"
    }

    detach() {
      hdiutil detach "${1}"
    }
    # Mount the boot disk in the specified mount point
    #
    # @param arg1 the device to mount. The boot partition will be found automatically
    # @param arg2 mount point
    mount_boot_disk() {
      # NO-OP: Darwin will mount the boot partition automatically as soon
      # as the new disk is detected
      true
    }

    prepare_raw_disk() {
      _RET=$1
    }

    cleanup() {
      true
    }

    sudo_prompt() {
      # Do not use sudo -v otherwise Travis CI will hang.
      true
    }

    play_ok() {
      afplay /System/Library/Sounds/Bottle.aiff
    }

    play_warn() {
      afplay /System/Library/Sounds/Basso.aiff
    }

    sed_i() {
      sed -i "" "$@"
    }
    ;;
  Linux|linux|linux-gnu*)
    size_opt="-c %s"
    bs_size=1M

    # Check that the system has all the needed binaries/requirements in place
    check_requirements() {
      if ! sudo sh -c 'command -v hdparm' > /dev/null; then
        echo "No 'hdparm' command found; please install hdparm by running:"
        echo "sudo [apt-get|yum|something-else] install hdparm"
        exit 1
      fi
    }

    # Try to identify the most likely device that the user will use to
    # write an image to.
    #
    # @return _RET the name of the device to use
    autodetect_device() {
      _RET=$(lsblk -n -o NAME -d | grep mmcblk)
    }

    # Show in the standard output the devices that are a likely
    # destination for the tool to write an image to.
    show_devices() {
      if [[ -x $(command -v lsblk) ]]; then
        lsblk --output NAME,SIZE,TYPE,MOUNTPOINT
      else
        df -h
      fi
    }

    # Convert a image file into a destination disk
    #
    # @param arg1 the destination image file
    # @return _RET the disk that represents the image
    prepare_raw_disk() {
      if [[ "$1" == *.img ]]; then
        error "Raw files not supported under Linux yet" 2
      fi
      _RET=$1
    }

    # Convert the device name into a raw device name that is suitable for
    # use by dd
    #
    # @param arg1 device name
    # @return _RET the raw device name
    get_raw_device_filename() {
      _RET="${1}"
    }

    # Check that the target device can be written. It will return 0 in
    # this case and 1 if it is not writable
    #
    # @param arg1: device name to check
    check_device_is_writable() {
      disk=$1
      if [[ "$disk" == "loo" ]]; then
        # CI helper
        _RET=1
        return
      fi

      if sudo hdparm -r "$disk" | grep -q off; then
        _RET=1
      else
        _RET=0
      fi
    }

    # Get the directory where the boot volume will be mounted
    #
    # @param arg1 the name of the device holding the volume to be mounted
    # @return _RET: mount point name
    get_boot_mount_point() {
      _RET=/tmp/"$(id -u)"/mnt.$$
      mkdir -p "${_RET}"
    }

    # Wait for the new created disk to be available
    #
    # @param arg1 device name to check
    wait_for_disk() {
      echo "Waiting for device $1"
      udevadm settle
      sudo hdparm -z "$1"
    }

    # Find the device name of the boot partition
    #
    # @param arg1 the disk name containing the partition
    find_boot_dev_name() {
      if beginswith /dev/mmcblk "${1}" ;then
        _RET="${1}p1"
      elif beginswith /dev/loop "${1}" ;then
        _RET="${1}p1"
      else
        _RET="${1}1"
      fi
    }


    # Unmount a disk
    #
    # @param arg1 the disk to unmount
    umount_disk() {
      for i in $(df |grep "$1" | awk '{print $1}')
      do
        sudo umount "$i"
      done
    }

    detach() {
      umount_disk "$1"
    }

    # Mount the boot disk in the specified mount point
    #
    # @param arg1 the device to mount. The boot partition will be found automatically
    # @param arg2 mount point
    mount_boot_disk() {
      local disk=$1
      local mount_point=$2
      local dev

      find_boot_dev_name "${disk}"
      dev=$_RET

      sudo mount -o uid="$(id -u)",gid="$(id -g)" "${dev}" "${mount_point}"
      ls -la "${mount_point}"
    }

    cleanup() {
      rmdir "$1"
    }

    sudo_prompt() {
      # this sudo here is used for a login without pv's progress bar
      # hiding the password prompt
      sudo -v
    }

    play_ok() {
      true
    }

    play_warn() {
      true
    }

    sed_i() {
      sed -i "$@"
    }
    ;;
  *)
    echo Unknown OS: "${OSTYPE}"
    exit 11
    ;;
esac

# if endswith Microsoft "$(uname -r)"; then
#   echo This script does not work in WSL.
#   exit 11
# fi

check_requirements

echo "Finding SD card"
auto=true
selectDiskFlash(){
  while true; do
    # default to device passed by user
    disk="$DEVICE"
    if [[ -z "${disk}" ]]; then
      if "$auto"; then
        # try to find the correct disk of the inserted SD card
        autodetect_device
        disk="$_RET"
      else
        # fallback to user input
        show_devices
        # shellcheck disable=SC2162
        read -p "Please pick your device: "
        disk="${REPLY}"
        [[ ${disk} != /dev/* ]] && disk="/dev/${disk}"
      fi
    fi
      #

    # ask for confirmation 
    if [[ -z "${FORCE}" ]]; then
      show_devices
      while true; do
        echo ""
        read -rp "Is ${disk} correct? " yn
        case $yn in
          [Yy]* ) break;;
          [Nn]* ) 
            auto=false
            selectDiskFlash
            ;;
          * ) echo "Please answer yes or no.";;
        esac
      done
    fi

    prepare_raw_disk "${disk}"
    disk=$_RET

    check_device_is_writable "${disk}"
    writable=$_RET

    echo "Unmounting ${disk} ..."
    umount_disk "${disk}"

    if [ "$writable" == "1" ]; then
      break
    else
      play_warn
      echo "👎  The SD card is write protected. Please eject, remove protection and insert again."
      exit
    fi
  done
}

selectDiskFlash

# flash img
flash_img(){

get_raw_device_filename "$disk"
rawdisk=$_RET

echo "Flashing ${image} to ${rawdisk} ...(may need to enter root password!)"

if [[ -x $(command -v pv) ]]; then
  sudo_prompt
  size=$(/usr/bin/stat "$size_opt" "${image}")
  pv -s "${size}" < "${image}" | sudo dd bs=$bs_size "of=${rawdisk}"
else
  echo "No 'pv' command found, so no progress available."
  echo "Press CTRL+T if you want to see the current info of dd command."
  sudo dd bs=1M "if=${image}" "of=${rawdisk}"
fi
}

wait_for_disk "${disk}"

## SSH and wifi

echo "Enabling SSH"
boot_mount_point=/media/$USER
sudo mkdir -p "${boot_mount_point}"
sudo mkdir -p "${boot_mount_point}/boot"
sudo mkdir -p "${boot_mount_point}/rootfs"

echo "Mounting ${disk} to customize..."

mount_boot_disk "${disk}p1" "${boot_mount_point}/boot"
sudo touch /media/$USER/boot/ssh
orig="$(sudo head -n1 /media/$USER/boot/cmdline.txt) cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory"
echo $orig | sudo tee /media/$USER/boot/cmdline.txt

mount_boot_disk "${disk}p2" "${boot_mount_point}/rootfs"

if [[ $isWifi == 1 ]]; then
  echo "Enabling Wifi"
  if [ ! -f .config/wifi ]; then
    read -p "What is the wifi network? " -r < /dev/tty
    echo "wifi=$REPLY" > .config/wifi
    read -p "What is the wifi password? " -r < /dev/tty
    echo "wifipwd=$REPLY" >> .config/wifi
  fi
  source .config/wifi

  echo "auto wlan0
allow-hotplug wlan0
iface wlan0 inet dhcp
  wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf" | sudo tee /media/$USER/rootfs/etc/network/interfaces.d/wlan0
  sudo chmod 666 /media/$USER/rootfs/etc/network/interfaces.d/wlan0
  wpa_passphrase "$wifi" "$wifipwd" | sudo tee /media/$USER/rootfs/etc/wpa_supplicant/wpa_supplicant.conf
  sudo chmod 666 /media/$USER/rootfs/etc/wpa_supplicant/wpa_supplicant.conf
fi

echo "Ejecting $disk"
sudo umount /media/$USER/rootfs
sudo umount /media/$USER/boot
sudo rm -rf /media/$USER
echo "All done!"
