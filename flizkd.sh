#!/bin/bash

## PATHS
flizkdDir=/root/flizkd
cfgDir="$flizkdDir"/cfg
rutCfgDir="$cfgDir"/rutorrent
rtCfgDir="$cfgDir"/rtorrent
delCfgDir="$cfgDir"/deluge
ngxCfgDir="$cfgDir"/nginx
scriptsDir="$flizkdDir"/scripts
initScripts="$scriptsDir"/init_scripts
srcDir="$flizkdDir"/source
wwwDir=/var/www
destDir=/opt

## Check if Flizkd has been previously ran
if [ ! -f /etc/flizkd1.0 ]; then
   if [ -f $flizkdDir/installed ]; then
      echo "You seem to have already installed an earlier version of flizkd on your system..."
      echo "Please reinstall your server if you wish to install "`tput bold``tput sgr 0 1`"Flizkd 1.0"`tput sgr0`"."
      exit 0
   fi
else
   bash $scriptsDir/flizkd-conf.sh
   exit 0
fi

## Check if certain packages are installed
check_install () {   
    local checkPkg=$(dpkg-query -l | grep $1 | wc -l)

    if [[ $checkPkg == 0 ]]; then
       echo "Installing $1..."
       apt-get -y install $1
    fi
}

## OS Check relies on lsb-release
check_install lsb-release

## SYS CHECK
distro=$(lsb_release -ds)
osVersion=$(lsb_release -rs)
arch=$(uname -m)
ksCheck=$(hostname | cut -d. -f2)
IP=$(ifconfig eth0 | grep 'inet addr' | awk -F: '{ printf $2 }' | awk '{ printf $1 }')
coresNo=$(nproc)
curUser=$(id -u)
homePart=$(df -h | grep /home | awk '{ printf $1 }')

echo "You are using "$distro

if [[ $curUser != 0 ]]; then
   echo
   echo `tput setaf 1``tput bold`"Please run this script as root."`tput sgr0`
   echo
   exit 1
fi

if [[ $arch != "x86_64" ]]; then
   echo `tput setaf 1``tput bold`"Not using 64 bit version, reinstall your distro with 64 bit version and try this script again. :( (EXITING)"`tput sgr0`
   echo
   exit 1
fi

clear
echo
echo `tput bold``tput sgr 0 1`"Flizkd 1.0"`tput sgr0`" - https://github.com/mindfk/flizkd/"
echo
echo "This script installs the newest versions of rtorrent, rutorrent + plugins,"
echo "autodl-irssi, nginx and FTP (vsftpd). It'll also create a web download"
echo "folder and a SSL certificate. You can choose to instal Deluge instead of"
echo "rTorrent if you wish. Optional: ZNC and Webmin."
echo
echo "Once you have installed the seedbox, you can run this script again at a later"
echo "time and you will be given configuration options (password changes etc.)"
echo
echo "Flizkd is a fork of Flizbox - http://sourceforge.net/projects/flizbox/."
echo
echo "Press control-z if you wish to cancel."
echo

until [[ $var1 == yes ]]; do
      case $osVersion in
           "10.04" | "11.04")
           ubuntu=yes
           ub1011x=yes
           ub1011=yes          
           deb6=no
           deb7=no
           usersha=no
           var1=yes
           ;;
           "11.10")
           ubuntu=yes
           ub1011x=yes
           ub1011=no
           deb6=no
           deb7=no
           usersha=no
           var1=yes           
           ;;
           "12.04")
           ubuntu=yes
           ub1011=no
           ub1011x=no
           deb6=no
           deb7=no
           usesha=yes
           var1=yes
           ;;
           "12.10" | "13.04" | "13.10")
           ubuntu=yes
           ub1011=no
           ub1011x=no
           deb6=no
           deb7=no
           var1=yes
           usesha=yes
           ;;
           6.0.[0-9])
           debian=yes
           deb6=yes
           deb7=no
           ubuntu=no
           ub1011=no
           ub1011x=no
           usesha=no
           var1=yes
           ;;
           7 | 7.[0-9])
           debian=yes
           deb7=yes
           deb6=no
           ubuntu=no
           ub1011=no
           ub1011x=no
           usesha=yes
           var1=yes
           ;;
           *)
           echo `tput setaf 1``tput bold`"This OS is not yet supported! (EXITING)"`tput sgr0`
           echo
           exit 1
           ;;
      esac
done

## app y_n app_yn
opt_app () {
       while true; do
             echo -n "Install $1? (Yes/No)"`tput setaf 3``tput bold`"[$2]: "`tput sgr0`
             read answer
             if [[ $2 == YES ]]; then             
                case $answer in
                     [yY] | [yY][eE][sS] | "")
                         eval $3=yes
                         break
                         ;;
                     [nN] | [nN][oO])
                         eval $3=no
                         break
                         ;;
                esac
             else  
                case $answer in
                     [yY] | [yY][eE][sS])
                         eval $3=yes
                         break
                         ;;
                     [nN] | [nN][oO] | "")
                         eval $3=no
                         break
                         ;;
                esac 
             fi                 
       done
} 

