#!/bin/bash

ROOT_DIR=`pwd`

#clone or pull huawei-repo

if [ -d $ROOT_DIR/src/huawei-rom ];then
    echo -e "\n***Pulling updates from huawei-rom git repository***"
    cd $ROOT_DIR/src/huawei-rom
    git pull
    [ $? -ne 0 ] && echo "Error! Can't make git pull for huawei-rom" && exit
    echo "***Done!***"
else
    echo -e "\n***Cloning huawei-rom git repository***"
    cd $ROOT_DIR/src
    git clone https://github.com/mycompany/huawei-rom.git
    [ $? -ne 0 ] && echo "Error! Can't make git pull for huawei-rom" && exit
    echo "***Done!***"
fi

#build ClockworkSettings
echo -e "\n***Building ClockworkSettings.apk***"
clockwork_dir=$ROOT_DIR/src/huawei-rom/src/ClockworkSettings
apktool b $clockwork_dir
[ $? -ne 0 ] && echo "Error! Can't build ClockworkSettings.apk" && exit
mv -f $clockwork_dir/dist/ClockworkSettings.apk $ROOT_DIR/sign
[ $? -ne 0 ] && echo "Error! Can't find file $clockwork_dir/dist/ClockworkSettings.apk" && exit
cd $ROOT_DIR/sign
java -jar signapk.jar platform.x509.pem platform.pk8 ClockworkSettings.apk $ROOT_DIR/packages/ClockworkSettings.apk
[ $? -ne 0 ] && echo "Error! Can't sign the file ClockworkSettings.apk" && exit
rm -f ClockworkSettings.apk
echo "***Done!***"

#build services.jar
echo -e "\n***Building services.jar***"
services_dir=$ROOT_DIR/src/huawei-rom/src/services
apktool b $services_dir
[ $? -ne 0 ] && echo "Error! Can't build services.jar" && exit
mv -f $services_dir/dist/services.jar $ROOT_DIR/sign
[ $? -ne 0 ] && echo "Error! Can't find file $services_dir/dist/services.jar" && exit
cd $ROOT_DIR/sign
java -jar signapk.jar platform.x509.pem platform.pk8 services.jar $ROOT_DIR/packages/services.jar
[ $? -ne 0 ] && echo "Error! Can't sign the file services.jar" && exit
rm -f services.jar
echo "***Done!***"

#build UpdateService
updateservice_dir=$ROOT_DIR/src/huawei-rom/src/UpdateService
echo -e "\n***Building UpdateService.apk***"
chmod 0777 $updateservice_dir/gradlew
cd $updateservice_dir
./gradlew assemble
[ $? -ne 0 ] && echo "Error! Can't build UpdateService.apk" && exit
cp -f $updateservice_dir/wear/build/outputs/apk/debug/wear-debug.apk $ROOT_DIR/sign/UpdateService.apk
[ $? -ne 0 ] && echo "Error! Can't find $updateservice_dir/wear/build/outputs/apk/debug/debug-wear.apk" && exit
cd $ROOT_DIR/sign
java -jar signapk.jar platform.x509.pem platform.pk8 UpdateService.apk $ROOT_DIR/packages/UpdateService.apk
[ $? -ne 0 ] && echo "Error! Can't sign the file UpdateService.apk" && exit
rm -f UpdateService.apk
echo "***Done!***"

