#!/bin/bash
# ================== 【终极版】彻底清除 Rust 及编译缓存 ==================
echo "========================================="
echo " 正在执行终极 Rust 清理操作..."
echo "========================================="

# 1. 物理删除 feeds 中的 rust 源码目录
rm -rf feeds/packages/lang/rust
echo ">> 已删除 feeds/packages/lang/rust"

# 2. 清理 build_dir 和 staging_dir 中的 Rust 编译缓存
rm -rf build_dir/target-*/host/rustc-*
rm -rf staging_dir/target-*/host/rustc-*
rm -rf build_dir/target-*/host/cargo-*
echo ">> 已清理 build_dir 和 staging_dir 中的 Rust 缓存"

# 3. 清理 dl 目录下可能损坏的 Rust 压缩包
rm -f dl/rust*
rm -f dl/cargo*
echo ">> 已清理 dl 目录下的 Rust 压缩包"

# 4. 禁用 .config 中所有 Rust 相关选项
sed -i 's/^CONFIG_PACKAGE_rust=y/# CONFIG_PACKAGE_rust is not set/' .config
sed -i 's/^CONFIG_RUST_SCCACHE=y/# CONFIG_RUST_SCCACHE is not set/' .config
sed -i 's/^CONFIG_RUST_SCCACHE_DIR=.*/CONFIG_RUST_SCCACHE_DIR=""/' .config
sed -i 's/^CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client=y/# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client is not set/' .config
sed -i 's/^CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Server=y/# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Server is not set/' .config
sed -i 's/^CONFIG_PACKAGE_luci-app-rustdesk-server=y/# CONFIG_PACKAGE_luci-app-rustdesk-server is not set/' .config
sed -i 's/^CONFIG_PACKAGE_shadowsocks-rust-.*=y/# & is not set/' .config
sed -i 's/^CONFIG_PACKAGE_rustdesk-server=y/# CONFIG_PACKAGE_rustdesk-server is not set/' .config
echo ">> 已在 .config 中禁用 Rust 相关选项"

# 5. 修改默认时区为 CST-8 (北京时间)
sed -i 's/^CONFIG_TIMEZONE=.*$/CONFIG_TIMEZONE="CST-8"/' .config
echo ">> 已将默认时区修改为 CST-8（北京时间）"

# 6. 重新生成依赖关系
make defconfig
echo ">> 已重新生成依赖关系"

echo "========================================="
echo " Rust 清理完成，准备开始编译..."
echo "========================================="