## Some of the code was borrowed from VladGh's LEMP
install_nginx () {

   ngConf=/etc/nginx
   ngSsl="$ngConf"/ssl
   local passwdFile="$ngConf"/.passwd
   local ngLogDir=/var/log/nginx
   local ngStateDir=/var/lib/nginx
   local ngConfFile="$ngConf"/nginx.conf
   local defCfg="$ngConf"/defcfgs
   local sitesAvail="$ngConf"/sites-available
   local sitesEnabl="$ngConf"/sites-enabled
   local defVhostFile="$sitesAvail"/default
   local defSslVhostFile="$sitesAvail"/default-ssl

    if [ ! -d $wwwDir ]; then
       mkdir $wwwDir  
    fi

    cd /tmp
       wget http://nginx.org/download/nginx-"$1".tar.gz 
       tar zxvf nginx-"$1".tar.gz       
       cd nginx-"$1"/
       echo 'Configuring nginx...'
        ./configure \
        --prefix="$destDir"/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --http-log-path="$ngLogDir"/access.log \
        --error-log-path="$ngLogDir"/error.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/lock/nginx.lock \
        --with-http_stub_status_module \
        --with-http_ssl_module \
        --with-http_realip_module \
        --with-http_gzip_static_module \
        --with-ipv6 \
        --without-mail_pop3_module \
        --without-mail_imap_module \
        --without-mail_smtp_module
        
        echo 'Compiling...' 
        make

        echo 'Installing...'
        checkinstall -y 

    if [ ! -d $ngStateDir ]; then
       mkdir $ngStateDir  
    fi   

    if [ ! -d $ngLogDir ]; then
       mkdir $ngLogDir
    fi 
   
    ## Backup the default nginx dir and replace it with the custom one 
    mv $ngConf /etc/nginx-backup
    cp -r $ngxCfgDir /etc/nginx
    
    cd $ngConf
       mkdir $sitesEnabl 
       sed -i 's_<ngLogDir>_'$ngLogDir'_g' $ngConfFile   

       ln -s $defVhostFile "$sitesEnabl"/default
       ln -s $defSslVhostFile "$sitesEnabl"/default-ssl
       sed -i 's_<passwdfile>_'$passwdFile'_g' $defVhostFile && sed -i 's_<passwdfile>_'$passwdFile'_g' $defSslVhostFile
       sed -i 's_<RPCuser>_'RPC.$usernamevar'_g' $defVhostFile && sed -i 's_<RPCuser>_'RPC.$usernamevar'_g' $defSslVhostFile
       sed -i 's_<ngSsl>_'$ngSsl'_g' $defSslVhostFile

       htpasswd -b -c $passwdFile $usernamevar $passvar
       
       mkdir $ngSsl 
       cd $ngSsl
          openssl req -x509 -nodes -days 3650 -subj "/CN=EB/O=EliteBox" -newkey rsa:1024 -keyout default.key -out default.crt
          chmod 600 default.key

    cd ~      

    chown -R www-data:www-data $ngLogDir
    echo '$ngLogDir/*.log {
    weekly
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 640 root adm
    sharedscripts
    postrotate
    [ ! -f /var/run/nginx.pid ] || kill -USR1 `cat /var/run/nginx.pid`
    endscript
    }' > /etc/logrotate.d/nginx
        
    ##init script
    cd $initScripts
       cp nginx /etc/init.d/nginx
    cd /etc/init.d/   
       sed -i 's_<destDir>_'$destDir'_' nginx
       chmod +x /etc/init.d/nginx
       if [ $ubuntu = "yes" ]; then
          update-rc.d nginx defaults
       else    
          insserv -dv nginx
       fi

}

