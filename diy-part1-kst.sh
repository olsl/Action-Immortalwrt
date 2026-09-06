#!/bin/bash
#
# DIY part 1 for KST WF3000A (ImmortalWrt 24.10.6, mainline mt76)
# Runs before feeds update
#

# 1. Copy DTS files into source tree
cp $GITHUB_WORKSPACE/mt7981b-kst-wf3000a.dts target/linux/mediatek/dts/
cp $GITHUB_WORKSPACE/mt7981b-kst-wf3000a.dtsi target/linux/mediatek/dts/

# 2. Append device definition to filogic.mk (based on cetron_ct3003)
cat >> target/linux/mediatek/image/filogic.mk <<'EOF'

define Device/kst_wf3000a
  DEVICE_VENDOR := KST
  DEVICE_MODEL := WF3000A
  DEVICE_DTS := mt7981b-kst-wf3000a
  DEVICE_DTS_DIR := ../dts
  SUPPORTED_DEVICES += kst,wf3000a
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 116736k
  KERNEL_IN_UBI := 1
  IMAGES += factory.bin
  IMAGE/factory.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += kst_wf3000a
EOF

# 3. Add OpenClash package
git clone --depth=1 https://github.com/vernesong/OpenClash.git package/openclash
