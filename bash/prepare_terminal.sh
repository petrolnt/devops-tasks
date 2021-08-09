#!/bin/bash

update="https://s3.eu-central-1.amazonaws.com/s3-bucket/app-terminal_04-apr-2018_omni-v2.0_linux-x64.zip"
[ -z "$update" ] && echo "Empty update link! Inser update link as parameter" && exit
teamviewer="teamviewer_13.1.3026_amd64.deb"
user="myuser"
password="1q2w3e"
userdir="/home/$user"
appfolder="/home/$user/saas-eagle-infoterminal-linux-x64"

#change default system locale
echo 'change default system locale'
echo 'LANG="en_EN.UTF-8"' > "/etc/default/locale"
locale-gen
localectl set-locale LANG=en_US.utf8

#disable ufw
echo 'disable ufw'
systemctl disable ufw

#disable autoupdates
echo 'disable autoupdates'
updStr='APT::Periodic::Update-Package-Lists "1";'
disableAutoUpd='APT::Periodic::Update-Package-Lists "0";'
sed -i "s/$updStr/$disableAutoUpd/g" "/etc/apt/apt.conf.d/10periodic"

#installing package whois for take mkpasswd utility
echo 'Installing whois'
apt install whois -y

#if user not created
grep -q "$user" /etc/passwd
if [ ! $? -eq 0 ] ; then
    echo 'Creating user saas'
    #useradd  $user -p `mkpasswd "$password"` -d $userdir -m -g users -s /bin/bash
    useradd  $user -p `mkpasswd "$password"` -d $userdir -m -s /bin/bash
fi

#allow sudo
echo 'Allow sudo for user saas'
usermod -a -G sudo $user

#check if sudo without password is not enabled
grep -q "$user ALL=(ALL:ALL) NOPASSWD: ALL" /etc/sudoers
if [ ! $? -eq 0 ] ; then
    echo "$user ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
fi

#install openssh-server
echo 'Installing openssh server and set ssh port 24383'
apt install openssh-server -y
systemctl enable ssh
#change a default 22 port to 24383 for sshd
sed -i 's/Port 22/Port 24383/g' "/etc/ssh/sshd_config"

#set autologin for user saas
echo 'Enable autologin for user saas'
str_autologin="[SeatDefaults]\n
autologin-guest=false\n
autologin-user=$user\n
autologin-user-timeout=0\n
autologin-session=lightdm-autologin\n
greeter-session=\n
user-session=ubuntu\n"
echo -e $str_autologin > "/etc/lightdm/lightdm.conf"

#Configuring HDMI audio
sudo sed -i '/module-detect/ {
n
a
### Linuxium fix for HDMI audio on Intel Compute Stick products STK1A32SC and STK1AW32SC
unload-module module-alsa-card
load-module module-alsa-sink device=hw:0,2
}' /etc/pulse/default.pa

pulseaudio -k
pulseaudio --start

#download an update
echo 'Downloading update'
tmparchive="$userdir/infoterminal-update.zip"
wget -O $tmparchive $update

#recreating application folder if exists
rm -rf $appfolder && mkdir $appfolder

#extracting an application
echo 'Extracting updates'
unzip -d $appfolder $tmparchive
chown -R "$user:$user" $appfolder

#remove archve after unziping
rm -f $tmparchive

#disable sleep and screen saver
echo 'Disable sleep and screen saver'
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.desktop.screensaver lock-enabled false

#add autorun entry
echo 'Set OmniTerminal as autorun application'
autorunfolder="/home/$user/.config/autostart"
mkdir -p $autorunfolder
fileContent="[Desktop Entry]\n
Type=Application\n
Exec=/home/$user/saas-eagle-infoterminal-linux-x64/saas-eagle-infoterminal\n
Hidden=false\n
NoDisplay=false\n
X-GNOME-Autostart-enabled=true\n
Name[de_DE]=Start infoterminal app\n
Name=Start infoterminal app\n
Comment[de_DE]=\n
Comment=\n"

autostartFile="/home/$user/.config/autostart/saas-eagle-infoterminal.desktop"
echo -e $fileContent > $autostartFile
chown -R "$user:$user" "/home/$user/.config"

echo 'Set teamviewer as service'
systemctl enable teamviewerd

