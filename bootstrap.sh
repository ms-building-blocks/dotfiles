#!/bin/bash

# curl -sSL http://bit.ly/slavkodotfiles > bootstrap.sh && chmod +x bootstrap.sh
# ./bootstrap.sh  <optional: simple | full>

set -e

if [ "$(id -u)" == "0" ]; then
echo "Installation must NOT be done under sudo"
echo "use your regular user account"
exit 1
fi

if [ -e /usr/bin/yum ]
then
    pkgmanager=yum
elif [ -e /usr/bin/apt ]
then
    pkgmanager=apt-get
else
    echo "No supported package manager"
    exit 1
fi

sudo $pkgmanager -y install git curl

if [ "$1" == "full" ]; then

  SUDOERUSER="$(whoami)"
  SUDOERFILE="/etc/sudoers.d/$SUDOERUSER"

  sudo bash -c "touch $SUDOERFILE"
  sudo bash -c "echo $SUDOERUSER ALL=\(ALL\) NOPASSWD: ALL > $SUDOERFILE"

  echo "===================================================================="
  echo "current user was added to SUDOERS w/o password"
  echo "don't  forget to remove settings after initial box configuration"
  echo "by removing file $SUDOERFILE"
  echo "===================================================================="


  if [ -e /usr/bin/yum ]
  then
      sudo yum install -y epel-release
      sudo yum install -y python-cffi
      sudo yum groupinstall -y "Development Tools"
      sudo yum install -y python-devel
      sudo yum install -y openssl-devel
      sudo yum install -y nano
  elif [ -e /usr/bin/apt ]
  then
      sudo apt-get -y install -y software-properties-common python-dev wget apt-transport-https libffi-dev libssl-dev
  fi

  sudo $pkgmanager install -y python-pip
  sudo pip install -U pip
  sudo pip install ansible

fi

echo "ssh-agent:"
eval "$(ssh-agent)"

if [ "$1" == "simple" ]; then
  git clone https://github.com/Voronenko/dotfiles.git
else
  git clone https://github.com/Voronenko/dotfiles.git
  cd dotfiles && git remote set-url origin git@github.com:Voronenko/dotfiles.git && cd ~
fi


if [ "$1" == "full" ]; then
  git clone https://github.com/Voronenko/ansible-developer_recipes.git
  cd ansible-developer_recipes && git remote set-url origin git@github.com:Voronenko/ansible-developer_recipes.git && cd ~
fi

cd dotfiles

if [ "$1" == "simple" ]; then
  ./init_simple.sh
else
  ./init.sh
fi
