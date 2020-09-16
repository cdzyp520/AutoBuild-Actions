#!/bin/bash
# AutoBuild Script Module by Hyy2001
# Actions

Diy_Core() {
#自定义作者、配置等信息
Author=Hyy2001
Github=https://github.com/Hyy2001X/Openwrt-AutoUpdate
TARGET_BOARD=ramips
TARGET_SUBTARGET=mt7621
TARGET_PROFILE=d-team_newifi-d2
}

ExtraPackages_GIT() {
[ -d ./package/lean/$1 ] && rm -rf ./package/lean/$1
while [ ! -f $1/Makefile ]
do
	git clone -b $3 $2/$1 $1
done
mv $1 ./package/lean
}

ExtraPackages_SVN() {
[ -d ./package/lean/$1 ] && rm -rf ./package/lean/$1
while [ ! -f $1/Makefile ]
do
	echo "Checking out $1 from $2 ..."
	svn checkout $2/$1 $1 > /dev/null 2>&1
done
echo "Package $1 detected!"
mv $1 ./package/lean
}

Diy-Part1() {
sed -i "s/#src-git helloworld/src-git helloworld/g" feeds.conf.default
#添加额外的软件包,使用方法: 
#[git clone] ExtraPackages_GIT 软件包名称 仓库地址 分支
#[svn checkout] ExtraPackages_SVN 软件包名称 仓库地址
ExtraPackages_GIT luci-theme-argon https://github.com/jerrykuku 18.06
ExtraPackages_SVN luci-app-openclash https://github.com/vernesong/OpenClash/trunk
ExtraPackages_SVN luci-app-adguardhome https://github.com/Lienol/openwrt/trunk/package/diy
ExtraPackages_SVN luci-app-smartdns https://github.com/project-openwrt/openwrt/trunk/package/ntlf9t
ExtraPackages_SVN smartdns https://github.com/project-openwrt/openwrt/trunk/package/ntlf9t
#添加 AutoUpdate 自动更新脚本到固件
[ -d ./Openwrt-AutoUpdate ] && rm -rf ./Openwrt-AutoUpdate
git clone $Github
mv Openwrt-AutoUpdate/AutoUpdate.sh ./package/base-files/files/bin
}

Diy-Part2() {
Date=`date +%Y/%m/%d`
DefaultFile=./package/lean/default-settings/files/zzz-default-settings
Version=`egrep -o "R[0-9]+\.[0-9]+\.[0-9]+" $DefaultFile`
#Openwrt 主界面显示作者、编译日期
if [ ! $(grep -o "Compiled by $Author" $DefaultFile | wc -l) = "1" ];then
	sed -i "s?$Version?$Version Compiled by $Author [$Date]?g" $DefaultFile
fi
Old_Date=`egrep -o "[0-9]+\/[0-9]+\/[0-9]+" $DefaultFile`
if [ ! $Date == $Old_Date ];then
	sed -i "s?$Old_Date?$Date?g" $DefaultFile
fi
echo "$Version-`date +%Y%m%d`" > ./package/base-files/files/etc/openwrt_date
}

Diy-Part3() {
Compile_Time=`date +'%Y-%m-%d %H:%M:%S'`
Version=`egrep -o "R[0-9]+\.[0-9]+\.[0-9]+" ./package/lean/default-settings/files/zzz-default-settings`
Default_Firmware=openwrt-$TARGET_BOARD-$TARGET_SUBTARGET-$TARGET_PROFILE-squashfs-sysupgrade.bin
AutoBuild_Firmware=AutoBuild-$TARGET_PROFILE-Lede-$Version`(date +-%Y%m%d.bin)`
AutoBuild_Detail=AutoBuild-$TARGET_PROFILE-Lede-$Version`(date +-%Y%m%d.detail)`

mkdir -p ./bin/Firmware
mv ./bin/targets/$TARGET_BOARD/$TARGET_SUBTARGET/$Default_Firmware ./bin/Firmware/$AutoBuild_Firmware
cd ./bin/Firmware
Firmware_Size=`ls -l $AutoBuild_Firmware | awk '{print $5}'`
Firmware_Size_MB=`awk 'BEGIN{printf "固件大小:%.2fMB\n",'$((Firmware_Size))'/1000000}'`
Firmware_MD5=`md5sum $AutoBuild_Firmware | cut -d ' ' -f1`
Firmware_SHA256=`sha256sum $AutoBuild_Firmware | cut -d ' ' -f1`
echo "$Firmware_Size_MB" > ./$AutoBuild_Detail
echo -e "编译日期:$Compile_Time\n" >> ./$AutoBuild_Detail
echo -e "MD5:$Firmware_MD5\nSHA256:$Firmware_SHA256" >> ./$AutoBuild_Detail
cd ../..
}
