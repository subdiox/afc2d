#!/bin/bash

OPENSSL_ROOT_DIR=/usr/local/opt/openssl
OPENSSL_LIBRARIES=/usr/local/opt/openssl/lib
export PATH=bin:$PATH

if [[ `uname` != Darwin ]]; then
	echo "This script supports macOS only."
	exit
fi

if ! type cmake > /dev/null 2>&1; then
  echo "[Error] Command \"cmake\" not found. Run \"brew install cmake\" to install it."
	exit
fi

if [[ ! -e $OPENSSL_ROOT_DIR || ! -e $OPENSSL_LIBRARIES ]]; then
  echo "[Error] Command \"openssl\" not found. Run \"brew install openssl\" to install it."
	exit
fi

if [[ ! -d afc2d ]]; then
	rm -f afc2d
	mkdir afc2d
fi
cd afc2d

echo "0. installing xpwn/dmg command ..."
if [[ ! -f bin/dmg || ! -f bin/libdmg.a ]]; then
	git clone https://github.com/planetbeing/xpwn
	pushd xpwn &> /dev/null
	cmake -DOPENSSL_ROOT_DIR=$OPENSSL_ROOT_DIR -DOPENSSL_LIBRARIES=$OPENSSL_LIBRARIES .
	make &> /dev/null
	popd &> /dev/null
	mkdir -p bin
	cp xpwn/dmg/dmg bin/
	cp xpwn/dmg/libdmg.a bin/
	rm -rf xpwn
fi

echo "1. downloading iOS 7.0.6 (iPhone 5s) firmware ..."
if [[ ! -f 058-2384-003.dmg ]]; then
	curl -O "http://appldnld.apple.com/iOS7/031-3045.20140221.8j5GW/iPhone6,1_7.0.6_11B651_Restore.ipsw"
	unzip -j iPhone6,1_7.0.6_11B651_Restore.ipsw 058-2384-003.dmg
	rm iPhone6,1_7.0.6_11B651_Restore.ipsw
fi

echo "2. decrypting dmg file in the firmware ..."
if [[ ! -f rootfs.dmg ]]; then
	dmg extract 058-2384-003.dmg rootfs.dmg -k a0d2c1d5ce091c62dcf28f1ac953e58a6a66c112184d125e177a1285b7e991262e3c5917
fi

echo "3. extracting afc2d command from decrypted dmg ..."
if [[ ! -f afc2d ]]; then
	disk_path=`hdiutil attach rootfs.dmg | awk '{print substr($0, index($0, "/Volumes"))}'`
	cp $disk_path/usr/libexec/afcd afc2d
	hdiutil detach $disk_path
fi

echo "4. downloading Apple File Conduit 2 deb file ..."
if [[ ! -f com.saurik.afc2d_1.2_iphoneos-arm.deb ]]; then
	curl -O http://apt.saurik.com/cydia/debs/com.saurik.afc2d_1.2_iphoneos-arm.deb
fi
ar x com.saurik.afc2d_1.2_iphoneos-arm.deb
if [[ ! -d Library || ! -d usr ]]; then
	tar xf data.tar.gz
fi
if [[ ! -d control ]]; then
	tar xf control.tar.gz
fi

echo "5. signing binaries ..."
cat << EOS > ent.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>platform-application</key>
        <true/>
    </dict>
</plist>
EOS
cp -f afc2d usr/libexec/afc2d
chmod +x usr/libexec/afc2d
chmod +x postrm
ldid -Sent.plist usr/libexec/afc2d
ldid -Sent.plist postrm
cat << EOS > extrainst_
killall -9 lockdownd || true
EOS
chmod +x extrainst_

echo "6. creating patched afc2d deb package ..."
rm data.tar.gz
tar zcf data.tar.gz Library usr
rm control.tar.gz
tar zcf control.tar.gz control postrm extrainst_
rm -f ../afc2d_patched.deb
ar rc ../afc2d_patched.deb debian-binary control.tar.gz data.tar.gz