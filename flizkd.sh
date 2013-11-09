#!/bin/bash
logfile=/root/script.log
exec > $logfile 2>&1

if [ ! -f /etc/flizkd1.0 ]; then
   if [ -d /root/flizkd ]; then
      echo "You seem to have already installed an earlier version of flizkd on your system..."
      echo "Please reinstall your server if you wish to install "`tput bold``tput sgr 0 1`"Flizkd 1.0"`tput sgr0`"."
      exit 0
   fi
else
   bash /root/flizkd/scripts/flizkd-conf.sh
   exit 0
fi

distro=$(lsb_release -ds)
os_version=$(lsb_release -rs)
arch=$(uname -m)
kscheck=$(hostname | cut -d. -f2)
IP=$(ifconfig eth0 | grep 'inet addr' | awk -F: '{ printf $2 }' | awk '{ printf $1 }')
adlport=$(perl -e 'print int(rand(65000-64990))+64990')
curuser=$(id -u)

clear
echo
echo `tput bold``tput sgr 0 1`"Flizkd 1.0"`tput sgr0`" - https://github.com/mindfk/flizkd/"
echo
echo "This script installs the newest versions of rtorrent, rutorrent + plugins,"
echo "autodl-irssi, lighttpd and FTP (vsftpd). It'll also create a web download"
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

until [[ $var9 == yes ]]; do
case $os_version in
        "10.04" | "11.04")
        ubuntu=yes
        ub1011=yes
        deb6=no
        deb7=no
        var9=yes
        ub1011x=yes
        usesha=no
        ;;
        "11.10")
        ubuntu=yes
        deb7=no
        deb6=no
        var9=yes
        ub1011=no
        ub1011x=yes
        usesha=no
        ;;
        "12.04")
        ubuntu=yes
        deb6=no
        deb7=no
        var9=yes
        ub1011=no
        ub1011x=no
        usesha=yes
        ;;
        "12.10")
        ubuntu=yes
        deb6=no
        deb7=no
        var9=yes
        ub1011=no
        ub1011x=no
        usesha=yes
        ;;
        "13.04" | "13.10")
        ubuntu=yes
        deb6=no
        deb7=no
        var9=yes
        ub1011=no
        ub1011x=no
        usesha=yes
        ;;
        6.0.[0-9])
        var9=yes
        debian=yes
        deb6=yes
        deb7=no
        ubuntu=no
        ub1011=no
        ub1011x=no
        usesha=no
        ;;
        7.[0-9])
        var9=yes
        debian=yes
        deb7=yes
        deb6=no
        ubuntu=no
        ub1011=no
        ub1011x=no
        usesha=yes
        ;;
        *)
        echo `tput setaf 1``tput bold`"This OS is not yet supported! (EXITING)"`tput sgr0`
        echo
        exit 1
        ;;
esac
done

echo "You are using "$distro

if [[ $curuser != 0 ]]; then
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

until [[ $var8 == carryon ]]; do
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
                              var8=carryon
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

until [[ $var7 == continue ]]; do
      echo -n "Which client do you want to install? (rTorrent/Deluge)"`tput setaf 3``tput bold`" [rTorrent]: "`tput sgr0`
      read ex1
      case $ex1 in
              [rR][tT][oO][rR][rR][eE][nN][tT] | "")
                     rtorrent_yn=yes
                     deluge_yn=no
                     var7=continue
                     ;;
              [dD][eE][lL][uU][gG][eE] )
                      rtorrent_yn=no
                      deluge_yn=yes
                      var7=continue
                      ;;
      esac
done

until [[ $var6 == continue ]]; do
      echo -n "Install ZNC? (Yes/No)"`tput setaf 3``tput bold`"[NO]: "`tput sgr0`
      read ex2
      case $ex2 in
              [yY] | [yY][eE][sS])
                    znc_yn=yes
                    var6=continue
                    ;;
              [nN] | [nN][oO] | "")
                    znc_yn=no
                    var6=continue
                    ;;
      esac
done

until [[ $var5 == continue ]]; do
      echo -n "Install Webmin? (Yes/No)"`tput setaf 3``tput bold`"[NO]: "`tput sgr0`
      read ex3
      case $ex3 in
              [yY] | [yY][eE][sS])
                    webmin_yn=yes
                    var5=continue
                    ;;
              [nN] | [nN][oO] | "" )
                    webmin_yn=no
                    var5=continue
                    ;;
      esac
done

echo