## Most of the code was borrowed from VladGh's LEMP
install_php () {
  
  local libraries="libcurl4-openssl-dev libgd2-xpm-dev libjpeg-dev libpng3-dev libxpm-dev libfreetype6-dev libt1-dev libmcrypt-dev libxslt1-dev bzip2 libbz2-dev libxml2-dev libevent-dev libltdl-dev libmagickwand-dev libmagickcore-dev imagemagick libreadline-dev libc-client-dev libsnmp-dev snmpd snmp libpq-dev"
  local archB=$(arch)-linux-gnu
  
  # Install all PHP Libraries
  echo 'Installing libraries...'
  apt-get -y install $libraries

  # Download PHP
  echo "Downloading and extracting PHP-$1..."
  wget -O /tmp/php-"$1".tar.gz "http://us1.php.net/distributions/php-$1.tar.gz" 
  cd /tmp
  tar xzvf php-"$1".tar.gz

  [ -f /usr/lib/${archB}/libjpeg.so ] && ln -fs /usr/lib/${archB}/libjpeg.so /usr/lib/
  [ -f /usr/lib/${archB}/libpng.so ] && ln -fs /usr/lib/${archB}/libpng.so /usr/lib/
  [ -f /usr/lib/${archB}/libXpm.so ] && ln -fs /usr/lib/${archB}/libXpm.so /usr/lib/
  [ -f /usr/lib/${archB}/libmysqlclient.so ] && ln -fs /usr/lib/${archB}/libmysqlclient.so /usr/lib/
  [ -d /usr/lib/${archB}/mit-krb5 ] && ln -fs /usr/lib/${archB}/mit-krb5/lib*.so /usr/lib/

  # Compile php source
  cd /tmp/php-"$1"
    ./buildconf --force
    echo 'Configuring PHP (Please be patient, this will take a while...)' 
    ./configure \
      --prefix="$destDir"/php5 \
      --with-config-file-path=/etc/php5 \
      --with-config-file-scan-dir=/etc/php5/conf.d \
      --with-curl \
      --with-pear \
      --with-gd \
      --with-jpeg-dir \
      --with-png-dir \
      --with-zlib \
      --with-xpm-dir \
      --with-freetype-dir \
      --with-t1lib \
      --with-mcrypt \
      --with-mhash \
      --with-mysql \
      --with-pgsql \
      --with-mysqli \
      --with-pdo-mysql \
      --with-pdo-pgsql \
      --with-openssl \
      --with-xmlrpc \
      --with-xsl \
      --with-bz2 \
      --with-gettext \
      --with-readline \
      --with-fpm-user=www-data \
      --with-fpm-group=www-data \
      --with-imap \
      --with-imap-ssl \
      --with-kerberos \
      --with-snmp \
      --disable-debug \
      --enable-fpm \
      --enable-cli \
      --enable-inline-optimization \
      --enable-exif \
      --enable-wddx \
      --enable-zip \
      --enable-bcmath \
      --enable-calendar \
      --enable-ftp \
      --enable-mbstring \
      --enable-soap \
      --enable-sockets \
      --enable-shmop \
      --enable-dba \
      --enable-sysvsem \
      --enable-sysvshm \
      --enable-sysvmsg

  echo 'Compiling PHP (Please be patient, this will take a while...)' 
  make -j8 
  echo 'Installing PHP...' 
  checkinstall -y

  # Copy configuration files
  echo 'Setting up PHP...' 
  sed -i "s~@destDir@~$destDir~" "$initScripts"/php5-fpm
  mkdir -p /etc/php5/conf.d /var/log/php5-fpm
  cp -f php.ini-production /etc/php5/php.ini
  cp "$cfgDir"/php-fpm.conf /etc/php5/php-fpm.conf
  [ -f /etc/init.d/*fpm*] && rm /etc/init.d/*fpm*
  cp "$initScripts"/php5-fpm /etc/init.d/php5-fpm

  # Prepare service
  cd /etc/init.d/
     sed -i 's_<destDir>_'$destDir'_' php5-fpm
     chmod +x /etc/init.d/php5-fpm
     update-rc.d -f php5-fpm defaults

  cd ~

  # The newer versions of php complain if a time zone is not set on php.ini (so we grab the system's one)
  TIMEZONE=$([ -f /etc/timezone ] && cat /etc/timezone | sed "s/\//\\\\\//g")
  sed -i "s/^\;date\.timezone.*$/date\.timezone = \"${TIMEZONE}\" /g" /etc/php5/php.ini

  chown -R www-data:www-data /var/log/php5-fpm

  # Create log rotation script
  echo '/var/log/php5-fpm/*.log {
  weekly
  missingok
  rotate 52
  compress
  delaycompress
  notifempty
  create 640 www-data www-data
  sharedscripts
  postrotate
  [ ! -f /var/run/php5-fpm.pid ] || kill -USR1 `cat /var/run/php5-fpm.pid`
  endscript
  }' > /etc/logrotate.d/php5-fpm

}

## lib_ver, rt_ver
install_rtorrent () { 
   
   local rutDir=/var/www/rutorrent
   local rutPluginsDir=$rutDir/plugins
   local rutConfDir=$rutDir/conf
   local rutUserConfDir=$rutConfDir/users
   local adlPort=$(perl -e 'print int(rand(65000-64990))+64990')

   cd /tmp
      svn co http://svn.code.sf.net/p/xmlrpc-c/code/advanced xmlrpc-c
      wget http://libtorrent.rakshasa.no/downloads/libtorrent-"$1".tar.gz && tar zxfv libtorrent-"$1".tar.gz
      wget http://libtorrent.rakshasa.no/downloads/rtorrent-"$2".tar.gz && tar zxfv rtorrent-"$2".tar.gz
      cd xmlrpc-c
         ./configure
         make
         make install
      cd ../libtorrent-"$1"
         chmod +x configure  
         ./configure
         make
         make install
      cd ../rtorrent-"$2"
         chmod +x configure 
         ./configure --with-xmlrpc-c
         make
         make install
         ldconfig
   
   cd ../
      rm -rf xmlrpc-c libtorrent* rtorrent*

   cd $wwwDir
      touch index.html
      mkdir webdownload
      cd webdownload
         ln -s "$userDir"/downloads
   cd $wwwDir
      svn co http://rutorrent.googlecode.com/svn/trunk/rutorrent
      cd $rutDir
         rm -rf plugins/
      cd $wwwDir
         svn co http://rutorrent.googlecode.com/svn/trunk/plugins
         mv plugins $rutDir
         cd $rutPluginsDir
            svn co http://rutorrent.googlecode.com/svn/trunk/plugins
            svn co http://rutorrent-pausewebui.googlecode.com/svn/trunk/ pausewebui 
            svn co http://rutorrent-logoff.googlecode.com/svn/trunk/ logoff
            svn co http://rutorrent-instantsearch.googlecode.com/svn/trunk/ rutorrent-instantsearch
            svn co http://svn.rutorrent.org/svn/filemanager/trunk/filemanager
  
   chown -R www-data:www-data $wwwDir
   chmod -R 755 $wwwDir
   chmod -R 777 "$rutDir"/share
   chmod -R 755 "$rutPluginsDir"/filemanager/scripts
   chmod 777 /tmp/

   cd "$rutPluginsDir"/filemanager
      sed -i "s_''_'/usr/bin/'_g" conf.php
      sed -i "
      /\['tar'\]/ a\
      \$pathToExternals['gzip'] = '/usr/bin/';
      " conf.php
      sed -i "
      /\['gzip'\]/ a\
      \$pathToExternals['bzip2'] = '/bin/';
      " conf.php

   cd $rutUserConfDir
      mkdir -p $usernamevar/plugins/autodl-irssi
      cp -f "$rutCfgDir"/config.php $rutConfDir
      sed -i 's/<username>/'$usernamevar'/' "$rutConfDir"/config.php
      cp "$rutConfDir"/config.php "$rutUserConfDir"/$usernamevar/config.php
      cp "$rutPluginsDir"/autodl-irssi/_conf.php "$rutPluginsDir"/autodl-irssi/conf.php
      sed -e 's_<adlPort>_'$adlPort'_' -e 's_<pass>_'$usernamevar'_' "$rutCfgDir"/plugins/adlconf > "$rutUserConfDir"/$usernamevar/plugins/autodl-irssi/conf.php

   cp "$initScripts"/rtorrent /etc/init.d/
   sed -i 's_<username>_'$usernamevar'_' /etc/init.d/rtorrent
   cd /etc/init.d/
      chmod +x rtorrent
      update-rc.d rtorrent defaults
   
   rm "$userDir"/.rtorrent.rc
   sed 's_<username>_'$usernamevar'_' "$rtCfgDir"/.rtorrent.rc > "$userDir"/.rtorrent.rc
   echo "check_hash = no" >> "$userDir"/.rtorrent.rc

   mkdir "$userDir"/downloads
   mkdir "$userDir"/scripts
   mkdir -p "$userDir"/rtorrent_watch
   mkdir -p "$userDir"/rtorrent/.session
   mkdir -p "$userDir"/.irssi/scripts/autorun
   
   sed 's_<username>_'$usernamevar'_' "$rtCfgDir"/check-rtorrent > "$userDir"/scripts/check-rt
   chmod +x "$userDir"/scripts/check-rt
   
   cd "$userDir"/.irssi/scripts
      wget -O autodl-irssi.zip https://autodl-irssi-community.googlecode.com/files/autodl-irssi-community.zip
      unzip -o autodl-irssi.zip
      rm autodl-irssi.zip
      cp autodl-irssi.pl autorun/
      mv "$rutCfgDir"/plugins/iFR.tracker AutodlIrssi/trackers/

   if [ $usesha = "yes" ]; then
      cp AutodlIrssi/MatchedRelease.pm matchtemp
      sed 's/Digest::SHA1 qw/Digest::SHA qw/' matchtemp > AutodlIrssi/MatchedRelease.pm
   fi

   mkdir -p "$userDir"/.autodl
   echo "[options]" > "$userDir"/.autodl/autodl.cfg
   echo "rt-dir = "$userDir"/downloads" >>$userDir/.autodl/autodl.cfg
   echo "upload-type = rtorrent" >>"$userDir"/.autodl/autodl.cfg
   echo "[options]" > "$userDir"/.autodl/autodl2.cfg
   echo "gui-server-port = "$adlPort >> $userDir/.autodl/autodl2.cfg
   echo "gui-server-password = dl"$usernamevar >> "$userDir"/.autodl/autodl2.cfg
   chown -R $usernamevar:$usernamevar "$userDir"/
   
   /etc/init.d/nginx restart
}

## version
install_deluge () {

   mkdir -p "$userDir"/.config/deluge
   mkdir "$userDir"/deluge_watch
   cp "$delCfgDir"/web.conf "$userDir"/.config/deluge/
   sed 's/<username>/'$usernamevar'/' "$delCfgDir"/core.conf > "$userDir"/.config/deluge/core.conf
   
   cd "$scriptsDir"
   sh makepem.sh "$ngSsl"/deluge.cert.pem "$ngSsl"/deluge.key.pem deluge 
   
   cd ~        
   if [ $ubuntu = "yes" ]; then            
      if [ $ub1011 = "yes" ]; then
         apt-get install -y python-twisted python-twisted-web2 python-openssl python-simplejson python-setuptools gettext intltool python-xdg python-chardet python-geoip python-libtorrent python-notify python-pygame python-gtk2 python-gtk2-dev librsvg2-dev xdg-utils python-mako
         cd /tmp
            wget http://download.deluge-torrent.org/source/deluge-"$1".tar.gz && tar zxfv deluge-"$1".tar.gz
            rm deluge-"$1".tar.gz
         cd deluge-"$1"
            python setup.py clean -a
            python setup.py build
            python setup.py install
      else
         add-apt-repository -y ppa:deluge-team/ppa
         apt-get update -y
         apt-get install -y deluged deluge-web
      fi
    fi
    if [ $debian = "yes" ]; then
       cd /tmp
          wget http://download.deluge-torrent.org/source/deluge-"$1".tar.gz && tar xvzf deluge-"$1".tar.gz
          rm deluge-"$1".tar.gz
       cd deluge-"$1"
          python setup.py clean -a
          python setup.py build
          python setup.py install
    fi
       
    echo $passvar >/root/pass.txt
    cd $scriptsDir
       python chdelpass.py "$userDir"/.config/deluge
       shred -n 6 -u -z /root/pass.txt

}
##mkdir script?
add_cron () {
   if [ $1 = "deluge" ]; then

      sed -i 's/<username>/'$usernamevar'/' "$delCfgDir"/check-deluge > "$userDir"/scripts/check-deluge
      chown $usernamevar:$usernamevar "$userDir"/scripts/check-deluge
      chmod +x "$userDir"/scripts/check-deluge
      echo "@reboot "$userDir"/scripts/check-deluge >> /dev/null 2>&1" >> tempcron
      echo "*/3 * * * * "$userDir"/scripts/check-deluge >> /dev/null 2>&1" >> tempcron
   fi
   if [ $1 = "rtorrent" ]; then
      cd ~
      echo "@reboot "$userDir"/scripts/check-rt >> /dev/null 2>&1" >> tempcron
      echo "*/3 * * * * "$userDir"/scripts/check-rt >> /dev/null 2>&1" >> tempcron
      echo "@reboot /usr/bin/screen -dmS irssi irssi" >> tempcron
   fi

   crontab -u $usernamevar tempcron
   rm tempcron

   if [ $ub1011x = "yes" ]; then
      if [ $ub1011 = "yes" ]; then
         echo "@reboot chmod 777 /var/run/screen" >> temprcron
      else
         echo "@reboot chmod 775 /var/run/screen" >> temprcron
      fi
   crontab temprcron
   rm temprcron
   fi
}

install_x2go () {
  if [ $deb7 = "yes" ]; then
     echo "deb http://repo.mate-desktop.org/debian wheezy main" >> /etc/apt/sources.list
     echo "deb http://packages.x2go.org/debian wheezy main" >> /etc/apt/sources.list
     apt-get update
     apt-get -y --force-yes --quiet --allow-unauthenticated install mate-archive-keyring x2go-keyring
     apt-get update
     apt-get -y install mate-desktop-environment-extra x2goserver x2goserver-xsession
  fi
}

## webmin
install_webmin () { 
   apt-get install -y openssl libauthen-pam-perl libio-pty-perl apt-show-versions
   if [ $ubuntu = "yes" ]; then
      http://www.webmin.com/download/deb/webmin-current.deb
      dpkg -i webmin_*_all.deb
   fi
   if [ $debian = "yes" ]; then
      cd /tmp
      wget http://www.webmin.com/download/deb/webmin-"$1".deb
      dpkg -i webmin_*_all.deb
   fi
}

## version
install_znc () {
   apt-get -y install build-essential libssl-dev libperl-dev pkg-config libc-ares-dev 
   cd /tmp
   wget http://znc.in/releases/znc-"$1".tar.gz
   tar -xzvf znc-"$1".tar.gz
   rm znc-"$1".tar.gz
   cd znc*
      ./configure --enable-extra
      make
      checkinstall -y
}


## Code borrowed from VladGh's LEMP
set_paths() {
  # Make the nginx and PHP paths global.
  echo 'Setting up paths...'
  export PATH="${PATH}:$destDir/nginx/sbin:$destDir/php5/bin:$destDir/php5/sbin"
  echo "PATH=\"$PATH\"" > /etc/environment
}

## Code borrowed from VladGh's LEMP
restart_servers() {
  # Restart both nginx and PHP
  echo 'Restarting servers...'
  invoke-rc.d php5-fpm restart
  sleep 1
  invoke-rc.d nginx restart
}

echo
echo "You'll need to choose a username and password. Everything else will run"
echo "automatically."
echo "Please be patient throughout the installation process. If you think it has"
echo "frozen, wait 10 minutes before rebooting."
echo
echo "Don't use UPPERCASE/CAPS usernames, just keep it simple - lowercase a-z"
echo "and 0-9 is ok. For the password consider using" `tput setaf 4``tput bold`"http://strongpasswordgenerator.com/"
echo `tput sgr0`"making sure 'use symbols' is unchecked. Please do not use any spaces"
echo "or special characters in your password (these are: &, *, \\, \$, and ?)."
echo

until [[ $var2 == carryon ]]; do
      echo -n "Choose username: "
      read usernamevar
      echo -n "Confirm username '"$usernamevar"' (Yes/No)"`tput setaf 3``tput bold`"[YES]: "`tput sgr0`
      read yno
      case $yno in
              [yY] | [yY][Ee][Ss] | "")
                      echo -n "Please choose a password: "`tput setaf 0``tput setab 0`
                      read passvar
                      echo -n `tput sgr0`"Retype password: "`tput setaf 0``tput setab 0`
                      read passvar2
                      tput sgr0
                      case $passvar2 in
                              $passvar )
                              var2=carryon
                              ;;
                              *)
                              echo -n "Passwords don't match."
                              sleep 0.5 && echo -n "." &&  sleep 0.5 && echo -n "." && sleep 0.5 && echo -n "." && sleep 0.5 && echo -n "." && sleep 0.5 && echo -n "."
                              sleep 1 && echo
                              ;;
                      esac
                      ;;
              [nN] | [nN][Oo] )
                      echo -n "Username not confirmed."
                      sleep 0.5 && echo -n "." &&  sleep 0.5 && echo -n "." && sleep 0.5 && echo -n "." && sleep 0.5 && echo -n "." && sleep 0.5 && echo -n "."
                      sleep 1 && echo
                      ;;
              *)
                      echo -n "Invalid input."
                      sleep 0.5 && echo -n "." &&  sleep 0.5 && echo -n "." && sleep 0.5 && echo -n "." && sleep 0.5 && echo -n "." && sleep 0.5 && echo -n "."
                      sleep 1 && echo
                      ;;
      esac
