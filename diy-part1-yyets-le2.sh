#!/bin/bash
# YYETs-LE2 (MT7621) 设备支持 - 在 feeds update 之前执行
# 1. 拷贝设备 dts 到源码树
cp $GITHUB_WORKSPACE/mt7621_hoolxun_yyets_le2.dts target/linux/ramips/dts/

# 2. 追加设备定义到 mt7621.mk（全部功能包一次带全）
cat >> target/linux/ramips/image/mt7621.mk <<'EOF'

define Device/hoolxun_yyets-le2
  DEVICE_VENDOR := HOELXUN
  DEVICE_MODEL := YYETs-LE2
  DEVICE_DTS := mt7621_hoolxun_yyets_le2
  DEVICE_PACKAGES := kmod-mt76x2 kmod-rtl8188eu kmod-rt2800-usb \
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

echo "[YYETs-LE2] dts + mt7621.mk 设备定义已写入"
