#!/bin/bash
#
# diy-part2 for TP-Link WMA301 V2 (5.4 build)
# 与 kj30-n 那份基本一致，唯一区别：**不改默认 LAN IP**（保持 192.168.1.1）。
# 原因：你现网 192.168.6.1 已经被 360T7 占着，新机器再默认 6.1 会撞 IP。
# 想改成 192.168.6.x 就把下面那行的注释去掉、改掉数字即可。
#

# Modify default IP  —— 默认不动，避免和你现网的 192.168.6.1 冲突
#sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate

# Modify hostname
#sed -i 's/ImmortalWrt/ImmortalWrt-Hanwckf/g' package/base-files/files/bin/config_generate

# Modify filename, add date prefix
sed -i 's/IMG_PREFIX:=/IMG_PREFIX:=$(shell date +"%Y%m%d")-/1' include/image.mk

# Modify ppp-down, add sleep 3
sed -i '$a\\sleep 3' package/network/services/ppp/files/lib/netifd/ppp-down

# 增加连接数
echo 'net.netfilter.nf_conntrack_buckets=65536' >>package/kernel/linux/files/sysctl-nf-conntrack.conf
echo 'net.netfilter.nf_conntrack_expect_max=16384' >>package/kernel/linux/files/sysctl-nf-conntrack.conf
echo 'net.netfilter.nf_conntrack_max=100000' >>package/kernel/linux/files/sysctl-nf-conntrack.conf

# ---------------------------------------------------------------------------
# 保险：强制 warp 驱动版本 = 2
# 配置文件里本来就有 CONFIG_WARP_VERSION=2，但如果那份 .config 被存成 \r\n / \r\r\n，
# kconfig 会把值读成 "2\r" 判为无效并退回默认 1；版本 1 去编 regs/reg_v1/warp_hw_v1.c，
# 与 mt7981 这套寄存器头文件（WED_WDMA_* / WDMA_*_FLD_*）对不上，会爆 73 个
# "undeclared identifier" 直接编译失败。这里用干净行尾补一行，兜底。
# ---------------------------------------------------------------------------
if grep -qx 'CONFIG_WARP_VERSION=2' .config; then
    echo "==> [WMA301] CONFIG_WARP_VERSION=2 已存在，无需处理"
else
    echo 'CONFIG_WARP_VERSION=2' >>.config
    echo "==> [WMA301] 已补写 CONFIG_WARP_VERSION=2"
fi
grep -n '^CONFIG_WARP_VERSION' .config
