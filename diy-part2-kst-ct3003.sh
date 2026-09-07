#!/bin/bash
# DIY part 2 for KST WF3000A (ct3003-based, 5.4 kernel)

# Remove rust toolchain (rustc-1.94.0 has checksum build failure, not needed for selected packages)
rm -rf feeds/packages/lang/rust

# Modify default IP
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# Fix mt_wifi ap_cfg.c/cmm_cfg.c implicit declaration of wtbl_update_pwr_offset
# (2410 分支源码缺陷：声明位于 include/mac/mac_mt/fmac/mt_fmac.h（受 MGMT_TXPWR_CTRL
# 保护），但 ap_cfg.c/cmm_cfg.c 的 include 链（rt_config.h）不包含该头文件，
# 启用 CONFIG_MTK_MGMT_TXPWR_CTRL 后即触发 -Werror=implicit-function-declaration。
# 补与 mt_fmac.h 一致的前向声明，C 允许重复声明，不影响后续 include)
MT_WIFI_DIR=package/mtk/drivers/mt_wifi/src/mt_wifi
for f in embedded/ap/ap_cfg.c embedded/common/cmm_cfg.c; do
  grep -q "wtbl_update_pwr_offset" $MT_WIFI_DIR/$f || continue
  sed -i '/^#include "rt_config.h"/a\
#ifdef MGMT_TXPWR_CTRL\
INT wtbl_update_pwr_offset(struct _RTMP_ADAPTER *pAd, struct wifi_dev *wdev);\
#endif' $MT_WIFI_DIR/$f
done


# Modify filename, add date prefix
sed -i 's/IMG_PREFIX:=/IMG_PREFIX:=$(shell date +"%Y%m%d")-/1' include/image.mk

# Add sleep 3 to ppp-down
sed -i '$a\\sleep 3' package/network/services/ppp/files/lib/netifd/ppp-down

# Increase conntrack
echo 'net.netfilter.nf_conntrack_buckets=65536' >> package/kernel/linux/files/sysctl-nf-conntrack.conf
echo 'net.netfilter.nf_conntrack_expect_max=16384' >> package/kernel/linux/files/sysctl-nf-conntrack.conf
echo 'net.netfilter.nf_conntrack_max=100000' >> package/kernel/linux/files/sysctl-nf-conntrack.conf