done

echo
echo "You will now be able to select optional addons for your seedbox..."
echo
opt_app rTorrent YES rtorrent_yn
opt_app Deluge NO deluge_yn
opt_app X2Go NO x2go_yn
opt_app Webmin NO webmin_yn
opt_app ZNC NO znc_yn

echo

apt-get -y install subversion
cd /root
   mkdir $flizkdDir && cd $flizkdDir
   svn co https://github.com/mindfk/flizkd/trunk/cfg
   svn co https://github.com/mindfk/flizkd/trunk/scripts

## Reduce the percentage of reserved blocks
tune2fs -m .5 $homePart

if [ $ksCheck = "kimsufi" ]; then
   if [ -f .ssh/authorized_keys2 ]; then
      rm .ssh/authorized_keys2
   fi   
fi

if [ $ubuntu = "yes" ]; then
   echo grub-pc hold | dpkg --set-selections
else
   echo mdadm hold | dpkg --set-selections
fi

apt-get upgrade -y

if [ $osVersion = "12.04" ]; then
   apt-get install -y python-software-properties
   apt-get update -y
   apt-get install -y checkinstall expect libpcre3 libpcre3-dev libncurses5 libncurses5-dev libsigc++-2.0-dev libcurl4-openssl-dev build-essential screen curl php5 php5-cgi php5-cli php5-common php5-curl php5-fpm libwww-perl libwww-curl-perl irssi libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl libxml-libxml-perl libdigest-sha-perl libjson-perl libjson-xs-perl libxml-libxslt-perl ffmpeg vsftpd unzip unrar rar zip python htop mktorrent nmap htop apache2-utils
   wget http://downloads.sourceforge.net/mediainfo/mediainfo_0.7.62-1_amd64.Debian_5.deb -O mediainfo.deb
   wget http://downloads.sourceforge.net/mediainfo/libmediainfo0_0.7.62-1_amd64.Ubuntu_12.04.deb -O libmediainfo.deb
   wget http://downloads.sourceforge.net/zenlib/libzen0_0.4.29-1_amd64.xUbuntu_12.04.deb -O libzen.deb
   dpkg -i libzen.deb libmediainfo.deb mediainfo.deb
