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

# ===================== 【新增：强制移除 Rust 解决编译报错】 =====================
echo "正在清理可能导致报错的 Rust 组件..."

# 1. 直接删除 feeds 中的 rust 目录，从源头切断
rm -rf feeds/packages/lang/rust

# 2. 在 .config 中显式禁用所有 rust 相关项 (防止其他插件唤醒它)
sed -i 's/CONFIG_PACKAGE_rust=y/# CONFIG_PACKAGE_rust is not set/g' .config
sed -i 's/CONFIG_PACKAGE_cargo=y/# CONFIG_PACKAGE_cargo is not set/g' .config
sed -i 's/CONFIG_PACKAGE_libruststd=y/# CONFIG_PACKAGE_libruststd is not set/g' .config
sed -i 's/CONFIG_PACKAGE_rust-host=y/# CONFIG_PACKAGE_rust-host is not set/g' .config

echo "Rust 清理完成！"
# ============================================================================

# ===================== 【新增：修改时区为中国标准时间】 =====================
# 将默认时区修改为 CST-8 (东八区北京时间)
sed -i 's/UTC/CST-8/g' package/base-files/files/bin/config_generate

# 替换默认的 NTP 服务器为阿里云，确保时间同步更准确
sed -i 's/0.openwrt.pool.ntp.org/ntp.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/1.openwrt.pool.ntp.org/ntp1.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/2.openwrt.pool.ntp.org/ntp2.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/3.openwrt.pool.ntp.org/ntp3.aliyun.com/g' package/base-files/files/bin/config_generate
# ============================================================================

# ===================== 【原有配置（已优化）】 =====================
# 修改默认 IP (如需修改请取消注释)
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# 修改默认主题 (如需修改请取消注释)
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 修改主机名 (如需修改请取消注释)
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate

# 【注意】已删除原本错误的 watchcat 拉取代码，避免 git clone 报错