echo "userpw=\`perl -e 'print crypt(\""$passvar"\", \"salt\"),\"\\n\"'\`" >tmp
echo "useradd "$usernamevar "-s\/bin\/bash -U -m -p\$userpw" >>tmp
bash tmp
shred -n 6 -u -z tmp
echo $usernamevar " ALL=(ALL) ALL" >> /etc/sudoers
echo $usernamevar > /root/flizkd/user

apt-get update -y

if [ $ubuntu = "yes" ]; then
   echo grub-pc hold | dpkg --set-selections
fi

if [ $debian = "yes" ]; then
   echo mdadm hold | dpkg --set-selections
fi

apt-get upgrade -y

if [ $os_version = "12.04" ]; then
   apt-get install -y python-software-properties
   apt-get update -y
   apt-get install -y subversion libncurses5 libncurses5-dev libsigc++-2.0-dev libcurl4-openssl-dev build-essential screen curl lighttpd php5 php5-cgi php5-cli php5-common php5-curl libwww-perl libwww-curl-perl irssi libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl libxml-libxml-perl libdigest-sha-perl libjson-perl libjson-xs-perl libxml-libxslt-perl ffmpeg vsftpd unzip unrar rar zip python htop mktorrent nmap
   wget http://downloads.sourceforge.net/mediainfo/mediainfo_0.7.62-1_amd64.Debian_5.deb -O mediainfo.deb
   wget http://downloads.sourceforge.net/mediainfo/libmediainfo0_0.7.62-1_amd64.Ubuntu_12.04.deb -O libmediainfo.deb
   wget http://downloads.sourceforge.net/zenlib/libzen0_0.4.29-1_amd64.xUbuntu_12.04.deb -O libzen.deb
   dpkg -i libzen.deb libmediainfo.deb mediainfo.deb
fi 

if [[ $os_version = "12.10" || $os_version = "13.04" || $os_version = "13.10" ]]; then
   apt-get install -y python-software-properties
   apt-get update -y
   apt-get install -y mediainfo subversion libncurses5 libncurses5-dev libsigc++-2.0-dev libcurl4-openssl-dev build-essential screen curl lighttpd php5 php5-cgi php5-cli php5-common php5-curl libwww-perl libwww-curl-perl irssi libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl libxml-libxml-perl libdigest-sha-perl libjson-perl libjson-xs-perl libxml-libxslt-perl ffmpeg vsftpd unzip unrar rar zip python htop mktorrent nmap
fi

if [ $ub1011x = "yes" ]; then
   apt-get install -y python-software-properties
   apt-get update -y
   apt-get install -y subversion libncurses5 libncurses5-dev libsigc++-2.0-dev libcurl4-openssl-dev build-essential screen curl lighttpd php5 php5-cgi php5-cli php5-common php5-curl libwww-perl libwww-curl-perl irssi libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl libxml-libxml-perl libdigest-sha1-perl libjson-perl libjson-xs-perl libxml-libxslt-perl ffmpeg vsftpd unzip unrar rar zip python htop mktorrent nmap
   wget http://sourceforge.net/projects/mediainfo/files/binary/libmediainfo0/0.7.62/libmediainfo0_0.7.62-1_amd64.Ubuntu_10.04.deb -O libmediainfo.deb
   wget http://downloads.sourceforge.net/zenlib/libzen0_0.4.29-1_amd64.xUbuntu_10.04.deb -O libzen.deb
   wget http://downloads.sourceforge.net/mediainfo/mediainfo_0.7.62-1_amd64.Debian_5.deb -O mediainfo.deb
   dpkg -i libzen.deb libmediainfo.deb mediainfo.deb
fi

