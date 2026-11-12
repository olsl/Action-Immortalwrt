#!/bin/bash
# YYETs-LE2 (MT7621) 设备支持 - 在 feeds update 之前执行
set -x

# 1. 恢复被 fork 裁剪的 mt76 驱动包（板载双 MT7612E 需要 kmod-mt76x2）
git clone --depth 1 --filter=blob:none --sparse -b openwrt-24.10 \
  https://github.com/immortalwrt/immortalwrt.git /tmp/immwrt
cd /tmp/immwrt && git sparse-checkout set package/kernel/mt76 package/kernel/rtl8812au-ct
cp -r package/kernel/mt76 $GITHUB_WORKSPACE/openwrt/package/kernel/
# 3. 恢复 RTL8812AU(USB) 驱动包 kmod-rtl8812au-ct（fork 里没有，用于外接 8812AU USB 网卡）
cp -r package/kernel/rtl8812au-ct $GITHUB_WORKSPACE/openwrt/package/kernel/
cd $GITHUB_WORKSPACE/openwrt

# 2. 拷贝设备 dts 到源码树
cp $GITHUB_WORKSPACE/mt7621_hoolxun_yyets_le2.dts target/linux/ramips/dts/

# 2b. 状态页温度读取（MT7621 无 on-die 传感器；直读 MT7612E 温度寄存器，无源显示 5G N/A）
mkdir -p target/linux/ramips/base-files/sbin
cat > target/linux/ramips/base-files/sbin/tempinfo <<'EOF'
#!/bin/sh
# LuCI 状态页温度 - YYETs-LE2 定制（MT7612E 5G 射频温度）
# 原理：mt76 的 dev->cal.temp 依赖 eeprom 温度补偿数据，新内核下常为 0；
#       这里直接读 MT7612E 温度传感器寄存器 MT_TEMP_SENSOR(0x1d000)，
#       按驱动公式 temp = ((reg & 0x7f) - ref25) * 1789 / 1000 + 25 换算，
#       ref25 取 eeprom 0x55 字节低 7 位（MT_EE_TX_POWER_EXT_PA_5G 高字节）。
DBG=""
for d in /sys/kernel/debug/ieee80211/phy1/mt76 /sys/kernel/debug/ieee80211/phy0/mt76; do
	[ -d "$d" ] && DBG="$d" && break
done
if [ -n "$DBG" ]; then
	echo 0x1d000 > "$DBG/regidx" 2>/dev/null
	RAW=$(cat "$DBG/regval" 2>/dev/null)
	BB=$(dd if="$DBG/eeprom" bs=1 skip=85 count=1 2>/dev/null | hexdump -e '1/1 "%02x"' 2>/dev/null)
	case "$RAW" in
	0x[0-9a-fA-F]*) : ;;
	*) RAW="" ;;
	esac
	if [ -n "$RAW" ] && [ -n "$BB" ]; then
		VAL=$(( RAW & 0x7f ))
		REF=$(( 0x$BB & 0x7f ))
		T=$(( (VAL - REF) * 1789 / 1000 + 25 ))
		if [ "$T" -ge 5 ] 2>/dev/null && [ "$T" -le 120 ]; then
			echo "5G ${T}°C"
			exit 0
		fi
	fi
fi
echo "5G N/A"
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
