usernamevar=`cat flizbox/user`
passok=no
var1=no
sshportmod=none
portcheck=0
until [[ $var1 == carryon ]]; do
clear
echo
echo "Welcome to the flizfk post-install script!"
echo
echo "Choose what you want to do:"
echo 
echo "[1] Change SSH/FTP Password"
echo "[2] Change RuTorrent/Webdownload folder Password"
echo "[3] Change SSH Port" 
echo "[4] Change Deluge WebUI Password"
echo "[5] Reboot the system!"
echo "[Q] Quit"
echo
echo -n "Select an option: "
read menuoption
case $menuoption in
"1")
var0=no
echo
passwd $usernamevar && var0=yes && echo && echo -n "Password changed! Press [ENTER] to continue.." && read
if [ $var0 = "no" ]; then
echo
echo -n "Press [ENTER] to continue.." && read
fi
;;
"2")
var3=no
passok=no
echo
echo "You can now choose a new password for ruTorrent/webdownload.."
echo
until [[ $var3 == carryon ]]; do
echo
echo -n "New Password for "$usernamevar": "`tput setaf 0``tput setab 0`
read passvar
echo -n `tput sgr0`"Confirm Password: "`tput setaf 0``tput setab 0`
read passvar2
tput sgr0
case $passvar2 in
        $passvar )
        passok=yes
        var3=carryon
        ;;
        *)
        echo
        echo -n "Passwords don't match - password not changed! Press [ENTER] to continue.." && read
        var3=carryon
        ;;
esac
done
if [ $passok = "yes" ]; then
python /root/scripts/htdigest.py -c -b /etc/lighttpd/.passwd "Authenticated Users" $usernamevar $passvar && echo -n "New Password accepted! Press [ENTER] to continue.." && read
fi
;;
"3")
var2=no
sshport=$(grep fliz_ssh /etc/ssh/sshd_config | awk '{ printf $2 }')
sshline=$(grep fliz_ssh /etc/ssh/sshd_config)

if [ $sshport = "" ]; then
echo
echo "Error! Cannot determine SSH port!"
exit 0
fi

echo
echo "You can now change your SSH port for increased security!"
echo "Its recommended to select a value from 49152 through 65535"
echo
echo "Default Value = 22"
echo "Current Value = "$sshport
echo
until [[ $var2 == yes ]]; do
echo -n "Select New Port Number"`tput setaf 3``tput bold`"[22]: "`tput sgr0`
read sshportmod
case $sshportmod in
    "")
    sed -i "s/$sshline/Port 22 # fliz_ssh/" /etc/ssh/sshd_config
    echo
    echo -n "SSH Port set to the default port 22! Press [ENTER] to continue.." && read
    var2=yes
    /etc/init.d/ssh restart
    ;;
    [1-9][0-9][0-9][0-9][0-5] | [1-9][0-9][0-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9] | [1-9] )
    portcheck=$(nmap -p 1-65535 localhost | grep $sshportmod"/tcp" | awk '{ printf $2 }')
    if [[ $portcheck = "open" ]]; then
        echo
        echo "Error! Port already in use!"
        echo
    fi
    if [[ $portcheck = "" ]]; then
        sshlinemod=`echo "Port "$sshportmod" # fliz_ssh"`
        sed -i "s/$sshline/$sshlinemod/" /etc/ssh/sshd_config
        echo
        echo -n "SSH Port Changed! Press [ENTER] to continue.." && read
        var2=yes
        /etc/init.d/ssh restart
    fi
    ;;
    *)
    echo
    echo "Error! Please select a valid port number!"
    echo
    ;;
esac
done
;;
"4")
var4=no
passok=no
echo
echo "You can now choose a new password for the Deluge Web-GUI.."
echo
until [[ $var4 == carryon ]]; do
echo -n "Enter New Password: "`tput setaf 0``tput setab 0`
read dpassvar
echo -n `tput sgr0`"Confirm New Password: "`tput setaf 0``tput setab 0`
read dpassvar2
tput sgr0
case $dpassvar2 in
        $dpassvar )
        passok=yes
        var4=carryon
        ;;
        *)
        echo
        echo -n "Passwords don't match - password not changed! Press [ENTER] to continue.." && read
        var4=carryon
        ;;
esac
done
if [ $passok = "yes" ]; then
echo $dpassvar >/root/pass.txt
python /root/scripts/chdelpass.py /home/$usernamevar/.config/deluge
echo "A reboot is required to reflect your new password change" && echo && echo -n "Press [ENTER] to return to the main menu" && read
shred -n 6 -u -z /root/pass.txt
fi
;;
"5")
var5=no
echo
echo -n "You sure you want to reboot?: "
until [[ $var5 == carryon ]]; do
read rq
case $rq in
         [Yy] | [Yy][Ee][Ss])
         reboot
         ;;
         *)
         var5=carryon
         ;;
esac
done
;;
[Qq] | [Qq][Uu][Ii][Tt])
exit 0
;;
*)
echo
echo -n "Invalid option! Type 1, 2, 3, 4, 5 or quit."
sleep 0.5 && echo -n "." &&  sleep 0.5 && echo -n "." && sleep 0.5 && echo -n "." && sleep 0.5 && echo -n "." && sleep 0.5 && echo -n "."
sleep 1 && echo
;;
esac
done
