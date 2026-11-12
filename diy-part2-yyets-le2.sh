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

# 端口严谨性：board.d 覆盖 board.json（物理 1WAN+2LAN），DSA 自动枚举的 4 LAN 在此修正
mkdir -p files/etc/board.d
cat > files/etc/board.d/99-yyets-ports <<'EOF'
#!/bin/sh
# YYETs-LE2 物理 1WAN+2LAN：lan1/lan2 为 LAN，wan 为 WAN。
# 注意：board.d 脚本由 /bin/board_detect 在子 shell 中 source，取不到 ucidef_* 函数，
#       且 ucidef_set_interface_lan 是"追加"语义（会导致 ports 越跑越多），
#       故这里用 sed 把 network.lan.ports 收敛为 lan1/lan2。
CFG=${CFG:-/etc/board.json}
[ -s "$CFG" ] || exit 0
sed -i \
  -e '/^[[:space:]]*"lan3",*$/d' \
  -e '/^[[:space:]]*"lan4",*$/d' \
  -e 's/^([[:space:]]*)"lan2",/\1"lan2"/' \
  "$CFG"
exit 0
EOF
chmod +x files/etc/board.d/99-yyets-ports

# 端口严谨性：dts 已禁用 port0/1（lan4/lan3），升级保留配置时清理残留引用，LUCI 不再显示
cat > files/etc/uci-defaults/98-yyets-ports <<'EOF'
#!/bin/sh
# 清理 dts 已禁用端口在旧配置中的残留（network 接口 + br-lan 桥端口）
for p in lan3 lan4; do
	uci -q delete network.$p
	i=0
	while uci -q get network.@device[$i].name >/dev/null 2>&1; do
		uci -q del_list network.@device[$i].ports="$p"
		i=$((i+1))
	done
done
uci -q commit network
exit 0
EOF
chmod +x files/etc/uci-defaults/98-yyets-ports

# SSH 可用性：确保刷机后 dropbear 开机启用、22 端口、密码登录，并默认放通 wg0/wan 侧 22
cat > files/etc/uci-defaults/99-yyets-ssh <<'EOF'
#!/bin/sh
# dropbear：密码登录 + 22 端口 + 开机启用（镜像默认可能关闭，这里强制打开）
uci -q set dropbear.main=dropbear
uci -q set dropbear.main.PasswordAuth=on
uci -q set dropbear.main.Port=22
uci -q commit dropbear
/etc/init.d/dropbear enable

# 防火墙：放通 wg0（隧道/远程运维）与 wan 侧的 22 端口，避免刷机后远程失联
uci -q delete firewall.allow_ssh_wg 2>/dev/null
uci -q set firewall.allow_ssh_wg=rule
uci -q set firewall.allow_ssh_wg.name='Allow-SSH-WG'
uci -q set firewall.allow_ssh_wg.src='wg0'
uci -q set firewall.allow_ssh_wg.dest_port='22'
uci -q set firewall.allow_ssh_wg.proto='tcp'
uci -q set firewall.allow_ssh_wg.target='ACCEPT'

uci -q delete firewall.allow_ssh_wan 2>/dev/null
uci -q set firewall.allow_ssh_wan=rule
uci -q set firewall.allow_ssh_wan.name='Allow-SSH-WAN'
uci -q set firewall.allow_ssh_wan.src='wan'
uci -q set firewall.allow_ssh_wan.dest_port='22'
uci -q set firewall.allow_ssh_wan.proto='tcp'
uci -q set firewall.allow_ssh_wan.target='ACCEPT'
uci -q commit firewall

/etc/init.d/firewall reload >/dev/null 2>&1
exit 0
EOF
chmod +x files/etc/uci-defaults/99-yyets-ssh

# 升级保留清单：把定制文件写进镜像默认的 /etc/sysupgrade.conf，刷机后不会丢
cat > files/etc/sysupgrade.conf <<'EOF'
# 自定义保留：wifi-relay 定制页 + 首页温度 + 端口修正 + 中继脚本
/etc/wireguard
/etc/hotplug.d/iface/90-wg-endpoint
/root
/etc/board.json
/sbin/tempinfo
/usr/bin/wifi_auto_select.sh
/usr/libexec/rpcd/wifi-relay
/www/luci-static/resources/view/network/wifi-relay.js
/www/luci-static/resources/view/status/include/10_system.js
/usr/share/rpcd/ucode/luci
/usr/share/rpcd/acl.d/luci-mod-status.json
/usr/share/rpcd/acl.d/luci-mod-status-index.json
/usr/share/rpcd/acl.d/luci-wifi-relay.json
/usr/share/luci/menu.d/luci-app-wifi-relay.json
EOF

