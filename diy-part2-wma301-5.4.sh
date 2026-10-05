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