if [ $deb6 = "yes" ]; then
   cp /etc/apt/sources.list /etc/apt/sources.list.back  
   nonfreetf=$(grep non-free /etc/apt/sources.list)
   repolink=$(grep squeeze /etc/apt/sources.list | head -n 2 | awk '{ printf $2 }')
   if [ -z $nonfreetf ]; then
      echo "deb "$repolink" squeeze non-free" >> /etc/apt/sources.list
   fi
   apt-get update -y
   apt-get purge -y --force-yes vsftpd lighttpd apache2 apache2-utils
   apt-get clean && apt-get autoclean
   apt-get -y --force-yes install libncursesw5-dev debhelper libtorrent-dev bc libcppunit-dev libssl-dev build-essential pkg-config libcurl4-openssl-dev libsigc++-2.0-dev libncurses5-dev lighttpd nano screen subversion libterm-readline-gnu-perl php5-cgi apache2-utils php5-cli php5-common irssi libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl libxml-libxml-perl libdigest-sha1-perl libjson-perl libjson-xs-perl libxml-libxslt-perl screen sudo rar curl unzip zip unrar python python-twisted python-twisted-web2 python-openssl python-simplejson python-setuptools gettext intltool python-xdg python-chardet python-geoip python-libtorrent python-notify python-pygame python-gtk2 python-gtk2-dev librsvg2-dev xdg-utils python-mako vsftpd automake libtool ffmpeg nmap mktorrent
   wget http://downloads.sourceforge.net/mediainfo/mediainfo_0.7.58-1_amd64.Debian_6.0.deb -O mediainfo.deb
   wget http://downloads.sourceforge.net/mediainfo/libmediainfo0_0.7.58-1_amd64.Debian_6.0.deb -O libmediainfo.deb
   wget http://downloads.sourceforge.net/zenlib/libzen0_0.4.26-1_amd64.Debian_6.0.deb -O libzen.deb
   dpkg -i libzen.deb libmediainfo.deb mediainfo.deb
fi

if [ $deb7 = "yes" ]; then
   cp /etc/apt/sources.list /etc/apt/sources.list.back  
   nonfreetf=$(grep non-free /etc/apt/sources.list)
   repolink=$(grep wheezy /etc/apt/sources.list | head -n 2 | awk '{ printf $2 }')    
   if [ -z $nonfreetf ]; then
      echo "deb "$repolink" wheezy non-free" >> /etc/apt/sources.list
   fi
   apt-get update -y
   apt-get purge -y --force-yes vsftpd
   apt-get clean && apt-get autoclean
   apt-get -y --force-yes install mediainfo libncursesw5-dev debhelper libtorrent-dev bc libcppunit-dev libssl-dev build-essential pkg-config libcurl4-openssl-dev libsigc++-2.0-dev libncurses5-dev lighttpd nano screen subversion libterm-readline-gnu-perl php5-cgi apache2-utils php5-cli php5-common irssi libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl libxml-libxml-perl libdigest-sha-perl libjson-perl libjson-xs-perl libxml-libxslt-perl screen sudo rar curl unzip zip unrar python python-twisted python-twisted-web2 python-openssl python-simplejson python-setuptools gettext intltool python-xdg python-chardet python-geoip python-libtorrent python-notify python-pygame python-gtk2 python-gtk2-dev librsvg2-dev xdg-utils python-mako vsftpd automake libtool ffmpeg nmap mktorrent
fi

cd /root/flizkd/cfg
   /etc/init.d/vsftpd stop
   rm /etc/vsftpd.conf
   mkdir /etc/vsftpd
   cp vsftpd.conf /etc

mkdir /etc/lighttpd/certs
rm /etc/lighttpd/lighttp.conf
cp lighttpd.conf /etc/lighttpd
sed -i 's/<SWAP-FOR-IP>/'$IP'/g' /etc/lighttpd/lighttpd.conf

cd /root/flizkd/scripts
   sh makepem.sh /etc/vsftpd/vsftpd.pem /etc/vsftpd/vsftpd.pem vsftpd
   /etc/init.d/vsftpd start

if [ $kscheck = "kimsufi" ]; then
   tune2fs -m .5 /dev/sda2
   rm .ssh/authorized_keys2
fi

add_deluge_cron=no
mkdir /root/flizkd/source

if [ $deluge_yn = "yes" ]; then
   mkdir -p /home/$usernamevar/.config/deluge
   mkdir /home/$usernamevar/deluge_watch
   cp /root/flizkd/cfg/web.conf /home/$usernamevar/.config/deluge/
   sed 's/<username>/'$usernamevar'/' /root/flizkd/cfg/core.conf > /home/$usernamevar/.config/deluge/core.conf
   sh makepem.sh /etc/lighttpd/certs/deluge.cert.pem /etc/lighttpd/certs/deluge.key.pem deluge
   add_deluge_cron=yes       
   if [ $ubuntu = "yes" ]; then            
      if [ $ub1011 = "yes" ]; then
         apt-get install -y python-twisted python-twisted-web2 python-openssl python-simplejson python-setuptools gettext intltool python-xdg python-chardet python-geoip python-libtorrent python-notify python-pygame python-gtk2 python-gtk2-dev librsvg2-dev xdg-utils python-mako
         cd /root/flizkd/source
            wget http://download.deluge-torrent.org/source/deluge-1.3.6.tar.gz && tar zxfv deluge-1.3.6.tar.gz
            rm deluge-1.3.6.tar.gz
         cd deluge-1.3.6
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
       cd /root/flizkd/source
          wget http://download.deluge-torrent.org/source/deluge-1.3.6.tar.gz && tar xvzf deluge-1.3.6.tar.gz
          rm deluge-1.3.6.tar.gz
       cd deluge-1.3.6
          python setup.py clean -a
          python setup.py build
          python setup.py install
    fi
       
    echo $passvar >/root/pass.txt
    cd /root/flizkd/scripts
       python chdelpass.py /home/$usernamevar/.config/deluge
       shred -n 6 -u -z /root/pass.txt
