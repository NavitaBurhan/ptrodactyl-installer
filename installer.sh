#!/bin/bash
#!/usr/bin/env bash

phpmyadmin() {
    apt install dnsutils -y || { echo "Error installing dnsutils"; exit 1; }
    echo ""
    echo "[!] Before installation, we need some information."
    echo ""
    phpmyadmin_fqdn
}

phpmyadmin_finish() {
    cd || { echo "Error accessing the home directory"; exit 1; }
    echo -e "PHPMyAdmin Installation\n\nSummary of the installation\n\nPHPMyAdmin URL: $PHPMYADMIN_FQDN\nPreselected webserver: NGINX\nSSL: $PHPMYADMIN_SSLSTATUS\nUser: $PHPMYADMIN_USER_LOCAL\nPassword: $PHPMYADMIN_PASSWORD\nEmail: $PHPMYADMIN_EMAIL" > phpmyadmin_credentials.txt
    clear
    echo "[!] Installation of PHPMyAdmin done"
    echo ""
    echo "    Summary of the installation"
    echo "    PHPMyAdmin URL: $PHPMYADMIN_FQDN"
    echo "    Preselected webserver: NGINX"
    echo "    SSL: $PHPMYADMIN_SSLSTATUS"
    echo "    User: $PHPMYADMIN_USER_LOCAL"
    echo "    Password: $PHPMYADMIN_PASSWORD"
    echo "    Email: $PHPMYADMIN_EMAIL"
    echo ""
    echo "    These credentials have been saved in a file called"
    echo "    phpmyadmin_credentials.txt in your current directory"
    echo ""
}

phpmyadminweb() {
    rm -rf /etc/nginx/sites-enabled/default || { echo "Error removing default NGINX config"; exit 1; }
    apt install mariadb-server -y || { echo "Error installing MariaDB"; exit 1; }
    PHPMYADMIN_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
    mariadb -u root -e "CREATE USER '$PHPMYADMIN_USER_LOCAL'@'localhost' IDENTIFIED BY '$PHPMYADMIN_PASSWORD';" && mariadb -u root -e "GRANT ALL PRIVILEGES ON *.* TO '$PHPMYADMIN_USER_LOCAL'@'localhost' WITH GRANT OPTION;" || { echo "Error creating MariaDB user"; exit 1; }

    if [ "$PHPMYADMIN_SSLSTATUS" = "true" ]; then
        rm -rf /etc/nginx/sites-enabled/default
        curl -o /etc/nginx/sites-enabled/phpmyadmin.conf https://raw.githubusercontent.com/NavitaBurhan/ptrodactyl-installer/main/configs/phpmyadmin-ssl.conf || { echo "Error downloading NGINX config"; exit 1; }
        sed -i -e "s@<domain>@${PHPMYADMIN_FQDN}@g" /etc/nginx/sites-enabled/phpmyadmin.conf || { echo "Error editing NGINX config"; exit 1; }
        systemctl stop nginx || { echo "Error stopping NGINX"; exit 1; }
        certbot certonly --standalone -d $PHPMYADMIN_FQDN --staple-ocsp --no-eff-email -m $PHPMYADMIN_EMAIL --agree-tos || { echo "Error with Certbot"; exit 1; }
        systemctl start nginx || { echo "Error starting NGINX"; exit 1; }
        phpmyadmin_finish
    fi

    if [ "$PHPMYADMIN_SSLSTATUS" = "false" ]; then
        curl -o /etc/nginx/sites-enabled/phpmyadmin.conf https://raw.githubusercontent.com/NavitaBurhan/ptrodactyl-installer/main/configs/phpmyadmin.conf || { echo "Error downloading NGINX config"; exit 1; }
        sed -i -e "s@<domain>@${PHPMYADMIN_FQDN}@g" /etc/nginx/sites-enabled/phpmyadmin.conf || { echo "Error editing NGINX config"; exit 1; }
        systemctl restart nginx || { echo "Error restarting NGINX"; exit 1; }
        phpmyadmin_finish
    fi
}