fi 

if [[ $osVersion = "12.10" || $osVersion = "13.04" || $osVersion = "13.10" ]]; then
   apt-get install -y python-software-properties
   apt-get update -y
   apt-get -y install checkinstall mediainfo libpcre3 libpcre3-dev libncursesw5-dev debhelper libtorrent-dev bc libcppunit-dev libssl-dev build-essential pkg-config libcurl4-openssl-dev libsigc++-2.0-dev libncurses5-dev nano screen libterm-readline-gnu-perl apache2-utilsirssi libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl libxml-libxml-perl libdigest-sha-perl libjson-perl libjson-xs-perl libxml-libxslt-perl rar curl unzip zip unrar python python-twisted python-twisted-web2 python-openssl python-simplejson python-setuptools gettext intltool python-xdg python-chardet python-geoip python-libtorrent python-notify python-pygame python-gtk2 python-gtk2-dev python-makolibrsvg2-dev xdg-utils  vsftpd automake libtool ffmpeg nmap mktorrent htopbinutils cpp flex gcc libc6-dev m4 libpopt-dev make perl perl-modules openssl autoconf2.13 gnu-standards bison zlib1g-dev ntp ntpdate autotools-dev g++ psmisc re2c
fi

if [ $ub1011x = "yes" ]; then
   apt-get install -y python-software-properties
   apt-get update -y
   apt-get install -y checkinstall expect libpcre3 libpcre3-dev libncurses5 libncurses5-dev libsigc++-2.0-dev libcurl4-openssl-dev build-essential screen curl php5 php5-cgi php5-cli php5-common php5-curl php5-fpm libwww-perl libwww-curl-perl irssi libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl libxml-libxml-perl libdigest-sha1-perl libjson-perl libjson-xs-perl libxml-libxslt-perl ffmpeg vsftpd unzip unrar rar zip python htop mktorrent nmap htop apache2-utils
   wget http://sourceforge.net/projects/mediainfo/files/binary/libmediainfo0/0.7.62/libmediainfo0_0.7.62-1_amd64.Ubuntu_10.04.deb -O libmediainfo.deb
   wget http://downloads.sourceforge.net/zenlib/libzen0_0.4.29-1_amd64.xUbuntu_10.04.deb -O libzen.deb
   wget http://downloads.sourceforge.net/mediainfo/mediainfo_0.7.62-1_amd64.Debian_5.deb -O mediainfo.deb
   dpkg -i libzen.deb libmediainfo.deb mediainfo.deb
