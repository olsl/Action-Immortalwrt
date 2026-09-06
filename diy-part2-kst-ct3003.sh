#!/bin/bash
# DIY part 2 for KST WF3000A (ct3003-based, 5.4 kernel)

# Remove rust toolchain (rustc-1.94.0 has checksum build failure, not needed for selected packages)
rm -rf feeds/packages/lang/rust

# Modify default IP
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# Modify filename, add date prefix
sed -i 's/IMG_PREFIX:=/IMG_PREFIX:=$(shell date +"%Y%m%d")-/1' include/image.mk

# Add sleep 3 to ppp-down
sed -i '$a\\sleep 3' package/network/services/ppp/files/lib/netifd/ppp-down

# Increase conntrack
echo 'net.netfilter.nf_conntrack_buckets=65536' >> package/kernel/linux/files/sysctl-nf-conntrack.conf
echo 'net.netfilter.nf_conntrack_expect_max=16384' >> package/kernel/linux/files/sysctl-nf-conntrack.conf
echo 'net.netfilter.nf_conntrack_max=100000' >> package/kernel/linux/files/sysctl-nf-conntrack.conf
