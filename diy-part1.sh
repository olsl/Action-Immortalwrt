#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Uncomment a feed source
# sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
# echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
# echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default
# echo 'src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages' >>feeds.conf.default

# Fix: copy kst_wf3000a DTS to expected path for 6.6 kernel build
# filogic.mk uses DEVICE_DTS_DIR := $(DTS_DIR)/mediatek, expecting DTS under
# target/linux/mediatek/dts/mediatek/, but it only ships in files-6.6/
mkdir -p target/linux/mediatek/dts/mediatek
cp -f target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981-kst-wf3000a.dts target/linux/mediatek/dts/mediatek/
cp -f target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981.dtsi target/linux/mediatek/dts/mediatek/

# Fix: add missing HIT_BIND_FORCE_TO_CPU define to mtk_eth_reset.h
# This macro is used by mtk_eth_soc.c but missing in 6.6 kernel headers
sed -i '/#define MTK_FE_RESET_NAT_DONE/a #define HIT_BIND_FORCE_TO_CPU 0x16' target/linux/mediatek/files-6.6/drivers/net/ethernet/mediatek/mtk_eth_reset.h

# Fix: add missing #include "mtk_eth_reset.h" to mtk_eth_soc.c
# 6 private macros (MTK_FE_START_RESET etc.) are defined in mtk_eth_reset.h
# but mtk_eth_soc.c does not include this header, causing compile failure
sed -i '/#include "mtk_ppe.h"/a #include "mtk_eth_reset.h"' drivers/net/ethernet/mediatek/mtk_eth_soc.c
