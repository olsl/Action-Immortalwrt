#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# ... (前面的代码保持不变) ...

# =============== 以下是修改部分 ===============

# 1. 修改默认 IP (可选)
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# 2. 修改默认主题 (可选)
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 3. 修改主机名 (可选)
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate

# 4. 【修复】移除错误的 watchcat 拉取代码
# rm -rf feeds/packages/utils/watchcat
# git clone ... (删除这行错误的代码)

# 5. 【新增】修改时区为中国标准时间 (北京时间)
# 解释：CST-8 代表 UTC+8 时区，即中国标准时间
sed -i 's/UTC/CST-8/g' package/base-files/files/bin/config_generate

# 6. 【可选】添加 NTP 服务器以确保时间同步 (推荐)
# 如果文件中有关于 NTP 的配置被注释了，可以取消注释并修改为国内服务器
# sed -i 's/0.openwrt.pool.ntp.org/ntp.aliyun.com/g' package/base-files/files/bin/config_generate
# sed -i 's/1.openwrt.pool.ntp.org/ntp1.aliyun.com/g' package/base-files/files/bin/config_generate
# sed -i 's/2.openwrt.pool.ntp.org/ntp2.aliyun.com/g' package/base-files/files/bin/config_generate
# sed -i 's/3.openwrt.pool.ntp.org/ntp3.aliyun.com/g' package/base-files/files/bin/config_generate

# =============== 修改结束 ===============
