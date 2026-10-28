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

# 2b. 状态页温度读取（MT7621 无 on-die 传感器；读无线卡/内核温度源，无源显示 N/A）
mkdir -p target/linux/ramips/base-files/sbin
cat > target/linux/ramips/base-files/sbin/tempinfo <<'EOF'
#!/bin/sh
# ImmortalWrt 状态页温度 - YYETs-LE2 定制
# MT7621 CPU 无温度传感器（芯片设计）；优先读内核 thermal/hwmon，其次 mt76 无线卡温度
T=""
if [ -r /sys/class/thermal/thermal_zone0/temp ]; then
	T=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
	[ -n "$T" ] && [ "$T" -gt 1000 ] 2>/dev/null && T=$((T/1000))
fi
if [ -z "$T" ]; then
	for f in /sys/class/hwmon/hwmon*/temp*_input; do
		[ -r "$f" ] && T=$(cat "$f" 2>/dev/null) && break
	done
fi
# mt76 无线卡温度（MT7612E debugfs，0=未启用）
if [ -z "$T" ] || [ "$T" = "0" ]; then
	mount -t debugfs none /sys/kernel/debug 2>/dev/null
	for p in /sys/kernel/debug/ieee80211/phy*/mt76/temperature; do
		[ -r "$p" ] || continue
		v=$(cat "$p" 2>/dev/null | tr -d '[:space:]')
		case "$v" in
			''|*[!0-9]*) continue ;;
			*) [ "$v" -ge 1 ] && [ "$v" -le 120 ] && T="$v" && break ;;
		esac
	done
fi
if [ -n "$T" ]; then
	case "$T" in
		*°) echo "$T" ;;
		*) echo "${T}°C" ;;
	esac
else
	echo "N/A"
fi
EOF
chmod +x target/linux/ramips/base-files/sbin/tempinfo

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