phpmyadmin_fqdn() {
    send_phpmyadmin_summary
    echo "[!] Please enter FQDN. You will access PHPMyAdmin with this."
    read -r PHPMYADMIN_FQDN
    if [ -z "$PHPMYADMIN_FQDN" ]; then
        echo "FQDN can't be empty."
        exit 1
    fi

    IP=$(dig +short myip.opendns.com @resolver2.opendns.com -4)
    DOMAIN=$(dig +short "${PHPMYADMIN_FQDN}")
    
    if [ "$IP" != "$DOMAIN" ]; then
        echo ""
        echo "Your FQDN does not resolve to the IP of this machine."
        echo "Continuing anyway in 10 seconds.. CTRL+C to stop."
        sleep 10s
        phpmyadmin_ssl
    else
        phpmyadmin_ssl
    fi
}

phpmyadmininstall() {
    apt update || { echo "Error updating package list"; exit 1; }
    apt install nginx certbot -y || { echo "Error installing NGINX or Certbot"; exit 1; }
    mkdir /var/www/phpmyadmin && cd /var/www/phpmyadmin || { echo "Error creating directory"; exit 1; }
    
    if [ "$dist" = "ubuntu" ] && [[ "$version" =~ ^20\.04|22\.04|24\.04$ ]]; then
        apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg || { echo "Error installing dependencies"; exit 1; }
        LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
        apt update || { echo "Error updating package list"; exit 1; }
        add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe" || { echo "Error adding Ubuntu repository"; exit 1; }
    fi

    if [ "$dist" = "debian" ] && [ "$version" = "11" ]; then
        apt -y install software-properties-common curl ca-certificates gnupg2 lsb-release || { echo "Error installing dependencies"; exit 1; }
        echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/sury-php.list
        curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/sury-keyring.gpg || { echo "Error adding PHP repository"; exit 1; }
        apt update -y || { echo "Error updating package list"; exit 1; }
    fi

    if [ "$dist" = "debian" ] && [ "$version" = "12" ]; then
        apt -y install software-properties-common curl ca-certificates gnupg2 lsb-release || { echo "Error installing dependencies"; exit 1; }
        apt install -y apt-transport-https lsb-release ca-certificates wget || { echo "Error installing required packages"; exit 1; }
        wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg || { echo "Error downloading PHP GPG key"; exit 1; }
        echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
        apt update -y || { echo "Error updating package list"; exit 1; }
    fi

    wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.tar.gz || { echo "Error downloading PHPMyAdmin"; exit 1; }
    tar xzf phpMyAdmin-5.2.1-all-languages.tar.gz || { echo "Error extracting PHPMyAdmin"; exit 1; }
    mv /var/www/phpmyadmin/phpMyAdmin-5.2.1-all-languages/* /var/www/phpmyadmin || { echo "Error moving PHPMyAdmin files"; exit 1; }
    chown -R www-data:www-data *
    mkdir config
    chmod o+rw config
    cp config.sample.inc.php config/config.inc.php
    chmod o+w config/config.inc.php
    rm -rf /var/www/phpmyadmin/config
    phpmyadminweb
}

phpmyadmin_summary() {
    clear
    echo ""
    echo "[!] Summary:"
    echo "    PHPMyAdmin URL: $PHPMYADMIN_FQDN"
    echo "    Preselected webserver: NGINX"
    echo "    SSL: $PHPMYADMIN_SSLSTATUS"
    echo "    User: $PHPMYADMIN_USER_LOCAL"
    echo "    Email: $PHPMYADMIN_EMAIL"
    echo ""
    echo "    These credentials have been saved in a file called"
    echo "    phpmyadmin_credentials.txt in your current directory"
    echo ""
    echo "    Do you want to start the installation? (Y/N)"
    read -r PHPMYADMIN_INSTALLATION

    if [[ "$PHPMYADMIN_INSTALLATION" =~ [Yy] ]]; then
        phpmyadmininstall
    fi

    if [[ "$PHPMYADMIN_INSTALLATION" =~ [Nn] ]]; then
        echo "[!] Installation has been aborted."
        exit 1
    fi
}

send_phpmyadmin_summary() {
    clear
    echo ""
    if [ -d "/var/www/phpmyadmin" ]; then
        echo "[!] WARNING: There seems to already be an installation of PHPMyAdmin installed! This script will fail!"
    fi
    echo ""
    echo "[!] Summary:"
    echo "    PHPMyAdmin URL: $PHPMYADMIN_FQDN"
    echo "    Preselected webserver: NGINX"
    echo "    SSL: $PHPMYADMIN_SSLSTATUS"
    echo "    User: $PHPMYADMIN_USER_LOCAL"
    echo "    Email: $PHPMYADMIN_EMAIL"
    echo ""
}

phpmyadmin_ssl() {
    send_phpmyadmin_summary
    echo "[!] Do you want to use SSL for PHPMyAdmin? This is recommended. (Y/N)"
    read -r SSL_CONFIRM

    if [[ "$SSL_CONFIRM" =~ [Yy] ]]; then
        PHPMYADMIN_SSLSTATUS=true
        phpmyadmin_email
    fi

    if [[ "$SSL_CONFIRM" =~ [Nn] ]]; then
        PHPMYADMIN_SSLSTATUS=false
        phpmyadmin_email
    fi
}

phpmyadmin_user() {
    send_phpmyadmin_summary
    echo "[!] Please enter username for admin account."
    read -r PHPMYADMIN_USER_LOCAL
    phpmyadmin_summary
}

phpmyadmin_email() {
    send_phpmyadmin_summary
    if [ "$PHPMYADMIN_SSLSTATUS" = "true" ]; then
        echo "[!] Please enter your email. It will be shared with Lets Encrypt."
        read -r PHPMYADMIN_EMAIL
        phpmyadmin_user
    fi

    if [ "$PHPMYADMIN_SSLSTATUS" = "false" ]; then
        phpmyadmin_user
        PHPMYADMIN_EMAIL="Unavailable"
    fi
}
### Options ###

options(){
    echo "What would you like to do?"
    echo "[1] Install Panel"
    echo "[2] Install Wings"
    echo "[3] Panel & Wings"
    echo "[4] Install PHPMyAdmin"
    echo "[5] Remove PHPMyAdmin"
    echo "[6] Remove Wings"
    echo "[7] Remove Panel"
    echo "[8] Switch Pterodactyl Domain"
    echo "Input 1-8"
    read -r option
    case $option in
        1 ) option=1
            INSTALLBOTH=false
            panel
            ;;
        2 ) option=2
            INSTALLBOTH=false
            wings
            ;;
        3 ) option=3
            INSTALLBOTH=true
            panel
            ;;
        4 ) option=4
            phpmyadmin
            ;;
        5 ) option=5
            removephpmyadmin
            ;;
        6 ) option=6
            wings_remove
            ;;
        7 ) option=7
            uninstallpanel
            ;;
        8 ) option=8
            switchdomains
            ;;
        * ) echo ""
            echo "Please enter a valid option from 1-8"
            options
    esac
}

### Start ###

clear
echo ""
echo "-------------------------------------------------------------------"
echo ""
echo "Pterodactyl Installer @ v3.0"
echo "Copyright 2025, Malthe K, <me@malthe.cc>"
echo "https://github.com/NavitaBurhan/ptrodactyl-installer"
echo ""
echo "Security notice:"
echo "This script connects to ipinfo.io to check IP address organization."
echo ""
echo "This script is not associated with the official Pterodactyl Panel."
echo ""
oscheck