fi

if [ $deb6 = "yes" ]; then
   echo "deb http://ftp.debian.org/debian squeeze main contrib non-free" >> /etc/apt/sources.list
   echo "deb-src http://ftp.debian.org/debian squeeze main contrib non-free" >> /etc/apt/sources.list
   apt-get update -y
   apt-get purge -y --force-yes vsftpd lighttpd apache2 apache2-utils
   apt-get clean && apt-get autoclean
   apt-get -y install checkinstall sudo libpcre3 libpcre3-dev libncursesw5-dev debhelper libtorrent-dev bc libcppunit-dev libssl-dev build-essential pkg-config libcurl4-openssl-dev libsigc++-2.0-dev libncurses5-dev nano screen libterm-readline-gnu-perl apache2-utilsirssi libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl libxml-libxml-perl libdigest-sha1-perl libjson-perl libjson-xs-perl libxml-libxslt-perl rar curl unzip zip unrar python python-twisted python-twisted-web2 python-openssl python-simplejson python-setuptools gettext intltool python-xdg python-chardet python-geoip python-libtorrent python-notify python-pygame python-gtk2 python-gtk2-dev python-makolibrsvg2-dev xdg-utils  vsftpd automake libtool ffmpeg nmap mktorrent htopbinutils cpp flex gcc libc6-dev m4 libpopt-dev make perl perl-modules openssl autoconf2.13 gnu-standards bison zlib1g-dev ntp ntpdate autotools-dev g++ psmisc re2c
   wget http://downloads.sourceforge.net/mediainfo/mediainfo_0.7.58-1_amd64.Debian_6.0.deb -O mediainfo.deb
   wget http://downloads.sourceforge.net/mediainfo/libmediainfo0_0.7.58-1_amd64.Debian_6.0.deb -O libmediainfo.deb
   wget http://downloads.sourceforge.net/zenlib/libzen0_0.4.26-1_amd64.Debian_6.0.deb -O libzen.deb
   dpkg -i libzen.deb libmediainfo.deb mediainfo.deb