fi

cd /root/flizkd/source

if [ $znc_yn = "yes" ]; then
   apt-get -y install build-essential libssl-dev libperl-dev pkg-config libc-ares-dev
   wget http://znc.in/releases/znc-latest.tar.gz
   tar -xzvf znc-latest.tar.gz
   rm znc-latest.tar.gz
   cd znc*
      ./configure --enable-extra
      make
      make install
fi

if [ $webmin_yn = "yes" ]; then
   apt-get install -y openssl libauthen-pam-perl libio-pty-perl apt-show-versions
   if [ $ubuntu = "yes" ]; then
      echo "deb http://download.webmin.com/download/repository sarge contrib deb" >> /etc/apt/sources.list
      echo "deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" >> /etc/apt/sources.list
      wget http://www.webmin.com/jcameron-key.asc
      apt-key add jcameron-key.asc
      apt-get update -y
      apt-get install -y webmin
   fi
   if [ $debian = "yes" ]; then
      wget http://prdownloads.sourceforge.net/webadmin/webmin_1.660_all.deb
      dpkg -i webmin_1.660_all.deb
   fi
fi

if [ $rtorrent_yn = "yes" ]; then 
   cd /root/flizkd/source
      svn co http://svn.code.sf.net/p/xmlrpc-c/code/advanced xmlrpc-c
      wget http://libtorrent.rakshasa.no/downloads/libtorrent-0.13.3.tar.gz && tar zxfv libtorrent-0.13.3.tar.gz
      wget http://libtorrent.rakshasa.no/downloads/rtorrent-0.9.3.tar.gz && tar zxfv rtorrent-0.9.3.tar.gz
      cd xmlrpc-c
         ./configure
         make
         make install
      cd ../libtorrent-0.13.3
         chmod +x configure  
         ./configure
         make
         make install
      cd ../rtorrent-0.9.3
         chmod +x configure 
         ./configure --with-xmlrpc-c
         make
         make install
         ldconfig
   
   cd ../
      rm -rf xmlrpc-c libtorrent* rtorrent*

   cd /var/www/
      touch index.html
      mkdir webdownload
      cd webdownload
         ln -s /home/$usernamevar/downloads
   cd /var/www
      svn co http://rutorrent.googlecode.com/svn/trunk/rutorrent
      cd /var/www/rutorrent
         rm -rf plugins/
         svn co http://rutorrent.googlecode.com/svn/trunk/plugins
         cd plugins/
            svn co https://autodl-irssi.svn.sourceforge.net/svnroot/autodl-irssi/trunk/rutorrent/autodl-irssi
            svn co http://rutorrent-pausewebui.googlecode.com/svn/trunk/ pausewebui
            svn co http://rutorrent-logoff.googlecode.com/svn/trunk/ logoff
            svn co http://rutorrent-instantsearch.googlecode.com/svn/trunk/ rutorrent-instantsearch
            svn co http://svn.rutorrent.org/svn/filemanager/trunk/filemanager
   chown -R www-data:www-data /var/www/
   chmod -R 755 /var/www
   chmod -R 777 /var/www/rutorrent/share
   chmor -R 755 /var/www/rutorrent/plugins/filemanager/scripts
   chmod 777 /tmp/

   cd /var/www/rutorrent/conf/users
      mkdir -p $usernamevar/plugins/autodl-irssi
      sed -i 's/<username>/'$usernamevar'/' /var/www/rutorrent/conf/config.php
      cp /var/www/rutorrent/conf/config.php /var/www/rutorrent/conf/users/$usernamevar/config.php
      cp /var/www/rutorrent/plugins/autodl-irssi/_conf.php /var/www/rutorrent/plugins/autodl-irssi/conf.php
      sed -e 's/<adlport>/'$adlport'/' -e 's/<pass>/'$usernamevar'/' /root/flizkd/cfg/adlconf > /var/www/rutorrent/conf/users/$usernamevar/plugins/autodl-irssi/conf.php

   rm /etc/init.d/rtorrent
   sed 's/<username>/'$usernamevar'/' /root/flizkd/cfg/rtorrent >> /etc/init.d/rtorrent
   cd /etc/init.d/
      chmod +x rtorrent
      update-rc.d rtorrent defaults
   
   rm /home/$usernamevar/.rtorrent.rc
   sed 's/<username>/'$usernamevar'/' /root/flizkd/cfg/.rtorrent.rc > /home/$usernamevar/.rtorrent.rc
   echo "check_hash = no" >> /home/$usernamevar/.rtorrent.rc

   mkdir /home/$usernamevar/downloads
   mkdir /home/$usernamevar/scripts
   mkdir -p /home/$usernamevar/rtorrent_watch
   mkdir -p /home/$usernamevar/rtorrent/.session
   mkdir -p /home/$usernamevar/.irssi/scripts/autorun
   
   sed 's/<username>/'$usernamevar'/' /root/flizkd/cfg/check-rtorrent > /home/$usernamevar/scripts/check-rt
   chmod +x /home/$usernamevar/scripts/check-rt
   
   cd /home/$usernamevar/.irssi/scripts
      wget https://sourceforge.net/projects/autodl-irssi/files/autodl-irssi-v1.31.zip --no-check-certificate
      unzip -o autodl-irssi-v*.zip
      rm autodl-irssi-v*.zip
      cp autodl-irssi.pl autorun/
      mv /root/flizkd/cfg/iFR.tracker AutodlIrssi/trackers/

   if [ $usesha = "yes" ]; then
      cp AutodlIrssi/MatchedRelease.pm matchtemp
      sed 's/Digest::SHA1 qw/Digest::SHA qw/' matchtemp > AutodlIrssi/MatchedRelease.pm
   fi

   mkdir -p /home/$usernamevar/.autodl
   echo "[options]" >/home/$usernamevar/.autodl/autodl.cfg
   echo "rt-dir = /home/"$usernamevar"/downloads" >>/home/$usernamevar/.autodl/autodl.cfg
   echo "upload-type = rtorrent" >>/home/$usernamevar/.autodl/autodl.cfg
   echo "[options]" > /home/$usernamevar/.autodl/autodl2.cfg
   echo "gui-server-port = "$adlport >> /home/$usernamevar/.autodl/autodl2.cfg
   echo "gui-server-password = dl"$usernamevar >> /home/$usernamevar/.autodl/autodl2.cfg
   chown -R $usernamevar:$usernamevar /home/$usernamevar/

   if [ $os_version = "10.04" ]; then
      sed -i 's/include_shell \"\/usr\/share\/lighttpd\/use-ipv6.pl\"/#include_shell \"\/usr\/share\/lighttpd\/use-ipv6.pl\"/g' /etc/lighttpd/lighttpd.conf
      killall apache2
      update-rc.d apache2 disable
   fi

   cd /root/flizkd/scripts
      python htdigest.py -c -b /etc/lighttpd/.passwd "ruTorrent" $usernamevar $passvar
      sh makepem.sh /etc/lighttpd/certs/rutorrent.pem /etc/lighttpd/certs/rutorrent.pem rutorrent
   /etc/init.d/lighttpd restart

   cd ~
   echo "@reboot /home/"$usernamevar"/scripts/check-rt >> /dev/null 2>&1" >> tempcron
   echo "*/3 * * * * /home/"$usernamevar"/scripts/check-rt >> /dev/null 2>&1" >> tempcron
   echo "@reboot /usr/bin/screen -dmS irssi irssi" >> tempcron
fi

if [ $add_deluge_cron = "yes" ]; then
   sed 's/<username>/'$usernamevar'/' /root/flizkd/cfg/check-deluge > /home/$usernamevar/scripts/check-deluge
   chown $usernamevar:$usernamevar /home/$usernamevar/scripts/check-deluge
   chmod +x /home/$usernamevar/scripts/check-deluge
   echo "@reboot /home/"$usernamevar"/scripts/check-deluge >> /dev/null 2>&1" >> tempcron
   echo "*/3 * * * * /home/"$usernamevar"/scripts/check-deluge >> /dev/null 2>&1" >> tempcron
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

echo

if [ $rtorrent_yn = "yes"]; then
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
echo `tput setaf 2``tput bold`"Rebooting... Wait a couple of minutes before trying to access ruTorrent."`tput sgr0`
echo

sed -i 's/Port 22/Port 22 # fliz_ssh/' /etc/ssh/sshd_config
touch /etc/flizkd1.0

reboot
