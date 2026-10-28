#!/bin/bash
# YYETs-LE2 定制 - 在 feeds install 之后执行

# 保持原机网段 192.168.8.1
sed -i 's/192.168.1.1/192.168.8.1/g' package/base-files/files/bin/config_generate

# 默认主题改为 Argon
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 连接数优化
echo 'net.netfilter.nf_conntrack_buckets=65536' >>package/kernel/linux/files/sysctl-nf-conntrack.conf
echo 'net.netfilter.nf_conntrack_expect_max=16384' >>package/kernel/linux/files/sysctl-nf-conntrack.conf
echo 'net.netfilter.nf_conntrack_max=100000' >>package/kernel/linux/files/sysctl-nf-conntrack.conf

# 固件文件名加日期前缀
sed -i 's/IMG_PREFIX:=/IMG_PREFIX:=$(shell date +"%Y%m%d")-/1' include/image.mk

# 8188EU 启动失联修复：vendor 驱动启动早期 probe 会阻塞网络初始化导致失联
# 方案：移除 boot 自动加载，改由 rc.local 在网络就绪后延迟加载；radio2 默认禁用
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-yyets-8188eu <<'EOF'
#!/bin/sh
# 移除启动早期自动 insmod（probe 阻塞 -> 网络起不来 -> 失联）
rm -f /etc/modules.d/rtl8188eu
# 网络就绪后延迟加载（启动时已插卡也能先通网再出无线）
grep -q 'modprobe rtl8188eu' /etc/rc.local 2>/dev/null || \
	sed -i '/^exit 0$/i sleep 50 \&\& modprobe rtl8188eu \&' /etc/rc.local
# radio2(8188EU) 默认禁用，避免 hostapd/br-lan 冲突，需要时 LUCI 手动开启
uci -q set wireless.radio2.disabled='1'
uci -q commit wireless
exit 0
EOF
chmod +x files/etc/uci-defaults/99-yyets-8188eu

echo "[YYETs-LE2] 定制完成: IP=192.168.8.1 / 主题=Argon / 连接数优化 / tempinfo / 8188EU延迟加载"