fi

if [ $deb7 = "yes" ]; then
   echo "deb http://ftp.debian.org/debian wheezy main contrib non-free" >> /etc/apt/sources.list
   echo "deb-src http://ftp.debian.org/debian wheezy main contrib non-free" >> /etc/apt/sources.list
   apt-get update -y
   apt-get purge -y --force-yes vsftpd
   apt-get clean && apt-get autoclean
   apt-get -y install checkinstall mediainfo sudo libpcre3 libpcre3-dev libncursesw5-dev debhelper libtorrent-dev bc libcppunit-dev libssl-dev build-essential pkg-config libcurl4-openssl-dev libsigc++-2.0-dev libncurses5-dev nano screen libterm-readline-gnu-perl apache2-utils irssi libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl libxml-libxml-perl libdigest-sha-perl libjson-perl libjson-xs-perl libxml-libxslt-perl rar curl unzip zip unrar python python-twisted python-twisted-web2 python-openssl python-simplejson python-setuptools gettext intltool python-xdg python-chardet python-geoip python-libtorrent python-notify python-pygame python-gtk2 python-gtk2-dev python-mako librsvg2-dev xdg-utils vsftpd automake libtool ffmpeg nmap mktorrent htop binutils cpp flex gcc libc6-dev m4 libpopt-dev make perl perl-modules openssl autoconf2.13 gnu-standards bison zlib1g-dev ntp ntpdate autotools-dev g++ psmisc re2c
