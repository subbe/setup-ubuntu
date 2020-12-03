#!/bin/bash

# OUTPUT-COLORING
nc=$(tput setaf 9)
red=$(tput setaf 1)
green=$(tput setaf 2)

upgrade_update() {
  sudo apt upgrade && sudo apt install
}

primary_packages() {
  printf "${green}### Installing primary packages\n${nc}"
  cat primary-packages.list | xargs sudo apt install -y
}

php() {
  sudo apt-add-repository -y ppa:ondrej/php
  sudo apt update
  cat php-packages.list | xargs sudo apt install -y
}

mysql() {
  printf "${green}### Installing MySQL\n${nc}"
  sudo debconf-set-selections <<<"mysql-server mysql-server/root_password password root"
  sudo debconf-set-selections <<<"mysql-server mysql-server/root_password_again password root"
  export DEBIAN_FRONTEND=noninteractive
  sudo -E apt-get install -q -y mysql-server-5.7
  sudo mysql -h127.0.0.1 -P3306 -uroot -e"UPDATE mysql.user SET authentication_string=PASSWORD('root'), plugin='mysql_native_password' WHERE User='root' AND Host='localhost';FLUSH PRIVILEGES;"
  sudo mysqld_safe --skip-grant-tables
  sudo service mysql restart
}

linuxbrew() {
  printf "${green}### Installing Brew\n${nc}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >>/home/subbe/.zshrc
  source ~/.zshrc

  cat brew-packages.list | xargs brew install
}

secondary_packages() {
  printf "${green}### Installing Secondary Packages\n${nc}"
  cat secondary-packages.list | xargs sudo apt install -y
}

composer_phar() {
  printf "${green}### Installing Composer\n${nc}"
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  php -r "if (hash_file('sha384', 'composer-setup.php') === '756890a4488ce9024fc62c56153228907f1545c228516cbf63f885e036d37e9a59d27d63f46af1d4d07ee0f76181c7d3') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
  php composer-setup.php
  php -r "unlink('composer-setup.php');"
  sudo mkdir -p /usr/local/bin
  sudo mv composer.phar /usr/local/bin/composer
}

linux_valet() {
  printf "${green}### Installing Valet\n${nc}"
  mkdir -p ~/Sites
  cd ~/Sites || return
  composer global require cpriego/valet-linux
  echo 'export PATH="${HOME}/.config/composer/vendor/bin:$PATH"' >>~/.zshrc
  source ~/.zshrc
  valet install
  valet park
}

snap() {
  printf "${green}### Installing Snap Applications\n${nc}"
  cat snap-packages.list | xargs sudo snap install
}

docker() {
  printf "${green}### Instaling Docker\n${nc}"
  sudo apt update
  sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo apt-key fingerprint 0EBFCD88
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  sudo apt update
  sudo apt-cache policy docker-ce
  sudo apt install -y docker-ce docker-ce-cli
  sudo usermod -aG docker $(whoami)
  sudo service docker stop
  echo "" | sudo tee -a /etc/NetworkManager/NetworkManager.conf
  echo '[keyfile]' | sudo tee -a /etc/NetworkManager/NetworkManager.conf
  echo 'unmanaged-devices=interface-name:docker0;interface-name:veth*' | sudo tee -a /etc/NetworkManager/NetworkManager.conf
  echo "" | sudo tee -a /etc/NetworkManager/NetworkManager.conf
  sudo service network-manager restart
  sudo service docker start
}

dbeaver() {
  printf "${green}### Installing DBeaver-CE\n${nc}"
  sudo add-apt-repository -y ppa:serge-rider/dbeaver-ce
  sudo apt update
  sudo apt install -y dbeaver-ce
}

teams_app() {
  printf "${green}### Installing Microsoft Teams\n${nc}"
  curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
  echo "deb [arch=amd64] https://packages.microsoft.com/repos/ms-teams stable main" | sudo tee /etc/apt/sources.list.d/teams.list
  sudo apt update
  sudo apt install teams
}

phpstorm() {
  printf "${green}### Installing Phpstorm Toolbox\n${nc}"
  wget https://download-cf.jetbrains.com/toolbox/jetbrains-toolbox-1.18.7609.tar.gz
  tar -xvf jetbrains-toolbox-1.18.7609.tar.gz
  sudo mv jetbrains-toolbox-1.18.7609/jetbrains-toolbox /usr/local/bin
  rm -rf jetbrains-toolbox-1.18.7609
  rm -rf jetbrains-toolbox-1.18.7609.tar.gz
  /usr/local/bin/jetbrains-toolbox
}

ulauncher() {
  printf "${green}### Installing ULauncher\n${nc}"
  sudo add-apt-repository -y ppa:agornostal/ulauncher
  sudo apt update
  sudo apt install -y ulauncher
}

zsh() {
  printf "${green}### Installing ZSH\n${nc}"
  sudo apt install -y zsh
  echo $(zsh --version)
  sudo chsh -s $(which zsh)
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

primary_packages
php
mysql
linuxbrew
secondary_packages
composer_phar
linux_valet
snap
docker
dbeaver
teams_app
phpstorm
ulauncher
zsh
upgrade_update
