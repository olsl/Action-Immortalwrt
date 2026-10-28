#!/bin/bash
# YYETs-LE2 (MT7621) 设备支持 - 在 feeds update 之前执行
set -x

# 1. 恢复被 fork 裁剪的 mt76 驱动包（板载双 MT7612E 需要 kmod-mt76x2）
git clone --depth 1 --filter=blob:none --sparse -b openwrt-24.10 \
  https://github.com/immortalwrt/immortalwrt.git /tmp/immwrt
cd /tmp/immwrt && git sparse-checkout set package/kernel/mt76
cp -r package/kernel/mt76 $GITHUB_WORKSPACE/openwrt/package/kernel/
cd $GITHUB_WORKSPACE/openwrt

# 2. 拷贝设备 dts 到源码树
cp $GITHUB_WORKSPACE/mt7621_hoolxun_yyets_le2.dts target/linux/ramips/dts/

# 3. 追加设备定义到 mt7621.mk（IMAGE_SIZE 按 firmware 分区 0x50000~0x2000000 = 32448KiB）
cat >> target/linux/ramips/image/mt7621.mk <<'EOF'

define Device/hoolxun_yyets-le2
  DEVICE_VENDOR := HOELXUN
  DEVICE_MODEL := YYETs-LE2
  DEVICE_DTS := mt7621_hoolxun_yyets_le2
  IMAGE_SIZE := 32448k
  DEVICE_PACKAGES := kmod-mt76x2 kmod-mt7603 kmod-rtl8188eu kmod-rt2800-usb \
	kmod-usb3 kmod-usb2 kmod-usb-storage kmod-fs-exfat kmod-fs-vfat \
	kmod-fs-ext4 kmod-fs-ntfs3 block-mount usbutils \
	kmod-usb-net kmod-usb-net-rndis kmod-usb-net-cdc-ether \
	kmod-usb-net-cdc-eem kmod-usb-net-cdc-mbim kmod-usb-net-ipheth \
	usb-modeswitch relayd aircrack-ng tcpdump horst iw \
	kmod-wireguard wireguard-tools luci-proto-wireguard kmod-nf-flow \
	luci-theme-argon
  IMAGE/sysupgrade.bin := append-kernel | append-rootfs | pad-rootfs | check-size
endef
TARGET_DEVICES += hoolxun_yyets-le2
EOF

echo "[YYETs-LE2] mt76 驱动已恢复 + dts + mt7621.mk 设备定义已写入"