# ---- WireGuard 联网自愈: 网络一通就恢复（刷机/换网后不再需要手动修 wg） ----
mkdir -p files/etc/wireguard files/etc/hotplug.d/iface
cat > files/etc/wireguard/update_wg_endpoint.sh <<'WGW'
#!/bin/sh
# 8.1 (HOELXUN YYETs-LE2) spoke: 动态 endpoint 选择
# 原则: 能通就用, 不管怎么联网
#   场景A 中继/内网(任一 STA 上行拿到 192.168.6.x): 直连 192.168.6.1:51820
#          (2.4G 走 phy0-sta0、5G 走 phy1-sta0 都按实际持有的接口判定)
#   场景B 异地(公网): 用 TXT(360t7wg.olsl.cc.cd) 的 lucky 打洞映射
PEER_PUB='sbMVivgp63nX/coj1SfIMU3OKvMlBxbEjv24QT/bS0A='
DNS='223.5.5.5'
DOMAIN='360t7wg.olsl.cc.cd'
HUB_LAN='192.168.6.1'
HUB_PORT='51820'

# 接口没起来就先拉起 (开机/重连后 netifd 可能尚未拉起 wg0)
ip link show wg0 >/dev/null 2>&1 || ifup wg0

# --- 找出承载 192.168.6.x 的上行接口: 2.4G/5G 中继都适用 ---
LANIF=""
for i in $(ls /sys/class/net 2>/dev/null); do
	case "$i" in
		phy*-sta0|wwan*|usb*) ;;
		*) continue ;;
	esac
	if ip -4 addr show "$i" 2>/dev/null | grep -q 'inet 192\.168\.6\.'; then
		LANIF="$i"
		break
	fi
done

# --- 场景A: 有 6.x 上行且 hub 可达 ---
if [ -n "$LANIF" ]; then
	# 维护直连主机路由: 覆盖 wg0 的 192.168.6.0/24 隧道路由, 防止流量进死隧道
	ip route replace "$HUB_LAN/32" dev "$LANIF" 2>/dev/null || \
		ip route add "$HUB_LAN/32" dev "$LANIF" 2>/dev/null
	if ping -c 1 -W 2 "$HUB_LAN" >/dev/null 2>&1; then
		wg set wg0 peer "$PEER_PUB" endpoint "$HUB_LAN:$HUB_PORT"
		logger -t wg-update "endpoint -> lan $HUB_LAN:$HUB_PORT (via $LANIF)"
		exit 0
	fi
	logger -t wg-update "上行 $LANIF 有 6.x 地址但 hub 不通, 转公网分支"
fi

# --- 场景B: 异地/公网, 用 TXT 打洞映射 (无 dig 时用 busybox nslookup) ---
if command -v dig >/dev/null 2>&1; then
	EP=$(dig +short TXT "$DOMAIN" @"$DNS" 2>/dev/null | tr -d '"')
else
	EP=$(nslookup -type=TXT "$DOMAIN" "$DNS" 2>/dev/null | sed -n 's/.*text *= *"\{0,1\}\([^"]*\)"\{0,1\}.*/\1/p' | head -n 1)
fi
[ -z "$EP" ] && { logger -t wg-update "取不到公网 endpoint, 保持现状"; exit 0; }
CUR=$(wg show wg0 endpoints 2>/dev/null | grep "$PEER_PUB" | awk '{print $2}')
if [ -z "$CUR" ] || [ "$EP" != "$CUR" ]; then
	wg set wg0 peer "$PEER_PUB" endpoint "$EP"
	logger -t wg-update "endpoint -> $EP (was: $CUR)"
fi
exit 0
WGW
chmod +x files/etc/wireguard/update_wg_endpoint.sh

cat > files/etc/hotplug.d/iface/90-wg-endpoint <<'WGH'
#!/bin/sh
# 网络一通就恢复 WireGuard: endpoint 跟随当前联网方式(中继内网/公网打洞)
# netifd 每次 ifup/ifdown 都会调用本脚本
[ "$ACTION" = "ifup" ] || exit 0
case "$INTERFACE" in
	wwan|wg0|wan|lan) ;;
	*) exit 0 ;;
esac
[ -x /etc/wireguard/update_wg_endpoint.sh ] || exit 0
# 等接口地址/路由落定再改 endpoint
( sleep 3; /etc/wireguard/update_wg_endpoint.sh >/dev/null 2>&1; \
  logger -t wg-hotplug "ifup $INTERFACE -> $(wg show wg0 endpoints 2>/dev/null | awk '{print $2}')" ) &
exit 0
WGH
chmod +x files/etc/hotplug.d/iface/90-wg-endpoint

echo "[YYETs-LE2] 定制完成: IP=192.168.8.1 / 主题=Argon / 连接数优化 / tempinfo / 8188EU延迟加载 / 端口残留清理 / SSH+防火墙放通 / 升级保留清单"