fi

## Create user
userDir=/home/$usernamevar
echo "userpw=\`perl -e 'print crypt(\""$passvar"\", \"salt\"),\"\\n\"'\`" >tmp
echo "useradd "$usernamevar "-s\/bin\/bash -U -m -p\$userpw" >>tmp
bash tmp
shred -n 6 -u -z tmp
echo $usernamevar " ALL=(ALL) ALL" >> /etc/sudoers
echo $usernamevar > $flizkdDir/user

## Install nginx & configure php-fpm
install_nginx 1.5.11
install_php 5.5.9

# Make nginx and PHP paths global & restart them both
set_paths
restart_servers

cd $cfgDir
   /etc/init.d/vsftpd stop
   rm /etc/vsftpd.conf
   mkdir /etc/vsftpd
   cp vsftpd.conf /etc

cd $scriptsDir
   sh makepem.sh /etc/vsftpd/vsftpd.pem /etc/vsftpd/vsftpd.pem vsftpd
   /etc/init.d/vsftpd start

## APP INSTALATION
if [ $rtorrent_yn = "yes" ]; then
   install_rtorrent 0.13.3 0.9.3 
   add_cron rtorrent
fi

if [ $deluge_yn = "yes" ]; then
   install_deluge 1.3.6
   add_cron deluge
fi

if [ $x2go_yn = "yes" ]; then
   install_x2go
fi

if [ $webmin_yn = "yes" ]; then
   install_webmin current
fi

if [ $znc_yn = "yes" ]; then
   install_znc latest 
fi

echo

## FINAL OUTPUT
if [ $rtorrent_yn = "yes" ]; then
   echo `tput sgr0`"You can access ruTorrent at "`tput setaf 4``tput bold`"https://"$IP"/rutorrent/"
   echo `tput sgr0`"You can access your webdownload fodler at "`tput setaf 4``tput bold`"https://"$IP"/webdownload/"`tput sgr0`
fi

if [ $deluge_yn = "yes" ]; then
   echo "You can access your Deluge WebUI at "`tput setaf 4``tput bold`"https://"$IP":8877"
fi

if [ $webmin_yn = "yes" ]; then
   echo `tput sgr0`"You can access Webmin at "`tput setaf 4``tput bold`"https://"$IP":10000"`tput sgr0`
fi

tput sgr0
echo
echo "Use the username and/or password you chose earlier for the above web-links."

if [ $znc_yn = "yes" ]; then
   echo
   echo `tput setaf 3`"ZNC is installed, but you will need to configure it yourself, to do this,"
   echo "you will need to log into SSH with the user you created and run the following command:"
   echo "'znc --makeconf'"
fi

echo
echo `tput setaf 1`"Your browser may tell you the SSL certificate is not trusted - this is fine"
echo "as its a self-signed certificate (your connection will still be secure)."`tput sgr0`
echo
echo `tput setaf 2``tput bold`"Rebooting... Wait a couple of minutes before trying to access your server."`tput sgr0`
echo

sed -i 's/Port 22/Port 22 # fliz_ssh/' /etc/ssh/sshd_config
touch $flizkdDir/installed
touch /etc/flizkd1.0

reboot