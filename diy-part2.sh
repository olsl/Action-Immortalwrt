#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# ================== 【新增】解决 Rust 编译报错 & 提速 ==================
echo "========================================="
echo " 正在执行防报错与优化操作..."
echo "========================================="

# 1. 物理删除 Rust 源码目录 (最彻底的方法)
# 这样编译器根本找不到它，就不会尝试下载或校验 checksum
rm -rf feeds/packages/lang/rust
echo ">> 已删除 feeds/packages/lang/rust"

# 2. 清理 dl 目录下可能损坏的 Rust 压缩包
# 有时候是因为下载的 rustc-xxx.tar.xz 文件本身坏了，导致无限循环报错
# 这行命令会删除 dl 目录下所有名字带 rust 的文件，强迫下次重新下载（或者直接因为目录被删而放弃）
rm -f dl/rust*
rm -f dl/cargo*
echo ">> 已清理 dl 目录下的 Rust 缓存"

# 3. 在 .config 中显式禁用 Rust 相关选项
# 防止某些依赖 Rust 的插件（如 homeproxy, dae 等）自动唤醒 Rust 编译
sed -i 's/CONFIG_PACKAGE_rust=y/# CONFIG_PACKAGE_rust is not set/g' .config
sed -i 's/CONFIG_PACKAGE_cargo=y/# CONFIG_PACKAGE_cargo is not set/g' .config
sed -i 's/CONFIG_PACKAGE_libruststd=y/# CONFIG_PACKAGE_libruststd is not set/g' .config
sed -i 's/CONFIG_PACKAGE_rust-host=y/# CONFIG_PACKAGE_rust-host is not set/g' .config
echo ">> 已在 .config 中禁用 Rust 相关组件"

echo "========================================="
echo " 优化操作完成，准备开始编译..."
echo "========================================="
# ================================================================


# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate

# Modify timezone to CST-8 (China Standard Time)
sed -i 's/UTC/CST-8/g' package/base-files/files/bin/config_generate
sed -i '/CST-8/a\\tset system.@system[-1].zonename='Asia/Shanghai'' package/base-files/files/bin/config_generate

# Remove useless packages (Optional: remove watchcat if not needed)
# rm -rf feeds/packages/utils/watchcat