#extracting ROM
echo -e "\n***Extracting ROM***"
rm -rf $ROOT_DIR/rom/huawei-rom/*
source_rom=Huawei_Watch2_201807200710.zip
[ $? -ne 0 ] && echo "Error! Can't clear ROM directory $ROOT_DIR/rom/huawei-rom" && exit
unzip $ROOT_DIR/rom/$source_rom -d $ROOT_DIR/rom/huawei-rom/
[ $? -ne 0 ] && echo "Error! Can't unzip $ROOT_DIR/rom/$source_rom" && exit
umount $ROOT_DIR/mnt/huawei/system
rm -rf $ROOT_DIR/mnt/huawei/*
cd $ROOT_DIR/rom/huawei-rom
sdat2img.py system.transfer.list system.new.dat $ROOT_DIR/mnt/huawei/system.img
[ $? -ne 0 ] && echo "Error! Can't extract system image from DAT files" && exit
mkdir -p $ROOT_DIR/mnt/huawei/system
mount -t ext4 -o loop $ROOT_DIR/mnt/huawei/system.img $ROOT_DIR/mnt/huawei/system
[ $? -ne 0 ] && echo "Error! Can't extract system image from DAT files" && exit
echo "***Done!***"

#replacing packages
echo -e "\n***Replacing packages in source ROM***"
echo "AssistMessenger..."
cp -f $ROOT_DIR/packages/AssistMessenger.apk $ROOT_DIR/mnt/huawei/system/priv-app/AssistManager/AssistManager.apk
[ $? -ne 0 ] && echo "Error! Can't copy AssistMessenger.apk to $ROOT_DIR/mnt/huawei/system/priv-app/AssistManager/AssistManager.apk" && exit
echo "ClockworkSettings..."
cp -f $ROOT_DIR/packages/ClockworkSettings.apk $ROOT_DIR/mnt/huawei/system/priv-app/ClockworkSettings/
[ $? -ne 0 ] && echo "Error! Can't copy ClockworkSettings.apk to $ROOT_DIR/mnt/huawei/system/priv-app/ClockworkSettings/ClockworkSettings.apk" && exit
echo "UpdateService..."
cp -f $ROOT_DIR/packages/UpdateService.apk $ROOT_DIR/mnt/huawei/system/priv-app/UpdateService/
[ $? -ne 0 ] && echo "Error! Can't copy UpdateService.apk to $ROOT_DIR/mnt/huawei/system/priv-app/UpdateService/UpdateService.apk" && exit
echo "services.jar..."
cp -f $ROOT_DIR/packages/services.jar $ROOT_DIR/mnt/huawei/system/framework/
[ $? -ne 0 ] && echo "Error! Can't copy services.jar to $ROOT_DIR/mnt/huawei/system/framework/services.jar" && exit

build_number=`/bin/date +%Y%m%d%H%M`
sed -i -- "s/store.ota.version=.*/store.ota.version=$build_number/g" $ROOT_DIR/mnt/huawei/system/build.prop
[ $? -ne 0 ] && echo "Error! Can't replace build number in $ROOT_DIR/mnt/huawei/system/build.prop" && exit
echo "***Done!***"

#packaging new ROM
echo -e "\n***Packaging ROM***"
cd $ROOT_DIR/mnt/huawei
umount system
img2simg system.img system_snew.img
[ $? -ne 0 ] && echo "Error! Can't create sparced image from $ROOT_DIR/mnt/huawei/system.img" && exit
img2sdat.py system_snew.img . 4
[ $? -ne 0 ] && echo "Error! Can't create DAT files from  $ROOT_DIR/mnt/huawei/system_snew.img" && exit
cp -f system.new.dat $ROOT_DIR/rom/huawei-rom
[ $? -ne 0 ] && echo "Error! Can't copy $ROOT_DIR/mnt/huawei/system.new.dat to ROM folder" && exit
cp -f system.patch.dat $ROOT_DIR/rom/huawei-rom
[ $? -ne 0 ] && echo "Error! Can't copy $ROOT_DIR/mnt/huawei/system.patch.dat to ROM folder" && exit
cp -f system.transfer.list $ROOT_DIR/rom/huawei-rom
[ $? -ne 0 ] && echo "Error! Can't copy $ROOT_DIR/mnt/huawei/system.transfer.list to ROM folder" && exit
cp -f $ROOT_DIR/src/huawei-rom/CustomRom/boot.img $ROOT_DIR/rom/huawei-rom
[ $? -ne 0 ] && echo "Error! Can't copy $ROOT_DIR/src/huawei-rom/CustomRom/boot.img to ROM folder" && exit

cd $ROOT_DIR/rom/huawei-rom
[ $? -ne 0 ] && echo "Error! Can't zip archive with a new ROM, can't find folder $ROOT_DIR/rom/huawei-rom" && exit
zip -r9 $ROOT_DIR/sign/Huawei_Watch2_$build_number.zip *
[ $? -ne 0 ] && echo "Error! Can't zip archive with a new ROM" && exit
echo "***Done!***"

#signing
echo -e "\n***Signing ROM***"
cd $ROOT_DIR/sign
java -jar signapk.jar platform.x509.pem platform.pk8 Huawei_Watch2_$build_number.zip $ROOT_DIR/out/Huawei_Watch2_$build_number.zip
[ $? -ne 0 ] && echo "Error! Can't sign ROM archive" && exit
rm -f $ROOT_DIR/sign/Huawei_Watch2_$build_number.zip
echo -e "***Done!***"
echo "Path to new ROM: $ROOT_DIR/out/Huawei_Watch2_$build_number.zip"
