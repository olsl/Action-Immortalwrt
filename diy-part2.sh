# ================== 【终极版】彻底清除 Rust 及编译缓存 ==================
echo "========================================="
echo " 正在执行终极 Rust 清理操作..."
echo "========================================="

# 1. 物理删除 feeds 中的 rust 源码目录
rm -rf feeds/packages/lang/rust
echo ">> 已删除 feeds/packages/lang/rust"

# 2. 【关键】清理 build_dir 和 staging_dir 中的 Rust 编译缓存
# 这是解决缓存导致反复报错的核心步骤！
rm -rf build_dir/target-*/host/rustc-*
rm -rf staging_dir/target-*/host/rustc-*
rm -rf build_dir/target-*/host/cargo-*
echo ">> 已清理 build_dir 和 staging_dir 中的 Rust 缓存"

# 3. 清理 dl 目录下可能损坏的 Rust 压缩包
rm -f dl/rust*
rm -f dl/cargo*
echo ">> 已清理 dl 目录下的 Rust 压缩包"

# 4. 在 .config 中显式禁用所有 Rust 相关选项
sed -i 's/CONFIG_PACKAGE_rust=y/# CONFIG_PACKAGE_rust is not set/g' .config
sed -i 's/CONFIG_PACKAGE_cargo=y/# CONFIG_PACKAGE_cargo is not set/g' .config
sed -i 's/CONFIG_PACKAGE_libruststd=y/# CONFIG_PACKAGE_libruststd is not set/g' .config
sed -i 's/CONFIG_PACKAGE_rust-host=y/# CONFIG_PACKAGE_rust-host is not set/g' .config

# 5. 【关键】重新生成依赖关系，让系统彻底忘记 Rust 的存在
./scripts/feeds update -a
./scripts/feeds install -a
make defconfig
echo ">> 已重新生成依赖关系"

echo "========================================="
echo " 终极清理完成，准备开始编译..."
echo "========================================="
# ============================================================================
